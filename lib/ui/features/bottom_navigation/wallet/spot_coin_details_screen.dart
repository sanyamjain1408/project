import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/swap/swap_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transaction_history_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transfer_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_crypto_withdraw/wallet_crypto_withdraw_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_fiat_deposit/wallet_fiat_deposit_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_fiat_withdrawal/wallet_fiat_withdrawal_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_overview_page.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/tx_detail_screen.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';

const _dmSans = 'DMSans';

// 2+ digit integer part → 2 decimals, single digit → 5 decimals
String _smartFmt(double v) => v.toStringAsFixed(v.abs() >= 10 ? 2 : 5);

class SpotCoinDetailsScreen extends StatefulWidget {
  const SpotCoinDetailsScreen({super.key, required this.wallet});
  final Wallet wallet;

  @override
  State<SpotCoinDetailsScreen> createState() => _SpotCoinDetailsScreenState();
}

class _SpotCoinDetailsScreenState extends State<SpotCoinDetailsScreen> {
  final _controller = Get.find<WalletController>();

  List<Map<String, dynamic>> _history = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Map<String, String> _authHeaders() {
    final token = GetStorage().read(PreferenceKey.accessToken) ?? '';
    final type = GetStorage().read(PreferenceKey.accessType) ?? 'Bearer';
    final secret = dotenv.env[EnvKeyValue.kApiSecret] ?? '';
    return {
      'Accept': 'application/json',
      'userapisecret': secret,
      if (token.isNotEmpty) 'Authorization': '$type $token',
    };
  }

