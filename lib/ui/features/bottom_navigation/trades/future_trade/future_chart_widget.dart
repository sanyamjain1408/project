import 'package:flutter/material.dart';
import 'future_models.dart';

// ── Depth chart data point ────────────────────────────────────────────────────
class DepthPoint {
  final double price;
  final double cumPct;
  const DepthPoint({required this.price, required this.cumPct});
}

// ── Depth chart painter ───────────────────────────────────────────────────────
class DepthChartPainter extends CustomPainter {
  final List<DepthPoint> bidPoints;
  final List<DepthPoint> askPoints;
  final double markPrice;
  final double lowPrice;
  final double highPrice;

  const DepthChartPainter({
    required this.bidPoints,
    required this.askPoints,
    required this.markPrice,
    required this.lowPrice,
    required this.highPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bidPoints.isEmpty && askPoints.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final priceRange = (highPrice - lowPrice).abs();
    if (priceRange == 0) return;

    double px(double price) => ((price - lowPrice) / priceRange * w).clamp(0.0, w);
    double py(double pct) => h - pct * h;

    if (bidPoints.isNotEmpty) {
      final bPath = Path();
      bPath.moveTo(px(bidPoints.first.price), h);
      bPath.lineTo(px(bidPoints.first.price), py(bidPoints.first.cumPct));
      for (int i = 1; i < bidPoints.length; i++) {
        final prev = bidPoints[i - 1];
        final cur = bidPoints[i];
        bPath.lineTo(px(cur.price), py(prev.cumPct));
        bPath.lineTo(px(cur.price), py(cur.cumPct));
      }
      bPath.lineTo(px(bidPoints.last.price), h);
      bPath.close();

      canvas.drawPath(
        bPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0x4D0ECB81), const Color(0x000ECB81)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
      canvas.drawPath(
        bPath,
        Paint()
          ..color = const Color(0xFF0ECB81)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (askPoints.isNotEmpty) {
      final aPath = Path();
      aPath.moveTo(px(askPoints.first.price), h);
      aPath.lineTo(px(askPoints.first.price), py(askPoints.first.cumPct));
      for (int i = 1; i < askPoints.length; i++) {
        final prev = askPoints[i - 1];
        final cur = askPoints[i];
        aPath.lineTo(px(cur.price), py(prev.cumPct));
        aPath.lineTo(px(cur.price), py(cur.cumPct));
      }
      aPath.lineTo(px(askPoints.last.price), h);
      aPath.close();

      canvas.drawPath(
        aPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0x4DF6465D), const Color(0x00F6465D)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
      canvas.drawPath(
        aPath,
        Paint()
          ..color = const Color(0xFFF6465D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final gridPaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(DepthChartPainter old) =>
      old.bidPoints != bidPoints || old.askPoints != askPoints || old.markPrice != markPrice;
}

// ── Full Order Book with Depth Chart (used in chart view mode) ────────────────
class FutureFullOrderBook extends StatelessWidget {
  final List<Map<String, dynamic>> bidRows;
  final List<Map<String, dynamic>> askRows;
  final double markPrice;
  final int pp;
  final double halfWidth;
  final void Function(String price) onPriceTap;

  const FutureFullOrderBook({
    super.key,
    required this.bidRows,
    required this.askRows,
    required this.markPrice,
    required this.pp,
    required this.halfWidth,
    required this.onPriceTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxBidCum = bidRows.isNotEmpty ? (bidRows.last['cum'] as double) : 1.0;
    final maxAskCum = askRows.isNotEmpty ? (askRows.last['cum'] as double) : 1.0;

    final bidPoints = bidRows.map((r) => DepthPoint(
      price: double.tryParse(r['price'] as String) ?? 0,
      cumPct: (r['cum'] as double) / maxBidCum,
    )).toList();

    final askPoints = askRows.map((r) => DepthPoint(
      price: double.tryParse(r['price'] as String) ?? 0,
      cumPct: (r['cum'] as double) / maxAskCum,
    )).toList();

    final lowPrice = bidPoints.isNotEmpty ? bidPoints.last.price : markPrice * 0.95;
    final highPrice = askPoints.isNotEmpty ? askPoints.last.price : markPrice * 1.05;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: futureGreen, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                const Text('Buy', style: TextStyle(fontSize: 11, color: futureMuted, fontFamily: futureDmSans)),
                const SizedBox(width: 12),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: futureRed, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                const Text('Sell', style: TextStyle(fontSize: 11, color: futureMuted, fontFamily: futureDmSans)),
              ],
            ),
          ),
          // Depth chart
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: DepthChartPainter(
                bidPoints: bidPoints,
                askPoints: askPoints,
                markPrice: markPrice,
                lowPrice: lowPrice,
                highPrice: highPrice,
              ),
              size: Size.infinite,
            ),
          ),
          // X-axis labels
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Row(
              children: [
                Text(lowPrice.toStringAsFixed(pp), style: const TextStyle(fontSize: 10, color: futureMuted, fontFamily: futureDmSans)),
                const Spacer(),
                Text(markPrice.toStringAsFixed(pp), style: const TextStyle(fontSize: 10, color: futureTextWhite, fontFamily: futureDmSans)),
                const Spacer(),
                Text(highPrice.toStringAsFixed(pp), style: const TextStyle(fontSize: 10, color: futureMuted, fontFamily: futureDmSans)),
              ],
            ),
          ),
          // Column headers
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(child: Text('Amount', style: TextStyle(fontSize: 11, color: futureMuted, fontFamily: futureDmSans))),
                Text('Price', style: TextStyle(fontSize: 11, color: futureMuted, fontFamily: futureDmSans)),
                Expanded(child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: futureMuted, fontFamily: futureDmSans))),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: bidRows.map((row) {
                    final pct = ((row['pct'] as double) / maxBidCum * 100).clamp(0.0, 100.0);
                    final price = row['price'] as String;
                    final amount = row['amount'] as String;
                    return GestureDetector(
                      onTap: () => onPriceTap(price),
                      child: SizedBox(
                        height: 24,
                        child: Stack(
                          children: [
                            Positioned(
                              right: 0, top: 2, bottom: 2,
                              width: halfWidth * pct / 100,
                              child: Container(color: const Color(0x140ECB81)),
                            ),
                            Row(
                              children: [
                                Text(amount, style: const TextStyle(fontSize: 11, color: futureMuted, fontFamily: futureDmSans)),
                                const Spacer(),
                                Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: futureGreen, fontFamily: futureDmSans)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: askRows.map((row) {
                    final pct = ((row['pct'] as double) / maxAskCum * 100).clamp(0.0, 100.0);
                    final price = row['price'] as String;
                    final amount = row['amount'] as String;
                    return GestureDetector(
                      onTap: () => onPriceTap(price),
                      child: SizedBox(
                        height: 24,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0, top: 2, bottom: 2,
                              width: halfWidth * pct / 100,
                              child: Container(color: const Color(0x14F6465D)),
                            ),
                            Row(
                              children: [
                                Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: futureRed, fontFamily: futureDmSans)),
                                const Spacer(),
                                Text(amount, style: const TextStyle(fontSize: 11, color: futureMuted, fontFamily: futureDmSans)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
