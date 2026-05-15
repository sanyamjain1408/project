import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/market_date.dart';
import 'package:tradexpro_flutter/ui/features/currency_pair_details/currency_pair_details_screen.dart';

import 'market_opportunity_controller.dart';

// ── Design tokens (matching market screen palette) ─────────────────
const _kBg       = Color(0xFF111111);
const _kSurface  = Color(0xFF1A1A1A);
const _kBorder   = Color(0xFF2A2A2A);
const _kGreen    = Color(0xFFCCFF00);
const _kRed      = Color(0xFFEF4444);
const _kText     = Color(0xFFE8ECF4);
const _kMuted    = Color(0xFF5A6278);
const _kMuted2   = Color(0x80FFFFFF);

// ── Fear & Greed helpers ───────────────────────────────────────────
Color _fgColor(int v) {
  if (v <= 24) return const Color(0xFFE53E3E);
  if (v <= 44) return const Color(0xFFDD6B20);
  if (v <= 54) return const Color(0xFFD69E2E);
  if (v <= 74) return const Color(0xFF38A169);
  return const Color(0xFF22C55E);
}

String _fgLabel(int v) {
  if (v <= 24) return 'Extreme Fear';
  if (v <= 44) return 'Fear';
  if (v <= 54) return 'Neutral';
  if (v <= 74) return 'Greed';
  return 'Extreme Greed';
}

String _fgShort(int v) => _fgLabel(v).split(' ').first;

// ── Heatmap color ─────────────────────────────────────────────────
Color _heatColor(double pct) {
  if (pct >= 5)  return const Color(0xFF006D2C);
  if (pct >= 3)  return const Color(0xFF00AC14);
  if (pct >= 2)  return const Color(0xFF007F0F);
  if (pct >= 1)  return const Color(0xFF00520A);
  if (pct > 0)   return const Color(0xFF003D07);
  if (pct > -1)  return const Color(0xFF3A3A3A);
  if (pct >= -2) return const Color(0xFFC00000);
  if (pct >= -5) return const Color(0xFF840000);
  return const Color(0xFF5C0000);
}

