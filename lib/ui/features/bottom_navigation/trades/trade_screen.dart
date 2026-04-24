import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/ui/p2p_trade_screen.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';

import 'spot_trade/spot_trade_screen.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen>
    with SingleTickerProviderStateMixin {
  // TradeController removed — it had length=2 which conflicted with our 5 tabs
  late final TabController _tabController;

  static const List<String> _tabs = ['Swap', 'Spot', 'Future', 'Earn', 'P2P'];
  int _selectedTab = 1; // default: Spot

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 1,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });

    // Handle deep-link navigation (old 2-tab IDs: 0=Spot, 1=P2P)
    if (TemporaryData.changingPageId != null) {
      final id = TemporaryData.changingPageId!;
      TemporaryData.changingPageId = null;
      // Map to new 5-tab positions: Spot=1, P2P=4
      final newIndex = id == 1 ? 4 : 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(newIndex);
        setState(() => _selectedTab = newIndex);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      
      children: [
        // ── Top tab bar: Swap / Spot / Future / Earn / P2P ──────────────────
        Container(
          color: Color(0xFF111111),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: const BoxDecoration(), // no underline
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: "DMSans",
              height: 1.5
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: "DMSans",
              height: 1.5
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tabs: _tabs.map((t) => Tab(text: t.tr)).toList(),
          ),
        ),

        // ── Tab body ─────────────────────────────────────────────────────────
        _buildTabBody(),
      ],
    );
  }

  Widget _buildTabBody() {
    switch (_selectedTab) {
      case 0:
        return _placeholderView('Swap');
      case 1:
        return const SpotTradeScreen();
      case 2:
        return _placeholderView('Future');
      case 3:
        return _placeholderView('Earn');
      case 4:
        return const P2PTradeScreen();
      default:
        return const SpotTradeScreen();
    }
  }

  Widget _placeholderView(String label) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_rounded, size: 48,
                color: Theme.of(context).primaryColorLight),
            vSpacer10(),
            TextRobotoAutoBold(
              '$label ${'coming_soon'.tr}',
              fontSize: Dimens.fontSizeLarge,
            ),
          ],
        ),
      ),
    );
  }
}