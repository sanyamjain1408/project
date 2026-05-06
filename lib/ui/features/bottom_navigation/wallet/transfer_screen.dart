import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/currency.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/activity/activity_screen.dart';

import 'swap/swap_screen.dart';
import 'wallet_crypto_withdraw/wallet_crypto_withdraw_controller.dart';

const _dmSans = 'DMSans';
const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);

// SVG original dimensions
const double _svgNW = 362.0;
const double _svgNH = 204.0;

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  final TextEditingController _amountCtrl = TextEditingController();
  final Rx<Currency> _selectedCoin = Currency().obs;
  late final WalletCryptoWithdrawController _withdrawCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _withdrawCtrl = Get.isRegistered<WalletCryptoWithdrawController>()
        ? Get.find<WalletCryptoWithdrawController>()
        : Get.put(WalletCryptoWithdrawController());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _withdrawCtrl.getWithdrawCoinList();
      if (_withdrawCtrl.currencyList.isNotEmpty && mounted) {
        _selectedCoin.value = _withdrawCtrl.currencyList.first;
      }
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _openCurrencySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CurrencySelectSheet(
        currencies: _withdrawCtrl.currencyList.toList(),
        onSelect: (c) {
          _selectedCoin.value = c;
          Get.back();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    final screenW = MediaQuery.of(context).size.width - 32;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.arrow_back, color: _white, size: 22),
          ),
        ),
        title: const Text(
          'Transfer',
          style: TextStyle(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: _dmSans,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                TemporaryData.activityType = HistoryType.transaction;
                Get.to(() => const ActivityScreen());
              },
              child: RotationTransition(
                turns: _spinCtrl,
                child: Image.asset(
                  'assets/icons/time.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.history, color: _white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── CONFIRM BUTTON ──────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          bottomPad > 0 ? bottomPad : 16,
        ),
        color: _bg,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Get.to(() => const SwapScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _card,
              elevation: 0,
              overlayColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: _white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: _dmSans,
                height: 24 / 16,
              ),
            ),
          ),
        ),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            // ── NEW BANNER ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF53F8A0), // #53F8A0
                          Color(0xFF00E5AB), // #00E5AB
                        ],
                      ),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        fontFamily: _dmSans,
                        height: 12 / 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Financial Account transfer are now supported. Transfers in or out will automatically subscribe to redeem from their respective flexible-term Earn products.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontFamily: _dmSans,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // ── TRANSFER DIRECTION CARD ─────────────────────────────────────
            _TransferDirectionCard(screenW: screenW),

            const SizedBox(height: 16),

            // ── CURRENCY SELECTOR ───────────────────────────────────────────
            GestureDetector(
              onTap: _openCurrencySheet,
              child: Obx(() {
                final coin = _selectedCoin.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      if ((coin.coinIcon ?? '').isNotEmpty) ...[
                        showImageNetwork(
                          imagePath: coin.coinIcon,
                          height: 28,
                          width: 28,
                          bgColor: Colors.transparent,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          coin.coinType?.isNotEmpty == true
                              ? coin.coinType!
                              : 'Select Currency',
                          style: const TextStyle(
                            color: _white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: _dmSans,
                            height: 24 / 16,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: _white,
                        size: 16,
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // ── AMOUNT INPUT ────────────────────────────────────────────────
            Obx(() {
              final coinType = _selectedCoin.value.coinType ?? 'USDT';
              return Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: _white,
                          fontFamily: _dmSans,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 24 / 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Minimum 0',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontFamily: _dmSans,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 24 / 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            coinType,
                            style: const TextStyle(
                              color: _white,
                              fontFamily: _dmSans,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 24 / 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Max',
                            style: TextStyle(
                              color: _green,
                              fontFamily: _dmSans,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 24 / 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),

            // ── MIN / COIN / MAX + AVAILABLE ────────────────────────────────
            Obx(() {
              final coinType = _selectedCoin.value.coinType ?? 'USDT';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Min : 0.0000001',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: _dmSans,
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        coinType,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: _dmSans,
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Max',
                        style: TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontFamily: _dmSans,
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Available: 0.00 $coinType',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: _dmSans,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 20),

            // ── HOLD TO EARN CARD ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x3377D215), Color(0x33DEFF9E)],
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hold to Earn',
                          style: TextStyle(
                            color: _white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: _dmSans,
                            height: 24 / 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'No lock-up. Trade anytime with daily earnings credited automatically.',
                          style: TextStyle(
                            color: _white,
                            fontSize: 12,
                            fontFamily: _dmSans,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF53F8A0), Color(0xFF00E5AB)],
                      ),
                    ),
                    child: const Text(
                      'APR up to 3.2%',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: _dmSans,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── TRANSFER DIRECTION CARD ─────────────────────────────────────────────────────
class _TransferDirectionCard extends StatefulWidget {
  const _TransferDirectionCard({required this.screenW});
  final double screenW;

  @override
  State<_TransferDirectionCard> createState() => _TransferDirectionCardState();
}

class _TransferDirectionCardState extends State<_TransferDirectionCard> {
  bool _spotIsFrom = true; // true = Spot→Future, false = Future→Spot

  void _swap() => setState(() => _spotIsFrom = !_spotIsFrom);

  @override
  Widget build(BuildContext context) {
    final screenW = widget.screenW;

    // Preserve SVG aspect ratio: 362 × 204
    final cardH = screenW * _svgNH / _svgNW;
    final sx = screenW / _svgNW;
    final sy = cardH / _svgNH;

    // Circle center and radius from SVG (center = 181,102 ; radius = 20)
    final circleCx = 181.0 * sx;
    final circleCy = 102.0 * sy;
    final circleR = 20.0 * sx;

    final fromLabel = _spotIsFrom ? 'Spot' : 'Future';
    final toLabel = _spotIsFrom ? 'Future' : 'Spot';

    return SizedBox(
      width: screenW,
      height: cardH,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── 1. Dark base ────────────────────────────────────────────────
          Positioned.fill(
            child: ClipPath(
              clipper: _TransferOuterClipper(sx: sx, sy: sy),
              child: Container(color: _bg),
            ),
          ),

          // ── 2. Left wave (horizontally flipped), clipped to card shape ──
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: screenW * 0.36,
            child: ClipPath(
              clipper: _TransferOuterClipper(sx: sx, sy: sy),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                child: Image.asset(
                  'assets/images/wallet_green_wave.png',
                  width: screenW * 0.36,
                  height: cardH,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ── 3. Right wave, clipped to card shape ────────────────────────
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: screenW * 0.36,
            child: ClipPath(
              clipper: _TransferOuterClipper(
                sx: sx,
                sy: sy,
                offsetX: screenW * 0.64,
              ),
              child: Image.asset(
                'assets/images/wallet_green_wave.png',
                width: screenW * 0.36,
                height: cardH,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ── 4. SVG card shape (dark fill + circle hole) ─────────────────
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/svg/transfer.svg',
              width: screenW,
              height: cardH,
              fit: BoxFit.fill,
            ),
          ),

          // ── 5. Border glow (notch only) + center divider lines ─────────
          Positioned.fill(
            child: CustomPaint(
              painter: _TransferBorderGlowPainter(
                sx: sx,
                sy: sy,
                cardW: screenW,
                cardH: cardH,
                circleCx: circleCx,
                circleCy: circleCy,
                circleR: circleR,
              ),
            ),
          ),

          // ── 7. "From" + fromLabel — top half ───────────────────────────
          Positioned(
            top: 10,
            left: 5,
            right: 0,
            height: circleCy - circleR,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'From',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: _dmSans,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fromLabel,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: _dmSans,
                    height: 28 / 20,
                  ),
                ),
              ],
            ),
          ),

          // ── 8. Swap arrows — inside the SVG circle hole ─────────────────
          Positioned(
            left: circleCx - circleR,
            top: circleCy - circleR,
            width: circleR * 2,
            height: circleR * 2,
            child: GestureDetector(
              onTap: _swap,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  'assets/icons/arrow.png', 
                  width: circleR * 1.1,
                  height: circleR * 1.1,
                  color: _white, 
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ── 9. toLabel + "To" — bottom half ────────────────────────────
          Positioned(
            bottom: 10,
            left: 5,
            right: 0,
            height: cardH - (circleCy + circleR),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  toLabel,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: _dmSans,
                    height: 28 / 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'To',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: _dmSans,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── STANDALONE PATH BUILDER ─────────────────────────────────────────────────────
// Outer boundary of assets/svg/transfer.svg — no hole, no offset.
Path _buildTransferCardOuterPath(double sx, double sy) {
  return Path()
    ..moveTo(132.716 * sx, 0)
    ..cubicTo(
      138.02 * sx,
      0,
      143.107 * sx,
      2.107 * sy,
      146.857 * sx,
      5.857 * sy,
    )
    ..lineTo(155.143 * sx, 14.143 * sy)
    ..cubicTo(
      158.893 * sx,
      17.893 * sy,
      163.98 * sx,
      20 * sy,
      169.284 * sx,
      20 * sy,
    )
    ..lineTo(192.716 * sx, 20 * sy)
    ..cubicTo(
      198.02 * sx,
      20 * sy,
      203.107 * sx,
      17.893 * sy,
      206.857 * sx,
      14.143 * sy,
    )
    ..lineTo(215.143 * sx, 5.857 * sy)
    ..cubicTo(218.893 * sx, 2.107 * sy, 223.98 * sx, 0, 229.284 * sx, 0)
    ..lineTo(342 * sx, 0)
    ..cubicTo(353.046 * sx, 0, 362 * sx, 8.954 * sy, 362 * sx, 20 * sy)
    ..lineTo(362 * sx, 184 * sy)
    ..cubicTo(
      362 * sx,
      195.046 * sy,
      353.046 * sx,
      204 * sy,
      342 * sx,
      204 * sy,
    )
    ..lineTo(229.284 * sx, 204 * sy)
    ..cubicTo(
      223.98 * sx,
      204 * sy,
      218.893 * sx,
      201.893 * sy,
      215.143 * sx,
      198.143 * sy,
    )
    ..lineTo(206.857 * sx, 189.857 * sy)
    ..cubicTo(
      203.107 * sx,
      186.107 * sy,
      198.02 * sx,
      184 * sy,
      192.716 * sx,
      184 * sy,
    )
    ..lineTo(169.284 * sx, 184 * sy)
    ..cubicTo(
      163.98 * sx,
      184 * sy,
      158.893 * sx,
      186.107 * sy,
      155.143 * sx,
      189.857 * sy,
    )
    ..lineTo(146.857 * sx, 198.143 * sy)
    ..cubicTo(
      143.107 * sx,
      201.893 * sy,
      138.02 * sx,
      204 * sy,
      132.716 * sx,
      204 * sy,
    )
    ..lineTo(20 * sx, 204 * sy)
    ..cubicTo(8.954 * sx, 204 * sy, 0, 195.046 * sy, 0, 184 * sy)
    ..lineTo(0, 20 * sy)
    ..cubicTo(0, 8.954 * sy, 8.954 * sx, 0, 20 * sx, 0)
    ..lineTo(132.716 * sx, 0)
    ..close();
}

// ── OUTER CARD CLIPPER ──────────────────────────────────────────────────────────
class _TransferOuterClipper extends CustomClipper<Path> {
  const _TransferOuterClipper({
    required this.sx,
    required this.sy,
    this.offsetX = 0,
  });
  final double sx, sy, offsetX;

  @override
  Path getClip(Size size) {
    final base = _buildTransferCardOuterPath(sx, sy);
    if (offsetX == 0) return base;
    return base.shift(Offset(-offsetX, 0));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ── BORDER GLOW PAINTER ─────────────────────────────────────────────────────────
// Draws the same shimmer-border as wallet_overview_page _CardShapePainter,
// but on BOTH the top curve AND the bottom curve of the transfer card.
class _TransferBorderGlowPainter extends CustomPainter {
  const _TransferBorderGlowPainter({
    required this.sx,
    required this.sy,
    required this.cardW,
    required this.cardH,
    required this.circleCx,
    required this.circleCy,
    required this.circleR,
  });
  final double sx, sy, cardW, cardH;
  final double circleCx, circleCy, circleR;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildTransferCardOuterPath(sx, sy);
    final glowH = 26.0 * sy;

    // Notch x range from SVG coords (132.716 … 229.284)
    final notchLeft = 132.716 * sx;
    final notchRight = 229.284 * sx;

    // ── top glow — only inside the notch cut ────────────────────────────
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(notchLeft, 0, notchRight - notchLeft, glowH));
    _drawGlow(canvas, path);
    canvas.restore();

    // ── bottom glow — only inside the notch cut ─────────────────────────
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(notchLeft, cardH - glowH, notchRight - notchLeft, glowH),
    );
    _drawGlow(canvas, path);
    canvas.restore();

    // ── center vertical divider lines ───────────────────────────────────
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // top: from notch bottom edge down to circle top
    canvas.drawLine(
      Offset(cardW / 2, glowH),
      Offset(cardW / 2, circleCy - circleR),
      linePaint,
    );

    // bottom: from circle bottom down to notch top edge
    canvas.drawLine(
      Offset(cardW / 2, circleCy + circleR),
      Offset(cardW / 2, cardH - glowH),
      linePaint,
    );
  }

  void _drawGlow(Canvas canvas, Path path) {
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      const steps = 1000;
      for (int i = 0; i < steps; i++) {
        final t = i / steps;
        final dist = metric.length * t;
        final tangent = metric.getTangentForOffset(dist);
        if (tangent == null) continue;

        final x = tangent.position.dx;
        final distFromCenter = ((x - cardW / 2) / (cardW / 2)).abs();
        final opacity = (0.02 + (1.0 - distFromCenter) * 0.18).clamp(0.0, 1.0);
        final strokeW = 0.3 + (1.0 - distFromCenter) * 0.9;

        final start = t * metric.length;
        final end = ((t + 1 / steps) * metric.length).clamp(0.0, metric.length);

        canvas.drawPath(
          metric.extractPath(start, end),
          Paint()
            ..color = Colors.white.withOpacity(0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.square,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── CURRENCY SELECT BOTTOM SHEET ────────────────────────────────────────────────
class _CurrencySelectSheet extends StatelessWidget {
  const _CurrencySelectSheet({
    required this.currencies,
    required this.onSelect,
  });

  final List<Currency> currencies;
  final void Function(Currency) onSelect;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.75,
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Select Currency',
              style: TextStyle(
                color: _white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans,
                height: 1.4,
              ),
            ),
          ),

          // Coin list
          Expanded(
            child: currencies.isEmpty
                ? const Center(child: CircularProgressIndicator(color: _green))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: currencies.length,
                    itemBuilder: (_, i) {
                      final coin = currencies[i];
                      return InkWell(
                        onTap: () => onSelect(coin),
                        splashColor: _green.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              showImageNetwork(
                                imagePath: coin.coinIcon,
                                height: 36,
                                width: 36,
                                bgColor: Colors.transparent,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coin.coinType ?? '',
                                    style: const TextStyle(
                                      color: _white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: _dmSans,
                                      height: 24 / 16,
                                    ),
                                  ),
                                  Text(
                                    coin.name ?? '',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 12,
                                      fontFamily: _dmSans,
                                      fontWeight: FontWeight.w400,
                                      height: 16 / 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
