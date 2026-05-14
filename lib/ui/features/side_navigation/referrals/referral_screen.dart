import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// ─── Wave Glow Painter (Stats Cards) ────────────────────────────────────────
class _WaveGlowPainter extends CustomPainter {
  final List<BoxShadow> glowLayers;
  const _WaveGlowPainter({required this.glowLayers});

  @override
  void paint(Canvas canvas, Size size) {
    final layerTopFractions = [0.55, 0.66, 0.76, 0.87];

    for (int i = 0; i < 4; i++) {
      final topY = size.height * layerTopFractions[i];
      final shadow = glowLayers[i];

      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

      final path = Path();
      path.moveTo(0, topY);

      final cp1x = size.width * 0.25;
      final cp1y = topY - size.height * 0.18;
      final mp1x = size.width * 0.40;
      final mp1y = topY + size.height * 0.08;
      final mp2x = size.width * 0.72;
      final mp2y = topY - size.height * 0.10;
      final cp3x = size.width * 0.88;
      final cp3y = topY - size.height * 0.22;

      path.cubicTo(cp1x, cp1y, mp1x - 10, mp1y - 5, mp1x, mp1y);
      path.cubicTo(mp1x + 20, mp1y + 5, mp2x - 20, mp2y + 5, mp2x, mp2y);
      path.cubicTo(cp3x - 10, cp3y, cp3x + 15, cp3y + 5, size.width, topY + 5);

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveGlowPainter old) => old.glowLayers != glowLayers;
}

// ─── Pending Rewards Painter ─────────────────────────────────────────────────
// Exact match to image 2:
//   Left  ~40% = very dark maroon  #0D0010 → #600050
//   Right ~60% = bright magenta/pink  #931A7E → #DF74CD → #FFC8F6
//
// Technique: draw blurred ovals from darkest (back) to lightest (front).
// An S-curve overlay darkens the left zone to match image exactly.
// ─────────────────────────────────────────────────────────────────────────────
// ─── Pending Rewards Painter ───────────────────────────────────────────────
class _PendingRewardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF0D0010),
    );

    // ── 1. Deep maroon blob — RIGHT TOP ─────────────────────
    // ── 1. Deep maroon blob — LEFT BOTTOM ───────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.18, h * 0.78),
        width: w * 0.60,
        height: h * 1.50,
      ),
      Paint()
        ..color = const Color(0xFF111111)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0),
    );

    // ── 2. Deep magenta — middle sweep ──────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.42, h * 0.42),
        width: w * 0.72,
        height: h * 1.30,
      ),
      Paint()
        ..color = const Color(0xFF600050)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );

    // ── 3. Bright magenta — lower RIGHT ─────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.66),
        width: w * 0.68,
        height: h * 1.10,
      ),
      Paint()
        ..color = const Color(0xFFFFC8F6).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );

    // ── 4. Light pink — BOTTOM RIGHT ────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.88, h * 0.84),
        width: w * 0.48,
        height: h * 0.72,
      ),
      Paint()
        ..color = const Color(0xFFFFC8F6).withOpacity(0.80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );

    // ── 5. Dark curve overlay from RIGHT → LEFT ───────────────
    final curvePath = Path();

    curvePath.moveTo(0, 0);
    curvePath.lineTo(w * 0.38, 0);

    curvePath.cubicTo(w * 0.26, h * 0.14, w * 0.14, h * 0.55, w * 0.06, h);

    curvePath.lineTo(0, h);
    curvePath.close();

    canvas.drawPath(
      curvePath,
      Paint()
        ..color = const Color(0xFF0D0010).withOpacity(0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Main Screen ─────────────────────────────────────────────────────────────
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  int _totalReferrals = 1;
  double _totalEarned = 0.00;
  double _pendingBalance = 0.00000000;
  int _activeReferrals = 0;

  String _referralLink = "https://trapix.com/signup?ref_code";
  String _referralCode = "TRX-5Q905R";

  final List<Map<String, dynamic>> _members = [
    {
      'name': 'Yug Patel',
      'joined_at': '26-04-2026',
      'trade_volume': 0.00,
      'you_earned': 0.00000,
    },
    {
      'name': 'Yug Patel',
      'joined_at': '26-04-2026',
      'trade_volume': 0.00,
      'you_earned': 0.00000,
    },
    {
      'name': 'Yug Patel',
      'joined_at': '26-04-2026',
      'trade_volume': 0.00,
      'you_earned': 0.00000,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeroSection(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHowItWorksSection(),
                const SizedBox(height: 40),
                _buildStatsSection(),
                const SizedBox(height: 40),
                _buildPendingRewards(),
                const SizedBox(height: 20),
                _buildHistorySection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        image: DecorationImage(
          image: AssetImage("assets/images/referral_screen.png"),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.05),
              Colors.black.withValues(alpha: 0.92),
            ],
            stops: const [0.3, 0.72],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.transparent,
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(
                  Icons.arrow_back_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
            const SizedBox(height: 200),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: "Refer Friends.\nEarn ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 40 / 30,
                      fontWeight: FontWeight.w700,
                      fontFamily: "DMSans",
                    ),
                  ),
                  TextSpan(
                    text: "20%",
                    style: TextStyle(
                      color: Color(0xFFD7FF00),
                      fontSize: 30,
                      height: 40 / 30,
                      fontWeight: FontWeight.w700,
                      fontFamily: "DMSans",
                    ),
                  ),
                  TextSpan(
                    text: " Forever.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 40 / 30,
                      fontWeight: FontWeight.w700,
                      fontFamily: "DMSans",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Invite anyone to Trapix. Every time they trade, you earn 20% of the 0.3% exchange fee — automatically, for life.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
            _buildReferralBox(value: _referralLink, isCode: false),
            _buildReferralBox(value: _referralCode, isCode: true),
            const SizedBox(height: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: "DMSans",
                ),
                children: [
                  TextSpan(
                    text: "Receive 20%",
                    style: TextStyle(color: Color(0xFFCCFF00)),
                  ),
                  TextSpan(
                    text: " commission on all trades made through your referrals",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00E6FF),
                    Color(0xFFCCFF00),
                    Color(0xFF77D215),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Invite Now",
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    fontFamily: "DMSans",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralBox({required String value, required bool isCode}) {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF111111),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Text(
            isCode ? "referral code :" : "referral link :",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontFamily: "DMSans",
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: "DMSans",
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              Get.snackbar(
                "Copied",
                "Copied Successfully",
                backgroundColor: const Color(0xFFD7FF00),
                colorText: Colors.black,
              );
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

  Widget _buildHowItWorksSection() {
    final data = [
      {"image": "assets/icons/referral1.png", "title": "Share links"},
      {
        "image": "assets/icons/referral2.png",
        "title": "Invitation\naccepted by\nfriends",
      },
      {
        "image": "assets/icons/referral3.png",
        "title": "Unlock your\nearning\npotential",
      },
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF1A1A1A),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(data.length, (index) {
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          data[index]['image']!,
                          height: 60,
                          width: 60,
                        ),
                      ),
                    ),
                    if (index != data.length - 1)
                      const Text(
                        "---->",
                        style: TextStyle(
                          color: Color(0xFFCCFF00),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(data.length, (index) {
              return Expanded(
                child: Text(
                  data[index]['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: "DMSans",
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.45,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      children: [
        _buildGlowCard(
          title: "Total Referral",
          value: "$_totalReferrals",
          boxShadow: const [
            BoxShadow(color: Color(0xFFFF6F00), blurRadius: 26.3),
            BoxShadow(color: Color(0xFFFF8A30), blurRadius: 26.3),
            BoxShadow(color: Color(0xFFFFB781), blurRadius: 26.3),
            BoxShadow(color: Color(0xFFFFE6D2), blurRadius: 26.3),
          ],
        ),
        _buildGlowCard(
          title: "Total Earned",
          value: _totalEarned.toStringAsFixed(2),
          suffix: "USDT",
          boxShadow: const [
            BoxShadow(color: Color(0xFF00E5FF), blurRadius: 26.3),
            BoxShadow(color: Color(0xFF37EBFF), blurRadius: 26.3),
            BoxShadow(color: Color(0xFF9AF5FF), blurRadius: 26.3),
            BoxShadow(color: Color(0xFFC9FAFF), blurRadius: 26.3),
          ],
        ),
        _buildGlowCard(
          title: "Commission",
          value: "20%",
          boxShadow: const [
            BoxShadow(color: Color(0xFF0062FF), blurRadius: 26.3),
            BoxShadow(color: Color(0xFF428AFF), blurRadius: 26.3),
            BoxShadow(color: Color(0xFF7EAFFF), blurRadius: 26.3),
            BoxShadow(color: Color(0xFFD8E7FF), blurRadius: 26.3),
          ],
        ),
        _buildGlowCard(
          title: "Active Referrals",
          value: "$_activeReferrals",
          boxShadow: const [
            BoxShadow(color: Color(0xFFCCFF00), blurRadius: 26.3),
            BoxShadow(color: Color(0xFFD9FF41), blurRadius: 26.3),
            BoxShadow(color: Color(0xFFE8FF8C), blurRadius: 26.3),
            BoxShadow(color: Color(0xFFF3FFC2), blurRadius: 26.3),
          ],
        ),
      ],
    );
  }

  Widget _buildGlowCard({
    required String title,
    required String value,
    required List<BoxShadow> boxShadow,
    String suffix = "",
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF1A1A1A),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WaveGlowPainter(glowLayers: boxShadow),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 0, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: "DMSans",
                    height: 1,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        fontFamily: "DMSans",
                        height: 1,
                      ),
                    ),
                    if (suffix.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          suffix,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PENDING REWARDS ───────────────────────────────────────────────────────
  Widget _buildPendingRewards() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF1A1A1A),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _PendingRewardWavePainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 5),

                Text(
                  "Pending Rewards",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _pendingBalance.toStringAsFixed(8),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: "  USDT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCCFF00),
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Image.asset(
                      "assets/icons/withdraw.png",
                      height: 20,
                      width: 20,
                      fit: BoxFit.contain,
                    ),
                    label: const Text(
                      "Withdraw to Reward Wallet",
                      style: TextStyle(
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1,
                        fontFamily: "DMSans",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.2),
                    ),
                    child: const Text(
                      "View Reward Wallet",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        fontFamily: "DMSans",
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Referral History",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: "DMSans",
                height: 1,
              ),
            ),
            const Spacer(),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildDateBox(
                    text: _startDate == null
                        ? "Start Date"
                        : _formatDate(_startDate!),
                    onTap: () => _selectDate(true),
                  ),
                  const SizedBox(width: 5),
                  const Text("—", style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 5),
                  _buildDateBox(
                    text: _endDate == null
                        ? "End Date"
                        : _formatDate(_endDate!),
                    onTap: () => _selectDate(false),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ✅ Yahan horizontal scroll wrap kiya
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        "No.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        "Referral",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(
                        "Joined",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        "Trading Volume",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        "You Earned (20%)",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Data rows
                Column(
                  children: List.generate(_members.length, (index) {
                    final item = _members[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: "DMSans",
                                height: 1,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              item['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: "DMSans",
                                height: 1,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Text(
                              item['joined_at'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: "DMSans",
                                height: 1,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: Text(
                              "\$${item['trade_volume'].toStringAsFixed(2)} USDT",
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: "DMSans",
                                height: 1,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Text(
                              "+${item['you_earned'].toStringAsFixed(5)} USDT",
                              style: const TextStyle(
                                color: Color(0xFFCCFF00),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: "DMSans",
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateBox({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: "DMSans",
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.calendar_month, size: 14, color: Color(0xFFCCFF00)),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startDate = picked;
        else
          _endDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
