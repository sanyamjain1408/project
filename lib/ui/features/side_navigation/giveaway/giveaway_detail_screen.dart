import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/giveaway.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:url_launcher/url_launcher.dart';

import 'giveaway_leaderboard_screen.dart';

const _bg    = Color(0xFF0B0B0F);
const _card  = Color(0xFF1A1A1A);
const _green = Color(0xFFC6FF00);
const _white = Colors.white;
const _muted = Color(0xFFA0A3BD);
const _font  = 'DMSans';

class GiveawayDetailScreen extends StatefulWidget {
  const GiveawayDetailScreen({super.key, required this.id});
  final dynamic id;

  @override
  State<GiveawayDetailScreen> createState() => _GiveawayDetailScreenState();
}

class _GiveawayDetailScreenState extends State<GiveawayDetailScreen> {
  Giveaway? _g;
  List<GiveawayTask> _tasks = [];
  bool _loading = true;
  bool _joining = false;
  final Set<int> _completingTasks = {};
  Set<int> _completedLocal = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    APIRepository().getGiveawayDetail(widget.id).then((r) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (r.success && r.data != null) {
          // Website reads: r.data?.data  where data = { giveaway:{}, tasks:[], joined:bool, completed_task_ids:[] }
          // Our ServerResponse already unwraps one level, so r.data = { giveaway:{}, tasks:[], joined:bool, completed_task_ids:[] }
          // OR r.data = { ...giveaway fields..., tasks:[] } (flat)
          if (r.data is! Map) return;
          final d = Map<String, dynamic>.from(r.data as Map);

          Map<String, dynamic> giveawayData;
          List rawTasks;
          bool joinedVal;
          List completedIds;

          if (d['giveaway'] != null) {
            // nested structure — same as website: data.giveaway, data.tasks, data.joined, data.completed_task_ids
            giveawayData = Map<String, dynamic>.from(d['giveaway'] as Map);
            rawTasks = d['tasks'] as List? ?? [];
            joinedVal = d['joined'] == true || d['joined'] == 1;
            completedIds = d['completed_task_ids'] as List? ?? [];
          } else {
            // flat structure
            giveawayData = d;
            rawTasks = d['tasks'] as List? ?? [];
            joinedVal = d['joined'] == true || d['joined'] == 1;
            completedIds = d['completed_task_ids'] as List? ?? [];
          }

          // Inject joined + completed_task_ids into giveaway map so Giveaway.fromJson picks them up
          giveawayData['joined'] = joinedVal;
          giveawayData['completed_task_ids'] = completedIds;

          _g = Giveaway.fromJson(giveawayData);
          _completedLocal = completedIds.map((e) => int.tryParse(e.toString()) ?? 0).toSet();
          _tasks = rawTasks
              .map((t) => GiveawayTask.fromJson(Map<String, dynamic>.from(t as Map)))
              .toList();
        }
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _join() async {
    if (_joining) return;
    setState(() => _joining = true);
    final r = await APIRepository().joinGiveaway(widget.id);
    if (!mounted) return;
    setState(() {
      _joining = false;
      if (r.success) {
        _g = Giveaway(
          id: _g!.id, title: _g!.title, slug: _g!.slug,
          description: _g!.description, bannerImage: _g!.bannerImage,
          status: _g!.status, comingSoon: _g!.comingSoon, endDate: _g!.endDate,
          winnerCount: _g!.winnerCount, rewardAmount: _g!.rewardAmount,
          rewardLabel: _g!.rewardLabel, coinIcon: _g!.coinIcon,
          coinSymbol: _g!.coinSymbol, participants: (_g!.participants ?? 0) + 1,
          joined: true, leaderboardEnabled: _g!.leaderboardEnabled,
          terms: _g!.terms, completedTaskIds: _g!.completedTaskIds,
        );
      } else {
        Get.snackbar('', r.message.isNotEmpty ? r.message : 'Failed to join',
            backgroundColor: Colors.red.withValues(alpha: 0.2),
            colorText: _white, duration: const Duration(seconds: 2));
      }
    });
  }

  void _completeTask(GiveawayTask task) async {
    if (_completingTasks.contains(task.id)) return;
    if (task.taskLink != null && task.taskLink!.isNotEmpty) {
      final uri = Uri.tryParse(task.taskLink!);
      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    _completingTasks.add(task.id);
    setState(() {});
    final r = await APIRepository().completeGiveawayTask(widget.id, task.id);
    if (!mounted) return;
    _completingTasks.remove(task.id);
    if (r.success) _completedLocal.add(task.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, elevation: 0, scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.arrow_back, color: _white, size: 22),
          ),
        ),
        leadingWidth: 48,
        title: const Text('Giveaway',
            style: TextStyle(color: _white, fontSize: 16,
                fontWeight: FontWeight.w700, fontFamily: _font)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _g == null
              ? const Center(child: Text('Could not load giveaway.',
                  style: TextStyle(color: _muted, fontFamily: _font)))
              : _body(),
    );
  }

