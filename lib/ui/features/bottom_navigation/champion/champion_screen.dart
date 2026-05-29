import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/champion/popular_champion.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/champion/champion_third_section.dart';

class ChampionScreen extends StatefulWidget {
  const ChampionScreen({super.key});

  @override
  State<ChampionScreen> createState() => _ChampionScreenState();
}

class _ChampionScreenState extends State<ChampionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _green = Color(0xFFCCFF00);
  static const _bg    = Color(0xFF0B0B0F);
  static const _card  = Color(0xFF1A1A1A);

  static const _popularPosters = [
    'assets/images/champion1.png',
    'assets/images/champion2.png',
    'assets/images/champion3.png',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  // ── Header ─────────────────────────────────────────────────────────────────
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

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return  Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.transparent,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 20/16,
              fontFamily: 'DMSans'),
          unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 20/16,
              fontFamily: 'DMSans'),
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _popularPosters.length,
      separatorBuilder: (context, i) => const SizedBox(height: 16),
      itemBuilder: (context, i) => _buildPosterCard(_popularPosters[i], i),
    );
  }

  Widget _buildPosterCard(String imagePath, int index) {
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          Get.to(() => const ChampionThirdSection());
        } else {
          Get.to(() => const PopularChampionScreen());
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          imagePath,
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
        ),
      ),
    );
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
              color: _card,
              shape: BoxShape.circle,
              border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
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
