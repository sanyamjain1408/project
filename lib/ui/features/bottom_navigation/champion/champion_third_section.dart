import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// ─── Data Models (swap with API models later) ─────────────────────────────────

class ThirdContestModel {
  final String title;
  final String prizePool;
  final String subtitle;
  final String heroImage;
  final DateTime? endsAt;
  final int participantsCount;
  final String? marqueeText;
  final ThirdMyStats? myStats;
  final List<ThirdLeaderboardEntry> leaderboard;
  final List<VolumeRewardTier> volumeRewards;
  final List<ThirdPrizeTier> prizeTiers;
  final List<EventScheduleItem3> schedule;
  final List<RuleModel3> rules;

  const ThirdContestModel({
    required this.title,
    required this.prizePool,
    required this.subtitle,
    required this.heroImage,
    this.endsAt,
    required this.participantsCount,
    this.marqueeText,
    this.myStats,
    required this.leaderboard,
    required this.volumeRewards,
    required this.prizeTiers,
    required this.schedule,
    required this.rules,
  });
}

class ThirdMyStats {
  final double yourDeposit;
  final double totalDeposited;
  final String availableBonus;   // e.g. "20%"
  final int nextBonus;
  final String myRanking;
  final double tradingVolume;
  final bool isRegistered;
  const ThirdMyStats({
    required this.yourDeposit,
    required this.totalDeposited,
    required this.availableBonus,
    required this.nextBonus,
    required this.myRanking,
    required this.tradingVolume,
    required this.isRegistered,
  });
}

class ThirdLeaderboardEntry {
  final int rank;
  final String uid;
  final double spotVol;
  final double futureVol;
  final double totalVol;
  final String prize;      // e.g. "💰 50 USDT"
  final String volReward;  // e.g. "20 USDT"
  const ThirdLeaderboardEntry({
    required this.rank,
    required this.uid,
    required this.spotVol,
    required this.futureVol,
    required this.totalVol,
    required this.prize,
    required this.volReward,
  });
}

class VolumeRewardTier {
  final String volume;   // e.g. "100 USDT"
  final String reward;   // e.g. "5 USDT"
  const VolumeRewardTier({required this.volume, required this.reward});
}

class ThirdPrizeTier {
  final String rankLabel;  // e.g. "#1" or "#4 - #10"
  final String reward;     // e.g. "Iphone 17" or "50 USDT"
  final bool isPhysical;   // true = phone/iPad icon, false = money bag
  const ThirdPrizeTier({
    required this.rankLabel,
    required this.reward,
    this.isPhysical = false,
  });
}

class EventScheduleItem3 {
  final String title;
  final DateTime dateTime;
  final bool completed;
  const EventScheduleItem3(
      {required this.title, required this.dateTime, this.completed = false});
}

class RuleModel3 {
  final String number;
  final String title;
  final String badge;
  final String description;
  final List<String> bullets;
  final String footer;
  const RuleModel3({
    required this.number,
    required this.title,
    required this.badge,
    required this.description,
    required this.bullets,
    required this.footer,
  });
}

