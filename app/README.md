# Pocklume app

Flutter client for Pocklume, a private, manual spending tracker that uses
streaks and a companion owl to make daily logging easier to sustain.

The iOS launch is iPhone-only and uses the registered Bundle ID
`com.pocklume.app`. Release builds receive RevenueCat and Supabase public
configuration through `--dart-define`; never commit secret keys.

See the repository README and `docs/app-store-launch-checklist.md` for setup,
validation, and release requirements.