  Widget _body() {
    final g = _g!;
    final diff = g.timeLeft;
    final isNeg = diff.isNegative;
    final days  = isNeg ? 0 : diff.inDays;
    final hours = isNeg ? 0 : (diff.inHours % 24);
    final mins  = isNeg ? 0 : (diff.inMinutes % 60);

    final doneCount = _tasks.where((t) => _completedLocal.contains(t.id)).length;
    final requiredTasks = _tasks.where((t) => t.required).toList();
    final allRequiredDone = requiredTasks.every((t) => _completedLocal.contains(t.id));

    // Website shows reward_amount directly as "Each" and "Per Winner" — it's already per-winner from backend
    final perWinner = g.rewardAmount ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
      children: [

        // ── BANNER ────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: (g.bannerImage != null && g.bannerImage!.isNotEmpty)
              ? Image.network(
                  g.bannerImage!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          width: double.infinity, height: 180,
                          color: const Color(0xFF1A2200),
                        ),
                  errorBuilder: (_, e, s) => _defaultBanner(),
                )
              : _defaultBanner(),
        ),
        const SizedBox(height: 14),

        // ── STATUS CHIP (small pill, not full-width) ──────────────
        Row(children: [_statusChip(g)]),
        const SizedBox(height: 10),

        // ── TITLE ─────────────────────────────────────────────────
        Text(g.title ?? '',
            style: const TextStyle(color: _white, fontSize: 22,
                fontWeight: FontWeight.w800, fontFamily: _font, height: 1.3)),
        const SizedBox(height: 14),

        // ── 3 STAT CARDS: Winners | Each | Joined ─────────────────
        Row(children: [
          Expanded(child: _statCard('🏆 Winners', '${g.winnerCount ?? 0}', Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('🪙 Each',
              '${_fmtNum(perWinner)} ${g.rewardLabel ?? ''}', _green)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('👥 Joined', '${g.participants ?? 0}', Colors.blue)),
        ]),
        const SizedBox(height: 10),

        // ── ENDS IN + PER WINNER ──────────────────────────────────
        if (g.isLive && !isNeg) ...[
          Row(children: [
            // Ends in
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('⏱ Ends in',
                      style: TextStyle(color: _muted, fontSize: 11, fontFamily: _font)),
                  const SizedBox(height: 4),
                  Text('${days}d ${hours}h ${mins}m',
                      style: const TextStyle(color: _green, fontSize: 19,
                          fontWeight: FontWeight.w800, fontFamily: _font)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            // Per Winner
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green.withValues(alpha: 0.16), _green.withValues(alpha: 0.03)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _green.withValues(alpha: 0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PER WINNER',
                      style: TextStyle(color: _green.withValues(alpha: 0.7), fontSize: 10,
                          fontFamily: _font, letterSpacing: 1, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(_fmtNum(perWinner),
                        style: const TextStyle(color: _white, fontSize: 19,
                            fontWeight: FontWeight.w800, fontFamily: _font)),
                    const SizedBox(width: 5),
                    if (g.coinIcon != null && g.coinIcon!.isNotEmpty)
                      Image.network(g.coinIcon!, width: 20, height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => const SizedBox.shrink())
                    else
                      Text(g.rewardLabel ?? '',
                          style: const TextStyle(color: _green, fontSize: 13,
                              fontWeight: FontWeight.w600, fontFamily: _font)),
                  ]),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),
        ],

        // ── ABOUT THIS GIVEAWAY ───────────────────────────────────
        if (g.description != null && g.description!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('About This Giveaway',
                  style: TextStyle(color: _white, fontSize: 15,
                      fontWeight: FontWeight.w700, fontFamily: _font)),
              const SizedBox(height: 10),
              Text(g.description!,
                  style: const TextStyle(color: Color(0xFFC8CAD8), fontSize: 13,
                      fontFamily: _font, height: 1.7)),
            ]),
          ),
          const SizedBox(height: 14),
        ],