  Future<void> _loadHistory() async {
    final coinType = widget.wallet.coinType ?? '';
    try {
      final results = await Future.wait([
        http.get(
          Uri.parse('${APIURLConstants.baseUrl}/api/wallet-history-app?type=deposit&page=1&per_page=20&coin_type=$coinType'),
          headers: _authHeaders(),
        ),
        http.get(
          Uri.parse('${APIURLConstants.baseUrl}/api/wallet-history-app?type=withdraw&page=1&per_page=20&coin_type=$coinType'),
          headers: _authHeaders(),
        ),
        http.get(
          Uri.parse('${APIURLConstants.baseUrl}/api/v1/swap/history'),
          headers: _authHeaders(),
        ),
        http.get(
          Uri.parse('${APIURLConstants.baseUrl}/api/v1/transfer-history?page=1&per_page=20'),
          headers: _authHeaders(),
        ),
      ]);

      final List<Map<String, dynamic>> combined = [];

      // deposit
      if (results[0].statusCode == 200) {
        final raw = jsonDecode(results[0].body)['data']?['histories']?['data'];
        if (raw is List) {
          for (final e in raw) combined.add({...Map<String, dynamic>.from(e), '_type': 'deposit'});
        }
      }

      // withdraw
      if (results[1].statusCode == 200) {
        final raw = jsonDecode(results[1].body)['data']?['histories']?['data'];
        if (raw is List) {
          for (final e in raw) combined.add({...Map<String, dynamic>.from(e), '_type': 'withdraw'});
        }
      }

      // swap — filter by coinType (from_coin or to_coin)
      if (results[2].statusCode == 200) {
        final data = jsonDecode(results[2].body)['data'];
        if (data is List) {
          for (final e in data) {
            final m = Map<String, dynamic>.from(e);
            if (m['from_coin']?.toString() == coinType || m['to_coin']?.toString() == coinType) {
              combined.add({...m, '_type': 'swap'});
            }
          }
        }
      }

      // transfer — filter by coinType
      if (results[3].statusCode == 200) {
        final data = jsonDecode(results[3].body)['data'];
        if (data is List) {
          for (final e in data) {
            final m = Map<String, dynamic>.from(e);
            if (m['coin_type']?.toString() == coinType) {
              combined.add({...m, '_type': 'transfer'});
            }
          }
        }
      }

      // sort by created_at desc — saari history, koi filter nahi
      combined.sort((a, b) {
        final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });

      if (mounted) {
        setState(() {
          _history = combined;
          _historyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;
    final pairList = _controller.getCoinPairList(wallet.coinType ?? '');
    final currencyName = getSettingsLocal()?.currency ?? DefaultValue.currency;
    final symbol = wallet.coinType ?? '';
    final total = wallet.total ?? 0;
    final totalUsd = wallet.totalBalanceUsd ?? 0;
    final available = wallet.availableBalance ?? 0;
    final locked = wallet.onOrder ?? 0;
    final availableUsd = wallet.availableBalanceUsd ?? 0;
    final lockedUsd = wallet.onOrderUsd ?? 0;

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
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 25),
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
                          _smartFmt(total),
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
                    avgPrice: wallet.avgPrice,
                    pnl: wallet.pnl,
                    pnlText: wallet.pnlText,
                  ),
                  vSpacer20(),

                  // ── Recommended ──
                  _RecommendedSection(wallet: wallet, symbol: symbol),
                  vSpacer20(),

                  // ── History ──
                  _HistorySection(
                    loading: _historyLoading,
                    history: _history,
                    onViewAll: () => Get.to(() => const TransactionHistoryScreen()),
                  ),
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
    this.avgPrice,
    this.pnl,
    this.pnlText,
  });
  final double available;
  final double availableUsd;
  final double locked;
  final double lockedUsd;
  final String currencyName;
  final double? avgPrice;
  final double? pnl;
  final String? pnlText;

  @override
  Widget build(BuildContext context) {
    final avgPriceStr = (avgPrice != null && avgPrice! > 0)
        ? '${coinFormat(avgPrice!)} USDT'
        : '0.00 USDT';

    String pnlStr;
    Color pnlColor;
    if (pnlText != null && pnlText!.isNotEmpty) {
      pnlStr = pnlText!;
      pnlColor = (pnl != null && pnl! >= 0) ? const Color(0xFF4ED78E) : const Color(0xFFD63B3B);
    } else {
      pnlStr = '+0 USDT (0.00%)';
      pnlColor = const Color(0xFFD63B3B);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statLabel('Available')),
            Expanded(child: _statLabel('Locked')),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(child: _statValue(_smartFmt(available), Colors.white.withValues(alpha: 0.50))),
            Expanded(child: _statValue(_smartFmt(locked), Colors.white.withValues(alpha: 0.50))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statLabel('Average Price')),
            Expanded(child: _statLabel("Today's PNL")),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(child: _statValue(avgPriceStr, Colors.white.withValues(alpha: 0.50))),
            Expanded(child: _statValue(pnlStr, pnlColor)),
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
                  () => const WalletDetailScreen(initialType: WalletViewType.earn),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  const _HistorySection({
    required this.loading,
    required this.history,
    required this.onViewAll,
  });
  final bool loading;
  final List<Map<String, dynamic>> history;
  final VoidCallback onViewAll;

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
              onPressed: onViewAll,
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
        const SizedBox(height: 12),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: Color(0xFFCCFF00), strokeWidth: 2),
            ),
          )
        else if (history.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No recent history',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50),
                  fontSize: 14,
                  fontFamily: _dmSans,
                ),
              ),
            ),
          )
        else
          ...history.map((tx) => _HistoryRow(tx: tx, onTap: () => Get.to(() => TxDetailScreen(tx: tx)))),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.tx, this.onTap});
  final Map<String, dynamic> tx;
  final VoidCallback? onTap;

  String _statusLabel(dynamic status) {
    switch (status?.toString()) {
      case '1': return 'Success';
      case '0':
      case '4': return 'Pending';
      case '5': return 'Processing';
      case '2': return 'Rejected';
      default: return 'Failed';
    }
  }

  Color _statusColor(String label) {
    if (label == 'Success') return const Color(0xFF4ED78E);
    if (label == 'Pending' || label == 'Processing') return const Color(0xFFE0B341);
    return const Color(0xFFD73C3C);
  }

  String _formatDate(dynamic raw) {
    try {
      if (raw == null || raw.toString().isEmpty) return '';
      final dt = DateTime.parse(raw.toString()).toLocal();
      return formatDate(dt, format: "d MMM ''yy, hh:mm a");
    } catch (_) {
      return raw?.toString() ?? '';
    }
  }

  String _fmtAmt(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '0') ?? 0;
    if (d == d.truncateToDouble()) return d.toStringAsFixed(2);
    return d.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final type = tx['_type']?.toString() ?? 'deposit';
    final isDep = type == 'deposit';
    final isSwap = type == 'swap';
    final isTransfer = type == 'transfer';
    final coinType = tx['coin_type']?.toString() ?? '';
    final status = (isSwap || isTransfer) ? 'Success' : _statusLabel(tx['status']);
    final statusColor = _statusColor(status);
    final date = _formatDate(tx['created_at']);

    // Title
    String title;
    if (isSwap) title = '${tx['from_coin']} → ${tx['to_coin']}';
    else if (isTransfer) title = 'Transfer $coinType';
    else title = isDep ? 'Deposit $coinType' : 'Withdraw $coinType';

    // Amount
    String amountStr;
    if (isSwap) {
      final toAmt = double.tryParse(tx['to_amount']?.toString() ?? '0') ?? 0;
      amountStr = '+${_fmtAmt(toAmt)} ${tx['to_coin']}';
    } else {
      final amt = tx['amount'];
      final prefix = isDep ? '+' : (isTransfer ? '' : '-');
      amountStr = '$prefix${_fmtAmt(amt)} $coinType';
    }

    // Icon
    final iconBg = isSwap || isTransfer
        ? const Color(0xFFCCFF00).withValues(alpha: 0.18)
        : isDep
            ? const Color(0xFF015629).withValues(alpha: 0.4)
            : const Color(0xFF920000).withValues(alpha: 0.5);
    final iconColor = isSwap || isTransfer
        ? const Color(0xFFCCFF00)
        : isDep ? const Color(0xFF4ED78E) : const Color(0xFFD73C3C);
    final iconData = isSwap || isTransfer
        ? Icons.swap_horiz
        : isDep ? Icons.arrow_downward : Icons.arrow_upward;
    final amtColor = isSwap || isDep ? const Color(0xFF4ED78E) : const Color(0xFFD73C3C);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: isTransfer
                  ? ClipOval(child: Image.asset('assets/images/transferlogo.png', width: 30, height: 30, fit: BoxFit.cover))
                  : isSwap
                      ? ClipOval(child: Image.asset('assets/images/swaplogo.png', width: 30, height: 30, fit: BoxFit.cover))
                      : Icon(iconData, color: iconColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: _dmSans, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(date, style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 11, fontFamily: _dmSans)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amountStr, style: TextStyle(color: amtColor, fontSize: 13, fontFamily: _dmSans, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontFamily: _dmSans)),
              ],
            ),
          ],
        ),
      ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null) ...[
              Image.asset(imagePath!, width: 20, height: 20),
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
