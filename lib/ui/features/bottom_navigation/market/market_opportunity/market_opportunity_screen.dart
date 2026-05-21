import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/market_date.dart';
import 'package:tradexpro_flutter/ui/features/currency_pair_details/currency_pair_details_screen.dart';

import 'market_opportunity_controller.dart';

// ── Design tokens ──────────────────────────────────────────────────
const _kSurface = Color(0xFF1A1A1A);
const _kBorder = Colors.transparent;
const _kGreen = Color(0xFFCCFF00);
const _kRed = Color(0xFFEF4444);
const _kText = Color(0xFFE8ECF4);
const _kMuted = Color(0x80FFFFFF);
const _kMuted2 = Color(0x80FFFFFF);

// ── Fear & Greed helpers ───────────────────────────────────────────
Color _fgColor(int v) {
  if (v <= 20) return const Color(0xFFE53E3E); // Red
  if (v <= 40) return const Color(0xFFDD6B20); // Orange
  if (v <= 60) return const Color(0xFFD69E2E); // Yellow
  if (v <= 80) return const Color(0xFF38A169); // Light Green
  return const Color(0xFF22C55E); // Green
}

String _fgLabel(int v) {
  if (v <= 20) return 'Extreme Fear';
  if (v <= 40) return 'Fear';
  if (v <= 60) return 'Neutral';
  if (v <= 80) return 'Greed';
  return 'Extreme Greed';
}

// ── Heatmap color ──────────────────────────────────────────────────
Color _heatColor(double pct) {
  if (pct >= 5) return const Color(0xFF006D2C);
  if (pct >= 3) return const Color(0xFF00AC14);
  if (pct >= 2) return const Color(0xFF007F0F);
  if (pct >= 1) return const Color(0xFF00520A);
  if (pct > 0) return const Color(0xFF003D07);
  if (pct > -1) return const Color(0xFF3A3A3A);
  if (pct >= -2) return const Color(0xFFC00000);
  if (pct >= -5) return const Color(0xFF840000);
  return const Color(0xFF5C0000);
}

// ── Number formatters ──────────────────────────────────────────────
String _fmtNum(double n) {
  if (n == 0) return '\$0';
  if (n >= 1e12) return '\$${(n / 1e12).toStringAsFixed(2)}T';
  if (n >= 1e9) return '\$${(n / 1e9).toStringAsFixed(2)}B';
  if (n >= 1e6) return '\$${(n / 1e6).toStringAsFixed(2)}M';
  if (n >= 1e3) return '\$${(n / 1e3).toStringAsFixed(2)}K';
  return '\$${n.toStringAsFixed(2)}';
}

