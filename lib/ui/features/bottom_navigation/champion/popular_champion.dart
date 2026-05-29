import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// ─── Data Models (replace with API models later) ──────────────────────────────

class ContestModel {
  final String title;
  final String prizePool;
  final String subtitle;
  final String heroImage;       // asset path for hero background
  final DateTime? endsAt;       // countdown target
  final int participantsCount;
  final List<TradingPairModel> tradingPairs;
  final List<LeaderboardEntry> leaderboard;
  final List<EventScheduleItem> schedule;
  final List<PrizePoolTier> prizeTiers;
  final List<RuleModel> rules;
  final String? marqueeText;
  final MyAchievementModel? myAchievement;

  const ContestModel({
    required this.title,
    required this.prizePool,
    required this.subtitle,
    required this.heroImage,
    this.endsAt,
    required this.participantsCount,
    required this.tradingPairs,
    required this.leaderboard,
    required this.schedule,
    required this.prizeTiers,
    required this.rules,
    this.marqueeText,
    this.myAchievement,
  });
}

class TradingPairModel {
  final String symbol;
  final double changePercent;
  const TradingPairModel({required this.symbol, required this.changePercent});
}

class LeaderboardEntry {
  final int rank;
  final String uid;
  final double tradingVolume;
  const LeaderboardEntry(
      {required this.rank, required this.uid, required this.tradingVolume});
}

class EventScheduleItem {
  final String title;
  final DateTime dateTime;
  final bool completed;
  const EventScheduleItem(
      {required this.title, required this.dateTime, this.completed = false});
}

class PrizePoolTier {
  final int rank;
  final String volumeRequired;
  final String reward;
  final String? rewardIcon; // asset path, null = use emoji
  const PrizePoolTier(
      {required this.rank,
      required this.volumeRequired,
      required this.reward,
      this.rewardIcon});
}

class RuleModel {
  final String number;    // e.g. "Rule 1"
  final String title;
  final String badge;     // e.g. "💎 First Milestone Rewards (During Contest)"
  final String description;
  final List<String> bullets;
  final String footer;
  const RuleModel({
    required this.number,
    required this.title,
    required this.badge,
    required this.description,
    required this.bullets,
    required this.footer,
  });
}

class MyAchievementModel {
  final String ranking;
  final double tradingVolume;
  final bool isRegistered;
  const MyAchievementModel({
    required this.ranking,
    required this.tradingVolume,
    required this.isRegistered,
  });
}

