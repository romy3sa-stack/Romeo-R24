# Receipt24 (Flutter app)

Shared Flutter codebase for all three Receipt24 areas — Consumer App,
Accountant Portal, Super Admin Dashboard (see `lib/areas/`). See the
top-level [`docs/`](../docs) folder for architecture, environments, and the
Phase 1/2 deliverable writeup.

## Setup

```bash
flutter pub get
cp env/development.example.json env/development.json   # then fill in your Supabase project
flutter run --dart-define-from-file=env/development.json
```

## Testing

```bash
flutter analyze
flutter test
```
