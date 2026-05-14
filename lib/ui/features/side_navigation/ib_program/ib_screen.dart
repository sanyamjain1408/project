import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// ─── Controller ──────────────────────────────────────────────────────────────
class IBController extends GetxController {
  var stats = IBStats().obs;
  var networkMembers = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    getIBData();
  }

  void getIBData() {
    stats.value = IBStats(
      referralLink: "https://trapix.com/signup?ib_code=TRX-5Q905R",
      referralCode: "TRX-5Q905R",
      totalReferrals: 7,
      totalEarned: 6.70,
      tierName: "Starter",
      activeReferrals: 3,
      pendingBalance: 0.0,
    );

    networkMembers.value = [
      {
        'name': 'tyty',
        'email': 'tyt***',
        'joined_at': '2026-04-02',
        'trade_volume': 4960.07,
        'you_earned': 4.464067,
      },
      {
        'name': 'ghghg ghghg',
        'email': 'ghg***',
        'joined_at': '2026-04-10',
        'trade_volume': 2480.04,
        'you_earned': 2.232034,
      },
      {
        'name': 'nmmn nmnm',
        'email': 'nmn***',
        'joined_at': '2026-04-10',
        'trade_volume': 0,
        'you_earned': 0,
      },
      {
        'name': 'Test User',
        'email': 'test***',
        'joined_at': '2026-04-13',
        'trade_volume': 0,
        'you_earned': 0,
      },
    ];
  }
}

class IBStats {
  String? referralLink;
  String? referralCode;
  int? totalReferrals;
  double? totalEarned;
  String? tierName;
  int? activeReferrals;
  double? pendingBalance;

  IBStats({
    this.referralLink,
    this.referralCode,
    this.totalReferrals,
    this.totalEarned,
    this.tierName,
    this.activeReferrals,
    this.pendingBalance,
  });
}

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
  _Tier(
    name: "Starter",
    min: 0,
    max: 9,
    commission: 30,
    color: Color(0xFFFF6F00),
  ),
  _Tier(
    name: "Pro",
    min: 10,
    max: 49,
    commission: 40,
    color: Color(0xFF00E5FF),
  ),
  _Tier(
    name: "Elite",
    min: 50,
    max: 199,
    commission: 50,
    color: Color(0xFF0062FF),
  ),
  _Tier(
    name: "VIP",
    min: 200,
    max: 999999,
    commission: 60,
    color: Color(0xFFCCFF00),
  ),
];

// ─── Shared Painters (same as referral_screen) ────────────────────────────────
class _WaveGlowPainter extends CustomPainter {
  final List<BoxShadow> glowLayers;
  const _WaveGlowPainter({required this.glowLayers});

  @override
  void paint(Canvas canvas, Size size) {
    final fractions = [0.55, 0.66, 0.76, 0.87];
    for (int i = 0; i < 4; i++) {
      final topY = size.height * fractions[i];
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

class _PendingRewardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF0D0010),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.08, h * 0.72),
        width: w * 0.60,
        height: h * 1.50,
      ),
      Paint()
        ..color = const Color(0xFF600050)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.32, h * 0.50),
        width: w * 0.62,
        height: h * 1.30,
      ),
      Paint()
        ..color = const Color(0xFF931A7E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.42),
        width: w * 0.68,
        height: h * 1.10,
      ),
      Paint()
        ..color = const Color(0xFFDF74CD).withOpacity(0.92)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.88, h * 0.22),
        width: w * 0.48,
        height: h * 0.72,
      ),
      Paint()
        ..color = const Color(0xFFFFC8F6).withOpacity(0.80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    final curvePath = Path();
    curvePath.moveTo(0, 0);
    curvePath.lineTo(w * 0.38, 0);
    curvePath.cubicTo(w * 0.26, h * 0.12, w * 0.16, h * 0.52, w * 0.07, h);
    curvePath.lineTo(0, h);
    curvePath.close();
    canvas.drawPath(
      curvePath,
      Paint()
        ..color = const Color(0xFF0D0010).withOpacity(0.68)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  @override
  bool shouldRepaint(_PendingRewardWavePainter old) => false;
}

// ─── Tier Card Painter (each tier card has its own color glow) ───────────────
class _TierCardPainter extends CustomPainter {
  final Color color;
  const _TierCardPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // Glow blob center-bottom
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.85),
        width: size.width * 0.90,
        height: size.height * 0.90,
      ),
      Paint()
        ..color = color.withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  @override
  bool shouldRepaint(covariant _TierCardPainter old) => old.color != color;
}

