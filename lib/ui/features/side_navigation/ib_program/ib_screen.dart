import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/ib_program/ib_program_controller.dart';

// ─── Tier Model ───────────────────────────────────────────────────────────────
class _Tier {
  final String name;
  final int min;
  final int max;
  final int commission;
  final Color color;

  const _Tier({
    required this.name,
    required this.min,
    required this.max,
    required this.commission,
    required this.color,
  });
}

const _kTiers = [
  _Tier(name: "Starter", min: 0,   max: 9,      commission: 30, color: Color(0xFFFF6F00)),
  _Tier(name: "Pro",     min: 10,  max: 49,     commission: 40, color: Color(0xFF00E5FF)),
  _Tier(name: "Elite",   min: 50,  max: 199,    commission: 50, color: Color(0xFF0062FF)),
  _Tier(name: "VIP",     min: 200, max: 999999, commission: 60, color: Color(0xFFCCFF00)),
];

// ─── Painters ─────────────────────────────────────────────────────────────────
class _StatWavePainter extends CustomPainter {
  final List<Color> colors;
  const _StatWavePainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(20)),
      Paint()..color = const Color(0xFF1A1A1A),
    );
    final fractions = [0.55, 0.67, 0.78, 0.90];
    for (int i = 0; i < 4; i++) {
      final topY = size.height * fractions[i];
      final path = Path();
      path.moveTo(0, topY);
      path.cubicTo(
        size.width * 0.25, topY - size.height * 0.25,
        size.width * 0.55, topY + size.height * 0.12,
        size.width, topY - size.height * 0.06,
      );
      path.lineTo(size.width, size.height + 50);
      path.lineTo(0, size.height + 50);
      path.close();
      canvas.drawPath(
          path,
          Paint()
            ..color = colors[i]
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25));
    }
  }

  @override
  bool shouldRepaint(_StatWavePainter old) => old.colors != colors;
}

class _TierCardPainter extends CustomPainter {
  final Color color;
  const _TierCardPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.50, size.height * 0.85),
          width: size.width * 0.90,
          height: size.height * 0.90),
      Paint()
        ..color = color.withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  @override
  bool shouldRepaint(covariant _TierCardPainter old) => old.color != color;
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class IBScreen extends StatefulWidget {
  const IBScreen({super.key});

  @override
  State<IBScreen> createState() => _IBScreenState();
}

class _IBScreenState extends State<IBScreen> {
  final _ctrl = Get.put(IBController());
  DateTime? _startDate;
  DateTime? _endDate;

