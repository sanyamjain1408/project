# Splash Screen Hang Fix - TODO Steps

## Plan Summary
App hangs on native splash because `getCommonSettings()` API call in main.dart blocks `runApp()`. Make init non-blocking, add logging/timeout/error handling.

## Steps (Approved Plan Breakdown)
- [x] **Step 1**: Edit `lib/data/remote/http_api_provider.dart` - Add timeout (10s) to all `http.get/post` calls. ✅
- [ ] **Step 2**: Edit `lib/main.dart` - Add prints around network/API, make `getCommonSettings()` non-blocking (move inside app with FutureBuilder), fallback to cached/local settings.
- [ ] **Step 3**: Run `flutter clean && flutter pub get && flutter run --verbose`.
- [ ] **Step 4**: Test on device, check logs for API response/error. Ping `https://api.trapix.com` manually.
- [ ] **Step 5**: If fixed, update this TODO.md with completion. Optional: Add custom splash screen.

**Progress: 0/5 steps complete. Starting Step 1...**

