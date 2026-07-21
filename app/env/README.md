# Environment configuration

Receipt24 has three environments: `development`, `test`, `production` (see
`docs/ENVIRONMENTS.md` for the full picture, including the matching Supabase
projects).

Every value in these files is a **public** client-side value (Supabase
anon key, analytics write key, payment publishable key). No secret ever
belongs here — secrets (service_role key, OCR provider keys, email provider
keys, payment secret keys) live only in Supabase Edge Function secrets /
CI environment variables, never in this Flutter app (Rule 11).

## Usage

1. Copy the example file for the environment you need:
   ```bash
   cp env/development.example.json env/development.json
   ```
2. Fill in the real values for that Supabase project.
3. Run/build with `--dart-define-from-file`:
   ```bash
   flutter run --dart-define-from-file=env/development.json
   flutter build web --dart-define-from-file=env/production.json
   ```

`env/*.json` (without `.example`) is gitignored — never commit a filled-in
file, even though the values themselves are public, to avoid churn/leakage
of which project each teammate points to.