        // ── TASKS ─────────────────────────────────────────────────
        if (_tasks.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('📋 Tasks',
                    style: TextStyle(color: _white, fontSize: 15,
                        fontWeight: FontWeight.w700, fontFamily: _font)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$doneCount/${_tasks.length} done',
                      style: const TextStyle(color: _green, fontSize: 11,
                          fontWeight: FontWeight.w700, fontFamily: _font)),
                ),
              ]),
              const SizedBox(height: 14),
              ..._tasks.map((t) => _TaskCard(
                task: t,
                completed: _completedLocal.contains(t.id),
                completing: _completingTasks.contains(t.id),
                canComplete: g.joined == true && !g.isEnded,
                onTap: () => _completeTask(t),
              )),
            ]),
          ),
          const SizedBox(height: 14),
        ],

        // ── TERMS ─────────────────────────────────────────────────
        if (g.terms != null && g.terms!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('📄 Terms & Conditions',
                  style: TextStyle(color: _green, fontSize: 14,
                      fontWeight: FontWeight.w700, fontFamily: _font)),
              const SizedBox(height: 8),
              Text(g.terms!,
                  style: const TextStyle(color: _muted, fontSize: 12,
                      fontFamily: _font, height: 1.6)),
            ]),
          ),
          const SizedBox(height: 14),
        ],

        // ── JOIN / YOU'RE IN / COMING SOON / ENDED ────────────────
        // Logic: comingSoon → soon card; ended → ended card;
        // joined → You're In; not joined & active → join button
        if (g.comingSoon == true) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_green.withValues(alpha: 0.16), _green.withValues(alpha: 0.03)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _green.withValues(alpha: 0.3)),
            ),
            child: const Column(children: [
              Text('⏳', style: TextStyle(fontSize: 32)),
              SizedBox(height: 6),
              Text('Coming Soon',
                  style: TextStyle(color: _green, fontWeight: FontWeight.w700,
                      fontSize: 15, fontFamily: _font)),
              SizedBox(height: 4),
              Text('This giveaway will go live shortly. Stay tuned!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 12, fontFamily: _font)),
            ]),
          ),
        ] else if (g.isEnded) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: const Center(
              child: Text('This giveaway has ended',
                  style: TextStyle(color: _muted, fontFamily: _font)),
            ),
          ),
        ] else if (g.joined == true) ...[
          // You're In card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.40)),
            ),
            child: const Column(children: [
              Text('🎉', style: TextStyle(fontSize: 32)),
              SizedBox(height: 8),
              Text("You're In!",
                  style: TextStyle(color: Color(0xFF00E676), fontSize: 20,
                      fontWeight: FontWeight.w800, fontFamily: _font)),
              SizedBox(height: 4),
              Text('Winners announced when giveaway ends',
                  style: TextStyle(color: _muted, fontSize: 13, fontFamily: _font)),
            ]),
          ),
        ] else ...[
          // Join button — disabled if required tasks not done
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _joining ? null
                  : (requiredTasks.isNotEmpty && !allRequiredDone) ? null
                  : _join,
              style: ElevatedButton.styleFrom(
                backgroundColor: (requiredTasks.isNotEmpty && !allRequiredDone)
                    ? Colors.white.withValues(alpha: 0.08)
                    : _green,
                foregroundColor: (requiredTasks.isNotEmpty && !allRequiredDone)
                    ? const Color(0xFF6B6B6B)
                    : Colors.black,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                disabledForegroundColor: const Color(0xFF6B6B6B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: _joining
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2.5))
                  : Text(
                      (requiredTasks.isNotEmpty && !allRequiredDone)
                          ? '🔒 Complete Tasks First'
                          : '🎁 Join Giveaway',
                      style: const TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 16, fontFamily: _font)),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // ── VIEW LEADERBOARD ──────────────────────────────────────
        if (g.leaderboardEnabled == true)
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton(
              onPressed: () => Get.to(() =>
                  GiveawayLeaderboardScreen(id: widget.id, giveaway: g)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _green.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('🏆 View Leaderboard',
                  style: TextStyle(color: _green, fontSize: 15,
                      fontWeight: FontWeight.w700, fontFamily: _font)),
            ),
          ),
      ],
    );
  }

  String _fmtNum(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  Widget _defaultBanner() => Container(
    height: 180,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          colors: [Color(0xFF1A3300), Color(0xFF0B0B0F)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    child: const Center(child: Text('🎁', style: TextStyle(fontSize: 60))),
  );

  Widget _statCard(String label, String val, Color valColor) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    decoration: BoxDecoration(
      color: _card, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _muted, fontSize: 10, fontFamily: _font)),
      const SizedBox(height: 3),
      Text(val,
          style: TextStyle(color: valColor, fontSize: 15,
              fontWeight: FontWeight.w700, fontFamily: _font),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ── Task icon mapper — mirrors website's renderIcon(t.icon) logic ─────────────
// Backend sends fa-* class strings like "fa-twitter", "fa-telegram-plane", etc.
String _taskEmoji(String? icon, String? name) {
  // If it's a real emoji (short, no letters), use as-is
  if (icon != null && icon.isNotEmpty && !icon.contains('fa') &&
      !icon.contains('-') && icon.runes.length <= 2) { return icon; }

  // Check icon string first (fa-* keys), then fallback to task name
  final v = (icon ?? '').toLowerCase();
  final n = (name ?? '').toLowerCase();
  final combined = '$v $n';

  if (combined.contains('twitter') || combined.contains('fa-x') || combined.contains(' x ')) return '🐦';
  if (combined.contains('telegram')) return '✈️';
  if (combined.contains('instagram')) return '📸';
  if (combined.contains('linkedin')) return '💼';
  if (combined.contains('youtube')) return '▶️';
  if (combined.contains('discord')) return '💬';
  if (combined.contains('facebook')) return '👍';
  if (combined.contains('tiktok')) return '🎵';
  if (combined.contains('reddit')) return '🤖';
  if (combined.contains('register') || combined.contains('signup') || combined.contains('sign-up')) return '📝';
  if (combined.contains('deposit') || combined.contains('trade')) return '💱';
  if (combined.contains('download') || combined.contains('app')) return '📱';
  if (combined.contains('email') || combined.contains('mail')) return '📧';
  if (combined.contains('subscribe') || combined.contains('bell')) return '🔔';
  if (combined.contains('visit') || combined.contains('website') || combined.contains('web') || combined.contains('globe')) return '🌐';
  if (combined.contains('follow')) return '👤';
  if (combined.contains('join')) return '🔗';
  if (combined.contains('share')) return '📤';
  if (combined.contains('like')) return '❤️';
  return '🎯';
}

// ── Status chip — small pill ──────────────────────────────────────────────────
Widget _statusChip(Giveaway g) {
  if (g.comingSoon == true) {
    return _pill('⏳ COMING SOON', const Color(0xFFC6FF00),
        const Color(0xFF4C5E00).withValues(alpha: 0.4),
        const Color(0xFFC6FF00).withValues(alpha: 0.3));
  } else if (g.isEnded) {
    return _pill('ENDED', const Color(0xFFFF6B6B),
        const Color(0xFFFF6B6B).withValues(alpha: 0.15),
        const Color(0xFFFF6B6B).withValues(alpha: 0.3));
  } else {
    return _pill('• LIVE NOW', const Color(0xFF00E676),
        const Color(0xFF00C853).withValues(alpha: 0.15),
        const Color(0xFF00C853).withValues(alpha: 0.3));
  }
}

Widget _pill(String label, Color color, Color bg, Color border) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border)),
  child: Text(label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800,
          fontFamily: _font, letterSpacing: 0.3)),
);

