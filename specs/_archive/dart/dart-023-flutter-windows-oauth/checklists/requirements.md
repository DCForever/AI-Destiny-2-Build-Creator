# Requirements checklist: DART-023

- [x] Scope limited to Windows loopback OAuth + secure storage + Settings sign-in/out
- [x] Exit criteria: Sign-in/out E2E (mocked host path); tokens not in SQLite plaintext
- [x] No CLIENT_SECRET / client_secret in client APIs
- [x] Soft guidance never auto-applies
- [x] Depends DART-022 + DART-019 only; no DART-024 inventory sync
- [x] Assumptions documented (fixed loopback port, flutter_secure_storage, mock E2E)
- [x] Success criteria measurable via flutter test + analyze
