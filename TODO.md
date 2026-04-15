# DM Sans Font Global Fix - Progress Tracker

**Goal**: Use assets/fonts/dm_sans DM Sans everywhere `fontFamily: "DMSans"` is declared (currently falling back to system font due to pubspec.yaml misconfig).

## Steps:
- [ ] 1. Fix pubspec.yaml - Declare `family: DMSans` with static font files
- [ ] 2. Run `flutter clean &amp;&amp; flutter pub get`
- [ ] 3. Update lib/utils/theme.dart TextTheme for global fontFamily: 'DMSans'
- [ ] 4. Test `flutter run` - Verify all Text widgets use DM Sans (geometric sans-serif style)
- [x] Complete

**Current Status**: Fonts ready in assets, code uses "DMSans", but pubspec prevents loading.

Updated TODO.md created.