String _fmtPrice(double? p) {
  if (p == null || p == 0) return '\$0.00';
  if (p >= 1000) {
    return '\$${p.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
  if (p >= 1) return '\$${p.toStringAsFixed(3)}';
  if (p >= 0.01) return '\$${p.toStringAsFixed(5)}';
  return '\$${p.toStringAsFixed(8)}';
}

// ── Main Screen ────────────────────────────────────────────────────
class MarketOpportunityScreen extends StatefulWidget {
  const MarketOpportunityScreen({super.key});

  @override
  State<MarketOpportunityScreen> createState() =>
      _MarketOpportunityScreenState();
}

class _MarketOpportunityScreenState extends State<MarketOpportunityScreen> {
  final _ctrl = Get.put(MarketOpportunityController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        color: _kGreen,
        backgroundColor: const Color(0xFF111111),
        onRefresh: _ctrl.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopStatsRow(),
              const SizedBox(height: 10),
              _buildBitcoinDominance(),
              const SizedBox(height: 20),
              _buildHeatmapCard(),
              const SizedBox(height: 20),
              _buildDistributionCard(),
              const SizedBox(height: 20),
              _buildGainersLosers(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Stats Row: FearGreed | MarketCap | Volume ──────────────
  Widget _buildTopStatsRow() {
    return Obx(() {
      final fgLoading = _ctrl.isFgLoading.value;
      final gLoading = _ctrl.isGlobalLoading.value;

      return Column(
        children: [
          // ── Fear & Greed — full width ──────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: fgLoading
                ? _Sk(h: 120)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fear & Greed Index',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Gauge + value
                          Column(
                            children: [
                              SizedBox(
                                width: 130,
                                height: 68,
                                child: CustomPaint(
                                  painter: _MiniGaugePainter(
                                    value: _ctrl.fgValue.value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${_ctrl.fgValue.value}',
                                style: TextStyle(
                                  color: _fgColor(
                                    _ctrl.fgValue.value,
                                  ), // ← yeh change karo
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'DMSans',
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Transform.translate(
                                offset: const Offset(-5, 0),
                                child: Text(
                                  _fgLabel(_ctrl.fgValue.value),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Historical pills
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _FgHistoryRow(
                                label: 'Yesterday',
                                value: _ctrl.fgYesterday.value,
                              ),
                              const SizedBox(height: 10),
                              _FgHistoryRow(
                                label: 'Last Week',
                                value: _ctrl.fgLastWeek.value,
                              ),
                              const SizedBox(height: 10),
                              _FgHistoryRow(
                                label: 'Last Month',
                                value: _ctrl.fgLastMonth.value,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 10),

          // ── Market Cap + Volume — side by side ─────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  child: gLoading
                      ? _Sk(h: 60)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Market Cap',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'DMSans',
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _fmtNum(_ctrl.totalMarketCap.value),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _kText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'DMSans',
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _ctrl.marketCapChange.value >= 0
                                      ? Icons.add
                                      : Icons.remove,
                                  color: _ctrl.marketCapChange.value >= 0
                                      ? Color(0xFF00B052)
                                      : _kRed,
                                  size: 14,
                                ),
                                Text(
                                  '${_ctrl.marketCapChange.value.abs().toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: _ctrl.marketCapChange.value >= 0
                                        ? Color(0xFF00B052)
                                        : _kRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'DMSans',
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  child: gLoading
                      ? _Sk(h: 60)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Volume',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'DMSans',
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _fmtNum(_ctrl.totalVolume24h.value),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _kText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'DMSans',
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _ctrl.marketCapChange.value >= 0
                                      ? Icons.add
                                      : Icons.remove,
                                  color: _ctrl.marketCapChange.value >= 0
                                      ? Color(0xFF00B052)
                                      : _kRed,
                                  size: 14,
                                ),
                                Text(
                                  '${_ctrl.marketCapChange.value.abs().toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: _ctrl.marketCapChange.value >= 0
                                        ? Color(0xFF00B052)
                                        : _kRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'DMSans',
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  // ── Bitcoin Dominance ──────────────────────────────────────────
  Widget _buildBitcoinDominance() {
    return Obx(() {
      if (_ctrl.isGlobalLoading.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: _Sk(h: 60),
        );
      }
      final btcDom = _ctrl.btcDominance.value;
      final ethDom = _ctrl.ethDominance.value;
      final othDom = _ctrl.othersDominance;
      final btcChg = _ctrl.btcChange24h.value;
      final ethChg = _ctrl.ethChange24h.value;

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bitcoin Dominance',
              style: TextStyle(
                color: _kText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
                height: 1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _DomItem(
                  label: 'Bitcoin',
                  color: const Color(0xFFD05858),
                  pct: btcDom,
                  change: btcChg,
                ),
                const SizedBox(width: 8),
                _DomItem(
                  label: 'Ethereum',
                  color: const Color(0xFF37EBFF),
                  pct: ethDom,
                  change: ethChg,
                ),
                const SizedBox(width: 8),
                _DomItem(
                  label: 'Others',
                  color: const Color(0xFF0062FF),
                  pct: othDom,
                  change: null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    Flexible(
                      flex: btcDom.round(),
                      child: Container(color: const Color(0xFFD05858)),
                    ),
                    const SizedBox(width: 0),
                    Flexible(
                      flex: ethDom.round(),
                      child: Container(color: const Color(0xFF37EBFF)),
                    ),
                    const SizedBox(width: 0),
                    Flexible(
                      flex: othDom.round().clamp(1, 100),
                      child: Container(color: const Color(0xFF0062FF)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Heatmap Card ──────────────────────────────────────────────
  Widget _buildHeatmapCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kBorder,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Heatmap',
            style: TextStyle(
              color: _kText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFCCFF00),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: _kBorder),
            ),
            child: const Text(
              '24h',
              style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
                height: 1,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Obx(() {
            const filters = [-3, -2, -1, 0, 1, 2, 3];
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((pct) {
                  final isActive = _ctrl.heatmapFilter.contains(pct);
                  final btnColor = pct < 0
                      ? const Color(0xFFEF4444)
                      : pct == 0
                      ? const Color(0xFF5A6278)
                      : const Color(0xFF22C55E);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _ctrl.toggleHeatmapFilter(pct),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? btnColor
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: isActive
                              ? null
                              : Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                        ),
                        child: Text(
                          '${pct > 0 ? '+' : ''}$pct%',
                          style: TextStyle(
                            color: isActive ? Colors.white : _kMuted2,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DMSans',
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          const SizedBox(height: 10),

          // Filter buttons
          Obx(() {
            if (_ctrl.isLoading.value) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.88,
                ),
                itemCount: 12,
                itemBuilder: (_, __) => _Sk(h: 90),
              );
            }
            final coins = _ctrl.filteredHeatmapCoins;
            if (coins.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No coins match the selected filter',
                    style: const TextStyle(
                      color: _kMuted,
                      fontSize: 12,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
              );
            }
            return _HeatmapTreeLayout(coins: coins);
          }),
        ],
      ),
    );
  }

  // ── Up/Down Distribution ───────────────────────────────────────
  Widget _buildDistributionCard() {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: _Sk(h: 110),
        );
      }

      final changes = _ctrl.allCoins.map((c) => c.change ?? 0.0).toList();
      if (changes.isEmpty) return const SizedBox.shrink();

      final bucketDefs = [
        _Bucket('>10%', 10, double.infinity, true),
        _Bucket('7-10%', 7, 10, true),
        _Bucket('5-7%', 5, 7, true),
        _Bucket('3-5%', 3, 5, true),
        _Bucket('0-3%', 0, 3, true),
        _Bucket('0%', -0.5, 0, false),
        _Bucket('0-3%', -3, -0.5, false),
        _Bucket('3-5%', -5, -3, false),
        _Bucket('5-7%', -7, -5, false),
        _Bucket('7-10%', -10, -7, false),
        _Bucket('>10%', double.negativeInfinity, -10, false),
      ];

      final buckets = bucketDefs.map((b) {
        final count = changes.where((c) => c >= b.min && c < b.max).length;
        return (b, count);
      }).toList();

      final maxCount = buckets.map((e) => e.$2).reduce(math.max);
      final upCount = _ctrl.upCount;
      final downCount = _ctrl.downCount;
      final total = upCount + downCount;
      final upPct = total > 0 ? (upCount / total * 100).round() : 50;
      final avgChange = changes.isEmpty
          ? 0.0
          : changes.reduce((a, b) => a + b) / changes.length;

      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ─────────────────────────────────────────────
          const Text(
            'Up / Down Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: 'Average: ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'DMSans',
                height: 1,
              ),
              children: [
                TextSpan(
                  text:
                      '${avgChange >= 0 ? '+' : ''}${avgChange.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: avgChange >= 0
                        ? const Color(0xFF00B052)
                        : const Color(0xFFD05858),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),

                // ── 1. Progress bar — UPAR ─────────────────────
                SizedBox(
                  height: 5,
                  child: Row(
                    children: [
                      Flexible(
                        flex: upPct,
                        child: ClipRect(
                          child: CustomPaint(
                            painter: _StripedBarPainter(
                              color: const Color(0xFF00B052),
                              positive: true,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 100 - upPct,
                        child: ClipRect(
                          child: CustomPaint(
                            painter: _StripedBarPainter(
                              color: const Color(0xFFD05858),
                              positive: false,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                // ── Up / Down count ────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Up  $upCount',
                      style: const TextStyle(
                        color: Color(0xFF00B052),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DMSans',
                      ),
                    ),
                    Text(
                      'Down  $downCount',
                      style: const TextStyle(
                        color: Color(0xFFD05858),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── 2. Graph — NEECHE, bars bottom se touch ────
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(buckets.length, (i) {
                      final (b, count) = buckets[i];
                      final barH = maxCount > 0
                          ? (count / maxCount * 120).clamp(12.0, 120.0)
                          : 12.0;
                      final clr = b.positive
                          ? Color.lerp(
                              const Color(0xFF00B052).withValues(alpha: 0.25),
                              const Color(0xFF00B052),
                              (i / 4).clamp(0.0, 1.0),
                            )!
                          : Color.lerp(
                              const Color(0xFFD05858),
                              const Color(0xFFD05858).withValues(alpha: 0.25),
                              ((i - 5) / 6).clamp(0.0, 1.0),
                            )!;

                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Count number
                            if (count > 0)
                              Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'DMSans',
                                  height: 1,
                                ),
                                overflow: TextOverflow.visible,
                              ),
                            const SizedBox(height: 2),

                            // Striped bar
                            Container(
                              height: barH,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5),
                                ),
                                child: CustomPaint(
                                  painter: _StripedBarPainter(
                                    color: clr,
                                    positive: b.positive,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),

                            // 5px gap bar ke neeche aur label ke upar
                            const SizedBox(height: 5),

                            // Label
                            Text(
                              b.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                                fontSize: 8,
                                fontFamily: 'DMSans',
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ── Gainers & Losers — horizontal scroll, side by side ─────────
  // Dono cards ek horizontal scroll mein pass pass dikhte hain.
  // Card width = 82% screen — doosra card thoda peek karta hai
  // jo user ko swipe karne ka hint deta hai.
  Widget _buildGainersLosers() {
    return Obx(() {
      final loading = _ctrl.isLoading.value;
      final screenW = MediaQuery.of(context).size.width;
      // 82% width: doosra card thoda peeks out, swipe hint milta hai
      final cardW = screenW * 0.82;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scroll hint label

          // Horizontal scroll — negative margin so cards reach screen edges
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(right: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CoinPageCard(
                  title: 'Gainers',
                  titleColor: Color(0xFF00B052),
                  loading: loading,
                  coins: loading ? [] : _ctrl.gainers,
                  isGainer: true,
                  cardWidth: cardW,
                ),
                const SizedBox(width: 10),
                _CoinPageCard(
                  title: 'Losers',
                  titleColor: Color(0xFFFF0A00),
                  loading: loading,
                  coins: loading ? [] : _ctrl.losers,
                  isGainer: false,
                  cardWidth: cardW,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ── Bucket helper ─────────────────────────────────────────────────
class _Bucket {
  const _Bucket(this.label, this.min, this.max, this.positive);
  final String label;
  final double min, max;
  final bool positive;
}

// ── Stat Card wrapper ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }
}

// ── Dominance item ────────────────────────────────────────────────
class _DomItem extends StatelessWidget {
  const _DomItem({
    required this.label,
    required this.color,
    required this.pct,
    this.change,
  });
  final String label;
  final Color color;
  final double pct;
  final double? change;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'DMSans',
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${pct.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            if (change != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    change! >= 0 ? Icons.add : Icons.remove,
                    color: change! >= 0
                        ? const Color(0xFF00B052)
                        : Color(0xFFD73C3C),
                    size: 12,
                  ),
                  Flexible(
                    child: Text(
                      '${change!.abs().toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: change! >= 0
                            ? const Color(0xFF00B052)
                            : Color(0xFFD73C3C),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'DMSans',
                        height: 1,
                      ),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'altcoins',
                style: TextStyle(
                  color: Color(0x80FFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'DMSans',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Mini Gauge Painter ────────────────────────────────────────────
class _MiniGaugePainter extends CustomPainter {
  const _MiniGaugePainter({required this.value});
  final int value;

  static const _segments = [
    (Color(0xFFE53E3E), 0.0, 36.0), // 0–20   Red
    (Color(0xFFDD6B20), 36.0, 36.0), // 21–40  Orange
    (Color(0xFFD69E2E), 72.0, 36.0), // 41–60  Yellow
    (Color(0xFF38A169), 108.0, 36.0), // 61–80  Light Green
    (Color(0xFF22C55E), 144.0, 36.0), // 81–100 Green
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    final r = size.width / 2 - 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.butt;

    for (final (color, startDeg, sweepDeg) in _segments) {
      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        (180 + startDeg) * math.pi / 180,
        sweepDeg * math.pi / 180,
        false,
        paint,
      );
    }

    // value 0 = leftmost (180°), value 100 = rightmost (0°)
    final clamped = value.clamp(0, 100).toDouble();
    final angleDeg = 180.0 - (clamped / 100.0) * 180.0;
    final rad = angleDeg * math.pi / 180.0;
    final len = r - 4;

    // needle tip: cos(angleDeg in standard) = cos(rad), sin = sin(rad)
    final tipX = cx + len * math.cos(angleDeg * math.pi / 180.0);
    final tipY = cy - len * math.sin(angleDeg * math.pi / 180.0);

    canvas.drawLine(
      Offset(cx, cy),
      Offset(tipX, tipY),
      Paint()
        ..color = _fgColor(value)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = _fgColor(value));
  }

  @override
  bool shouldRepaint(_MiniGaugePainter old) => old.value != value;
}

// ── Heatmap Cell ─────────────────────────────────────────────────
class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.coin});
  final MarketCoin coin;

  @override
  Widget build(BuildContext context) {
    final pct = coin.change ?? 0;
    final bg = _heatColor(pct);

    return GestureDetector(
      onTap: () =>
          Get.to(() => CurrencyPairDetailsScreen(pair: coin.convertCoinPair())),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CoinIcon(
              iconUrl: coin.coinIcon,
              symbol: coin.coinType ?? '',
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              coin.coinType ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _fmtPrice(coin.price),
              style: const TextStyle(
                color: Color(0x80FFFFFF),
                fontSize: 8,
                fontFamily: 'DMSans',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gainers / Losers Card ─────────────────────────────────────────
// cardWidth se fixed width milti hai — horizontal scroll mein sahi fit hota hai
// shrinkWrap:true + NeverScrollableScrollPhysics — sara data dikhta hai, cut nahi hota
class _CoinPageCard extends StatelessWidget {
  const _CoinPageCard({
    required this.title,
    required this.titleColor,
    required this.loading,
    required this.coins,
    required this.isGainer,
    required this.cardWidth,
  });

  final String title;
  final Color titleColor;
  final bool loading;
  final List<MarketCoin> coins;
  final bool isGainer;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // height = content
          children: [
            // ── Title ───────────────────────────────────────────
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                  ),
                ),
                SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: titleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: titleColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    isGainer ? Icons.trending_up : Icons.trending_down,
                    color: titleColor,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Column headers ───────────────────────────────────
            // Yeh poora Padding(headers) block replace karo:
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: const [
                  Expanded(
                    child: Text(
                      'Market',
                      style: TextStyle(
                        color: Color(0x80FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Last Price',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0x80FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '24h Change',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0x80FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: _kBorder, height: 14),
            // ── Rows ─────────────────────────────────────────────
            if (loading)
              ...List.generate(
                5,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Sk(h: 40),
                ),
              )
            else
              // shrinkWrap — container grows with content, no cut-off
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: coins.length,
                itemBuilder: (_, i) =>
                    _CoinRow(coin: coins[i], isGainer: isGainer),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Coin Row ──────────────────────────────────────────────────────
class _CoinRow extends StatelessWidget {
  const _CoinRow({required this.coin, required this.isGainer});
  final MarketCoin coin;
  final bool isGainer;

  @override
  Widget build(BuildContext context) {
    final pct = coin.change ?? 0;
    final pctColor = isGainer ? Color(0xFF00B052) : Color(0xFFD05858);

    return GestureDetector(
      onTap: () =>
          Get.to(() => CurrencyPairDetailsScreen(pair: coin.convertCoinPair())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        // Poora _CoinRow ka child Row replace karo:
        child: Row(
          children: [
            // ── Market (coin icon + name) — Expanded ──────────
            Expanded(
              child: Row(
                children: [
                  _CoinIcon(
                    iconUrl: coin.coinIcon,
                    symbol: coin.coinType ?? '',
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            coin.coinType ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ),
                        const Text(
                          ' USDT',
                          style: TextStyle(
                            color: Color(0x80FFFFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'DMSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Last Price — Expanded center ──────────────────
            Expanded(
              child: Text(
                _fmtPrice(coin.price),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'DMSans',
                ),
              ),
            ),

            // ── 24h Change — Expanded right ───────────────────
            Expanded(
              child: Text(
                '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pctColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coin Icon with fallback ────────────────────────────────────────
class _CoinIcon extends StatefulWidget {
  const _CoinIcon({
    required this.iconUrl,
    required this.symbol,
    this.size = 24,
  });
  final String? iconUrl;
  final String symbol;
  final double size;

  @override
  State<_CoinIcon> createState() => _CoinIconState();
}

class _CoinIconState extends State<_CoinIcon> {
  int _srcIdx = 0;

  List<String> get _sources {
    final sym = widget.symbol.toLowerCase();
    return [
      if ((widget.iconUrl ?? '').isNotEmpty) widget.iconUrl!,
      'https://assets.coincap.io/assets/icons/$sym@2x.png',
      'https://cdn.jsdelivr.net/gh/spothq/cryptocurrency-icons@master/32/color/$sym.png',
    ];
  }

  Color get _fallbackColor {
    const colors = [
      Color(0xFFF7931A),
      Color(0xFF627EEA),
      Color(0xFF9945FF),
      Color(0xFF00AAE4),
      Color(0xFF3CC8C8),
      Color(0xFFFF007A),
      Color(0xFF8247E5),
      Color(0xFF2A5ADA),
    ];
    int hash = 0;
    for (final ch in widget.symbol.codeUnits) {
      hash = (hash * 31 + ch) & 0xFFFFFF;
    }
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_srcIdx >= _sources.length) return _letterAvatar();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: _sources[_srcIdx],
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _srcIdx++);
          });
          return _letterAvatar();
        },
        placeholder: (_, __) => _letterAvatar(),
      ),
    );
  }

  Widget _letterAvatar() {
    final col = _fallbackColor;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: col.withValues(alpha: 0.15),
        border: Border.all(color: col.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        widget.symbol.length >= 2
            ? widget.symbol.substring(0, 2).toUpperCase()
            : widget.symbol.toUpperCase(),
        style: TextStyle(
          color: col,
          fontSize: widget.size * 0.32,
          fontWeight: FontWeight.w800,
          fontFamily: 'DMSans',
        ),
      ),
    );
  }
}

// ── Fear & Greed History Row ──────────────────────────────────────
class _FgHistoryRow extends StatelessWidget {
  const _FgHistoryRow({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final col = _fgColor(value); // value ke hisaab se color
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 12,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: col.withOpacity(0.10), // us color ki 10% opacity
            borderRadius: BorderRadius.circular(10),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${_fgLabel(value)} – ',
                  style: TextStyle(
                    color: col, // label bhi same color
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                  ),
                ),
                TextSpan(
                  text: '$value',
                  style: TextStyle(
                    color: col, // number bhi same color
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Striped Bar Painter ───────────────────────────────────────────
class _StripedBarPainter extends CustomPainter {
  const _StripedBarPainter({required this.color, required this.positive});
  final Color color;
  final bool positive;

  @override
  void paint(Canvas canvas, Size size) {
    // Base fill — thodi transparent
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = color.withOpacity(0.35),
    );

    // Diagonal stripes
    final stripePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const stripeGap = 5.0;
    // Positive: left-to-right diagonal (/), Negative: right-to-left (\)
    if (positive) {
      // / diagonal stripes
      double x = -size.height;
      while (x < size.width + size.height) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height, 0),
          stripePaint,
        );
        x += stripeGap;
      }
    } else {
      // \ diagonal stripes
      double x = -size.height;
      while (x < size.width + size.height) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x + size.height, size.height),
          stripePaint,
        );
        x += stripeGap;
      }
    }
  }

  @override
  bool shouldRepaint(_StripedBarPainter old) =>
      old.color != color || old.positive != positive;
}

// ── Skeleton ──────────────────────────────────────────────────────
class _Sk extends StatelessWidget {
  const _Sk({required this.h});
  final double h;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ── Heatmap Tree Layout ───────────────────────────────────────────
// ── Heatmap Tree Layout ───────────────────────────────────────────
class _HeatmapTreeLayout extends StatelessWidget {
  const _HeatmapTreeLayout({required this.coins});
  final List<MarketCoin> coins;

  @override
  Widget build(BuildContext context) {
    final sorted = List<MarketCoin>.from(coins)
      ..sort((a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0));

    if (sorted.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        const totalH = 450.0;

        const rowDefs = [
          (coinCount: 2, flexes: [6, 4], heightRatio: 30.0),
          (coinCount: 3, flexes: [45, 35, 20], heightRatio: 22.0),
          (coinCount: 4, flexes: [1, 1, 1, 1], heightRatio: 18.0),
          (coinCount: 5, flexes: [1, 1, 1, 1, 1], heightRatio: 15.0),
          (coinCount: 6, flexes: [1, 1, 1, 1, 1, 1], heightRatio: 10.0),
        ];
        const totalRatio = 30.0 + 22.0 + 18.0 + 15.0 + 10.0; // 95

        Widget coinCell(MarketCoin coin, double cellH) {
          final pct = coin.change ?? 0;
          final bg = _heatColor(pct);
          final iconSize = cellH < 38 ? 12.0 : (cellH < 60 ? 16.0 : 22.0);

          // Display levels:
          // showAll      → cellH >= 80 : icon + name + price + %
          // showMinimal  → 45 <= cellH < 80 : icon + % only
          // showIconOnly → cellH < 45 : sirf icon
          final showAll = cellH >= 80;
          final showMinimal = cellH >= 45 && cellH < 80;

          return GestureDetector(
            onTap: () => Get.to(
              () => CurrencyPairDetailsScreen(pair: coin.convertCoinPair()),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CoinIcon(
                          iconUrl: coin.coinIcon,
                          symbol: coin.coinType ?? '',
                          size: iconSize,
                        ),
                        // showIconOnly: kuch nahi — sirf icon upar show hua
                        if (showMinimal) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ],
                        if (showAll) ...[
                          const SizedBox(height: 3),
                          Text(
                            '${coin.coinType ?? ''}/USDT',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _fmtPrice(coin.price),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:  TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // ── Build rows from sorted coins ──────────────────────────
        final rows = <Widget>[];
        int coinIdx = 0;

        for (int rowIdx = 0; rowIdx < rowDefs.length; rowIdx++) {
          final def = rowDefs[rowIdx];
          final rowH =
              (totalH - gap * (rowDefs.length - 1)) *
              def.heightRatio /
              totalRatio;

          final available = (sorted.length - coinIdx).clamp(0, def.coinCount);
          if (available == 0) break;

          final rowCoins = sorted.sublist(coinIdx, coinIdx + available);
          coinIdx += available;

          if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));

          rows.add(
            SizedBox(
              height: rowH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < rowCoins.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(
                      flex: i < def.flexes.length ? def.flexes[i] : 1,
                      child: coinCell(rowCoins[i], rowH),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // ── Extra coins (20+) — 6 coins per row, sirf icon ────────
        while (coinIdx < sorted.length) {
          final available = (sorted.length - coinIdx).clamp(0, 6);
          final rowCoins = sorted.sublist(coinIdx, coinIdx + available);
          coinIdx += available;

          const extraRowH = 38.0; // itni choti height = showIconOnly
          rows.add(const SizedBox(height: gap));
          rows.add(
            SizedBox(
              height: extraRowH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < rowCoins.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(child: coinCell(rowCoins[i], extraRowH)),
                  ],
                ],
              ),
            ),
          );
        }

        // ── 450 fix height + vertical scroll ─────────────────────
        return SizedBox(
          height: totalH,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        );
      },
    );
  }
}
