import 'package:flutter/material.dart';
import 'future_models.dart';

// ── Order book row bar painter (no gaps between rows) ────────────────────────
class _OrderRowBarPainter extends CustomPainter {
  final List<double> bidFracs;
  final List<double> askFracs;
  final double rowH;
  final double colW;
  final double gap;
  final Color bidColor;
  final Color askColor;

  const _OrderRowBarPainter({
    required this.bidFracs,
    required this.askFracs,
    required this.rowH,
    required this.colW,
    required this.gap,
    required this.bidColor,
    required this.askColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bidPaint = Paint()..color = bidColor;
    final askPaint = Paint()..color = askColor;
    // bid bars: grow from right edge of left column leftward
    for (int i = 0; i < bidFracs.length; i++) {
      final frac = bidFracs[i];
      if (frac <= 0) continue;
      final barW = colW * frac;
      final top = i * rowH;
      canvas.drawRect(Rect.fromLTWH(colW - barW, top, barW, rowH), bidPaint);
    }
    // ask bars: grow from left edge of right column rightward (after gap)
    for (int i = 0; i < askFracs.length; i++) {
      final frac = askFracs[i];
      if (frac <= 0) continue;
      final barW = colW * frac;
      final top = i * rowH;
      canvas.drawRect(Rect.fromLTWH(colW + gap, top, barW, rowH), askPaint);
    }
  }

  @override
  bool shouldRepaint(_OrderRowBarPainter old) =>
      old.bidFracs != bidFracs || old.askFracs != askFracs;
}

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
  final String base;
  final String quote;
  final void Function(String price) onPriceTap;

  const FutureFullOrderBook({
    super.key,
    required this.bidRows,
    required this.askRows,
    required this.markPrice,
    required this.pp,
    required this.halfWidth,
    this.base = 'BTC',
    this.quote = 'USDT',
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
          // Column headers — matches DetailsOrderBookView exactly
          Row(
            children: [
              Expanded(flex: 3, child: Text('Amount($base)', style: const TextStyle(fontSize: 10, color: Color(0xFF848E9C)), overflow: TextOverflow.ellipsis)),
              Expanded(flex: 3, child: Text('Price($quote)', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Color(0xFF848E9C)), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: Text('Price($quote)', style: const TextStyle(fontSize: 10, color: Color(0xFF848E9C)), overflow: TextOverflow.ellipsis)),
              Expanded(flex: 3, child: Text('Amount($base)', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Color(0xFF848E9C)), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          // Paired rows — single CustomPaint for seamless color bars, text on top
          LayoutBuilder(builder: (context, constraints) {
            const rowH = 18.0;
            final maxRows = bidRows.length > askRows.length ? bidRows.length : askRows.length;
            if (maxRows == 0) return const SizedBox.shrink();
            final totalH = maxRows * rowH;
            final totalW = constraints.maxWidth;
            const gap = 10.0;
            final colW = (totalW - gap) / 2;

            final bidFracs = List.generate(maxRows, (i) =>
                i < bidRows.length ? ((bidRows[i]['pct'] as double) / 100).clamp(0.0, 1.0) : 0.0);
            final askFracs = List.generate(maxRows, (i) =>
                i < askRows.length ? ((askRows[i]['pct'] as double) / 100).clamp(0.0, 1.0) : 0.0);

            return SizedBox(
              height: totalH,
              child: Stack(
                children: [
                  // Single painter draws all bars with no gaps
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _OrderRowBarPainter(
                        bidFracs: bidFracs,
                        askFracs: askFracs,
                        rowH: rowH,
                        colW: colW,
                        gap: gap,
                        bidColor: const Color(0x2622C55E),
                        askColor: const Color(0x26D05858),
                      ),
                    ),
                  ),
                  // Text rows on top
                  Column(
                    children: List.generate(maxRows, (i) {
                      final bid = i < bidRows.length ? bidRows[i] : null;
                      final ask = i < askRows.length ? askRows[i] : null;
                      return SizedBox(
                        height: rowH,
                        child: Row(
                          children: [
                            // Buy side: Amount | Price
                            SizedBox(
                              width: colW,
                              child: Row(children: [
                                Expanded(flex: 3, child: Text(
                                  bid != null ? (bid['amount'] as String) : '',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFDDDDDD), fontFamily: 'monospace'),
                                  maxLines: 1,
                                )),
                                Expanded(flex: 3, child: Text(
                                  bid != null ? (bid['price'] as String) : '',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 11, color: futureGreen, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                  maxLines: 1,
                                )),
                              ]),
                            ),
                            const SizedBox(width: gap),
                            // Sell side: Price | Amount
                            SizedBox(
                              width: colW,
                              child: Row(children: [
                                Expanded(flex: 3, child: Text(
                                  ask != null ? (ask['price'] as String) : '',
                                  style: const TextStyle(fontSize: 11, color: futureRed, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                  maxLines: 1,
                                )),
                                Expanded(flex: 3, child: Text(
                                  ask != null ? (ask['amount'] as String) : '',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFDDDDDD), fontFamily: 'monospace'),
                                  maxLines: 1,
                                )),
                              ]),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