// ── Number formatter ──────────────────────────────────────────────
String _fmtPrice(double? p) {
  if (p == null || p == 0) return '\$0.00';
  if (p >= 1000) {
    return '\$${p.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
  if (p >= 1)    return '\$${p.toStringAsFixed(3)}';
  if (p >= 0.01) return '\$${p.toStringAsFixed(5)}';
  return '\$${p.toStringAsFixed(8)}';
}

// ── Main Screen ───────────────────────────────────────────────────
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
        backgroundColor: _kSurface,
        onRefresh: _ctrl.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildFearGreedCard(),
              const SizedBox(height: 16),
              _buildHeatmapCard(),
              const SizedBox(height: 16),
              _buildGainersLosers(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x1FCCFF00),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'OPPORTUNITIES',
            style: TextStyle(
              color: _kGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Discover Opportunities\nBefore the Market Moves',
          style: TextStyle(
            color: _kText,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontFamily: 'DMSans',
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track top gainers, visualize trends with heatmaps\nand make smarter, data-driven decisions.',
          style: TextStyle(
            color: _kMuted2,
            fontSize: 13,
            fontFamily: 'DMSans',
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Fear & Greed Card ─────────────────────────────────────────────
  Widget _buildFearGreedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fear & Greed Index',
            style: TextStyle(
              color: _kText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (_ctrl.isFgLoading.value) {
              return _skeleton(height: 140);
            }
            if (!_ctrl.fgLoaded.value) {
              return const Center(
                child: Text(
                  'Data unavailable',
                  style: TextStyle(color: _kMuted, fontSize: 12),
                ),
              );
            }
            return Column(
              children: [
                _FgGauge(value: _ctrl.fgValue.value),
                const SizedBox(height: 16),
                _fgPill('Yesterday', _ctrl.fgYesterday.value),
                const SizedBox(height: 10),
                _fgPill('Last Week', _ctrl.fgLastWeek.value),
                const SizedBox(height: 10),
                _fgPill('Last Month', _ctrl.fgLastMonth.value),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _fgPill(String label, int value) {
    final col = _fgColor(value);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'DMSans',
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: col.withOpacity(0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: col.withOpacity(0.35)),
          ),
          child: Text(
            '${_fgShort(value)} – $value',
            style: TextStyle(
              color: col,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      ],
    );
  }

  // ── Heatmap Card ──────────────────────────────────────────────────
  Widget _buildHeatmapCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Heatmap (24h)',
            style: TextStyle(
              color: _kText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            if (_ctrl.isLoading.value) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.9,
                ),
                itemCount: 20,
                itemBuilder: (_, __) => _skeleton(height: 80),
              );
            }
            final coins = _ctrl.heatmapCoins;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.9,
              ),
              itemCount: coins.length,
              itemBuilder: (_, i) => _HeatCell(coin: coins[i]),
            );
          }),
        ],
      ),
    );
  }

  // ── Gainers & Losers ─────────────────────────────────────────────
  Widget _buildGainersLosers() {
    return Obx(() {
      final loading = _ctrl.isLoading.value;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _CoinListCard(
              title: 'Top Gainers',
              titleColor: _kGreen,
              loading: loading,
              coins: loading ? [] : _ctrl.gainers,
              isGainer: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CoinListCard(
              title: 'Top Losers',
              titleColor: _kRed,
              loading: loading,
              coins: loading ? [] : _ctrl.losers,
              isGainer: false,
            ),
          ),
        ],
      );
    });
  }

  Widget _skeleton({double height = 14, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ── Fear & Greed Gauge ────────────────────────────────────────────
class _FgGauge extends StatelessWidget {
  const _FgGauge({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final col   = _fgColor(value);
    final label = _fgLabel(value);

    return SizedBox(
      width: 140,
      child: Column(
        children: [
          CustomPaint(
            size: const Size(140, 76),
            painter: _GaugePainter(value: value),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              color: col,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'DMSans',
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: col,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.value});
  final int value;

  static const _segments = [
    (Color(0xFFE53E3E), 0.0, 36.0),   // Extreme Fear
    (Color(0xFFDD6B20), 36.0, 36.0),  // Fear
    (Color(0xFFD69E2E), 72.0, 36.0),  // Neutral
    (Color(0xFF38A169), 108.0, 36.0), // Greed
    (Color(0xFF22C55E), 144.0, 36.0), // Extreme Greed
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    final r  = size.width / 2 - 4;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap  = StrokeCap.butt;

    for (final (color, startDeg, sweepDeg) in _segments) {
      trackPaint.color = color;
      final startRad = (180 + startDeg) * math.pi / 180;
      final sweepRad = sweepDeg * math.pi / 180;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startRad, sweepRad, false, trackPaint,
      );
    }

    // Needle
    final clamped  = value.clamp(0, 100).toDouble();
    final angleDeg = 180 - (clamped / 100) * 180;
    final rad      = angleDeg * math.pi / 180;
    final needleLen = r - 10;
    final needleEnd = Offset(
      cx + needleLen * math.cos(math.pi - rad),
      cy - needleLen * math.sin(rad),
    );

    final needleColor = _fgColor(value);
    canvas.drawLine(
      Offset(cx, cy),
      needleEnd,
      Paint()
        ..color       = needleColor
        ..strokeWidth = 4
        ..strokeCap   = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      7,
      Paint()..color = needleColor,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}

// ── Heatmap Cell ─────────────────────────────────────────────────
class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.coin});
  final MarketCoin coin;

  @override
  Widget build(BuildContext context) {
    final pct = coin.change ?? 0;
    final bg  = _heatColor(pct);

    return GestureDetector(
      onTap: () => Get.to(
        () => CurrencyPairDetailsScreen(pair: coin.convertCoinPair()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CoinIcon(iconUrl: coin.coinIcon, symbol: coin.coinType ?? '', size: 24),
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

// ── Coin List Card (Gainers / Losers) ─────────────────────────────
class _CoinListCard extends StatelessWidget {
  const _CoinListCard({
    required this.title,
    required this.titleColor,
    required this.loading,
    required this.coins,
    required this.isGainer,
  });

  final String title;
  final Color titleColor;
  final bool loading;
  final List<MarketCoin> coins;
  final bool isGainer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 10),
          // Header
          Row(
            children: [
              const Expanded(
                flex: 5,
                child: Text(
                  'Coin',
                  style: TextStyle(
                    color: _kMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'DMSans',
                  ),
                ),
              ),
              const Text(
                '24h',
                style: TextStyle(
                  color: _kMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
          Divider(color: _kBorder, height: 12),
          if (loading)
            ...List.generate(
              6,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            )
          else
            ...coins.map((coin) => _CoinRow(coin: coin, isGainer: isGainer)),
        ],
      ),
    );
  }
}

class _CoinRow extends StatelessWidget {
  const _CoinRow({required this.coin, required this.isGainer});
  final MarketCoin coin;
  final bool isGainer;

  @override
  Widget build(BuildContext context) {
    final pct      = coin.change ?? 0;
    final pctColor = isGainer ? _kGreen : _kRed;

    return GestureDetector(
      onTap: () => Get.to(
        () => CurrencyPairDetailsScreen(pair: coin.convertCoinPair()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _CoinIcon(
              iconUrl: coin.coinIcon,
              symbol: coin.coinType ?? '',
              size: 20,
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.coinType ?? '',
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  Text(
                    _fmtPrice(coin.price),
                    style: const TextStyle(
                      color: _kMuted,
                      fontSize: 9,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
              style: TextStyle(
                color: pctColor,
                fontSize: 11,
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

// ── Coin Icon with fallback ───────────────────────────────────────
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
    final colors = [
      const Color(0xFFF7931A), const Color(0xFF627EEA),
      const Color(0xFF9945FF), const Color(0xFF00AAE4),
      const Color(0xFF3CC8C8), const Color(0xFFFF007A),
      const Color(0xFF8247E5), const Color(0xFF2A5ADA),
    ];
    int hash = 0;
    for (final ch in widget.symbol.codeUnits) {
      hash = (hash * 31 + ch) & 0xFFFFFF;
    }
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_srcIdx >= _sources.length) {
      return _letterAvatar();
    }
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
        color: col.withOpacity(0.15),
        border: Border.all(color: col.withOpacity(0.4)),
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