// ── Task Card ─────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task, required this.completed,
    required this.completing, required this.canComplete, required this.onTap,
  });
  final GiveawayTask task;
  final bool completed;
  final bool completing;
  final bool canComplete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFF00C853).withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? const Color(0xFF00C853).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(children: [
        // Left icon box
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: completed
                ? const Color(0xFF00C853).withValues(alpha: 0.15)
                : _green.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: completed
                ? const Text('✅', style: TextStyle(fontSize: 20))
                : Text(_taskEmoji(task.icon, task.name),
                    style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 10),

        // Name + description
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text(task.name ?? '',
                  style: const TextStyle(color: _white, fontSize: 13,
                      fontWeight: FontWeight.w600, fontFamily: _font),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (task.required) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('REQ',
                    style: TextStyle(color: Colors.red, fontSize: 9,
                        fontWeight: FontWeight.w800, fontFamily: _font)),
              ),
            ],
          ]),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(task.description!,
                style: const TextStyle(color: _muted, fontSize: 11, fontFamily: _font),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ])),
        const SizedBox(width: 8),

        // Right button
        if (completed)
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
                color: Color(0xFF00C853), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.black, size: 18),
          )
        else if (canComplete)
          GestureDetector(
            onTap: onTap,
            child: completing
                ? const SizedBox(width: 26, height: 26,
                    child: CircularProgressIndicator(color: _green, strokeWidth: 2.5))
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Go',
                        style: TextStyle(color: Colors.black, fontSize: 12,
                            fontWeight: FontWeight.w800, fontFamily: _font)),
                  ),
          )
        else
          Icon(Icons.lock_outline_rounded,
              color: _muted.withValues(alpha: 0.4), size: 20),
      ]),
    );
  }
}