// ─── Static mock — replace with API call later ────────────────────────────────
ThirdContestModel _mockThirdContest() {
  return ThirdContestModel(
    title: 'MEGA TRADE FESTIVAL',
    prizePool: 'DEPOSIT JUST\n10 USDT',
    subtitle: '& JOIN THE BIGGEST\nTRADING FESTIVAL',
    heroImage: 'assets/images/champion5.png',
    endsAt: DateTime.now()
        .add(const Duration(days: 2, hours: 23, minutes: 37, seconds: 53)),
    participantsCount: 231,
    marqueeText: '362****128 has registered for the contest',
    myStats: const ThirdMyStats(
      yourDeposit: 1,
      totalDeposited: 0.0,
      availableBonus: '20%',
      nextBonus: 0,
      myRanking: 'N/A',
      tradingVolume: 0.0,
      isRegistered: false,
    ),
    leaderboard: const [
      ThirdLeaderboardEntry(rank: 1, uid: '362****128', spotVol: 2026651.58, futureVol: 0, totalVol: 2026651.58, prize: '💰 50 USDT', volReward: '20 USDT'),
      ThirdLeaderboardEntry(rank: 2, uid: '362****128', spotVol: 2026651.58, futureVol: 0, totalVol: 2026651.58, prize: '💰 50 USDT', volReward: '20 USDT'),
      ThirdLeaderboardEntry(rank: 3, uid: '362****128', spotVol: 1242.52,    futureVol: 1242.52, totalVol: 2026651.58, prize: '💰 50 USDT', volReward: '20 USDT'),
      ThirdLeaderboardEntry(rank: 4, uid: '362****128', spotVol: 1242.52,    futureVol: 1242.52, totalVol: 2026651.58, prize: '💰 50 USDT', volReward: '20 USDT'),
      ThirdLeaderboardEntry(rank: 5, uid: '362****128', spotVol: 1242.52,    futureVol: 1242.52, totalVol: 2026651.58, prize: '💰 50 USDT', volReward: '20 USDT'),
    ],
    volumeRewards: const [
      VolumeRewardTier(volume: '100 USDT',    reward: '5 USDT'),
      VolumeRewardTier(volume: '500 USDT',    reward: '10 USDT'),
      VolumeRewardTier(volume: '1,000 USDT',  reward: '20 USDT'),
      VolumeRewardTier(volume: '5,000 USDT',  reward: '50 USDT'),
      VolumeRewardTier(volume: '10,000 USDT', reward: '120 USDT'),
      VolumeRewardTier(volume: '50,000 USDT', reward: '300 USDT'),
      VolumeRewardTier(volume: '100,000 USDT',reward: '1000 USDT'),
    ],
    prizeTiers: const [
      ThirdPrizeTier(rankLabel: '#1',        reward: 'Iphone 17',  isPhysical: true),
      ThirdPrizeTier(rankLabel: '#2',        reward: 'Ipad Air',   isPhysical: true),
      ThirdPrizeTier(rankLabel: '#3',        reward: 'Airpods',    isPhysical: true),
      ThirdPrizeTier(rankLabel: '#4 – #10',  reward: '50 USDT'),
      ThirdPrizeTier(rankLabel: '#11 – #25', reward: '25 USDT'),
      ThirdPrizeTier(rankLabel: '#26 – #50', reward: '15 USDT'),
      ThirdPrizeTier(rankLabel: '#51 – #100',reward: '10 USDT'),
    ],
    schedule: [
      EventScheduleItem3(title: 'Warm-up',              dateTime: DateTime(2026, 2, 22, 12, 15), completed: true),
      EventScheduleItem3(title: 'Contest Launch',        dateTime: DateTime(2026, 2, 22, 12, 15), completed: true),
      EventScheduleItem3(title: 'Eligibility Review',    dateTime: DateTime(2026, 2, 22, 12, 15), completed: true),
      EventScheduleItem3(title: 'Rewards Distributions', dateTime: DateTime(2026, 2, 22, 12, 15), completed: true),
    ],
    rules: const [
      RuleModel3(
        number: 'Rule 1',
        title: 'Trading Volume Milestone Rewards',
        badge: '💎 First Milestone Rewards (During Contest)',
        description:
            'If a user reaches the required trading volume milestone during the contest period, they will become eligible for milestone rewards.',
        bullets: [
          'Rewards will be distributed after the contest ends',
          'Only verified (KYC completed) users are eligible',
          'Trading volume will include all eligible spot trades',
        ],
        footer: '👉 Reach the milestone and unlock exciting rewards.',
      ),
      RuleModel3(
        number: 'Rule 2',
        title: 'Special Trader Bonus',
        badge: '',
        description: 'After the competition ends:',
        bullets: [
          'The Top 3 traders with the highest trading volume will receive the exclusive rewards.',
          'In case of equal trading volume, the user who reached the volume first will rank higher.',
          'Only users who meet the required trading volume conditions will qualify.',
        ],
        footer: '👉 Compete with traders and secure your position among the top winners.',
      ),
    ],
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ChampionThirdSection extends StatefulWidget {
  final ThirdContestModel? contest;
  const ChampionThirdSection({super.key, this.contest});

  @override
  State<ChampionThirdSection> createState() => _ChampionThirdSectionState();
}

class _ChampionThirdSectionState extends State<ChampionThirdSection> {
  static const _green  = Color(0xFFCCFF00);
  static const _bg     = Color(0xFF0B0B0F);
  static const _card   = Color(0xFF1A1A1A);
  static const _dmSans = 'DMSans';

  late ThirdContestModel _contest;
  late Duration _remaining;
  Timer? _timer;
  int _leaderboardPage = 0;
  static const _perPage = 5;

  @override
  void initState() {
    super.initState();
    _contest = widget.contest ?? _mockThirdContest();
    _remaining = _contest.endsAt != null
        ? _contest.endsAt!.difference(DateTime.now())
        : Duration.zero;
    if (_remaining.isNegative) _remaining = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHero(),
          if (_contest.marqueeText != null) _buildMarquee(),
          const SizedBox(height: 16),
          _buildCountdown(),
          const SizedBox(height: 16),
          _buildStatsGrid(),
          const SizedBox(height: 16),
          _buildMyAchievements(),
          const SizedBox(height: 16),
          _buildLeaderboard(),
          const SizedBox(height: 16),
          _buildVolumeRewards(),
          const SizedBox(height: 16),
          _buildPrizePools(),
          const SizedBox(height: 16),
          _buildEventSchedule(),
          const SizedBox(height: 16),
          ..._contest.rules.map(_buildRule),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Image.asset(
            _contest.heroImage,
            fit: BoxFit.cover,
            errorBuilder: (context, err, stack) =>
                Container(color: const Color(0xFF111111)),
          ),
        ),
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xDD0B0B0F)],
              stops: [0.3, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_outlined,
                      color: Colors.white, size: 24),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.timer_outlined,
                      color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Marquee ────────────────────────────────────────────────────────────────
  Widget _buildMarquee() {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.volume_up_outlined, color: _green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _contest.marqueeText!,
              style: const TextStyle(
                  color: _green, fontSize: 12, fontFamily: _dmSans),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Countdown ─────────────────────────────────────────────────────────────
  Widget _buildCountdown() {
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Text('Contest Concludes in',
                style: TextStyle(
                    color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w600, fontFamily: _dmSans)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _countUnit(_pad(d), 'D'),
                _countSep(),
                _countUnit(_pad(h), 'H'),
                _countSep(),
                _countUnit(_pad(m), 'M'),
                _countSep(),
                _countUnit(_pad(s), 'S'),
              ],
            ),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: '${_contest.participantsCount} ',
                    style: const TextStyle(
                        color: _green, fontSize: 15,
                        fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                const TextSpan(
                    text: 'Users Participated!',
                    style: TextStyle(
                        color: Colors.white, fontSize: 15, fontFamily: _dmSans)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countUnit(String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value,
            style: const TextStyle(
                color: _green, fontSize: 30,
                fontWeight: FontWeight.w800, fontFamily: _dmSans, height: 1)),
        const SizedBox(width: 2),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w600, fontFamily: _dmSans)),
        ),
      ],
    );
  }

  Widget _countSep() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text(':',
            style: TextStyle(
                color: Colors.white54, fontSize: 24,
                fontWeight: FontWeight.w300)),
      );

  // ── Stats 2×2 Grid ─────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    final s = _contest.myStats;
    final items = [
      ('Your Deposit',    s != null ? s.yourDeposit.toStringAsFixed(0) : '0',   ''),
      ('Total Deposited', s != null ? s.totalDeposited.toStringAsFixed(2) : '0.00', 'USDT'),
      ('Available Bonus', s?.availableBonus ?? '0%', ''),
      ('Next Bonus',      s != null ? '${s.nextBonus}' : '0', ''),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: items.map((item) {
          final (label, value, unit) = item;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12, fontFamily: _dmSans)),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(value,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(unit,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10, fontFamily: _dmSans)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── My Achievements ────────────────────────────────────────────────────────
  Widget _buildMyAchievements() {
    final s = _contest.myStats;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('My Achievements',
                  style: TextStyle(
                      color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w700, fontFamily: _dmSans)),
              const SizedBox(width: 10),
              _greenTag('Overall Ranking'),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Ranking',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11, fontFamily: _dmSans)),
                    const SizedBox(height: 4),
                    Text(s?.myRanking ?? 'N/A',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Trading Vol(USDT)',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11, fontFamily: _dmSans)),
                    const SizedBox(height: 4),
                    Text(
                        s != null
                            ? s.tradingVolume.toStringAsFixed(2)
                            : '0.00',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: wire register API
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  s?.isRegistered == true ? 'Registered ✓' : 'Register Now',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w700,
                      fontSize: 15, fontFamily: _dmSans),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Leaderboard (horizontal scroll table) ─────────────────────────────────
  Widget _buildLeaderboard() {
    final all   = _contest.leaderboard;
    final pages = (all.length / _perPage).ceil().clamp(1, 9999);
    final start = _leaderboardPage * _perPage;
    final slice = all.skip(start).take(_perPage).toList();

    // Top 3 avatars
    final top3 = all.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                const Text('Leaderboard',
                    style: TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                const SizedBox(width: 10),
                _greenTag('Overall Ranking'),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Top 3 podium avatars ─────────────────────────────────────
            if (top3.length >= 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _podiumAvatar(top3[1], height: 80), // 2nd
                    _podiumAvatar(top3[0], height: 100), // 1st (tallest)
                    _podiumAvatar(top3[2], height: 72), // 3rd
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ── Horizontal scroll table ──────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _lbRow(
                    rank: 'Ranking',
                    uid: 'UID',
                    spotVol: 'SPOT VOL',
                    futVol: 'FUTURE VOL',
                    totalVol: 'TOTAL VOL',
                    prize: 'PRIZE',
                    volReward: 'VOL REWARD',
                    isHeader: true,
                  ),
                  const SizedBox(height: 6),
                  ...slice.map((e) => _lbRow(
                        rank: '${e.rank}',
                        uid: e.uid,
                        spotVol: _fmtVol(e.spotVol),
                        futVol: _fmtVol(e.futureVol),
                        totalVol: _fmtVol(e.totalVol),
                        prize: e.prize,
                        volReward: e.volReward,
                        isHeader: false,
                        rankInt: e.rank,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Pagination ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageBtn(
                    icon: Icons.chevron_left_rounded,
                    enabled: _leaderboardPage > 0,
                    onTap: () => setState(() => _leaderboardPage--)),
                const SizedBox(width: 14),
                Text('${_leaderboardPage + 1}/$pages',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontFamily: _dmSans)),
                const SizedBox(width: 14),
                _pageBtn(
                    icon: Icons.chevron_right_rounded,
                    enabled: _leaderboardPage < pages - 1,
                    onTap: () => setState(() => _leaderboardPage++)),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Text('The last update was on March 10 at 12:00',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11, fontFamily: _dmSans)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _podiumAvatar(ThirdLeaderboardEntry e, {required double height}) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFB0B0B0),
      const Color(0xFFCD7F32),
    ];
    final color = e.rank <= 3 ? colors[e.rank - 1] : Colors.white24;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: height * 0.28,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(Icons.person, color: color, size: height * 0.28),
            ),
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: _card, width: 2)),
                child: Center(
                  child: Text('${e.rank}',
                      style: const TextStyle(
                          color: Colors.black, fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(e.uid,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontFamily: _dmSans)),
        Text(_fmtVol(e.totalVol),
            style: TextStyle(
                color: color, fontSize: 11,
                fontWeight: FontWeight.w700, fontFamily: _dmSans)),
      ],
    );
  }

  Widget _lbRow({
    required String rank,
    required String uid,
    required String spotVol,
    required String futVol,
    required String totalVol,
    required String prize,
    required String volReward,
    required bool isHeader,
    int rankInt = 0,
  }) {
    final style = isHeader
        ? TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontFamily: _dmSans,
            fontWeight: FontWeight.w500)
        : const TextStyle(
            color: Colors.white, fontSize: 12,
            fontFamily: _dmSans, fontWeight: FontWeight.w400);

    final prizeStyle = isHeader
        ? style
        : const TextStyle(
            color: _green, fontSize: 12,
            fontFamily: _dmSans, fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 64,  child: Text(rank,     style: style, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 90,  child: Text(uid,      style: style, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 90,  child: Text(spotVol,  style: style, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 90,  child: Text(futVol,   style: style, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 100, child: Text(totalVol, style: style, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 90,  child: Text(prize,    style: prizeStyle, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 80,  child: Text(volReward,style: isHeader ? style : const TextStyle(
              color: _green, fontSize: 12, fontFamily: _dmSans, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // ── Volume Rewards Table ───────────────────────────────────────────────────
  Widget _buildVolumeRewards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trade & Earn Volume Reward',
                style: TextStyle(
                    color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700, fontFamily: _dmSans)),
            const SizedBox(height: 6),
            Text(
              'Participants are divided into 3 tiers, based on trading\nvolume achieved during the event:',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12, fontFamily: _dmSans, height: 1.5),
            ),
            const SizedBox(height: 16),
            // Header
            Row(children: [
              Expanded(
                child: Text('TRADING VOLUME',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11, fontFamily: _dmSans,
                        fontWeight: FontWeight.w600)),
              ),
              Text('REWARD (USDT) WITHDRAWABLE',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11, fontFamily: _dmSans,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            ..._contest.volumeRewards.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Expanded(
                      child: Text(t.volume,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14,
                              fontFamily: _dmSans)),
                    ),
                    Text(t.reward,
                        style: const TextStyle(
                            color: _green, fontSize: 14,
                            fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                  ]),
                )),
          ],
        ),
      ),
    );
  }

  // ── Prize Pools ────────────────────────────────────────────────────────────
  Widget _buildPrizePools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prize Pools',
                style: TextStyle(
                    color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700, fontFamily: _dmSans)),
            const SizedBox(height: 6),
            Text(
              'Participants are divided into 3 tiers, based on trading\nvolume achieved during the event:',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12, fontFamily: _dmSans, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Text('Price',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11, fontFamily: _dmSans)),
              ),
              Text('Rewards',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11, fontFamily: _dmSans)),
            ]),
            const SizedBox(height: 10),
            ..._contest.prizeTiers.map(_prizeRow),
          ],
        ),
      ),
    );
  }

  Widget _prizeRow(ThirdPrizeTier tier) {
    final rank = tier.rankLabel;
    final isTop3 = rank == '#1' || rank == '#2' || rank == '#3';
    Widget rankWidget;
    if (isTop3) {
      final idx = int.parse(rank.substring(1)) - 1;
      final colors = [
        const Color(0xFFFFD700),
        const Color(0xFFB0B0B0),
        const Color(0xFFCD7F32),
      ];
      rankWidget = Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[idx].withValues(alpha: 0.2),
            border: Border.all(color: colors[idx], width: 1.5)),
        child: Center(
          child: Text('${idx + 1}',
              style: TextStyle(
                  color: colors[idx], fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ),
      );
    } else {
      rankWidget = Text(rank,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontFamily: _dmSans));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 80, child: rankWidget),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tier.isPhysical)
                  const Icon(Icons.phone_iphone_rounded,
                      color: Colors.white70, size: 16)
                else
                  const Text('💰 ', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  tier.reward,
                  style: TextStyle(
                      color: tier.isPhysical ? Colors.white : _green,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: _dmSans),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Event Schedule ─────────────────────────────────────────────────────────
  Widget _buildEventSchedule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Event Schedule',
                style: TextStyle(
                    color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700, fontFamily: _dmSans)),
            const SizedBox(height: 16),
            ...List.generate(_contest.schedule.length, (i) {
              final isLast = i == _contest.schedule.length - 1;
              return _scheduleRow(_contest.schedule[i], isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _scheduleRow(EventScheduleItem3 item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.completed
                        ? _green.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                        color: item.completed ? _green : Colors.white24,
                        width: 1.5),
                  ),
                  child: item.completed
                      ? const Icon(Icons.check, color: _green, size: 12)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                        width: 2,
                        color: _green.withValues(alpha: 0.4)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13,
                          fontFamily: _dmSans)),
                  Text(_fmtDate(item.dateTime),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12, fontFamily: _dmSans)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rules ──────────────────────────────────────────────────────────────────
  Widget _buildRule(RuleModel3 rule) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: '${rule.number} : ',
                    style: const TextStyle(
                        color: _green, fontSize: 15,
                        fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                TextSpan(
                    text: rule.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w700, fontFamily: _dmSans)),
              ]),
            ),
            if (rule.badge.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(rule.badge,
                  style: const TextStyle(
                      color: _green, fontSize: 13, fontFamily: _dmSans)),
            ],
            const SizedBox(height: 10),
            Text(rule.description,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13, fontFamily: _dmSans, height: 1.5)),
            const SizedBox(height: 10),
            ...rule.bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13)),
                      Expanded(
                        child: Text(b,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontFamily: _dmSans, height: 1.5)),
                      ),
                    ],
                  ),
                )),
            if (rule.footer.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(rule.footer,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13,
                      fontFamily: _dmSans, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _greenTag(String label, {bool active = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? _green.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: active
                ? _green.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(label,
          style: TextStyle(
              color: active ? _green : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: _dmSans)),
    );
  }

  Widget _pageBtn(
      {required IconData icon,
      required bool enabled,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
        ),
        child: Icon(icon,
            color: enabled ? Colors.white : Colors.white24, size: 22),
      ),
    );
  }

  String _fmtVol(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(2)}M';
    }
    if (v >= 1000) {
      return v
          .toStringAsFixed(2)
          .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return v.toStringAsFixed(2);
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
      '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
}
