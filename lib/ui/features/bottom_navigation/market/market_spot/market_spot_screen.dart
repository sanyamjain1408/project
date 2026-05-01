import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';

import '../market_widgets.dart';
import 'market_spot_controller.dart';
import 'market_spot_widgets.dart' as spot;

const _bgcolor = Colors.transparent;
const _green = Color(0xFFB5F000);

class MarketSpotScreen extends StatefulWidget {
  const MarketSpotScreen({super.key});

  @override
  MarketSpotState createState() => MarketSpotState();
}

class MarketSpotState extends State<MarketSpotScreen>
    with TickerProviderStateMixin {
  final _controller = Get.put(MarketSpotController(), permanent: true);

  late final TabController _oldTabController;
  late final TabController _filterTabController;

  int _selectedCategoryIndex = 0; // Category selected index

  @override
  void initState() {
    _oldTabController = TabController(
      length: _controller.getTypeMap().values.length,
      vsync: this,
    );
    _filterTabController = TabController(
      length: _controller.getFilterList().length,
      vsync: this,
    );

    _filterTabController.addListener(() {
      if (!_filterTabController.indexIsChanging) {
        _controller.onFilterChanged(_filterTabController.index);
      }
    });

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getMarketOverviewTopCoinList(false);
      _controller.subscribeSocketChannels();
    });
  }

  @override
  void dispose() {
    _controller.unSubscribeChannel();
    _oldTabController.dispose();
    _filterTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: _bgcolor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterTabBar(),

            _buildStaticCategoryList(),

            const SizedBox(height: 10),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: textFieldSearch(
                  controller: _controller.searchController,
                  height: Dimens.btnHeightSmall,
                  margin: 0,
                  borderRadius: Dimens.radiusCornerMid,
                  onTextChange: _controller.onTextChanged,
                  bgColor: const Color(0xFF1A1A1A),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const MarketHeaderRow(),

            SizedBox(height: 7),


            Obx(() {
              return _controller.marketList.isEmpty
                  ? _controller.isLoading.value
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _green, // Green color
                              strokeWidth: 2,
                            ),
                          )
                        : showEmptyView(height: 100)
                  : Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(5),
                        separatorBuilder: (context, index) =>
                            const SizedBox.shrink(),
                        itemCount: _controller.marketList.length,
                        itemBuilder: (context, index) {
                          if (_controller.hasMoreData &&
                              index == _controller.marketList.length - 1) {
                            WidgetsBinding.instance.addPostFrameCallback(
                              (t) => _controller.getMarketOverviewTopCoinList(
                                true,
                              ),
                            );
                          }
                          return Builder(
                            builder: (BuildContext newContext) {
                              return spot.MarketCoinItemViewBottom(
                                coin: _controller.marketList[index],
                                onFavChange: (message) =>
                                    showToast(message, isError: false),
                              );
                            },
                          );
                        },
                      ),
                    );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabBar() {
    final filterList = _controller.getFilterList();

    return Obx(
      () => Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.transparent,
        child: Row(
          children: filterList.asMap().entries.map((entry) {
            final index = entry.key;
            final title = entry.value;
            final isSelected = _controller.selectedFilterIndex.value == index;

            return GestureDetector(
              onTap: () {
                _filterTabController.animateTo(index);
                _controller.onFilterChanged(index);
              },
              child: Container(
                height: 35,
                color: Colors.transparent,
                margin: const EdgeInsets.only(
                  right: 20,
                ), // <--- Yahan gap do apne hisaab se
                alignment: Alignment.center,

                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "DMSans",
                    fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── STATIC CATEGORY LIST ──
  Widget _buildStaticCategoryList() {
    final categories = [
      "All",
      "🔥 AI",
      "Meme",
      "RWA",
      "DeFi",
      "NFT",
      "Layer 1",
      "Layer 2",
    ];

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: EdgeInsets.only(top: 10, bottom: 10),
      color: Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFB5F000)
                    : Color(0xFF1A1A1A), // "All" ke liye thoda different color
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF000000)
                      : const Color(0xFFFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: "DMSans",
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} // ← MarketSpotState end

// ── MARKET HEADER ROW ──
class MarketHeaderRow extends StatelessWidget {
  const MarketHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.transparent,
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: const Text(
              "Pair/Vol",
              style: TextStyle(
                color: Colors.white30, // ✅ 50% white
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Price",
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white30, // ✅ 50% white
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Text(
              "24h Change",
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white30, // ✅ 50% white
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
