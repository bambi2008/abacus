-- Abacus savings-buddy sync — the ONLY server-side data in an otherwise
-- local-first, privacy-first app. It deliberately stores nothing financial:
-- per person per day we keep an anonymous user id, a calendar date, and a
-- single boolean "logged something that day". No amounts, categories, or
-- notes ever leave the device. See docs/technical-architecture.md.
--
-- Setup (one-time, done by the project owner — not automatable from the app):
--   1. Create a Supabase project (https://supabase.com — free tier is fine).
--   2. Authentication → Providers → enable "Anonymous sign-ins".
--   3. Run this file in the SQL editor.
--   4. Build the app with:
--        --dart-define=SUPABASE_URL=https://xxxx.supabase.co
--        --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
--      With those unset, the app runs exactly as before (local-only buddy).

-- A pairing between two anonymous users. `code` is the human-shareable
-- join code; `partner_id` is null until someone joins.
create table if not exists public.buddy_links (
  id          uuid primary key default gen_random_uuid(),
  code        text unique not null,
  creator_id  uuid not null,
  partner_id  uuid,
  created_at  timestamptz not null default now()
);

-- One row per (link, user, day). `logged` is the whole payload.
create table if not exists public.buddy_marks (
  link_id     uuid not null references public.buddy_links(id) on delete cascade,
  user_id     uuid not null,
  day         date not null,
  logged      boolean not null default true,
  updated_at  timestamptz not null default now(),
  primary key (link_id, user_id, day)
);

alter table public.buddy_links enable row level security;
alter table public.buddy_marks enable row level security;

-- You can see a link only if you're one of its two participants.
create policy "read own links"
  on public.buddy_links for select
  using (auth.uid() = creator_id or auth.uid() = partner_id);

-- You can create a link only as yourself.
create policy "create own link"
  on public.buddy_links for insert
  with check (auth.uid() = creator_id);

-- Marks are readable by both participants of the link...
create policy "read link marks"
  on public.buddy_marks for select
  using (
    exists (
      select 1 from public.buddy_links l
      where l.id = link_id and (auth.uid() = l.creator_id or auth.uid() = l.partner_id)
    )
  );

-- ...but writable only for your own rows on a link you belong to.
create policy "write own marks"
  on public.buddy_marks for insert
  with check (
    auth.uid() = user_id and exists (
      select 1 from public.buddy_links l
      where l.id = link_id and (auth.uid() = l.creator_id or auth.uid() = l.partner_id)
    )
  );

create policy "update own marks"
  on public.buddy_marks for update
  using (auth.uid() = user_id);

-- Joining is a security-definer RPC because the joiner does NOT yet own the
-- link row (so RLS would otherwise hide it). This atomically claims an
-- unclaimed link by code, refusing to let the creator join their own link.
create or replace function public.join_buddy_link(join_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  claimed_id uuid;
begin
  update public.buddy_links
     set partner_id = auth.uid()
   where code = join_code
     and partner_id is null
     and creator_id <> auth.uid()
  returning id into claimed_id;
  return claimed_id;
end;
$$;

-- Realtime so both devices update live (partner joining, partner logging a
-- day) instead of only on the next local action. RLS still applies to
-- Realtime the same as regular queries — a device only ever receives
-- events for rows it's already allowed to read.
alter publication supabase_realtime add table public.buddy_links;
alter publication supabase_realtime add table public.buddy_marks;