// ─── Level 2 Green Card Painter ───────────────────────────────────────────────
class _GreenCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A1A0A),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.80),
        width: size.width * 0.95,
        height: size.height * 1.0,
      ),
      Paint()
        ..color = const Color(0xFF00FF66).withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class IBScreen extends StatefulWidget {
  const IBScreen({super.key});

  @override
  State<IBScreen> createState() => _IBScreenState();
}

class _IBScreenState extends State<IBScreen> {
  final _ctrl = Get.put(IBController());
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showTerms = false;

  String _referralLink = "https://trapix.com/signup?ref_code";
  String _referralCode = "TRX-5Q905R";

  static const _dmSans = 'DMSans';
  static const _green = Color(0xFFCCFF00);
  static const _white = Colors.white;

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
    final cur = _currentTier;
    final nxt = _nextTier;
    if (nxt == null) return 100.0;
    return ((count - cur.min) / (nxt.min - cur.min) * 100).clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: Color(0xFF111111),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeroSection(),
          Padding(
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
        ],
      ),
    );
  }

  // ── HERO ──────────────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Transform.translate(
      offset: Offset(0, -20),
      child: Container(
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
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Introducing ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 40 / 30,
                        fontWeight: FontWeight.w700,
                        fontFamily: "DMSans",
                      ),
                    ),
      
                    TextSpan(
                      text: "Broken ",
                      style: TextStyle(
                        color: Color(0xFFCCFF00),
                        fontSize: 30,
                        height: 40 / 30,
                        fontWeight: FontWeight.w700,
                        fontFamily: "DMSans",
                      ),
                    ),
      
                    TextSpan(
                      text: "earn\n",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 40 / 30,
                        fontWeight: FontWeight.w700,
                        fontFamily: "DMSans",
                      ),
                    ),
      
                    TextSpan(
                      text: "up to ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 40 / 30,
                        fontWeight: FontWeight.w700,
                        fontFamily: "DMSans",
                      ),
                    ),
      
                    TextSpan(
                      text: "60%",
                      style: TextStyle(
                        color: Color(0xFFCCFF00),
                        fontSize: 30,
                        height: 40 / 30,
                        fontWeight: FontWeight.w700,
                        fontFamily: "DMSans",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
      
             
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Introduce traders to Trapix and ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),
      
                      TextSpan(
                        text: "earn up to 60% ",
                        style: TextStyle(
                          color: Color(0xFFCCFF00),
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),
      
                      TextSpan(
                        text: "of the\n",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),
      
                      TextSpan(
                        text: "exchange's ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),
      
                      TextSpan(
                        text: "0.3% trading free ",
                        style: TextStyle(
                          color: Color(0xFFCCFF00),
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),
      
                      TextSpan(
                        text: "forever, on every trade they make.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      
              const SizedBox(height: 40),
              Column(
                children: [
                  _buildReferralBox(value: _referralLink, isCode: false),
                  _buildReferralBox(value: _referralCode, isCode: true),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: RichText(
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
                            text:
                                " commission on all trades made through your referrals",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.fromLTRB(10, 0, 0, 20),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralBox({required String value, required bool isCode}) {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(10, 10, 0, 0),
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

  // ── STATS (same glow cards as referral) ──────────────────────────────────
  Widget _buildStatsSection() {
    return Obx(() {
      final s = _ctrl.stats.value;
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.45,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildGlowCard(
            "Total Referral",
            "${s.totalReferrals ?? 0}",
            "",
            const [
              BoxShadow(color: Color(0xFFFF6F00), blurRadius: 26.3),
              BoxShadow(color: Color(0xFFFF8A30), blurRadius: 26.3),
              BoxShadow(color: Color(0xFFFFB781), blurRadius: 26.3),
              BoxShadow(color: Color(0xFFFFE6D2), blurRadius: 26.3),
            ],
          ),
          _buildGlowCard(
            "Total Earned",
            (s.totalEarned ?? 0).toStringAsFixed(2),
            "USDT",
            const [
              BoxShadow(color: Color(0xFF00E5FF), blurRadius: 26.3),
              BoxShadow(color: Color(0xFF37EBFF), blurRadius: 26.3),
              BoxShadow(color: Color(0xFF9AF5FF), blurRadius: 26.3),
              BoxShadow(color: Color(0xFFC9FAFF), blurRadius: 26.3),
            ],
          ),
          _buildGlowCard("Commission", "20%", "", const [
            BoxShadow(color: Color(0xFF0062FF), blurRadius: 26.3),
            BoxShadow(color: Color(0xFF428AFF), blurRadius: 26.3),
            BoxShadow(color: Color(0xFF7EAFFF), blurRadius: 26.3),
            BoxShadow(color: Color(0xFFD8E7FF), blurRadius: 26.3),
          ]),
          _buildGlowCard(
            "Active Referrals",
            "${s.activeReferrals ?? 0}",
            "",
            const [
              BoxShadow(color: Color(0xFFCCFF00), blurRadius: 26.3),
              BoxShadow(color: Color(0xFFD9FF41), blurRadius: 26.3),
              BoxShadow(color: Color(0xFFE8FF8C), blurRadius: 26.3),
              BoxShadow(color: Color(0xFFF3FFC2), blurRadius: 26.3),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildGlowCard(
    String title,
    String value,
    String suffix,
    List<BoxShadow> shadows,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1A1A1A),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _WaveGlowPainter(glowLayers: shadows)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: _dmSans,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans,
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
                            fontFamily: _dmSans,
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

  // ── PENDING REWARDS (same painter as referral) ────────────────────────────
  Widget _buildPendingRewards() {
    return Obx(() {
      final balance = _ctrl.stats.value.pendingBalance ?? 0;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0D0010),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PendingRewardWavePainter()),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Pending Rewards",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      fontFamily: _dmSans,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: balance.toStringAsFixed(8),
                          style: const TextStyle(
                            color: _white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            fontFamily: _dmSans,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: "  USDT",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.70),
                            fontSize: 13,
                            fontFamily: _dmSans,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.upload_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      label: const Text(
                        "Withdraw to Reward Wallet",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: _dmSans,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.08),
                      ),
                      child: const Text(
                        "View Reward Wallet",
                        style: TextStyle(
                          color: _white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: _dmSans,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── HOW IB REWARDS FLOW ───────────────────────────────────────────────────
  Widget _buildFlowSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.transparent, // border color
          width: 2, // border width
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How IB Rewards Flow",
            style: TextStyle(
              color: _white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: _dmSans,
              height: 1,
            ),
          ),
          const SizedBox(height: 20),

          // A → B → C flow diagram
          Row(
            children: [
              _flowCircle(
                "A",
                Color(0xFFFF6F00).withOpacity(0.5),
                Color(0xFFFF6F00),
              ),
              _flowDots(),
              _flowCircle(
                "B",
                Color(0xFF00E5FF).withOpacity(0.5),
                Color(0xFF00E5FF),
              ),
              _flowDots(),
              _flowCircle(
                "C",
                Color(0xFF0062FF).withOpacity(0.5),
                Color(0xFF0062FF),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Description cards
          _flowDescCard(
            "A",
            Color(0xFFFF6F00).withOpacity(0.5),
            Color(0xFFFF6F00),
            "Receive 30–60% of the 0.3% trade fee from your Level 1 referrals (B) and 10% from Level 2 (C)",
          ),
          const SizedBox(height: 10),
          _flowDescCard(
            "B",
            Color(0xFF00E5FF).withOpacity(0.5),
            Color(0xFF00E5FF),
            "Receive 30–60% of the 0.3% trading fee from Level 1 (C) trades",
          ),
          SizedBox(height: 10),
          _flowDescCard(
            "C",
            Color(0xFF0062FF).withOpacity(0.5),
            Color(0xFF0062FF),
            "Trading continues normally IB rewards come automatically from the 0.3% exchange fee",
          ),
        ],
      ),
    );
  }

  Widget _flowCircle(String letter, Color color, Color bordercolor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: bordercolor, // border color
          width: 2, // border thickness
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: _white,
            fontWeight: FontWeight.w400,
            fontSize: 16,
            fontFamily: _dmSans,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _flowDots() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // dashed line
            Expanded(
              child: Transform.translate(
                offset: const Offset(10, 0),
                child: Row(
                  children: List.generate(
                    7,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 4,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // arrow
            Transform.translate(
              offset: const Offset(-3, 0),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flowDescCard(
    String letter,
    Color color,
    Color bordercolor,
    String desc,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: bordercolor, // border color
                width: 2, // border thickness
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  fontFamily: _dmSans,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: _dmSans,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── KEY RULES ─────────────────────────────────────────────────────────────
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
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Key Rules",
            style: TextStyle(
              color: _white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: _dmSans,
              height: 1,
            ),
          ),
          const SizedBox(height: 20),
          ...rules.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "→ ",
                    style: TextStyle(
                      color: Color(0XFFCCFF00),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: _dmSans,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LEVEL 1 ───────────────────────────────────────────────────────────────
  Widget _buildLevel1Section() {
    final count = _ctrl.stats.value.totalReferrals ?? 0;
    final cur = _currentTier;
    final nxt = _nextTier;
    final prog = _progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          "LEVEL 1 — DIRECT IBS",
          style: TextStyle(
            color: Color(0XFFCCFF00),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: _dmSans,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "Commission scales with your network size",
          style: TextStyle(
            color: _white,
            fontSize: 16,
            fontFamily: _dmSans,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0XFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.transparent, // border color
              width: 2, // border width
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _pill(
                    "$count Direct IB${count == 1 ? '' : 's'}",
                    Color(0XFFCCFF00).withOpacity(0.3),
                    Color(0XFFCCFF00),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0XFF111111),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.transparent, // border color
                        width: 2, // border width
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Current Tier : ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: _dmSans,
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                        Text(
                          cur.name,
                          style: TextStyle(
                            color: Color(0XFFCCFF00),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: _dmSans,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0XFF111111), // background color
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: "Next : ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: _dmSans,
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: "${nxt?.name} @ ${nxt?.min} IBs",
                          style: TextStyle(
                            color: Color(0XFF00E5FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: _dmSans,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Progress bar
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        "Level 1 Progress",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                          height: 1,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        "${prog.toInt()}%",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                          height: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 10,

                          // outer border
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1), // #FFFFFF80
                              width: 1,
                            ),
                          ),

                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                // empty background
                                Container(color: Colors.white.withOpacity(0.5)),

                                // progress fill
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
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        "${count}/${nxt?.min ?? count} IBs",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 4 tier cards grid
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 20,
                mainAxisSpacing: 10,
                children: _kTiers.map((tier) {
                  final isActive = tier.name == cur.name;
                  return _buildTierCard(tier);
                }).toList(),
              ),
            ],
          ),
        ),

        // Status pills row
      ],
    );
  }

  Widget _pill(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: _dmSans,
        ),
      ),
    );
  }

  Widget _buildTierCard(_Tier tier) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),

        // gradient border
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tier.color.withOpacity(0.6),
            Colors.transparent,
            tier.color.withOpacity(0.4),
          ],
        ),

        // glow / elevation
        // boxShadow: [
        //   BoxShadow(
        //     color: tier.color.withOpacity(0.25),
        //     blurRadius: 18,
        //     spreadRadius: 1,
        //   ),
        // ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(1), // border thickness

        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(15),
          ),

          clipBehavior: Clip.hardEdge,

          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TierCardPainter(color: tier.color),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(0),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tier.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: _dmSans,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "${tier.commission}%",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0XFFCCFF00),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans,
                        height: 1,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "of 0.3% fee",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        fontFamily: _dmSans,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── LEVEL 2 ───────────────────────────────────────────────────────────────
  Widget _buildLevel2Section() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "LEVEL 2 — INDIRECT IBS",
          style: TextStyle(
            color: Color(0XFFCCFF00),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: _dmSans,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Fixed for all tiers",
          style: TextStyle(
            color: _white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: _dmSans,
            height: 1,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF1AFF00).withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Green gradient glow
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
                  horizontal: 18,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Flat Commission",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: _dmSans,
                              height: 1,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "When your IB brings someone",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: _dmSans,
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Text(
                      "30%",
                      style: TextStyle(
                        color: Color(0xFFCCFF00),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── REFERRAL HISTORY ──────────────────────────────────────────────────────
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const Text(
              "Referral History",
              style: TextStyle(
                color: _white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans,
              ),
            ),
            const Spacer(),
            _buildDateBox(
              text: _startDate == null ? "Start Date" : _fmtDate(_startDate!),
              onTap: () => _pickDate(true),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                "—",
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            _buildDateBox(
              text: _endDate == null ? "End Date" : _fmtDate(_endDate!),
              onTap: () => _pickDate(false),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Scrollable table
        Obx(() {
          final members = _ctrl.networkMembers;
          if (members.isEmpty) {
            return Center(
              child: Text(
                "No referrals yet",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  fontFamily: _dmSans,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      _tableCell("No.", 36, isHeader: true),
                      _tableCell("Referral", 110, isHeader: true),
                      _tableCell("Joined", 110, isHeader: true),
                      _tableCell("Trading Volume", 140, isHeader: true),
                      _tableCell("You Earned (20%)", 155, isHeader: true),
                    ],
                  ),
                  Divider(color: Colors.white.withOpacity(0.08), height: 20),
                  ...List.generate(members.length, (i) {
                    final m = members[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        children: [
                          _tableCell("${i + 1}", 36),
                          _tableCell(m['name'] ?? '', 110),
                          _tableCell(m['joined_at'] ?? '', 110),
                          SizedBox(
                            width: 140,
                            child: Text(
                              "\$${(m['trade_volume'] ?? 0).toStringAsFixed(2)} USDT",
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: _dmSans,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 155,
                            child: Text(
                              "+${(m['you_earned'] ?? 0).toStringAsFixed(5)} USDT",
                              style: const TextStyle(
                                color: _green,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: _dmSans,
                              ),
                            ),
                          ),
                        ],
                      ),
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
      child: Text(
        text,
        style: TextStyle(
          color: isHeader ? Colors.white.withOpacity(0.45) : _white,
          fontSize: isHeader ? 11 : 13,
          fontWeight: isHeader ? FontWeight.w500 : FontWeight.w400,
          fontFamily: _dmSans,
        ),
      ),
    );
  }

  Widget _buildDateBox({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                color: _white,
                fontSize: 10,
                fontFamily: _dmSans,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.calendar_today_rounded, size: 13, color: _green),
          ],
        ),
      ),
    );
  }

  // ── TERMS & CONDITIONS ────────────────────────────────────────────────────
  Widget _buildTermsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),

        color: const Color(0xFF1A1A1A),

        border: Border.all(color: Colors.transparent),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Title
          const Text(
            "IB Program — Terms & Conditions",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _dmSans,
              height: 1,
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 Subtitle
          Text(
            "Last updated: June 2025 · Please read carefully before participating",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontFamily: _dmSans,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (picked != null)
      setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  String _fmtDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";
}
