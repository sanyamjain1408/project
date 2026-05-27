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
    const gap = 10.0;
    final halfW = (w - gap) / 2;

    // Bids: highest bid price → right edge (halfW = center), lowest → left (0)
    double bidPx(double price) {
      if (bidPoints.isEmpty) return halfW;
      final lo = bidPoints.last.price;   // lowest bid = left
      final hi = bidPoints.first.price;  // highest bid = right (center)
      final range = (hi - lo).abs();
      if (range == 0) return halfW;
      return (halfW * (price - lo) / range).clamp(0.0, halfW);
    }

    // Asks: lowest ask price → left edge (halfW+gap = center), highest → right (w)
    double askPx(double price) {
      if (askPoints.isEmpty) return halfW + gap;
      final lo = askPoints.first.price;  // lowest ask = left (center)
      final hi = askPoints.last.price;   // highest ask = right
      final range = (hi - lo).abs();
      if (range == 0) return halfW + gap;
      return (halfW + gap + halfW * (price - lo) / range).clamp(halfW + gap, w);
    }

    // Y: 0% = bottom, 100% = top
    double py(double pct) => h - pct * h;

    // ── Bids (left half) — staircase from center outward ──────────────────
    if (bidPoints.isNotEmpty) {
      // bidPoints[0] = highest price (center), last = lowest price (left edge)
      final bPath = Path();
      bPath.moveTo(halfW, h);
      bPath.lineTo(halfW, py(bidPoints.first.cumPct));
      for (int i = 1; i < bidPoints.length; i++) {
        final prev = bidPoints[i - 1];
        final cur  = bidPoints[i];
        bPath.lineTo(bidPx(cur.price), py(prev.cumPct));
        bPath.lineTo(bidPx(cur.price), py(cur.cumPct));
      }
      bPath.lineTo(bidPx(bidPoints.last.price), h);
      bPath.close();

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, halfW, h));
      canvas.drawPath(
        bPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0x400ECB81), const Color(0x000ECB81)],
          ).createShader(Rect.fromLTWH(0, 0, halfW, h)),
      );
      canvas.drawPath(
        bPath,
        Paint()
          ..color = const Color(0x800ECB81)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.restore();
    }

    // ── Asks (right half) — staircase from center outward ─────────────────
    if (askPoints.isNotEmpty) {
      // askPoints[0] = lowest price (center), last = highest price (right edge)
      final aPath = Path();
      aPath.moveTo(halfW + gap, h);
      aPath.lineTo(halfW + gap, py(askPoints.first.cumPct));
      for (int i = 1; i < askPoints.length; i++) {
        final prev = askPoints[i - 1];
        final cur  = askPoints[i];
        aPath.lineTo(askPx(cur.price), py(prev.cumPct));
        aPath.lineTo(askPx(cur.price), py(cur.cumPct));
      }
      aPath.lineTo(askPx(askPoints.last.price), h);
      aPath.close();

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(halfW + gap, 0, halfW, h));
      canvas.drawPath(
        aPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0x40F6465D), const Color(0x00F6465D)],
          ).createShader(Rect.fromLTWH(halfW + gap, 0, halfW, h)),
      );
      canvas.drawPath(
        aPath,
        Paint()
          ..color = const Color(0x80F6465D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.restore();
    }

    // Horizontal grid lines
    final gridPaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      canvas.drawLine(Offset(0, h * i / 4), Offset(w, h * i / 4), gridPaint);
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

  static const _labelStyle = TextStyle(fontSize: 10, color: futureMuted, fontFamily: futureDmSans);
  static const _labelWhite = TextStyle(fontSize: 10, color: futureTextWhite, fontFamily: futureDmSans);

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

    final lowPrice  = bidPoints.isNotEmpty ? bidPoints.last.price  : markPrice * 0.95;
    final highPrice = askPoints.isNotEmpty ? askPoints.last.price : markPrice * 1.05;

    // Right Y-axis: 4 evenly-spaced ask price labels (top→bottom = high→low)
    String fmtPrice(double v) => v.toStringAsFixed(pp);
    final askLo = askPoints.isNotEmpty ? askPoints.first.price : markPrice;
    final askHi = askPoints.isNotEmpty ? askPoints.last.price  : markPrice * 1.05;

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
          // Depth chart + right Y-axis labels overlay
          SizedBox(
            height: 110,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: DepthChartPainter(
                      bidPoints: bidPoints,
                      askPoints: askPoints,
                      markPrice: markPrice,
                      lowPrice: lowPrice,
                      highPrice: highPrice,
                    ),
                  ),
                ),
                // Right Y-axis: ask price range (top = highest ask, bottom = lowest ask)
                Positioned(
                  right: 2, top: 0, bottom: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmtPrice(askHi), style: _labelStyle),
                      Text(fmtPrice(askLo + (askHi - askLo) * 0.66), style: _labelStyle),
                      Text(fmtPrice(askLo + (askHi - askLo) * 0.33), style: _labelStyle),
                      Text(fmtPrice(askLo), style: _labelStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // X-axis labels: low | mark | high
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Row(
              children: [
                Text(lowPrice.toStringAsFixed(pp), style: _labelStyle),
                const Spacer(),
                Text(markPrice.toStringAsFixed(pp), style: _labelWhite),
                const Spacer(),
                Text(highPrice.toStringAsFixed(pp), style: _labelStyle),
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
