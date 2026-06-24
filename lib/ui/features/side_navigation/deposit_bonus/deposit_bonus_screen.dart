import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';

const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _innerCard = Color(0xFF111111);
const _accent = Color(0xFFCCFF00);
const _font = 'DMSans';

// ── Scrolling ticker widget ──────────────────────────────────────────────────
class _TickerBanner extends StatefulWidget {
  final String text;
  const _TickerBanner({required this.text});
  @override
  State<_TickerBanner> createState() => _TickerBannerState();
}

class _TickerBannerState extends State<_TickerBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // 60px per second speed — smooth linear loop
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Duplicate text so seamless loop: "text     text     "
    final display = '${widget.text}               ${widget.text}               ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.volume_up_rounded, color: _accent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) {
                  return FractionalTranslation(
                    translation: Offset(-_ctrl.value, 0),
                    child: child,
                  );
                },
                child: RepaintBoundary(
                  child: Text(
                    display,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _font,
                      height: 1.33,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DepositBonusScreen extends StatefulWidget {
  const DepositBonusScreen({super.key});

  @override
  State<DepositBonusScreen> createState() => _DepositBonusScreenState();
}

class _DepositBonusScreenState extends State<DepositBonusScreen> {
  String _tab = 'bonus';
  bool _loading = true;
  bool _leaderboardOpen = true;
  Map<String, dynamic> _bonusStatus = {};
  List<dynamic> _leaderboard = [];
  List<dynamic> _depositHistory = [];
  Map<String, dynamic> _myStats = {};

  // Ticker
  int _tickerIndex = 0;
  Timer? _tickerTimer;

  // Countdown
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  final _endDate = DateTime.utc(2026, 6, 30, 23, 59, 59);

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _startCountdown();
    _tickerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _tickerIndex = (_tickerIndex + 1));
    });
  }

  void _startCountdown() {
    _remaining = _endDate.difference(DateTime.now().toUtc());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = _endDate.difference(DateTime.now().toUtc());
      if (mounted) setState(() => _remaining = r.isNegative ? Duration.zero : r);
    });
  }

  String _authToken() => GetStorage().read(PreferenceKey.accessToken) ?? '';

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_authToken()}',
      };

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    await Future.wait([_fetchBonus(), _fetchLeaderboard(), _fetchHistory(), _fetchMyStats()]);
    if (mounted) setState(() => _loading = false);
  }

  String _userId() {
    final obj = GetStorage().read(PreferenceKey.userObject);
    if (obj != null) {
      try { return obj['id']?.toString() ?? ''; } catch (_) {}
    }
    return '';
  }

  Future<void> _fetchBonus() async {
    try {
      final uid = _userId();
      final url = uid.isNotEmpty
          ? 'https://api.trapix.com/api/deposit-bonus/status?user_id=$uid'
          : 'https://api.trapix.com/api/deposit-bonus/status';
      final r = await http.get(Uri.parse(url), headers: _headers());
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        if (b['success'] == true) _bonusStatus = b;
      }
    } catch (_) {}
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final r = await http.get(Uri.parse('https://api.trapix.com/api/trade-earn/leaderboard'), headers: _headers());
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        // Always store volume_rewards, top_3_prizes, leaderboard_rewards regardless of success
        if (b['volume_rewards'] != null) _myStats['volume_rewards'] = b['volume_rewards'];
        if (b['top_3_prizes'] != null) _myStats['top_3_prizes'] = b['top_3_prizes'];
        if (b['leaderboard_rewards'] != null) _myStats['leaderboard_rewards'] = b['leaderboard_rewards'];
        if (b['success'] == true) {
          _leaderboard = b['leaderboard'] ?? [];
          if (mounted) setState(() => _leaderboardOpen = true);
        } else {
          if (mounted) setState(() => _leaderboardOpen = false);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchHistory() async {
    try {
      final uid = _userId();
      final url = uid.isNotEmpty
          ? 'https://api.trapix.com/api/deposit-bonus/history?user_id=$uid'
          : 'https://api.trapix.com/api/deposit-bonus/history';
      final r = await http.get(Uri.parse(url), headers: _headers());
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        if (b['success'] == true) _depositHistory = b['history'] ?? [];
      }
    } catch (_) {}
  }

  Future<void> _fetchMyStats() async {
    try {
      final uid = _userId();
      final url = uid.isNotEmpty
          ? 'https://api.trapix.com/api/trade-earn/my-stats?user_id=$uid'
          : 'https://api.trapix.com/api/trade-earn/my-stats';
      final r = await http.get(Uri.parse(url), headers: _headers());
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        _myStats = b;
        if (b['success'] == false && mounted) setState(() => _leaderboardOpen = false);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tickerTimer?.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String get _tickerText {
    if (_leaderboard.isNotEmpty) {
      final item = _leaderboard[_tickerIndex % _leaderboard.length];
      final name = item['email']?.toString() ?? item['user_id']?.toString() ?? 'User';
      return '${_maskUid(name)} has registered for the contest.';
    }
    return '302*****08 has registered for the contest.';
  }

  String _maskUid(String s) {
    if (s.contains('@')) {
      final parts = s.split('@');
      final name = parts[0];
      if (name.length <= 3) return '${name}***@${parts[1]}';
      return '${name.substring(0, 3)}***${name[name.length - 1]}@${parts[1]}';
    }
    if (s.length <= 6) return s;
    return '${s.substring(0, 3)}*****${s.substring(s.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Builder(builder: (context) {
        final bannerH = 240.0 + MediaQuery.of(context).padding.top;
        return Stack(
        children: [
          // ── Hero Banner — full width, fixed height ────────────────────────
          _buildBanner(),

          // ── Rounded container overlaps banner by 20px from bottom ─────────
          Column(
            children: [
              // Spacer = banner height minus 20px overlap
              SizedBox(height: bannerH - 20),

              // Rounded-top container with ticker + tabs + content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Ticker inside the container
                      _TickerBanner(text: _tickerText),

                      // Tabs row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            _tabBtn('bonus', 'Deposit Bonus'),
                            _tabBtn('leaderboard', 'Leaderboard'),
                            _tabBtn('history', 'History'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                            : RefreshIndicator(
                                color: _accent,
                                backgroundColor: _card,
                                onRefresh: _fetchAll,
                                child: ListView(
                                  padding: const EdgeInsets.fromLTRB(15, 12, 15, 15),
                                  children: [
                                    if (_tab == 'bonus') ..._buildBonusTab(),
                                    if (_tab == 'leaderboard') ..._buildLeaderboardTab(),
                                    if (_tab == 'history') ..._buildHistoryTab(),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      }),
    );
  }

  Widget _tabBtn(String id, String label) {
    final active = _tab == id;
    return GestureDetector(
      onTap: () => setState(() => _tab = id),
      child: Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white.withValues(alpha: 0.50),
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 16,
                fontFamily: _font,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BONUS TAB ──────────────────────────────────────────────────────────────
  List<Widget> _buildBonusTab() {
    final d = _remaining;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    final totalParticipants = _leaderboard.length > 0 ? _leaderboard.length : 231;

    return [
      // Countdown card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _innerCard,
          border: Border.all(color: _accent, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text('Contest Concludes in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15, fontFamily: _font)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _cdNum(_pad(days)), _cdUnit('D'),
                _cdNum(_pad(hours)), _cdUnit('H'),
                _cdNum(_pad(mins)), _cdUnit('M'),
                _cdNum(_pad(secs)), _cdUnit('S', last: true),
              ],
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, fontFamily: _font, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(text: '$totalParticipants', style: const TextStyle(color: _accent)),
                  const TextSpan(text: ' Users Participated!', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 15),

      // Deposit tier cards
      SizedBox(
        height: 140,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _tierCard('1st', '100%', '10 USDT → 10 USDT'),
            _tierCard('2nd', '200%', '10 USDT → 20 USDT'),
            _tierCard('3rd', '300%', '10 USDT → 30 USDT'),
          ],
        ),
      ),
      const SizedBox(height: 15),

      // Stats grid
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [
          _statCard('Your Deposit', '${_bonusStatus['your_deposits'] ?? 0}', Colors.white),
          _statCard('Total Deposited', '${double.tryParse(_bonusStatus['total_deposited']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} USDT', const Color(0xFF60A5FA)),
          _statCard('Available Bonus', '${_bonusStatus['available_bonus'] ?? 0}%', _accent),
          _statCard('Next Bonus', '${_bonusStatus['next_bonus'] ?? 'N/A'}', const Color(0xFFFBBF24)),
        ],
      ),
      const SizedBox(height: 15),

      // Next deposit target card (website: bonusStatus.next_deposit !== 'Max reached')
      if (_bonusStatus.isNotEmpty && _bonusStatus['next_deposit'] != 'Max reached')
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: _accent, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎯 ${_bonusStatus['example'] ?? ''}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: _font),
              ),
              const SizedBox(height: 6),
              Text(
                'Min: ${_bonusStatus['min_deposit'] ?? ''} • Leverage: ${_bonusStatus['max_leverage'] ?? ''} • Valid: ${_bonusStatus['bonus_valid_days'] ?? ''} days',
                style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: _font),
              ),
            ],
          ),
        ),
      if (_bonusStatus.isNotEmpty && _bonusStatus['next_deposit'] != 'Max reached')
        const SizedBox(height: 15),

      // Active Bonuses card
      _card2(
        title: 'Active Bonuses',
        child: Column(
          children: [
            const SizedBox(height: 8),
            if (_bonusStatus['active_bonuses'] == null || (_bonusStatus['active_bonuses'] as List).isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No active bonuses found.', style: TextStyle(color: Colors.white38, fontSize: 13, fontFamily: _font)),
              )
            else
              ...(_bonusStatus['active_bonuses'] as List).map((b) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${b['deposit']} Deposit • ${b['bonus']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: _font)),
                        const SizedBox(height: 4),
                        Text('Expires in ${b['expires_in']}', style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: _font)),
                      ],
                    ),
                    Text('${b['amount']}', style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: _font)),
                  ],
                ),
              )),
          ],
        ),
      ),
      const SizedBox(height: 15),

      // Event Rules
      _card2(
        title: 'Event Rules',
        child: Column(
          children: [
            const SizedBox(height: 12),
            ...['Minimum Deposit: 10 USDT', 'Maximum Leverage: 25x', 'Bonus Valid For 7 Days', 'Profit Withdraw Supported', 'Rewards unlock instantly by volume', 'Bonus cannot be withdrawn directly', 'Bonus for futures trading only', 'Profit from bonus can be withdrawn']
                .map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✓  ', style: TextStyle(color: _accent, fontSize: 13)),
                          Expanded(child: Text(r, style: const TextStyle(color: Colors.white60, fontSize: 13, fontFamily: _font))),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  // ── LEADERBOARD TAB ────────────────────────────────────────────────────────
  List<Widget> _buildLeaderboardTab() {
    final myRank = _myStats['rank'];
    final myVol = double.tryParse(_myStats['total_volume']?.toString() ?? '0') ?? 0;
    final top3 = _leaderboard.where((e) => (e['rank'] ?? 99) <= 3).toList();
    final rest = _leaderboard.where((e) => (e['rank'] ?? 99) > 3).toList();

    return [
      // My stats
      _card2(
        title: 'My Achievements',
        chip: 'Overall Ranking',
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              _achieveItem('My Ranking', myRank != null && myRank > 0 ? '#$myRank' : 'N/A'),
              _achieveItem('Trading Vol (USDT)', myVol.toStringAsFixed(2)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 15),

      if (_leaderboardOpen && _leaderboard.isNotEmpty) ...[
        _card2(
          title: 'Leaderboard',
          chip: 'Overall Ranking',
          child: Column(
            children: [
              // Podium
              if (top3.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (top3.length > 1) _podiumItem(top3.firstWhere((e) => e['rank'] == 2, orElse: () => top3[1]), scale: 1.0),
                      const SizedBox(width: 16),
                      _podiumItem(top3.firstWhere((e) => e['rank'] == 1, orElse: () => top3[0]), scale: 1.1, isFirst: true),
                      const SizedBox(width: 16),
                      if (top3.length > 2) _podiumItem(top3.firstWhere((e) => e['rank'] == 3, orElse: () => top3[2]), scale: 1.0),
                    ],
                  ),
                ),
              const Divider(color: Color(0xFF1E1E1E)),
              // Table
              if (rest.isNotEmpty)
                Table(
                  columnWidths: const {0: FixedColumnWidth(40), 1: FlexColumnWidth(), 2: FlexColumnWidth(), 3: FlexColumnWidth()},
                  children: [
                    TableRow(
                      children: ['#', 'UID', 'Vol', 'Total']
                          .map((h) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(h, style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: _font)),
                              ))
                          .toList(),
                    ),
                    ...rest.map((row) {
                      final uid = _maskUid(row['email']?.toString() ?? row['user_id']?.toString() ?? '');
                      final total = double.tryParse(row['total_volume']?.toString() ?? '0') ?? 0;
                      final spot = double.tryParse(row['spot_volume']?.toString() ?? '0') ?? 0;
                      return TableRow(
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A)))),
                        children: [
                          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('${row['rank']}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: _font))),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(uid, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: _font))),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(spot.toStringAsFixed(0), style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: _font))),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(total.toStringAsFixed(0), style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: _font))),
                        ],
                      );
                    }).toList(),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],

      // Trade & Earn Volume Reward (from myStats.volume_rewards)
      if (_myStats['volume_rewards'] != null)
        _card2(
          title: 'Trade & Earn Volume Reward',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Participants are divided into 3 tiers, based on trading volume achieved during the event:',
                style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: _font),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('TRADING VOLUME', style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: _font))),
                  Text('REWARD (USDT) WITHDRAWABLE', style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: _font)),
                ],
              ),
              const Divider(color: Color(0xFF1E1E1E)),
              ...() {
                final rewards = Map<String, dynamic>.from(_myStats['volume_rewards'] as Map);
                final myVol = double.tryParse(_myStats['total_volume']?.toString() ?? '0') ?? 0;
                final sorted = rewards.entries.toList()
                  ..sort((a, b) => double.parse(a.key).compareTo(double.parse(b.key)));
                return sorted.map((e) {
                  final vol = double.tryParse(e.key) ?? 0;
                  final reward = double.tryParse(e.value.toString()) ?? 0;
                  final completed = myVol >= vol;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: completed ? const Color(0xFF00C850).withValues(alpha: 0.2) : Colors.transparent,
                            border: completed ? null : Border.all(color: Colors.white24, style: BorderStyle.solid),
                          ),
                          child: completed ? const Icon(Icons.check, size: 10, color: Color(0xFF00C850)) : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${vol.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} USDT',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: _font)),
                        ),
                        Text('${reward.toStringAsFixed(0)} USDT',
                          style: TextStyle(color: completed ? const Color(0xFF00C850) : _accent, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: _font)),
                      ],
                    ),
                  );
                }).toList();
              }(),
            ],
          ),
        ),
      if (_myStats['volume_rewards'] != null) const SizedBox(height: 15),

      // Prize Pools
      _card2(
        title: 'Prize Pools',
        child: Column(
          children: [
            const SizedBox(height: 12),
            ...[
              ['🥇', 'iPhone 17'],
              ['🥈', 'iPad Air'],
              ['🥉', 'AirPods'],
              ['#4 - #10', '50 USDT'],
              ['#11 - #25', '25 USDT'],
              ['#26 - #50', '15 USDT'],
              ['#51 - #100', '10 USDT'],
            ].map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p[0], style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: _font)),
                      Text(p[1], style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: _font)),
                    ],
                  ),
                )),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  // ── HISTORY TAB ────────────────────────────────────────────────────────────
  List<Widget> _buildHistoryTab() {
    if (_depositHistory.isEmpty) {
      return [
        const SizedBox(height: 60),
        Center(child: Text('No deposit history found.', style: TextStyle(color: Colors.white38, fontFamily: _font))),
      ];
    }
    return _depositHistory.map((item) {
      final status = item['status'];
      final statusColor = status == 1 ? const Color(0xFF00C850) : status == 0 ? const Color(0xFFEAB308) : const Color(0xFFFF4444);
      final statusText = status == 1 ? 'Confirmed' : status == 0 ? 'Pending' : 'Failed';
      final amount = double.tryParse(item['dollar']?.toString() ?? item['amount']?.toString() ?? '0') ?? 0;
      final bonus = double.tryParse(item['bonus_earned']?.toString() ?? '0') ?? 0;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white54, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            _historyRow('Date', item['created_at']?.toString().substring(0, 19) ?? '', Colors.white),
            _historyRow('Amount', '\$${amount.toStringAsFixed(2)}', Colors.white),
            _historyRow('Coin', (item['coin_type']?.toString() ?? 'USDT').toUpperCase(), Colors.white),
            _historyRow('Status', statusText, statusColor),
            _historyRow('Bonus', '+${bonus.toStringAsFixed(2)}', const Color(0xFF00B052)),
          ],
        ),
      );
    }).toList();
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  Widget _buildBanner() {
    final bannerUrl = _bonusStatus['banner_image']?.toString() ?? '';
    final topPad = MediaQuery.of(context).padding.top;
    final bannerH = 240.0 + topPad;
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: bannerH,
          child: bannerUrl.isNotEmpty
              ? Image.network(
                  bannerUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, e, s) => Image.asset(
                    'assets/images/champion5.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    width: double.infinity,
                    height: bannerH,
                  ),
                )
              : Image.asset(
                  'assets/images/champion5.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: bannerH,
                ),
        ),
        // Back button over banner
        Positioned(
          top: topPad + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cdNum(String t) => Text(t, style: const TextStyle(color: _accent, fontSize: 36, fontWeight: FontWeight.w800, fontFamily: _font));
  Widget _cdUnit(String t, {bool last = false}) => Padding(
        padding: EdgeInsets.only(left: 3, right: last ? 0 : 12),
        child: Text(t, style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: _font)),
      );

  Widget _tierCard(String tier, String pct, String range) => Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _innerCard, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$tier Deposit', style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: _font)),
              Text(tier, style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: _font)),
            ]),
            const SizedBox(height: 6),
            Text(pct, style: const TextStyle(color: _accent, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: _font)),
            const Text('Trading Bonus', style: TextStyle(color: Colors.white38, fontSize: 12, fontFamily: _font)),
            const Divider(color: Color(0xFF2A2A2A)),
            Text(range, style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: _font)),
          ],
        ),
      );

  Widget _statCard(String label, String value, Color color) => Container(

        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _innerCard, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: _font, letterSpacing: 0.3)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: _font), overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _card2({required String title, String? chip, required Widget child}) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: _innerCard, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: _font)),
                if (chip != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
                    child: Text(chip, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: _font)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF1E1E1E)),
            child,
          ],
        ),
      );

  Widget _achieveItem(String label, String val) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: _font)),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: _font)),
          ],
        ),
      );

  Widget _podiumItem(Map e, {double scale = 1.0, bool isFirst = false}) {
    final uid = _maskUid(e['email']?.toString() ?? e['user_id']?.toString() ?? '');
    final vol = double.tryParse(e['total_volume']?.toString() ?? '0') ?? 0;
    final rank = e['rank'] ?? 0;
    final ringColor = rank == 1 ? const Color(0xFFFBBF24) : rank == 2 ? const Color(0xFF9CA3AF) : const Color(0xFFD97706);
    return Transform.scale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ringColor, width: 2.5), color: _innerCard),
            child: Center(child: Text(uid.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(height: 6),
          Text(uid, style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: _font), overflow: TextOverflow.ellipsis),
          Text(vol.toStringAsFixed(2), style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: _font)),
        ],
      ),
    );
  }

  Widget _historyRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 12,
                fontFamily: _font,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
            Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontFamily: _font,
                fontWeight: FontWeight.w400,
                height: 1.07,
              ),
            ),
          ],
        ),
      );
}

