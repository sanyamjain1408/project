import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/swap/swap_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transfer_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_crypto_withdraw/wallet_crypto_withdraw_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_fiat_deposit/wallet_fiat_deposit_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_fiat_withdrawal/wallet_fiat_withdrawal_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_overview_page.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';

const _dmSans = 'DMSans';

class SpotCoinDetailsScreen extends StatelessWidget {
  SpotCoinDetailsScreen({super.key, required this.wallet});

  final Wallet wallet;
  final _controller = Get.find<WalletController>();

  @override
  Widget build(BuildContext context) {
    final pairList = _controller.getCoinPairList(wallet.coinType ?? '');
    final currencyName = getSettingsLocal()?.currency ?? DefaultValue.currency;
    final symbol = wallet.coinType ?? '';
    final total = wallet.total ?? 0;
    final totalUsd = wallet.totalBalanceUsd ?? 0;
    final available = wallet.availableBalance ?? 0;
    final locked = wallet.onOrder ?? 0;
    final lockedUsd = wallet.onOrderUsd ?? 0;
    final availableUsd = wallet.availableBalanceUsd ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 25,
              ),
            ),

            const SizedBox(width: 15),

            ClipOval(
              child: showImageNetwork(
                imagePath: wallet.coinIcon,
                width: 25,
                height: 25,
                bgColor: Colors.transparent,
              ),
            ),

            const SizedBox(width: 5),

            Text(
              symbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: _dmSans,
                fontWeight: FontWeight.w700,
                height: 1.50,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  vSpacer10(),

                  // ── Spot Balance label ──
                  Text(
                    'Spot Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 12,
                      fontFamily: _dmSans,
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── Big balance + USD inline ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          coinFormat(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontFamily: _dmSans,
                            fontWeight: FontWeight.w700,
                            height: 1.33,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '= \$${_fmtUsd(totalUsd)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.50),
                          fontSize: 12,
                          fontFamily: _dmSans,
                          fontWeight: FontWeight.w400,
                          height: 1.33,
                        ),
                      ),
                    ],
                  ),
                  vSpacer20(),

                  // ── 4-cell stats grid ──
                  _StatsGrid(
                    available: available,
                    availableUsd: availableUsd,
                    locked: locked,
                    lockedUsd: lockedUsd,
                    currencyName: currencyName,
                  ),
                  vSpacer20(),

                  // ── Recommended ──
                  _RecommendedSection(wallet: wallet, symbol: symbol),
                  vSpacer20(),

                  // ── History ──
                  _HistorySection(),
                  vSpacer20(),
                ],
              ),
            ),
          ),

          // ── Bottom Bar ──
          _BottomBar(wallet: wallet, pairList: pairList),
        ],
      ),
    );
  }

  String _fmtUsd(double v) => v.toStringAsFixed(v < 0.01 ? 8 : 2);
}

// ── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.available,
    required this.availableUsd,
    required this.locked,
    required this.lockedUsd,
    required this.currencyName,
  });
  final double available;
  final double availableUsd;
  final double locked;
  final double lockedUsd;
  final String currencyName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Available | Available (locked label)
        Row(
          children: [
            Expanded(child: _statLabel('Available')),
            Expanded(child: _statLabel('Locked')),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: _statValue(
                coinFormat(available),
                Colors.white.withValues(alpha: 0.50),
              ),
            ),
            Expanded(
              child: _statValue(
                coinFormat(locked),
                Colors.white.withValues(alpha: 0.50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Row 2: Average Price | Today's PNL
        Row(
          children: [
            Expanded(child: _statLabel('Average Price')),
            Expanded(child: _statLabel("Today's PNL")),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: _statValue(
                '0.00 USDT',
                Colors.white.withValues(alpha: 0.50),
              ),
            ),
            Expanded(
              child: _statValue('+0 USDT (0.00%)', const Color(0xFFD63B3B)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statLabel(String text) => Text(
    text,
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.50),
      fontSize: 12,
      fontFamily: _dmSans,
      fontWeight: FontWeight.w400,
      height: 1.33,
    ),
  );

  Widget _statValue(String text, Color color) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 15,
      fontFamily: _dmSans,
      fontWeight: FontWeight.w400,
    ),
  );
}

// ── Recommended ──────────────────────────────────────────────────────────────

class _RecommendedSection extends StatelessWidget {
  const _RecommendedSection({required this.wallet, required this.symbol});
  final Wallet wallet;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: _dmSans,
            fontWeight: FontWeight.w700,
            height: 1.50,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RecommendCard(
                title: 'Convert $symbol to other crypto',
                actionLabel: 'Convert Now',
                imagePath: 'assets/images/swap.png',
                onTap: () => Get.to(() => SwapScreen(preWallet: wallet)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RecommendCard(
                title: 'Earn $symbol ARP up to 53.27%',
                actionLabel: 'Earn Now',
                imagePath: 'assets/images/earning.png',
                onTap: () => Get.to(
                  () => const WalletDetailScreen(
                    initialType: WalletViewType.earn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecommendCard extends StatelessWidget {
  const _RecommendCard({
    required this.title,
    required this.actionLabel,
    required this.imagePath,
    required this.onTap,
  });
  final String title;
  final String actionLabel;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 176,
        height: 82,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: ShapeDecoration(
          color: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: _dmSans,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Color(0xFFCCFF00),
                    fontSize: 12,
                    fontFamily: _dmSans,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
                Image.asset(imagePath, width: 18, height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── History ───────────────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: _dmSans,
                fontWeight: FontWeight.w700,
                height: 1.50,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50),
                  fontSize: 15,
                  fontFamily: _dmSans,
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Center(
          child: Text(
            'No recent history',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.50),
              fontSize: 14,
              fontFamily: _dmSans,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.wallet, required this.pairList});
  final Wallet wallet;
  final List<String> pairList;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0x7F111111),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          // Add Funds
          if (wallet.isDeposit == 1)
            Expanded(
              child: _BarBtn(
                label: 'Add Funds',
                onTap: () {
                  if (wallet.currencyType == CurrencyType.crypto) {
                    Get.to(() => WalletCryptoDepositScreen(wallet: wallet));
                  } else if (wallet.currencyType == CurrencyType.fiat) {
                    Get.to(() => WalletFiatDepositScreen(wallet: wallet));
                  }
                },
              ),
            ),
          if (wallet.isDeposit == 1) const SizedBox(width: 10),

          // Withdraw
          if (wallet.isWithdrawal == 1)
            Expanded(
              child: _BarBtn(
                label: 'Withdraw',
                imagePath: 'assets/images/withdraw.png',
                onTap: () {
                  if (wallet.currencyType == CurrencyType.crypto) {
                    Get.to(() => WalletCryptoWithdrawScreen(wallet: wallet));
                  } else if (wallet.currencyType == CurrencyType.fiat) {
                    Get.to(() => WalletFiatWithdrawalScreen(wallet: wallet));
                  }
                },
              ),
            ),
          if (wallet.isWithdrawal == 1) const SizedBox(width: 10),

          // Transfer
          Expanded(
            child: _BarBtn(
              label: 'Transfer',
              imagePath: 'assets/images/transfer.png',
              onTap: () => Get.to(() => const TransferScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarBtn extends StatelessWidget {
  const _BarBtn({required this.label, required this.onTap, this.imagePath});
  final String label;
  final VoidCallback? onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null) ...[
              Image.asset(
                imagePath!,
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: _dmSans,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
