import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/features/root/root_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/referrals/referral_controller.dart';

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
  late final ReferralController _ctrl;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ReferralController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.getReferralData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF111111),
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
                children: [
                  const SizedBox(height: 40),
                  _buildHowItWorksSection(),
                  _buildStatsSection(),
                  const SizedBox(height: 40),
                  _buildPendingRewards(),
                  const SizedBox(height: 20),
                  _buildHistorySection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          )),
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
        padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(top: 10),
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
            const SizedBox(height: 230),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  const TextSpan(
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
                    text: "${(_ctrl.referralData.value.commissionPercentage ?? 20).toStringAsFixed(0)}%",
                    style: TextStyle(
                      color: Color(0xFFD7FF00),
                      fontSize: 30,
                      height: 40 / 30,
                      fontWeight: FontWeight.w700,
                      fontFamily: "DMSans",
                    ),
                  ),
                  const TextSpan(
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
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "Invite anyone to Tripix. Every time they trade, you ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      TextSpan(
                        text: "earn up to ${(_ctrl.referralData.value.commissionPercentage ?? 20).toStringAsFixed(0)}% ",
                        style: const TextStyle(
                          color: Color(0xFFCCFF00),
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const TextSpan(
                        text: "of",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const TextSpan(
                        text: "the ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      TextSpan(
                        text: "${(_ctrl.referralData.value.feePercentage ?? 0.3).toStringAsFixed(1)}% exchange free ",
                        style: TextStyle(
                          color: Color(0xFFCCFF00),
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const TextSpan(
                        text: "automatically, for life.",
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
            const SizedBox(height: 20),
            _buildReferralBox(value: _ctrl.referralData.value.referralLink ?? _ctrl.referralData.value.url ?? '', isCode: false),
            _buildReferralBox(value: _ctrl.referralData.value.referralCode ?? _ctrl.referralData.value.user?.affiliate?.code ?? '', isCode: true),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: "DMSans",
                  ),
                  children: [
                    TextSpan(
                      text: "Receive ${(_ctrl.referralData.value.commissionPercentage ?? 20).toStringAsFixed(0)}%",
                      style: TextStyle(color: Color(0xFFCCFF00)),
                    ),
                    const TextSpan(
                      text: " commission on all trades made through your referrals",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
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
                onPressed: _ctrl.copyReferralLink,
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
        value: "${_ctrl.referralData.value.countReferrals ?? 0}",
      ),

      _buildGlowCard(
        title: "Total Earned",
        value: (_ctrl.referralData.value.totalReward?.toDouble() ?? 0.0).toStringAsFixed(2),
        suffix: "USDT",
      ),

      _buildGlowCard(
        title: "Commission",
        value: "${(_ctrl.referralData.value.commissionPercentage ?? 20).toStringAsFixed(0)}%",
      ),

      _buildGlowCard(
        title: "Active Referrals",
        value: "${_ctrl.referralData.value.activeReferrals ?? 0}",
      ),
    ],
  );
}

Widget _buildGlowCard({
  required String title,
  required String value,
  String suffix = "",
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),

      /// SAME GRADIENT FOR ALL CARDS
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF081A00),
          Color(0xFF0C2600),
          Color(0xFF00391A),
          
        ],
        stops: [0.0, 0.5962, 0.9519],
      ),

      border: Border.all(
        color: Colors.white.withOpacity(0.06),
      ),
    ),

    child: Padding(
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
  );
}

  // ── PENDING REWARDS ───────────────────────────────────────────────────────
 Widget _buildPendingRewards() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),

      /// SAME GRADIENT
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF00391A),
          Color(0xFF0C2600),
          Color(0xFF081A00),
        ],
        stops: [0.0, 0.5962, 0.9519],
      ),

      border: Border.all(
        color: Colors.white.withOpacity(0.06),
      ),
    ),

    clipBehavior: Clip.hardEdge,

    child: Padding(
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
                  text: (_ctrl.referralData.value.pendingBalance ?? 0.0).toStringAsFixed(8),
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

            child: Obx(() => ElevatedButton.icon(
              onPressed: _ctrl.isWithdrawing.value ? null : _ctrl.withdrawToWallet,

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
            )),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 40,
            width: double.infinity,

            child: OutlinedButton(
              onPressed: () async {
                Get.offAll(() => const RootScreen());
                await Future.delayed(const Duration(milliseconds: 300));
                getRootController().changeBottomNavIndex(AppBottomNavKey.wallet);
              },

              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.2,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                backgroundColor: const Color(
                  0xFF1A1A1A,
                ).withOpacity(0.2),
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildDateBox(
                    text: _startDate == null ? "Start Date" : _formatDate(_startDate!),
                    onTap: () => _selectDate(true),
                  ),
                  const SizedBox(width: 6),
                  Text("—", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  const SizedBox(width: 6),
                  _buildDateBox(
                    text: _endDate == null ? "End Date" : _formatDate(_endDate!),
                    onTap: () => _selectDate(false),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Obx(() {
          final all = _ctrl.rewards;
          final filtered = all.where((item) {
            if (_startDate == null && _endDate == null) return true;
            final d = item.createdAt;
            if (d == null) return true;
            if (_startDate != null && d.isBefore(_startDate!)) return false;
            if (_endDate != null && d.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  "No referral history yet",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    fontFamily: "DMSans",
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _refCell("No.", 36, isHeader: true),
                      _refCell("Trade Type", 90, isHeader: true),
                      _refCell("Date", 110, isHeader: true),
                      _refCell("Volume", 120, isHeader: true),
                      _refCell("Commission", 100, isHeader: true),
                      _refCell("Reward", 130, isHeader: true),
                      _refCell("Status", 90, isHeader: true),
                    ],
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 24),
                  ...List.generate(filtered.length, (i) {
                    final item = filtered[i];
                    final dateStr = item.createdAt != null
                        ? "${item.createdAt!.day.toString().padLeft(2, '0')}-${item.createdAt!.month.toString().padLeft(2, '0')}-${item.createdAt!.year}"
                        : '—';
                    final isCredited = item.status == 'credited';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        children: [
                          _refCell("${i + 1}", 36),
                          SizedBox(
                            width: 90,
                            child: Text(
                              (item.tradeType ?? '—').toUpperCase(),
                              style: TextStyle(
                                color: item.tradeType == 'buy'
                                    ? const Color(0xFF00E5FF)
                                    : const Color(0xFFFF6F00),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: "DMSans",
                              ),
                            ),
                          ),
                          _refCell(dateStr, 110),
                          _refCell(
                            "${(item.tradeVolume ?? 0).toStringAsFixed(2)} USDT",
                            120,
                          ),
                          _refCell(
                            "${(item.commissionRate ?? 0).toStringAsFixed(0)}%",
                            100,
                          ),
                          SizedBox(
                            width: 130,
                            child: Text(
                              "+${(item.rewardAmount ?? 0).toStringAsFixed(5)} USDT",
                              style: const TextStyle(
                                color: Color(0xFFCCFF00),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: "DMSans",
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              item.status ?? '—',
                              style: TextStyle(
                                color: isCredited
                                    ? const Color(0xFF00E5FF)
                                    : Colors.white54,
                                fontSize: 12,
                                fontFamily: "DMSans",
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

  Widget _refCell(String text, double width, {bool isHeader = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          color: isHeader ? Colors.white.withValues(alpha: 0.5) : Colors.white,
          fontSize: isHeader ? 11 : 13,
          fontWeight: isHeader ? FontWeight.w500 : FontWeight.w400,
          fontFamily: "DMSans",
        ),
      ),
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
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
