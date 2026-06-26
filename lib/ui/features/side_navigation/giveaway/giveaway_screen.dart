import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/giveaway.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/ui/features/root/prefetch_service.dart';
import 'giveaway_detail_screen.dart';

const _bg    = Color(0xFF0B0B0F);
const _card  = Color(0xFF1A1A1A);
const _green = Color(0xFFC6FF00);
const _white = Colors.white;
const _muted = Color(0xFFA0A3BD);
const _font  = 'DMSans';

class GiveawayScreen extends StatefulWidget {
  const GiveawayScreen({super.key});
  @override
  State<GiveawayScreen> createState() => _GiveawayScreenState();
}

class _GiveawayScreenState extends State<GiveawayScreen> {
  List<Giveaway> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PrefetchService>()) {
      final cached = PrefetchService.to.giveawayList;
      if (cached.isNotEmpty) {
        _list = List.from(cached);
        _loading = false;
      }
    }
    _load();
  }

  void _load() {
    APIRepository().getGiveaways().then((r) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (r.success && r.data != null) {
            final raw = r.data is List ? r.data : (r.data['data'] ?? []);
            _list = (raw as List).map((e) => Giveaway.fromJson(e)).toList();
            if (Get.isRegistered<PrefetchService>()) PrefetchService.to.giveawayList.assignAll(_list);
          }
        });
      }
    }).catchError((_) { if (mounted) setState(() => _loading = false); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.arrow_back, color: _white, size: 22)),
        ),
        leadingWidth: 48,
        title: const Text('Giveaways', style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _font)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _list.isEmpty
              ? _empty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  children: [
                    // Header badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C5E00).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _green.withValues(alpha: 0.2)),
                        ),
                        child: const Text('🎁 Rewards Program', style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: _font)),
                      ),
                    ),
                    const Center(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: 'Trapix ', style: TextStyle(color: _white, fontSize: 26, fontWeight: FontWeight.w800, fontFamily: _font)),
                        TextSpan(text: 'Giveaways', style: TextStyle(color: _green, fontSize: 26, fontWeight: FontWeight.w800, fontFamily: _font)),
                      ])),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text('Complete tasks and win crypto rewards every week',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, fontSize: 13, fontFamily: _font, height: 1.5)),
                    ),
                    const SizedBox(height: 20),
                    ..._list.map((g) => _GiveawayCard(g: g, onTap: () => Get.to(() => GiveawayDetailScreen(id: g.id)))),
                  ],
                ),
    );
  }

  Widget _empty() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('🎁', style: TextStyle(fontSize: 48)),
      SizedBox(height: 12),
      Text('No active giveaways right now.', style: TextStyle(color: _muted, fontSize: 14, fontFamily: _font)),
    ]),
  );
}

class _GiveawayCard extends StatelessWidget {
  const _GiveawayCard({required this.g, required this.onTap});
  final Giveaway g;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diff = g.timeLeft;
    final days = diff.inDays.clamp(0, 9999);
    final hours = (diff.inHours % 24).clamp(0, 23);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _card.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: g.isEnded ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Banner
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: g.bannerImage != null
                ? _BannerImage(url: g.bannerImage!, height: 120)
                : _defaultBanner(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _statusChip(g),
                const Spacer(),
                Text(
                  '${(g.rewardAmount ?? 0).toStringAsFixed(0)} ${g.rewardLabel ?? ''}',
                  style: const TextStyle(color: _green, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: _font),
                ),
              ]),
              const SizedBox(height: 8),
              Text(g.title ?? '', style: const TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: _font)),
              const SizedBox(height: 8),
              Row(children: [
                Text('🔥 ${(g.participants ?? 0).toString()} joined', style: const TextStyle(color: _muted, fontSize: 12, fontFamily: _font)),
                const SizedBox(width: 16),
                Text('🏆 ${g.winnerCount ?? 0} winners', style: const TextStyle(color: _muted, fontSize: 12, fontFamily: _font)),
              ]),
              if (g.isLive && !diff.isNegative) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _green.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text('⏰ Ends in ${days}d ${hours}h',
                        style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: _font)),
                  ),
                ),
              ] else if (g.comingSoon == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _green.withValues(alpha: 0.2)),
                  ),
                  child: const Center(
                    child: Text('⏳ Starting Soon', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: _font)),
                  ),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _defaultBanner() => Container(
    width: double.infinity, height: 120,
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF1A3300), Color(0xFF0B0B0F)]),
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    child: const Center(child: Text('🎁', style: TextStyle(fontSize: 44))),
  );
}

// Fast-loading banner with instant shimmer placeholder and fade-in
class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.url, required this.height});
  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      // show shimmer instantly while loading
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1A2200), const Color(0xFF1A1A1A), const Color(0xFF1A2200)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
      errorBuilder: (_, e, s) => Container(
        width: double.infinity,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1A3300), Color(0xFF0B0B0F)]),
        ),
        child: const Center(child: Text('🎁', style: TextStyle(fontSize: 44))),
      ),
    );
  }
}

Widget _statusChip(Giveaway g) {
  if (g.comingSoon == true) {
    return _chip('⏳ SOON', const Color(0xFFC6FF00), const Color(0xFF4C5E00).withValues(alpha: 0.4), const Color(0xFFC6FF00).withValues(alpha: 0.3));
  } else if (g.isEnded) {
    return _chip('ENDED', const Color(0xFFFF6B6B), const Color(0xFFFF6B6B).withValues(alpha: 0.12), const Color(0xFFFF6B6B).withValues(alpha: 0.3));
  } else {
    return _chip('✅ LIVE', const Color(0xFF00E676), const Color(0xFF00C853).withValues(alpha: 0.15), const Color(0xFF00C853).withValues(alpha: 0.3));
  }
}

Widget _chip(String label, Color color, Color bg, Color border) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
  child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: _font, letterSpacing: 0.5)),
);
