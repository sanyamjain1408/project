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
    return GestureDetector(
      onTap: () => _openDetail(comp, index),
      child: ClipRRect(
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
    );
  }

  Widget _buildFallbackCard(String imagePath, int index) {
    return GestureDetector(
      onTap: () => Get.to(() => const PopularChampionScreen()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _fallbackImage(imagePath),
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

  // ── Previous Contests ──────────────────────────────────────────────────────
  Widget _buildPreviousContests() {
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
              border: Border.all(
                  color: _green.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: Color(0xFFCCFF00), size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Coming Soon',
            style: TextStyle(
                color: Color(0xFFCCFF00),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans'),
          ),
          const SizedBox(height: 8),
          Text(
            'Previous contest results will\nappear here',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                fontFamily: 'DMSans',
                height: 1.5),
          ),
        ],
      ),
    );
  }
}
