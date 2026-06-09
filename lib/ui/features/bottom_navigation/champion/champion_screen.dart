import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/champion/champion_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/champion/popular_champion.dart';

class ChampionScreen extends StatefulWidget {
  const ChampionScreen({super.key});

  @override
  State<ChampionScreen> createState() => _ChampionScreenState();
}

class _ChampionScreenState extends State<ChampionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ChampionController _ctrl;

  static const _green = Color(0xFFCCFF00);

  // Fallback poster assets if banner_image is null
  static const _fallbackPosters = [
    'assets/images/champion1.png',
    'assets/images/champion2.png',
    'assets/images/champion3.png',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ctrl = Get.put(ChampionController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.fetchCompetitions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPopularContests(),
                  _buildPreviousContests(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_outlined,
                color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: TabBar(
        controller: _tabController,
        indicator: const BoxDecoration(color: Colors.transparent),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            height: 20 / 16, fontFamily: 'DMSans'),
        unselectedLabelStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400,
            height: 20 / 16, fontFamily: 'DMSans'),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Popular Contests'),
          Tab(text: 'Previous Contests'),
        ],
      ),
    );
  }

  // ── Popular Contests ───────────────────────────────────────────────────────
  Widget _buildPopularContests() {
    return Obx(() {
      if (_ctrl.isLoadingList.value) {
        return const Center(child: CircularProgressIndicator(color: _green));
      }

      final comps = _ctrl.competitions;

      // If API returned competitions, show them dynamically
      if (comps.isNotEmpty) {
        return RefreshIndicator(
          color: _green,
          onRefresh: _ctrl.fetchCompetitions,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: comps.length,
            separatorBuilder: (context, i) => const SizedBox(height: 16),
            itemBuilder: (context, i) => _buildApiCard(comps[i], i),
          ),
        );
      }

      // Fallback: show static poster assets
      return RefreshIndicator(
        color: _green,
        onRefresh: _ctrl.fetchCompetitions,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: _fallbackPosters.length,
          separatorBuilder: (context, i) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _buildFallbackCard(_fallbackPosters[i], i),
        ),
      );
    });
  }

  Widget _buildApiCard(ApiCompetition comp, int index) {
    final isComingSoon = comp.status == 'coming_soon' ||
        comp.status == 'comingSoon' ||
        comp.status == 'coming soon' ||
        comp.status == 'draft';
    return GestureDetector(
      onTap: () {
        if (isComingSoon) {
          _showComingSoonToast(comp.title);
          return;
        }
        _openDetail(comp, index);
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: comp.bannerImage != null && comp.bannerImage!.isNotEmpty
                ? Image.network(
                    comp.bannerImage!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, err, stack) =>
                        _fallbackImage(_fallbackPosters[index % _fallbackPosters.length]),
                  )
                : _fallbackImage(_fallbackPosters[index % _fallbackPosters.length]),
          ),
          if (isComingSoon)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackCard(String imagePath, int index) {
    return GestureDetector(
      onTap: () => _showComingSoonToast('This contest'),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _fallbackImage(imagePath),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage(String path) {
    return Image.asset(
      path,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, err, stack) => Container(
        height: 200,
        color: Colors.transparent,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: Colors.white24, size: 48),
        ),
      ),
    );
  }

  void _openDetail(ApiCompetition comp, int index) {
    Get.to(() => PopularChampionScreen(competitionId: comp.id));
  }

  void _showComingSoonToast(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title is coming soon. Stay tuned!',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Previous Contests ──────────────────────────────────────────────────────
  Widget _buildPreviousContests() {
    return Obx(() {
      if (_ctrl.isLoadingList.value) {
        return const Center(child: CircularProgressIndicator(color: _green));
      }

      final prev = _ctrl.competitions
          .where((c) => c.status == 'ended' || c.status == 'settled')
          .toList();

      if (prev.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                  border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.emoji_events_outlined, color: Color(0xFFCCFF00), size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Previous Contests',
                style: TextStyle(color: Color(0xFFCCFF00), fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'DMSans'),
              ),
              const SizedBox(height: 8),
              Text(
                'Previous contest results will\nappear here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13, fontFamily: 'DMSans', height: 1.5),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: _green,
        onRefresh: _ctrl.fetchCompetitions,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: prev.length,
          separatorBuilder: (context, i) => const SizedBox(height: 16),
          itemBuilder: (ctx, i) => _buildPreviousCard(prev[i]),
        ),
      );
    });
  }

  Widget _buildPreviousCard(ApiCompetition comp) {
    final statusColor = comp.status == 'settled' ? const Color(0xFF9B59B6) : const Color(0xFFE74C3C);
    final statusLabel = comp.status == 'settled' ? 'Settled' : 'Ended';

    String dateRange = '';
    if (comp.startAt != null && comp.endAt != null) {
      try {
        final start = DateTime.parse(comp.startAt!).toLocal();
        final end = DateTime.parse(comp.endAt!).toLocal();
        dateRange = '${start.day}/${start.month}/${start.year} – ${end.day}/${end.month}/${end.year}';
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => Get.to(() => PopularChampionScreen(competitionId: comp.id)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            if (comp.bannerImage != null && comp.bannerImage!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  comp.bannerImage!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, stack) => const SizedBox.shrink(),
                ),
              )
            else
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [Color(0xFF062806), Color(0xFF0B3D0B), Color(0xFF111111)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.emoji_events_outlined, color: Color(0xFFCCFF00), size: 48),
              ),

            // Footer row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comp.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DMSans',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DMSans',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dateRange.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      dateRange,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ],
                  if (comp.prizes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('🏆 ', style: TextStyle(fontSize: 13)),
                        Text(
                          comp.prizes.first.prizeDescription,
                          style: const TextStyle(
                            color: Color(0xFFF0B90B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DMSans',
                          ),
                        ),
                        Text(
                          ' Prize Pool',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontFamily: 'DMSans',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people_outline, color: Colors.white.withValues(alpha: 0.4), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${comp.participantsCount} Participants',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'View Results →',
                        style: TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ],
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
