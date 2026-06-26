import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/champion/champion_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/champion/competition_deposit_history_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_controller.dart';

// ─── Data Models (replace with API models later) ──────────────────────────────

class ContestModel {
  final String title;
  final String prizePool;
  final String subtitle;
  final String heroImage; // asset path for hero background
  final DateTime? endsAt; // countdown target
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
  final int? userId;
  final String? prize;
  final String? prizeStatus;
  const LeaderboardEntry({
    required this.rank,
    required this.uid,
    required this.tradingVolume,
    this.userId,
    this.prize,
    this.prizeStatus,
  });
}

class EventScheduleItem {
  final String title;
  final DateTime dateTime;
  final bool completed;
  const EventScheduleItem({
    required this.title,
    required this.dateTime,
    this.completed = false,
  });
}

class PrizePoolTier {
  final int rank;
  final String volumeRequired;
  final String reward;
  final String? rewardIcon; // asset path, null = use emoji
  const PrizePoolTier({
    required this.rank,
    required this.volumeRequired,
    required this.reward,
    this.rewardIcon,
  });
}

class RuleModel {
  final String number; // e.g. "Rule 1"
  final String title;
  final String badge; // e.g. "💎 First Milestone Rewards (During Contest)"
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

// ─── Screen ───────────────────────────────────────────────────────────────────
class PopularChampionScreen extends StatefulWidget {
  final ContestModel? contest;
  final int? competitionId;
  const PopularChampionScreen({super.key, this.contest, this.competitionId});

