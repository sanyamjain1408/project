# Trapix Flutter App — CLAUDE.md

## What This Is
Flutter mobile app for the Trapix crypto exchange platform (tradexpro_flutter v4.3.0).
It connects to the Trapix backend API at `https://api.trapix.com`.

## Server Access (Trapix Production)
- **SSH**: `sshpass -p 'CLj5p6U6i5ccXZ' ssh -o StrictHostKeyChecking=no root@45.61.140.29`
- **SCP upload**: `SSHPASS='CLj5p6U6i5ccXZ' sshpass -e scp -o StrictHostKeyChecking=no <local_file> root@45.61.140.29:<remote_path>`
- **Web frontend**: `/var/www/trapix.com` (Next.js, managed by PM2)
- **Backend**: `/var/www/management15080304.trapix.com` (Laravel PHP)
- **Build command** (NEVER run yourself — tell user): `cd /var/www/trapix.com && yarn build && pm2 restart all`

## Project Structure
```
lib/
  main.dart                        # App entry point
  data/
    local/api_constants.dart       # All API endpoint URLs — base: https://api.trapix.com
    local/constants.dart           # App-wide constants
    models/                        # Data models (wallet, user, coin, etc.)
    remote/
      api_repository.dart          # Main API call methods
      http_api_provider.dart       # HTTP client
      socket_provider.dart         # WebSocket (spot/futures live data)
  ui/features/
    auth/                          # Sign in, sign up, forgot password, 2FA
    bottom_navigation/
      landing/                     # Home dashboard
      market/                      # Market overview (spot + futures)
      trades/
        spot_trade/                # Spot trading screen
        future_trade/              # Futures trading screen
      wallet/
        wallet_crypto_withdraw/    # Crypto withdrawal (fee display fix lives here)
        wallet_crypto_deposit/     # Crypto deposit
    side_navigation/
      earn/                        # Staking, dual investment, MC staking
      staking/                     # Staking plans
      p2p_trade/ (addons)          # P2P trading
      profile/                     # KYC, security, 2FA settings
      referrals/                   # Referral / IB program
  addons/
    p2p_trade/                     # P2P module
    ico/                           # ICO / token launch module
```

## Key Files to Know
| File | Purpose |
|------|---------|
| `lib/data/local/api_constants.dart` | All API endpoint paths |
| `lib/data/remote/api_repository.dart` | API call implementations |
| `lib/ui/features/bottom_navigation/wallet/wallet_crypto_withdraw/wallet_crypto_withdraw_controller.dart` | Withdrawal logic (fees, networks) |
| `lib/ui/features/bottom_navigation/wallet/wallet_crypto_withdraw/wallet_crypto_withdraw_screen.dart` | Withdrawal UI |
| `lib/ui/features/bottom_navigation/trades/future_trade/future_controller.dart` | Futures trading logic |
| `lib/utils/colors.dart` | Theme colors |
| `lib/utils/number_util.dart` | Number formatting helpers |

## Known Issues / Context
- **Withdrawal fee display**: Backend stores fees in `coin_networks.withdrawal_fees`, not `coins.withdrawal_fees`. The API response top-level `withdrawal_fees` field has the correct value.
- **Network name "Coin Payment"**: BTC/ETH/XRP/USDT use Coin Payment provider — network name in DB is "Coin Payment". Display should show `<COIN> Network` instead (e.g., "BTC Network").
- **Leverage tiers**: Users have per-account max leverage — 5x / 20x / 50x / 75x / 100x tiers. Enforced in backend.

## Flutter SDK
- Flutter: ^3.35.3, Dart SDK: >=3.9.2 <4.0.0
- State management: GetX (controllers in each feature folder)
- HTTP: dio or http (check `api_provider.dart`)

## Do NOT
- Push to GitHub without user confirmation
- Change `baseUrl` in `api_constants.dart` without user approval
- Run `flutter build` or deploy without asking — user controls all builds/releases