// ─── Static mock — swap this with an API call later ───────────────────────────
ContestModel _mockContest() {
  return ContestModel(
    title: 'TRADING CONTEST',
    prizePool: '\$20,000',
    subtitle: 'Price Pool + Iphone 17',
    heroImage: 'assets/images/champion4.png',
    endsAt: DateTime.now().add(const Duration(days: 2, hours: 23, minutes: 37, seconds: 53)),
    participantsCount: 231,
    marqueeText: '362****128 has registered for the contest',
    myAchievement: const MyAchievementModel(
      ranking: 'N/A',
      tradingVolume: 0.0,
      isRegistered: false,
    ),
    tradingPairs: const [
      TradingPairModel(symbol: 'XLM/USDT', changePercent: 6.21),
      TradingPairModel(symbol: 'SHIB/USDT', changePercent: 6.21),
    ],
    leaderboard: const [
      LeaderboardEntry(rank: 1, uid: '362****128', tradingVolume: 2026651.58),
      LeaderboardEntry(rank: 2, uid: '362****128', tradingVolume: 2026651.58),
      LeaderboardEntry(rank: 3, uid: '362****128', tradingVolume: 2026651.58),
      LeaderboardEntry(rank: 4, uid: '362****128', tradingVolume: 2026651.58),
      LeaderboardEntry(rank: 5, uid: '362****128', tradingVolume: 2026651.58),
    ],
    schedule: [
      EventScheduleItem(
          title: 'Warm-up',
          dateTime: DateTime(2026, 2, 22, 12, 15),
          completed: true),
      EventScheduleItem(
          title: 'Contest Launch',
          dateTime: DateTime(2026, 2, 22, 12, 15),
          completed: true),
      EventScheduleItem(
          title: 'Eligibility Review',
          dateTime: DateTime(2026, 2, 22, 12, 15),
          completed: true),
      EventScheduleItem(
          title: 'Rewards Distributions',
          dateTime: DateTime(2026, 2, 22, 12, 15),
          completed: true),
    ],
    prizeTiers: const [
      PrizePoolTier(rank: 1, volumeRequired: '10,00,000 USDT', reward: 'Iphone 17'),
      PrizePoolTier(rank: 2, volumeRequired: '5,00,000 USDT',  reward: 'Ipad Air'),
      PrizePoolTier(rank: 3, volumeRequired: '2,50,000 USDT',  reward: 'Airpods'),
    ],
    rules: const [
      RuleModel(
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
      RuleModel(
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
class PopularChampionScreen extends StatefulWidget {
  // Pass a ContestModel when wiring to API; defaults to mock
  final ContestModel? contest;
  const PopularChampionScreen({super.key, this.contest});

  @override
  State<PopularChampionScreen> createState() => _PopularChampionScreenState();
}

class _PopularChampionScreenState extends State<PopularChampionScreen>
    with SingleTickerProviderStateMixin {
  static const _green  = Color(0xFFCCFF00);
  static const _bg     = Color(0xFF0B0B0F);
  static const _card   = Color(0xFF1A1A1A);
  static const _dmSans = 'DMSans';

  late ContestModel _contest;
  late Duration _remaining;
  Timer? _timer;
  int _leaderboardPage = 0;
  static const _perPage = 5;

  // Tab: Spot / Futures
  int _pairTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _contest = widget.contest ?? _mockContest();
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

  // ── Helper: pad 2 digits ────────────────────────────────────────────────────
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
          _buildMyAchievements(),
          const SizedBox(height: 16),
          _buildTradingPairs(),
          const SizedBox(height: 16),
          _buildLeaderboard(),
          const SizedBox(height: 16),
          _buildEventSchedule(),
          const SizedBox(height: 16),
          _buildPrizePools(),
          const SizedBox(height: 16),
          ..._contest.rules.map(_buildRule),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HERO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHero() {
    return Stack(
      children: [
        // Background image
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Image.asset(
            _contest.heroImage,
            fit: BoxFit.cover,
            errorBuilder: (context, err, stack) => Container(color: const Color(0xFF111111)),
          ),
        ),
        // Dark gradient overlay
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
        // Back button + timer icon
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
        // Title + prize text (bottom of hero)
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _contest.title,
                style: const TextStyle(
                  color: _green,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: _dmSans,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _contest.prizePool,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFamily: _dmSans,
                  height: 1.1,
                ),
              ),
              Text(
                _contest.subtitle,
                style: const TextStyle(
                  color: _green,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: _dmSans,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MARQUEE
  // ══════════════════════════════════════════════════════════════════════════
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

  // ══════════════════════════════════════════════════════════════════════════
  // COUNTDOWN
  // ══════════════════════════════════════════════════════════════════════════
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
            const Text(
              'Contest Concludes in',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: _dmSans),
            ),
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
                      color: _green,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: _dmSans),
                ),
                const TextSpan(
                  text: 'Users Participated!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: _dmSans),
                ),
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
        Text(
          value,
          style: const TextStyle(
              color: _green,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              fontFamily: _dmSans,
              height: 1),
        ),
        const SizedBox(width: 2),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: _dmSans),
          ),
        ),
      ],
    );
  }

  Widget _countSep() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text(':',
            style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.w300)),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // MY ACHIEVEMENTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMyAchievements() {
    final ach = _contest.myAchievement;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('My Achievements',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans)),
                const SizedBox(width: 10),
                _greenTag('Overall Ranking'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Ranking',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontFamily: _dmSans)),
                      const SizedBox(height: 4),
                      Text(ach?.ranking ?? 'N/A',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: _dmSans)),
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
                              fontSize: 11,
                              fontFamily: _dmSans)),
                      const SizedBox(height: 4),
                      Text(
                          ach != null
                              ? ach.tradingVolume.toStringAsFixed(2)
                              : '0.00',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: _dmSans)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: wire to register API
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  ach?.isRegistered == true ? 'Registered ✓' : 'Register Now',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFamily: _dmSans),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRADING PAIRS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTradingPairs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Trading Pairs',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _pairTabIndex = 0),
                  child: _greenTag('Spot',
                      active: _pairTabIndex == 0),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _pairTabIndex = 1),
                  child: _greenTag('Futures',
                      active: _pairTabIndex == 1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 24,
              runSpacing: 10,
              children: _contest.tradingPairs.map((p) {
                final isPos = p.changePercent >= 0;
                return RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: '${p.symbol}  ',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: _dmSans)),
                    TextSpan(
                        text:
                            '${isPos ? '+' : ''}${p.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                            color: isPos ? _green : Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: _dmSans)),
                  ]),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LEADERBOARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLeaderboard() {
    final all    = _contest.leaderboard;
    final pages  = (all.length / _perPage).ceil();
    final start  = _leaderboardPage * _perPage;
    final slice  = all.skip(start).take(_perPage).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Leaderboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans)),
                const SizedBox(width: 10),
                _greenTag('Overall Ranking'),
              ],
            ),
            const SizedBox(height: 14),
            // Header row
            Row(
              children: [
                const SizedBox(width: 44),
                const Expanded(
                  flex: 3,
                  child: Text('UID',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontFamily: _dmSans)),
                ),
                Expanded(
                  flex: 4,
                  child: Text('Cumulative Trading\nVol(USDT)',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontFamily: _dmSans)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...slice.map((e) => _leaderboardRow(e)),
            const SizedBox(height: 16),
            // Pagination
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageBtn(
                    icon: Icons.chevron_left_rounded,
                    enabled: _leaderboardPage > 0,
                    onTap: () => setState(() => _leaderboardPage--)),
                const SizedBox(width: 14),
                Text(
                  '${_leaderboardPage + 1}/$pages',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: _dmSans),
                ),
                const SizedBox(width: 14),
                _pageBtn(
                    icon: Icons.chevron_right_rounded,
                    enabled: _leaderboardPage < pages - 1,
                    onTap: () => setState(() => _leaderboardPage++)),
              ],
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text('The last update was on March 10 at 12:00',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 11, fontFamily: _dmSans)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardRow(LeaderboardEntry e) {
    Widget rankWidget;
    if (e.rank == 1) {
      rankWidget = _medalBadge('🥇', const Color(0xFFFFD700));
    } else if (e.rank == 2) {
      rankWidget = _medalBadge('🥈', const Color(0xFFB0B0B0));
    } else if (e.rank == 3) {
      rankWidget = _medalBadge('🥉', const Color(0xFFCD7F32));
    } else {
      rankWidget = SizedBox(
        width: 36,
        child: Text('${e.rank}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: _dmSans)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 44, child: rankWidget),
          Expanded(
            flex: 3,
            child: Text(e.uid,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontFamily: _dmSans)),
          ),
          Expanded(
            flex: 4,
            child: Text(
              _fmtVolume(e.tradingVolume),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: _dmSans),
            ),
          ),
        ],
      ),
    );
  }

  Widget _medalBadge(String emoji, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 1.5)),
      child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 14))),
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

  // ══════════════════════════════════════════════════════════════════════════
  // EVENT SCHEDULE
  // ══════════════════════════════════════════════════════════════════════════
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
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans)),
            const SizedBox(height: 16),
            ...List.generate(_contest.schedule.length, (i) {
              final item = _contest.schedule[i];
              final isLast = i == _contest.schedule.length - 1;
              return _scheduleRow(item, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _scheduleRow(EventScheduleItem item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // Circle icon
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
                // Vertical line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _green.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: _dmSans)),
                  Text(
                    _fmtScheduleDate(item.dateTime),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontFamily: _dmSans),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIZE POOLS
  // ══════════════════════════════════════════════════════════════════════════
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
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans)),
            const SizedBox(height: 6),
            Text(
              'Participants are divided into 3 tiers, based on trading\nvolume achieved during the event:',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: _dmSans,
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                const SizedBox(width: 44),
                Expanded(
                    child: Text('Volume Required',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontFamily: _dmSans))),
                SizedBox(
                    width: 90,
                    child: Text('Rewards',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontFamily: _dmSans))),
              ],
            ),
            const SizedBox(height: 10),
            ..._contest.prizeTiers.map(_prizeRow),
          ],
        ),
      ),
    );
  }

  Widget _prizeRow(PrizePoolTier tier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: tier.rank <= 3
                ? _medalBadge(
                    ['🥇', '🥈', '🥉'][tier.rank - 1],
                    [
                      const Color(0xFFFFD700),
                      const Color(0xFFB0B0B0),
                      const Color(0xFFCD7F32)
                    ][tier.rank - 1])
                : Text('${tier.rank}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14)),
          ),
          Expanded(
            child: Text(tier.volumeRequired,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontFamily: _dmSans)),
          ),
          SizedBox(
            width: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(tier.reward,
                    style: const TextStyle(
                        color: _green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: _dmSans)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RULES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRule(RuleModel rule) {
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
                        color: _green,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans)),
                TextSpan(
                    text: rule.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans)),
              ]),
            ),
            if (rule.badge.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(rule.badge,
                  style: const TextStyle(
                      color: _green,
                      fontSize: 13,
                      fontFamily: _dmSans)),
            ],
            const SizedBox(height: 10),
            Text(rule.description,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontFamily: _dmSans,
                    height: 1.5)),
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
                                fontFamily: _dmSans,
                                height: 1.5)),
                      ),
                    ],
                  ),
                )),
            if (rule.footer.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(rule.footer,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: _dmSans,
                      height: 1.5)),
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
      child: Text(
        label,
        style: TextStyle(
            color: active ? _green : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: _dmSans),
      ),
    );
  }

  String _fmtVolume(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) {
      return v.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return v.toStringAsFixed(2);
  }

  String _fmtScheduleDate(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }
}