  static const _dmSans = 'DMSans';
  static const _green  = Color(0xFFCCFF00);
  static const _white  = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.getIBData());
  }

  // ── Tier helpers ──────────────────────────────────────────────────────────
  _Tier get _currentTier {
    final count = _ctrl.stats.value.totalReferrals ?? 0;
    return _kTiers.firstWhere(
      (t) => count >= t.min && count <= t.max,
      orElse: () => _kTiers.first,
    );
  }

  _Tier? get _nextTier {
    final count = _ctrl.stats.value.totalReferrals ?? 0;
    try {
      return _kTiers.firstWhere((t) => count < t.min);
    } catch (_) {
      return null;
    }
  }

  double get _progress {
    final count = _ctrl.stats.value.totalReferrals ?? 0;
    final cur   = _currentTier;
    final nxt   = _nextTier;
    if (nxt == null) return 100.0;
    return ((count - cur.min) / (nxt.min - cur.min) * 100).clamp(0.0, 100.0);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(() => Transform.translate(
                offset: const Offset(0, -30),
                child: _buildHeroSection(),
              )),
          Obx(() => Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsSection(),
                      const SizedBox(height: 40),
                      _buildPendingRewards(),
                      const SizedBox(height: 20),
                      _buildFlowSection(),
                      const SizedBox(height: 20),
                      _buildLevel1Section(),
                      const SizedBox(height: 20),
                      _buildLevel2Section(),
                      const SizedBox(height: 30),
                      _buildHistorySection(),
                      const SizedBox(height: 20),
                      _buildKeyRules(),
                      const SizedBox(height: 20),
                      _buildTermsSection(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HERO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        image: DecorationImage(
          image: AssetImage("assets/images/ib_screen.png"),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.only(top: 60, left: 10, right: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button
            Container(
              color: Colors.transparent,
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_outlined,
                    color: Colors.white, size: 25),
              ),
            ),
            const SizedBox(height: 200),
            const SizedBox(height: 20),

            // Title
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(children: [
                TextSpan(
                    text: "Introducing ",
                    style: TextStyle(
                        color: Colors.white, fontSize: 30, height: 40 / 30,
                        fontWeight: FontWeight.w700, fontFamily: "DMSans")),
                TextSpan(
                    text: "Broken ",
                    style: TextStyle(
                        color: Color(0xFFCCFF00), fontSize: 30, height: 40 / 30,
                        fontWeight: FontWeight.w700, fontFamily: "DMSans")),
                TextSpan(
                    text: "earn\n",
                    style: TextStyle(
                        color: Colors.white, fontSize: 30, height: 40 / 30,
                        fontWeight: FontWeight.w700, fontFamily: "DMSans")),
                TextSpan(
                    text: "up to ",
                    style: TextStyle(
                        color: Colors.white, fontSize: 30, height: 40 / 30,
                        fontWeight: FontWeight.w700, fontFamily: "DMSans")),
                TextSpan(
                    text: "60%",
                    style: TextStyle(
                        color: Color(0xFFCCFF00), fontSize: 30, height: 40 / 30,
                        fontWeight: FontWeight.w700, fontFamily: "DMSans")),
              ]),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(children: [
                  TextSpan(
                      text: "Introduce traders to Trapix and ",
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontFamily: "DMSans", fontWeight: FontWeight.w400)),
                  TextSpan(
                      text: "earn up to 60% ",
                      style: TextStyle(color: Color(0xFFCCFF00), fontSize: 12,
                          fontFamily: "DMSans", fontWeight: FontWeight.w400)),
                  TextSpan(
                      text: "of the\n",
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontFamily: "DMSans", fontWeight: FontWeight.w400)),
                  TextSpan(
                      text: "exchange's ",
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontFamily: "DMSans", fontWeight: FontWeight.w400)),
                  TextSpan(
                      text: "0.3% trading free ",
                      style: TextStyle(color: Color(0xFFCCFF00), fontSize: 12,
                          fontFamily: "DMSans", fontWeight: FontWeight.w400)),
                  TextSpan(
                      text: "forever, on every trade they make.",
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontFamily: "DMSans", fontWeight: FontWeight.w400)),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // Referral boxes + invite button
            Column(
              children: [
                _buildReferralBox(
                    value: _ctrl.stats.value.referralLink ?? '', isCode: false),
                _buildReferralBox(
                    value: _ctrl.stats.value.referralCode ?? '', isCode: true),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 20),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontFamily: "DMSans"),
                      children: [
                        TextSpan(
                            text: "Receive 30%–60%",
                            style: TextStyle(color: Color(0xFFCCFF00))),
                        TextSpan(
                            text: " commission on all trades from your IBs"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.fromLTRB(30, 0, 20, 20),
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E6FF), Color(0xFFCCFF00), Color(0xFF77D215)],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Invite Now",
                        style: TextStyle(
                            color: Color(0xFF111111),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: "DMSans")),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralBox({required String value, required bool isCode}) {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(30, 0, 20, 0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF111111)),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Text(
            isCode ? "referral code :" : "referral link :",
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12, fontFamily: "DMSans"),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontFamily: "DMSans")),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              Get.snackbar("Copied", "Copied Successfully",
                  backgroundColor: const Color(0xFFD7FF00),
                  colorText: Colors.black);
            },
            child: Container(
              padding: const EdgeInsets.only(right: 10),
              height: 25,
              width: 25,
              child: Image.asset("assets/icons/copy.png", fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS GRID
  // ══════════════════════════════════════════════════════════════════════════
  static const _statCardColors = [
    [Color(0xFFFF6F00), Color(0xFFFF8A30), Color(0xFFFFB781), Color(0xFFFFE6D2)],
    [Color(0xFF00E5FF), Color(0xFF37EBFF), Color(0xFF9AF5FF), Color(0xFFC9FAFF)],
    [Color(0xFF0062FF), Color(0xFF428AFF), Color(0xFF7EAFFF), Color(0xFFD8E7FF)],
    [Color(0xFFCCFF00), Color(0xFFD9FF41), Color(0xFFE8FF8C), Color(0xFFF3FFC2)],
  ];

  Widget _buildStatsSection() {
    return Obx(() {
      final s = _ctrl.stats.value;
      final cards = [
        ("Total IBs",    "${s.totalReferrals ?? 0}", ""),
        ("Total Earned", (s.totalEarned ?? 0).toStringAsFixed(2), "USDT"),
        ("Current Tier", s.tierName ?? "Starter", ""),
        ("Active IBs",   "${s.activeReferrals ?? 0}", ""),
      ];
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.45,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: List.generate(cards.length, (i) {
          final (title, value, suffix) = cards[i];
          return _buildGlowCard(title, value, suffix, _statCardColors[i]);
        }),
      );
    });
  }

  Widget _buildGlowCard(
      String title, String value, String suffix, List<Color> waveColors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: _StatWavePainter(colors: waveColors),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w600, fontFamily: _dmSans)),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _white, fontSize: 26,
                            fontWeight: FontWeight.w700,
                            fontFamily: _dmSans, height: 1)),
                  ),
                  if (suffix.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(suffix,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10, fontFamily: _dmSans)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PENDING REWARDS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPendingRewards() {
    return Obx(() {
      final balance     = _ctrl.stats.value.pendingBalance ?? 0;
      final withdrawing = _ctrl.isWithdrawing.value;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00391A), Color(0xFF0C2600), Color(0xFF081A00)],
            stops: [0.0, 0.5962, 0.9519],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Pending Rewards",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13, fontFamily: _dmSans)),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: balance.toStringAsFixed(8),
                      style: const TextStyle(
                          color: _white, fontSize: 26,
                          fontWeight: FontWeight.w700,
                          fontFamily: _dmSans, height: 1.2)),
                  TextSpan(
                      text: "  USDT",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.70),
                          fontSize: 13, fontFamily: _dmSans)),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Withdraw button ────────────────────────────────────────
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: withdrawing || balance <= 0
                      ? null
                      : () => _ctrl.withdrawToWallet(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: _green.withOpacity(0.4),
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: withdrawing
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.upload_rounded,
                          color: Colors.black, size: 20),
                  label: Text(
                    withdrawing ? "Withdrawing..." : "Withdraw to Reward Wallet",
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w700,
                        fontSize: 14, fontFamily: "DMSans"),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── View Wallet button ─────────────────────────────────────
              SizedBox(
                height: 50,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.white.withOpacity(0.25), width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.white.withOpacity(0.08),
                  ),
                  child: const Text("View Reward Wallet",
                      style: TextStyle(
                          color: _white, fontWeight: FontWeight.w700,
                          fontSize: 14, fontFamily: "DMSans")),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HOW IB REWARDS FLOW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFlowSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.transparent, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("How IB Rewards Flow",
              style: TextStyle(
                  color: _white, fontSize: 16, fontWeight: FontWeight.w700,
                  fontFamily: _dmSans, height: 1)),
          const SizedBox(height: 20),
          Row(
            children: [
              _flowCircle("A", const Color(0xFFFF6F00).withOpacity(0.5),
                  const Color(0xFFFF6F00)),
              _flowDots(),
              _flowCircle("B", const Color(0xFF00E5FF).withOpacity(0.5),
                  const Color(0xFF00E5FF)),
              _flowDots(),
              _flowCircle("C", const Color(0xFF0062FF).withOpacity(0.5),
                  const Color(0xFF0062FF)),
            ],
          ),
          const SizedBox(height: 40),
          _flowDescCard("A", const Color(0xFFFF6F00).withOpacity(0.5),
              const Color(0xFFFF6F00),
              "Receive 30–60% of the 0.3% trade fee from your Level 1 referrals (B) and 10% from Level 2 (C)"),
          const SizedBox(height: 10),
          _flowDescCard("B", const Color(0xFF00E5FF).withOpacity(0.5),
              const Color(0xFF00E5FF),
              "Receive 30–60% of the 0.3% trading fee from Level 1 (C) trades"),
          const SizedBox(height: 10),
          _flowDescCard("C", const Color(0xFF0062FF).withOpacity(0.5),
              const Color(0xFF0062FF),
              "Trading continues normally IB rewards come automatically from the 0.3% exchange fee"),
        ],
      ),
    );
  }

  Widget _flowCircle(String letter, Color color, Color borderColor) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: color,
          border: Border.all(color: borderColor, width: 2)),
      child: Center(
          child: Text(letter,
              style: const TextStyle(
                  color: _white, fontWeight: FontWeight.w400,
                  fontSize: 16, fontFamily: _dmSans, height: 1))),
    );
  }

  Widget _flowDots() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Transform.translate(
                offset: const Offset(10, 0),
                child: Row(
                  children: List.generate(
                      7,
                      (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 4, height: 2,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2)),
                          )),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(-3, 0),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flowDescCard(
      String letter, Color color, Color borderColor, String desc) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.transparent)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color,
                border: Border.all(color: borderColor, width: 2)),
            child: Center(
                child: Text(letter,
                    style: const TextStyle(
                        color: _white, fontWeight: FontWeight.w800,
                        fontSize: 13, fontFamily: _dmSans))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(desc,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12, fontWeight: FontWeight.w400,
                    fontFamily: _dmSans, height: 1.2)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LEVEL 1
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLevel1Section() {
    final count = _ctrl.stats.value.totalReferrals ?? 0;
    final cur   = _currentTier;
    final nxt   = _nextTier;
    final prog  = _progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("LEVEL 1 — DIRECT IBS",
            style: TextStyle(
                color: Color(0XFFCCFF00), fontSize: 16,
                fontWeight: FontWeight.w700, fontFamily: _dmSans, height: 1)),
        const SizedBox(height: 10),
        const Text("Commission scales with your network\nsize",
            style: TextStyle(
                color: _white, fontSize: 16, fontFamily: _dmSans,
                fontWeight: FontWeight.w700, height: 1.4)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0XFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.transparent, width: 2)),
          child: Column(
            children: [
              // Pills row
              Row(
                children: [
                  _pill("$count Direct IB${count == 1 ? '' : 's'}",
                      const Color(0XFFCCFF00).withOpacity(0.3),
                      const Color(0XFFCCFF00)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0XFF111111),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.transparent, width: 2)),
                    child: Row(children: [
                      const Text("Current Tier : ",
                          style: TextStyle(
                              color: Colors.white, fontSize: 12,
                              fontFamily: _dmSans,
                              fontWeight: FontWeight.w400, height: 1)),
                      Text(cur.name,
                          style: const TextStyle(
                              color: Color(0XFFCCFF00), fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: _dmSans, height: 1)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Next tier
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0XFF111111),
                      borderRadius: BorderRadius.circular(10)),
                  child: RichText(
                    text: TextSpan(children: [
                      const TextSpan(
                          text: "Next : ",
                          style: TextStyle(
                              color: Colors.white, fontSize: 12,
                              fontFamily: _dmSans,
                              fontWeight: FontWeight.w400, height: 1)),
                      TextSpan(
                          text: nxt != null
                              ? "${nxt.name} @ ${nxt.min} IBs"
                              : "VIP Maxed",
                          style: const TextStyle(
                              color: Color(0XFF00E5FF), fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: _dmSans, height: 1)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Progress bar
              Column(children: [
                Row(children: [
                  const Text("Level 1 Progress",
                      style: TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans, height: 1)),
                  const Spacer(),
                  Text("${prog.toInt()}%",
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans, height: 1)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1), width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(children: [
                          Container(color: Colors.white.withOpacity(0.5)),
                          FractionallySizedBox(
                            widthFactor: prog / 100,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFF00E6FF),
                                    Color(0xFFCCFF00),
                                    Color(0xFF77D215),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("${count}/${nxt?.min ?? count} IBs",
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans, height: 1)),
                ]),
              ]),
              const SizedBox(height: 15),

              // Tier cards
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 20,
                mainAxisSpacing: 10,
                children:
                    _kTiers.map((tier) => _buildTierCard(tier)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 12,
              fontWeight: FontWeight.w700, fontFamily: _dmSans)),
    );
  }

  Widget _buildTierCard(_Tier tier) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tier.color.withOpacity(0.6),
            Colors.transparent,
            tier.color.withOpacity(0.4),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(15)),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                  child: CustomPaint(
                      painter: _TierCardPainter(color: tier.color))),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(tier.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontFamily: _dmSans, fontWeight: FontWeight.w400)),
                  const SizedBox(height: 5),
                  Text("${tier.commission}%",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0XFFCCFF00), fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: _dmSans, height: 1)),
                  const SizedBox(height: 5),
                  const Text("of 0.3% fee",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w300,
                          fontFamily: _dmSans, height: 1)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LEVEL 2
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLevel2Section() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("LEVEL 2 — INDIRECT IBS",
            style: TextStyle(
                color: Color(0XFFCCFF00), fontSize: 16,
                fontWeight: FontWeight.w700, fontFamily: _dmSans, height: 1)),
        const SizedBox(height: 10),
        const Text("Fixed for all tiers",
            style: TextStyle(
                color: _white, fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans, height: 1)),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: const Color(0xFF1AFF00).withOpacity(0.15), width: 1),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF00FF04).withOpacity(0.95),
                        const Color(0xFF00FF04).withOpacity(0.45),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Flat Commission",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: _dmSans, height: 1)),
                          const SizedBox(height: 10),
                          const Text("When your IB brings someone",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12,
                                  fontFamily: _dmSans,
                                  fontWeight: FontWeight.w400, height: 1)),
                        ],
                      ),
                    ),
                    const Text("30%",
                        style: TextStyle(
                            color: Color(0xFFCCFF00), fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: _dmSans, height: 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // IB HISTORY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("IB History",
                style: TextStyle(
                    color: _white, fontSize: 16,
                    fontWeight: FontWeight.w700, fontFamily: _dmSans)),
            const Spacer(),
            _buildDateBox(
                text: _startDate == null
                    ? "Start Date"
                    : _fmtDate(_startDate!),
                onTap: () => _pickDate(true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text("—",
                  style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            _buildDateBox(
                text: _endDate == null ? "End Date" : _fmtDate(_endDate!),
                onTap: () => _pickDate(false)),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          final all = _ctrl.networkMembers;
          final members = all.where((m) {
            if (_startDate == null && _endDate == null) return true;
            final raw = m['joined_at'] as String?;
            if (raw == null || raw.isEmpty) return true;
            final d = DateTime.tryParse(raw);
            if (d == null) return true;
            if (_startDate != null && d.isBefore(_startDate!)) return false;
            if (_endDate != null &&
                d.isAfter(_endDate!.add(const Duration(days: 1)))) {
              return false;
            }
            return true;
          }).toList();

          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text("No IB history yet",
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13, fontFamily: _dmSans)),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _tableCell("No.", 36, isHeader: true),
                    _tableCell("Referral", 110, isHeader: true),
                    _tableCell("Joined", 110, isHeader: true),
                    _tableCell("Trading Volume", 140, isHeader: true),
                    _tableCell("You Earned", 155, isHeader: true),
                  ]),
                  Divider(
                      color: Colors.white.withOpacity(0.08), height: 20),
                  ...List.generate(members.length, (i) {
                    final m = members[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(children: [
                        _tableCell("${i + 1}", 36),
                        _tableCell(m['name'] ?? '', 110),
                        _tableCell(m['joined_at'] ?? '', 110),
                        SizedBox(
                          width: 140,
                          child: Text(
                            "\$${(m['trade_volume'] ?? 0).toStringAsFixed(2)} USDT",
                            style: const TextStyle(
                                color: Color(0xFF00E5FF), fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: _dmSans),
                          ),
                        ),
                        SizedBox(
                          width: 155,
                          child: Text(
                            "+${(m['you_earned'] ?? 0).toStringAsFixed(5)} USDT",
                            style: const TextStyle(
                                color: _green, fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: _dmSans),
                          ),
                        ),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _tableCell(String text, double width, {bool isHeader = false}) {
    return SizedBox(
      width: width,
      child: Text(text,
          style: TextStyle(
              color: isHeader ? Colors.white.withOpacity(0.45) : _white,
              fontSize: isHeader ? 11 : 13,
              fontWeight:
                  isHeader ? FontWeight.w500 : FontWeight.w400,
              fontFamily: _dmSans)),
    );
  }

  Widget _buildDateBox(
      {required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Text(text,
              style: const TextStyle(
                  color: _white, fontSize: 10, fontFamily: _dmSans)),
          const SizedBox(width: 5),
          const Icon(Icons.calendar_today_rounded, size: 13, color: _green),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // KEY RULES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildKeyRules() {
    final rules = [
      "All IB rewards come from Trapix's 0.3% exchange fee only",
      "Max 2 levels deep — no further chain",
      "Level 1 commission upgrades automatically as your network grows",
      "Withdraw IB rewards anytime to your IB Rewards Wallet",
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.transparent)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Key Rules",
              style: TextStyle(
                  color: _white, fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: _dmSans, height: 1)),
          const SizedBox(height: 20),
          ...rules.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("→ ",
                        style: TextStyle(
                            color: Color(0XFFCCFF00), fontSize: 12,
                            fontWeight: FontWeight.w400, height: 1)),
                    Expanded(
                        child: Text(r,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12,
                                fontFamily: _dmSans,
                                height: 1.3,
                                fontWeight: FontWeight.w400))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TERMS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTermsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: Colors.transparent)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("IB Program — Terms & Conditions",
              style: TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: _dmSans, height: 1)),
          const SizedBox(height: 10),
          Text(
            "Last updated: June 2025 · Please read carefully before participating",
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12, fontFamily: _dmSans,
                fontWeight: FontWeight.w400, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Date helpers ──────────────────────────────────────────────────────────
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(
          () => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  String _fmtDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.year}";
}