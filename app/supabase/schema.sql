-- Abacus savings-buddy sync — Supabase schema.
--
-- Run this once in a fresh Supabase project (SQL Editor → paste → Run).
-- Then also: Authentication → Providers → enable "Anonymous sign-ins".
--
-- PRIVACY BOUNDARY (load-bearing for Abacus's positioning): the only data
-- that ever leaves a device is, per buddy per day, an anonymous auth user
-- id + a calendar date + a single boolean "logged something that day".
-- No amounts, no categories, no notes — nothing financial. Row-Level
-- Security below enforces that a user can only ever read/write rows for a
-- buddy link they are actually part of.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.buddy_links (
  id          uuid primary key default gen_random_uuid(),
  code        text unique not null,
  creator_id  uuid not null references auth.users (id) on delete cascade,
  partner_id  uuid references auth.users (id) on delete set null,
  created_at  timestamptz not null default now()
);

create table if not exists public.buddy_marks (
  link_id  uuid not null references public.buddy_links (id) on delete cascade,
  user_id  uuid not null references auth.users (id) on delete cascade,
  day      date not null,
  logged   boolean not null default false,
  primary key (link_id, user_id, day)
);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------

alter table public.buddy_links enable row level security;
alter table public.buddy_marks enable row level security;

-- buddy_links: a member (creator or partner) can read the link; the creator
-- can insert and delete their own link. Joining is NOT a direct update — it
-- goes through join_buddy_link() below (security definer), because the
-- joiner has no read/update access to an unclaimed link by design.
drop policy if exists buddy_links_select on public.buddy_links;
create policy buddy_links_select on public.buddy_links
  for select using (creator_id = auth.uid() or partner_id = auth.uid());

drop policy if exists buddy_links_insert on public.buddy_links;
create policy buddy_links_insert on public.buddy_links
  for insert with check (creator_id = auth.uid());

drop policy if exists buddy_links_delete on public.buddy_links;
create policy buddy_links_delete on public.buddy_links
  for delete using (creator_id = auth.uid());

-- buddy_marks: members of the link can read all marks on it; a user may only
-- write (insert/update) their OWN mark rows, and only on links they belong to.
drop policy if exists buddy_marks_select on public.buddy_marks;
create policy buddy_marks_select on public.buddy_marks
  for select using (
    exists (
      select 1 from public.buddy_links l
      where l.id = link_id and (l.creator_id = auth.uid() or l.partner_id = auth.uid())
    )
  );

drop policy if exists buddy_marks_insert on public.buddy_marks;
create policy buddy_marks_insert on public.buddy_marks
  for insert with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.buddy_links l
      where l.id = link_id and (l.creator_id = auth.uid() or l.partner_id = auth.uid())
    )
  );

drop policy if exists buddy_marks_update on public.buddy_marks;
create policy buddy_marks_update on public.buddy_marks
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------

-- Claim a link by its share code. Security definer so a joiner (who cannot
-- see or update the unclaimed row under RLS) can attach themselves as the
-- partner. Returns the link id, or null if the code is unknown, already
-- claimed by someone else, or is the caller's own link.
create or replace function public.join_buddy_link(join_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target public.buddy_links%rowtype;
begin
  select * into target from public.buddy_links where code = upper(join_code);
  if not found then
    return null;
  end if;
  if target.creator_id = auth.uid() then
    return null; -- can't be your own buddy
  end if;
  if target.partner_id is not null and target.partner_id <> auth.uid() then
    return null; -- already claimed by someone else
  end if;
  update public.buddy_links set partner_id = auth.uid() where id = target.id;
  return target.id;
end;
$$;

-- Delete everything this (anonymous) user has synced — the in-app
-- "delete my buddy data" path required by App Store Guideline 5.1.1(v).
-- Removes their marks, the links they created (marks cascade), and detaches
-- them from any link they joined as a partner. The anonymous auth user row
-- itself carries no personal data; the app signs out after calling this.
create or replace function public.delete_my_buddy_data()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.buddy_marks where user_id = auth.uid();
  delete from public.buddy_links where creator_id = auth.uid();
  update public.buddy_links set partner_id = null where partner_id = auth.uid();
end;
$$;

-- ---------------------------------------------------------------------------
-- Realtime — both tables broadcast changes so partners update live.
-- ---------------------------------------------------------------------------

alter publication supabase_realtime add table public.buddy_links;
alter publication supabase_realtime add table public.buddy_marks;
