import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/giveaway.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';

const _bg    = Color(0xFF0B0B0F);
const _card  = Color(0xFF1A1A1A);
const _green = Color(0xFFC6FF00);
const _white = Colors.white;
const _muted = Color(0xFFA0A3BD);
const _font  = 'DMSans';

class GiveawayLeaderboardScreen extends StatefulWidget {
  const GiveawayLeaderboardScreen({super.key, required this.id, this.giveaway});
  final dynamic id;
  final Giveaway? giveaway;

  @override
  State<GiveawayLeaderboardScreen> createState() => _GiveawayLeaderboardScreenState();
}

class _GiveawayLeaderboardScreenState extends State<GiveawayLeaderboardScreen> {
  List<GiveawayEntry> _entries = [];
  List<GiveawayWinner> _winners = [];
  bool _loadingEntries = true;
  bool _loadingWinners = true;
  bool _showLeaderboard = true; // true = leaderboard tab, false = winners tab

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _loadWinners();
  }

  void _loadEntries() {
    APIRepository().getGiveawayLeaderboard(widget.id).then((r) {
      if (!mounted) return;
      setState(() {
        _loadingEntries = false;
        if (r.success && r.data != null) {
          final raw = r.data is List ? r.data : (r.data['data'] ?? []);
          _entries = (raw as List)
              .map((e) => GiveawayEntry.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      });
    }).catchError((_) { if (mounted) setState(() => _loadingEntries = false); });
  }

  void _loadWinners() {
    APIRepository().getGiveawayWinners(widget.id).then((r) {
      if (!mounted) return;
      setState(() {
        _loadingWinners = false;
        if (r.success && r.data != null) {
          final raw = r.data is List ? r.data : (r.data['data'] ?? []);
          _winners = (raw as List)
              .map((e) => GiveawayWinner.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      });
    }).catchError((_) { if (mounted) setState(() => _loadingWinners = false); });
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
        title: Text(widget.giveaway?.title ?? 'Leaderboard',
            style: const TextStyle(color: _white, fontSize: 15,
                fontWeight: FontWeight.w700, fontFamily: _font)),
      ),
      body: Column(children: [
        // ── HEADER: trophy + title + participants ──────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(children: [
            const Text('🏆', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 4),
            Text(widget.giveaway?.title ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _white, fontSize: 19,
                    fontWeight: FontWeight.w800, fontFamily: _font)),
            const SizedBox(height: 4),
            Text.rich(TextSpan(children: [
              TextSpan(
                text: '${_entries.length}',
                style: const TextStyle(color: _green, fontWeight: FontWeight.w700,
                    fontSize: 13, fontFamily: _font),
              ),
              const TextSpan(
                text: ' participants',
                style: TextStyle(color: _muted, fontSize: 13, fontFamily: _font),
              ),
            ])),
            const SizedBox(height: 14),

            // ── PILL TAB SWITCHER ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(children: [
                _tabBtn('🥇 Leaderboard', _showLeaderboard,
                    () => setState(() => _showLeaderboard = true)),
                _tabBtn('🎁 Winners', !_showLeaderboard,
                    () => setState(() => _showLeaderboard = false)),
              ]),
            ),
            const SizedBox(height: 12),
          ]),
        ),

        // ── CONTENT ───────────────────────────────────────────────
        Expanded(
          child: _showLeaderboard
              ? (_loadingEntries
                  ? const Center(child: CircularProgressIndicator(color: _green))
                  : _entriesList())
              : (_loadingWinners
                  ? const Center(child: CircularProgressIndicator(color: _green))
                  : _winnersList()),
        ),
      ]),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? _green : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: active ? Colors.black : _muted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                fontFamily: _font,
              )),
        ),
      ),
    ),
  );

  Widget _entriesList() {
    if (_entries.isEmpty) {
      return const Center(
        child: Text('No participants yet. Be the first!',
            style: TextStyle(color: _muted, fontFamily: _font)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      itemCount: _entries.length,
      itemBuilder: (_, i) {
        final e = _entries[i];
        final rank = i + 1;
        final top3 = rank <= 3;

        final rankBg = rank == 1 ? _green
            : rank == 2 ? const Color(0xFFB0BEC5)
            : rank == 3 ? const Color(0xFFCD7F32)
            : Colors.white.withValues(alpha: 0.06);
        final rankTextColor = top3 ? Colors.black : _muted;

        final borderColor = rank == 1 ? _green.withValues(alpha: 0.4)
            : rank == 2 ? const Color(0xFFB0BEC5).withValues(alpha: 0.3)
            : rank == 3 ? const Color(0xFFCD7F32).withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.06);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: rank == 1
                ? _green.withValues(alpha: 0.07)
                : _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(children: [
            // Rank circle
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: rankBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$rank',
                    style: TextStyle(color: rankTextColor,
                        fontWeight: FontWeight.w800, fontSize: 13,
                        fontFamily: _font)),
              ),
            ),
            const SizedBox(width: 10),

            // Avatar circle with initial
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _avatarColor(e.username ?? 'U'),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(_initial(e.username ?? 'U'),
                    style: const TextStyle(color: Colors.black,
                        fontWeight: FontWeight.w800, fontSize: 16,
                        fontFamily: _font)),
              ),
            ),
            const SizedBox(width: 12),

            // Username
            Expanded(
              child: Text(e.username ?? 'Anonymous',
                  style: TextStyle(color: _white, fontSize: 14,
                      fontWeight: top3 ? FontWeight.w700 : FontWeight.w600,
                      fontFamily: _font),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),

            // Medal on right
            if (top3) ...[
              const SizedBox(width: 8),
              Text(_medal(rank), style: const TextStyle(fontSize: 20)),
            ],
          ]),
        );
      },
    );
  }

  Widget _winnersList() {
    if (_winners.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🎁', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          const Text('Winners announced when giveaway ends.',
              style: TextStyle(color: _muted, fontSize: 14, fontFamily: _font)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      itemCount: _winners.length,
      itemBuilder: (_, i) {
        final w = _winners[i];
        final rank = w.rank ?? (i + 1);
        final isPaid = w.rewardStatus == 'distributed';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _green.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            // Rank circle (green)
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
              child: Center(
                child: Text('$rank',
                    style: const TextStyle(color: Colors.black,
                        fontWeight: FontWeight.w800, fontSize: 14,
                        fontFamily: _font)),
              ),
            ),
            const SizedBox(width: 10),

            // Avatar
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _avatarColor(w.username ?? 'U'),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(_initial(w.username ?? 'U'),
                    style: const TextStyle(color: Colors.black,
                        fontWeight: FontWeight.w800, fontSize: 16,
                        fontFamily: _font)),
              ),
            ),
            const SizedBox(width: 12),

            // Username + reward
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.username ?? 'Anonymous',
                  style: const TextStyle(color: _white, fontSize: 14,
                      fontWeight: FontWeight.w700, fontFamily: _font),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('🎁 ${(w.rewardAmount ?? 0).toStringAsFixed(2)} ${widget.giveaway?.rewardLabel ?? ''}',
                  style: const TextStyle(color: _green, fontSize: 11,
                      fontWeight: FontWeight.w600, fontFamily: _font)),
            ])),
            const SizedBox(width: 8),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPaid
                    ? const Color(0xFF00C853).withValues(alpha: 0.15)
                    : _green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(isPaid ? '✅ Paid' : 'Pending',
                  style: TextStyle(
                    color: isPaid ? const Color(0xFF00E676) : _green,
                    fontSize: 10, fontWeight: FontWeight.w700, fontFamily: _font,
                  )),
            ),
          ]),
        );
      },
    );
  }

  String _initial(String name) => name.isNotEmpty ? name[0].toUpperCase() : 'U';

  String _medal(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '';
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFFC6FF00), Color(0xFFFF6F61), Color(0xFF42A5F5),
      Color(0xFFAB47BC), Color(0xFF26A69A), Color(0xFFFFA726),
      Color(0xFFEC407A), Color(0xFF7E57C2),
    ];
    int hash = 0;
    for (final c in name.codeUnits) { hash = c + ((hash << 5) - hash); }
    return colors[hash.abs() % colors.length];
  }
}