  @override
  State<PopularChampionScreen> createState() => _PopularChampionScreenState();
}

class _PopularChampionScreenState extends State<PopularChampionScreen>
    with TickerProviderStateMixin {
  static const _green = Color(0xFFCCFF00);
  static const _bg = Color(0xFF111111);
  static const _card = Color(0xFF1A1A1A);
  static const _dmSans = 'DMSans';

  late ContestModel _contest;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  late AnimationController _circleSpinCtrl;
  late Animation<double> _circleSpinAnim;
  int _leaderboardPage = 0;
  static const _perPage = 5;
  int _pairTabIndex = 0;
  bool _apiLoading = false;
  bool _hasData = false;
  ChampionController? _ctrl;

  @override
  void initState() {
    super.initState();
    _circleSpinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _circleSpinAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -3.1416 / 2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -3.1416 / 2, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _circleSpinCtrl, curve: Curves.easeInOut));
    _circleSpinCtrl.repeat();
    if (widget.competitionId != null) {
      _ctrl = Get.find<ChampionController>();
      // Instantly render from cached list data — no loading wait
      final cached = _ctrl!.competitions.firstWhereOrNull(
          (c) => c.id == widget.competitionId);
      if (cached != null) {
        _contest = _apiToContest(cached, List.from(_ctrl!.leaderboard));
        _hasData = true;
        _apiLoading = false;
        _startTimer();
      } else {
        _apiLoading = true;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromApi());
    } else if (widget.contest != null) {
      _contest = widget.contest!;
      _hasData = true;
      _startTimer();
    }
  }

  Future<void> _loadFromApi() async {
    if (!mounted) return;
    final id = widget.competitionId;
    if (id == null) {
      setState(() => _apiLoading = false);
      return;
    }
    _ctrl ??= Get.find<ChampionController>();
    // Only show loading if no cached data yet
    if (!_hasData) setState(() => _apiLoading = true);
    // fetchDetail also calls fetchLeaderboard internally
    await _ctrl!.fetchDetail(id);
    if (!mounted) return;
    final detail = _ctrl!.currentDetail.value;
    // Read leaderboard AFTER fetchDetail completes (it includes fetchLeaderboard)
    final lb = List<ApiLeaderboardEntry>.from(_ctrl!.leaderboard);
    if (detail != null) {
      setState(() {
        _contest = _apiToContest(detail, lb);
        _hasData = true;
        _timer?.cancel();
        _startTimer();
        _apiLoading = false;
      });
    } else {
      setState(() => _apiLoading = false);
    }
  }

  double _getPairChange(String base, String quote) {
    try {
      if (!Get.isRegistered<LandingController>()) return 0;
      final lc = Get.find<LandingController>();
      final allPairs = [
        ...?lc.landingList.value.assetCoinPairs,
        ...?lc.landingList.value.hourlyCoinPairs,
      ];
      final match = allPairs.firstWhereOrNull((p) =>
          (p.childCoinName ?? '').toUpperCase() == base.toUpperCase() &&
          (p.parentCoinName ?? '').toUpperCase() == quote.toUpperCase());
      return match?.priceChange ?? 0;
    } catch (_) {
      return 0;
    }
  }

  ContestModel _apiToContest(ApiCompetition d, List<ApiLeaderboardEntry> lb) {
    final endAt = d.endAt != null ? DateTime.tryParse(d.endAt!) : null;
    final startAt = d.startAt != null ? DateTime.tryParse(d.startAt!) : null;

    // Website: pair_restriction = 'any' | 'specific_coin' | 'specific_pair'
    final pairs = <TradingPairModel>[];
    if (d.pairRestriction == 'specific_pair' &&
        d.restrictedPair != null &&
        d.restrictedPair!.isNotEmpty) {
      for (final p in d.restrictedPair!.split(',')) {
        pairs.add(TradingPairModel(symbol: p.trim(), changePercent: 0));
      }
    } else if (d.pairRestriction == 'specific_coin' &&
        d.restrictedCoin != null &&
        d.restrictedCoin!.isNotEmpty) {
      for (final c in d.restrictedCoin!.split(',')) {
        pairs.add(
          TradingPairModel(symbol: c.trim().toUpperCase(), changePercent: 0),
        );
      }
    } else {
      // 'any' or no restriction — show top default pairs like web
      pairs.add(TradingPairModel(symbol: 'BTC/USDT', changePercent: _getPairChange('BTC', 'USDT')));
      pairs.add(TradingPairModel(symbol: 'ETH/USDT', changePercent: _getPairChange('ETH', 'USDT')));
    }

    final prizes = d.prizes;
    final prizeTiers = prizes
        .map(
          (p) => PrizePoolTier(
            rank: p.rank,
            volumeRequired: d.minVolume != null
                ? '${d.minVolume!.toStringAsFixed(0)} USDT'
                : '-',
            reward: p.prizeDescription,
            rewardIcon: p.prizeType == 'physical' ? 'physical' : null,
          ),
        )
        .toList();

    final lbEntries = lb
        .map(
          (e) => LeaderboardEntry(
            rank: e.rank,
            uid: e.nickname,
            tradingVolume: e.totalVolume,
            userId: e.userId,
            prize: e.prize,
            prizeStatus: e.prizeStatus,
          ),
        )
        .toList();

    // Build schedule from start/end
    final schedule = <EventScheduleItem>[];
    if (startAt != null) {
      schedule.add(
        EventScheduleItem(
          title: 'Contest Launch',
          dateTime: startAt,
          completed: startAt.isBefore(DateTime.now()),
        ),
      );
    }
    if (endAt != null) {
      schedule.add(
        EventScheduleItem(
          title: 'Contest Ends',
          dateTime: endAt,
          completed: endAt.isBefore(DateTime.now()),
        ),
      );
      schedule.add(
        EventScheduleItem(
          title: 'Rewards Distribution',
          dateTime: endAt.add(const Duration(days: 1)),
          completed: endAt
              .add(const Duration(days: 1))
              .isBefore(DateTime.now()),
        ),
      );
    }

    final prizeText = prizes.isNotEmpty ? prizes.first.prizeDescription : '';
    final topPrize =
        prizes
            .where((p) => p.rank == 1)
            .map((p) => p.prizeDescription)
            .firstOrNull ??
        prizeText;

    return ContestModel(
      title: d.title.toUpperCase(),
      prizePool: topPrize.isNotEmpty ? topPrize : 'Prize Pool',
      subtitle: '${d.participantsCount} Participants',
      heroImage: d.bannerImage ?? 'assets/images/champion4.png',
      endsAt: endAt,
      participantsCount: d.participantsCount,
      marqueeText: d.participantsCount > 0
          ? '${d.participantsCount} users have registered for the contest'
          : null,
      myAchievement: MyAchievementModel(
        ranking: d.myRank != null ? '#${d.myRank}' : 'N/A',
        tradingVolume: d.myVolume ?? 0.0,
        isRegistered: d.joined,
      ),
      tradingPairs: pairs,
      leaderboard: lbEntries,
      schedule: schedule,
      prizeTiers: prizeTiers,
      rules: d.rules
          .asMap()
          .entries
          .map(
            (e) => RuleModel(
              number: 'Rule ${e.key + 1}',
              title: e.value.title,
              badge: e.value.badge ?? '',
              description: e.value.description ?? '',
              bullets: e.value.bullets,
              footer: e.value.footer ?? '',
            ),
          )
          .toList(),
    );
  }

  void _startTimer() {
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
    _circleSpinCtrl.dispose();
    super.dispose();
  }

  // ── Helper: pad 2 digits ────────────────────────────────────────────────────
  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _apiLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFCCFF00)),
            )
          : !_hasData
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // ── Hero image (full width, no radius) ──────────────
                  _buildHero(),

                  // ── Curved container starts here ────────────────────
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Marquee inside curved container
                          if (_contest.marqueeText != null) ...[
                            _buildMarquee(),
                            const SizedBox(height: 20),
                          ],
                          _buildCountdown(),
                          const SizedBox(height: 20),
                          _buildMyAchievements(),
                          const SizedBox(height: 20),
                          _buildTradingPairs(),
                          const SizedBox(height: 20),
                          _buildLeaderboard(),
                          const SizedBox(height: 20),
                          _buildEventSchedule(),
                          const SizedBox(height: 20),
                          _buildPrizePools(),
                          const SizedBox(height: 20),
                          ..._defaultRules().map(_buildRule),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: Color(0xFFCCFF00),
            size: 56,
          ),
          const SizedBox(height: 16),
          const Text(
            'No contest data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: _dmSans,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadFromApi,
            child: const Text(
              'Retry',
              style: TextStyle(color: Color(0xFFCCFF00), fontFamily: _dmSans),
            ),
          ),
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
        // Background image — tall, full width
        SizedBox(
          height: 300,
          width: double.infinity,
          child: _contest.heroImage.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: _contest.heroImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 300,
                  placeholder: (context, url) =>
                      Container(height: 300, color: const Color(0xFF111111)),
                  errorWidget: (context, url, err) =>
                      Container(height: 300, color: const Color(0xFF111111)),
                )
              : Image.asset(
                  _contest.heroImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, stack) =>
                      Container(height: 300, color: const Color(0xFF111111)),
                ),
        ),
        // Bottom fade so curved container blends in
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFF0B0B0F)],
              ),
            ),
          ),
        ),
        // Back button + timer icon
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.arrow_back_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () {
                      if (widget.competitionId != null) {
                        Get.to(() => CompetitionDepositHistoryScreen(
                              competitionId: widget.competitionId!,
                            ));
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _circleSpinAnim,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _circleSpinAnim.value,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/icons/time.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, err, stack) => const Icon(
                          Icons.history_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Title + prize text (bottom-left of hero)
        Positioned(
          bottom: 100,
          left: 20,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF00E6FF),
                    Color(0xFFCCFF00),
                    Color(0xFF77D215),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: Text(
                  _contest.title,
                  style: const TextStyle(
                    color: Colors.white, // Required for ShaderMask
                    fontSize: 20,
                    height: 24 / 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _contest.prizePool,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  fontFamily: _dmSans,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _contest.subtitle,
                style: const TextStyle(
                  color: Color(0xFFCCFF00),
                  fontSize: 16,
                  height: 1,
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
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.volume_up_outlined, color: _green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _contest.marqueeText!,
              style: const TextStyle(
                color: _green,
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w400,
                fontFamily: _dmSans,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _green, width: 2),
        ),
        child: Column(
          children: [
            const Text(
              'Contest Concludes in',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 20 / 16,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _countUnit(_pad(d), 'D'),
                SizedBox(width: 20),
                _countUnit(_pad(h), 'H'),
                SizedBox(width: 20),
                _countUnit(_pad(m), 'M'),
                SizedBox(width: 20),
                _countUnit(_pad(s), 'S'),
              ],
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${_contest.participantsCount} ',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: _dmSans,
                    ),
                  ),
                  const TextSpan(
                    text: 'Users Participated!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: _dmSans,
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

  Widget _countUnit(String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _green,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            fontFamily: _dmSans,
            height: 40 / 30,
          ),
        ),
        const SizedBox(width: 2),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _dmSans,
              height: 20 / 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _countSep() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      ':',
      style: TextStyle(
        color: Colors.white54,
        fontSize: 24,
        fontWeight: FontWeight.w300,
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // MY ACHIEVEMENTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMyAchievements() {
    final ach = _contest.myAchievement;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'My Achievements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 20 / 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
                const SizedBox(width: 10),
                _greenTag('Overall Ranking'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Ranking',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ach?.ranking ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 20 / 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: _dmSans,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Trading Vol(USDT)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ach != null
                            ? ach.tradingVolume.toStringAsFixed(2)
                            : '0.00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 20 / 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: _dmSans,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ach?.isRegistered == true
                    ? null
                    : () async {
                        if (widget.competitionId != null && _ctrl != null) {
                          final ok = await _ctrl!.joinCompetition(widget.competitionId!);
                          if (ok && mounted) await _loadFromApi();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  ach?.isRegistered == true ? 'Registered ✓' : 'Register Now',
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 20 / 16,
                    fontFamily: _dmSans,
                  ),
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
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Trading Pairs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 20 / 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _pairTabIndex = 0),
                  child: _greenTag('Spot', active: _pairTabIndex == 0),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Figma: outer container 362x120, inner pair cards 151x40
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: _contest.tradingPairs.map((p) {
                  final isPos = p.changePercent >= 0;
                  final pctColor = isPos ? const Color(0xFF00B052) : Colors.redAccent;
                  return Expanded(
                    child: Container(
                      height: 40,
                      margin: EdgeInsets.only(
                        right: p == _contest.tradingPairs.last ? 0 : 12,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              p.symbol,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: _dmSans,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${isPos ? '+' : ''}${p.changePercent.toStringAsFixed(2)}%',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: pctColor,
                                fontSize: 13,
                                fontFamily: _dmSans,
                                fontWeight: FontWeight.w400,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
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
    final all = _contest.leaderboard;
    final pages = (all.length / _perPage).ceil();
    final start = _leaderboardPage * _perPage;
    final slice = all.skip(start).take(_perPage).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 20 / 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
                const SizedBox(width: 10),
                _greenTag('Overall Ranking'),
              ],
            ),

            const SizedBox(height: 20),

            // Header Row
            Row(
              children: [
                 SizedBox(
                  width: 50,
                  child: Text(
                    'Ranking',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                 Expanded(
                  flex: 3,
                  child: Text(
                    'UID',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                    ),
                  ),
                ),

                 Expanded(
                  flex: 4,
                  child: Text(
                    'Cumulative Trading\nVol(USDT)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Data Rows
            ...slice.map((e) => _leaderboardRow(e)),

            const SizedBox(height: 40),

            // Pagination
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageBtn(
                  icon: Icons.chevron_left_rounded,
                  enabled: _leaderboardPage > 0,
                  onTap: () => setState(() => _leaderboardPage--),
                ),

                const SizedBox(width: 30),

                Text(
                  '${_leaderboardPage + 1}/$pages',
                  style:  TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 20 / 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),

                const SizedBox(width: 30),

                _pageBtn(
                  icon: Icons.chevron_right_rounded,
                  enabled: _leaderboardPage < pages - 1,
                  onTap: () => setState(() => _leaderboardPage++),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Center(
              child: Text(
                'Last updated: ${_fmtNow()}',
                style:  TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: _dmSans,
                ),
              ),
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
        width: 34,
        child: Text(
          '${e.rank}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            fontFamily: _dmSans,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(width: 34, child: rankWidget),

          const SizedBox(width: 12),

          Expanded(
            flex: 3,
            child: Text(
              e.userId == gUserRx.value.id ? '${e.uid} (You)' : e.uid,
              style: TextStyle(
                color: e.userId == gUserRx.value.id
                    ? Colors.white
                    : Colors.white,
                fontSize: 12,
                height: 16 / 12,
                fontWeight: e.userId == gUserRx.value.id
                    ? FontWeight.w400
                    : FontWeight.w400,
                fontFamily: _dmSans,
              ),
            ),
          ),

          Expanded(
            flex: 4,
            child: Text(
              _fmtVolume(e.tradingVolume),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w400,
                fontFamily: _dmSans,
              ),
            ),
          ),

          // if (e.prize != null) ...[
          //   const SizedBox(width: 8),
          //   Text(
          //     e.prize!,
          //     style: const TextStyle(
          //       color: Color(0xFFCCFF00),
          //       fontSize: 11,
          //       fontFamily: _dmSans,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _medalBadge(String emoji, Color color) {
    // rank 1=gold, 2=silver, 3=bronze — web-style circular badge with ribbon icon
    final List<Color> gradColors = color == const Color(0xFFFFD700)
        ? [const Color(0xFFFFE066), const Color(0xFFB8860B)]
        : color == const Color(0xFFB0B0B0)
            ? [const Color(0xFFE0E0E0), const Color(0xFF808080)]
            : [const Color(0xFFE8A060), const Color(0xFF7B3F00)];
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)],
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _pageBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
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
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white24,
          size: 22,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EVENT SCHEDULE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEventSchedule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Schedule',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 20 / 16,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans,
              ),
            ),
            const SizedBox(height: 20),
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
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.completed
                        ? _green.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: item.completed ? _green : Colors.white24,
                      width: 1.5,
                    ),
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
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                    ),
                  ),
                  Text(
                    _fmtScheduleDate(item.dateTime),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
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

  // ══════════════════════════════════════════════════════════════════════════
  // PRIZE POOLS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPrizePools() {
    // Hardcoded — Figma exact design
    const rows = [
      (rank: 1, volume: '10,00,000 USDT', reward: 'Iphone 17',  icon: Icons.smartphone),
      (rank: 2, volume: '5,00,000 USDT',  reward: 'Ipad Air',   icon: Icons.tablet_mac),
      (rank: 3, volume: '2,50,000 USDT',  reward: 'Airpods',    icon: Icons.headphones),
    ];

    final medalEmoji  = ['🥇', '🥈', '🥉'];
    final medalGrad   = [
      [const Color(0xFFFFE066), const Color(0xFFB8860B)],
      [const Color(0xFFE0E0E0), const Color(0xFF808080)],
      [const Color(0xFFE8A060), const Color(0xFF7B3F00)],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Prize Pools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: _dmSans,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            const Text(
              'Participants are divided into 3 tiers, based on trading volume achieved during the event:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: _dmSans,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                // "Price" label above medal col
                SizedBox(
                  width: 44,
                  child: Text(
                    'Price',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: _dmSans,
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Volume Required',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: _dmSans,
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                ),
                Text(
                  'Rewards',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontFamily: _dmSans,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Data rows
            ...rows.map((t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  // Medal badge
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: medalGrad[t.rank - 1],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(color: medalGrad[t.rank - 1][0].withValues(alpha: 0.5), blurRadius: 6)],
                    ),
                    child: Center(child: Text(medalEmoji[t.rank - 1], style: const TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 26),
                  // Volume
                  Expanded(
                    child: Text(
                      t.volume,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: _dmSans,
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                      ),
                    ),
                  ),
                  // Device icon + reward
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        t.reward,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontFamily: _dmSans,
                          fontWeight: FontWeight.w700,
                          height: 1.33,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }


  // ══════════════════════════════════════════════════════════════════════════
  // RULES
  // ══════════════════════════════════════════════════════════════════════════
  List<RuleModel> _defaultRules() => const [
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
      footer:
          '👉 Compete with traders and secure your position among the top winners.',
    ),
  ];

  Widget _buildRule(RuleModel rule) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${rule.number} : ',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: _dmSans,
                    ),
                  ),
                  TextSpan(
                    text: rule.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: _dmSans,
                    ),
                  ),
                ],
              ),
            ),
            if (rule.badge.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                rule.badge,
                style:  TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 16 / 12,
                  fontFamily: _dmSans,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              rule.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: _dmSans,
                height: 16/12,
              ),
            ),
            const SizedBox(height: 20),
            ...rule.bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: _dmSans,
                        height: 16 / 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                          height: 16 / 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (rule.footer.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                rule.footer,
                style:  TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: _dmSans,
                  height: 16/12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _greenTag(String label, {bool active = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: active ? _green : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? Colors.transparent : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active
              ? Color(0xFF000000)
              : Color(0xFF000000).withOpacity(0.5),
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w400,
          fontFamily: _dmSans,
        ),
      ),
    );
  }

  String _fmtVolume(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) {
      return v
          .toStringAsFixed(2)
          .replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return v.toStringAsFixed(2);
  }

  String _fmtNow() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)} ${_pad(now.hour)}:${_pad(now.minute)}';
  }

  String _fmtScheduleDate(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }
}
