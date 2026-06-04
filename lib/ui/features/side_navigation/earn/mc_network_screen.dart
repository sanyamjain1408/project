import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/referrals/referral_controller.dart';
import 'mc_portfolio_screen.dart';
import 'mc_my_stakes_screen.dart';
import 'mc_staking_screen.dart' show McReferralRewardsScreen, McRewardsScreen;

const _green = Color(0xFFCCFF00);
const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);

class McNetworkScreen extends StatefulWidget {
  const McNetworkScreen({super.key});

  @override
  State<McNetworkScreen> createState() => _McNetworkScreenState();
}

class _McNetworkScreenState extends State<McNetworkScreen> {
  late ReferralController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.isRegistered<ReferralController>()
        ? Get.find<ReferralController>()
        : Get.put(ReferralController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.getReferralData();
    });
  }

  Color _levelColor(String? level) {
    final l = _norm(level);
    if (l == 'Level 1') return _green;
    if (l == 'Level 2') return const Color(0xFF34D399);
    return const Color(0xFF00E5FF);
  }

  String _levelPct(String? level) {
    final l = _norm(level);
    if (l == 'Level 1') return '10%';
    if (l == 'Level 2') return '5%';
    return '3%';
  }

  String _norm(String? level) {
    if (level == null) return 'Level 1';
    if (level == '1') return 'Level 1';
    if (level == '2') return 'Level 2';
    if (level == '3') return 'Level 3';
    return level;
  }

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      'Copied',
      'Referral link copied!',
      backgroundColor: _green,
      colorText: Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Obx(() {
        final data = _ctrl.referralData.value;
        final referrals = data.referrals ?? [];
        final lvl1 = referrals.where((r) => _norm(r.level) == 'Level 1').length;
        final lvl2 = referrals.where((r) => _norm(r.level) == 'Level 2').length;
        final lvl3 = referrals.where((r) => _norm(r.level) == 'Level 3').length;
        final total = referrals.length;
        final referralLink = data.referralLink ?? data.url ?? '';

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Hero Header with gradient ────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromARGB(255, 85, 17, 94), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(-10, 0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Refer Friends.\nEarn Forever.',
                          style: TextStyle(
                            color: _green,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DMSans',
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Text(
                          'Invite friends and earn commissions automatically every day',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'DMSans',
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Referral Link Box ──────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'referral link : ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  referralLink.isEmpty
                                      ? 'Loading...'
                                      : referralLink,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'DMSans',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _copyLink(referralLink),
                                child: const Icon(
                                  Icons.copy_outlined,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Share text ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    'Share this link. You earn commissions from referrals ',
                              ),
                              TextSpan(
                                text: 'up to 3 levels',
                                style: TextStyle(
                                  color: _green,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(text: ' deep.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Invite Now Button ──────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF00E6FF),
                                  Color(0xFFCCFF00),
                                  Color(0xFF77D215),
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _copyLink(referralLink),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Invite Now',
                                style: TextStyle(
                                  color: Color(0xFF111111),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 0),

                  // ── Stats Cards 2×2 ───────────────────────────────────────
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1.7,
                    children: [
                      _statCard(
                        'Total Referral',
                        '$total',
                        _green,
                        showMembers: false,
                      ),
                      _statCard(
                        'Level 1',
                        '$lvl1',
                        const Color(0xFFE946FF),
                        pct: '10%',
                      ),
                      _statCard(
                        'Level 2',
                        '$lvl2',
                        const Color(0xFF00B052),
                        pct: '5%',
                      ),
                      _statCard(
                        'Level 3',
                        '$lvl3',
                        const Color(0xFF00E5FF),
                        pct: '3%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── All Referrals Table ───────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                       
                        if (referrals.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No Referrals Yet\nShare your link to start earning',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 720,
                              child: Column(
                                children: [
                                  _tableHeader(),
                                  ...referrals.asMap().entries.map(
                                    (e) => _tableRow(e.key, e.value),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Bottom Nav Cards (same as staking home) ───────────────
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.4,
                    children: [
                      _navCard(
                        'assets/images/live.png',
                        'Live Dashboard',
                        'Real-time earnings',
                        () => Get.to(() => const McPortfolioScreen()),
                      ),
                      _navCard(
                        'assets/images/my.png',
                        'My Stakes',
                        'Manage positions',
                        () => Get.to(() => const McMyStakesScreen()),
                      ),
                      _navCard(
                        'assets/images/referral.png',
                        'Referral Earnings',
                        'Commission history',
                        () => Get.to(() => const McReferralRewardsScreen()),
                      ),
                      _navCard(
                        'assets/images/reward.png',
                        'Reward History',
                        'Daily logs',
                        () => Get.to(() => const McRewardsScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color color, {
    String pct = '',
    bool showMembers = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style:  TextStyle(
                  color: Colors.white.withOpacity(0.5) ,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'DMSans',
                ),
              ),
              if (pct.isNotEmpty)
                Text(
                  pct,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DMSans',
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
              height: 1,
            ),
          ),
          if (showMembers)
             Text(
              'Members',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'DMSans',
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    decoration:  BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
    ),
    child:  Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            'No.',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'),
          ),
        ),
        SizedBox(
          width: 160,
          child: Text(
            'Member',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'),
          ),
        ),
        SizedBox(
          width: 110,
          child: Text(
            'Level',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'),
          ),
        ),
        SizedBox(
          width: 170,
          child: Text(
            'You Commission',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'),
          ),
        ),
        SizedBox(
          width: 160,
          child: Text(
            'Joined',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'),
          ),
        ),
      ],
    ),
  );

  Widget _tableRow(int idx, dynamic r) {
    final color = _levelColor(r.level);
    final pct = _levelPct(r.level);
    final name = (r.fullName?.isNotEmpty == true) ? r.fullName! : 'Trapix User';
    final email = r.email ?? '';
    final initials = name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    final joined = r.joiningDate != null
        ? '${r.joiningDate!.year}-${r.joiningDate!.month.toString().padLeft(2, '0')}-${r.joiningDate!.day.toString().padLeft(2, '0')} ${r.joiningDate!.hour.toString().padLeft(2, '0')}:${r.joiningDate!.minute.toString().padLeft(2, '0')}:${r.joiningDate!.second.toString().padLeft(2, '0')}'
        : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      
      child: Row(
        children: [
          // No.
          SizedBox(
            width: 56,
            child: Text(
              '${idx + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'),
            ),
          ),
          // Member (name + email)
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
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
          // Level
          SizedBox(
            width: 130,
            child: Text(
                'L${_norm(r.level).replaceAll('Level ', '')} · $pct',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'DMSans',
                ),
              ),
          ),
          // You Commission
          SizedBox(
            width: 180,
            child: Text(
              '+0.1000000 USDT',
              style: const TextStyle(
                color: Color(0xFF00B052),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'DMSans',
              ),
            ),
          ),
          // Date & Time
          SizedBox(
            width: 160,
            child: Text(
              joined,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navCard(String image, String label, String desc, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Image.asset(image, width: 20, height: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 10,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
