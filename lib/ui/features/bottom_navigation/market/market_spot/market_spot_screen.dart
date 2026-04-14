import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:k_chart_plus/utils/index.dart';
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


const _bgcolor =  Colors.transparent;

class MarketSpotScreen extends StatefulWidget {
  const MarketSpotScreen({super.key});

  @override
  MarketSpotState createState() => MarketSpotState();
}

class MarketSpotState extends State<MarketSpotScreen> with TickerProviderStateMixin {
  final _controller = Get.put(MarketSpotController());
  
  late final TabController _oldTabController; 
  late final TabController _filterTabController;

  @override
  void initState() {
    _oldTabController = TabController(length: _controller.getTypeMap().values.length, vsync: this);
    _filterTabController = TabController(length: _controller.getFilterList().length, vsync: this);
    
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
                padding: const EdgeInsets.symmetric(horizontal:4),
                child: textFieldSearch(
                    controller: _controller.searchController,
                    height: Dimens.btnHeightSmall,
                    margin: 0,
                    borderRadius: Dimens.radiusCornerMid,
                    onTextChange: _controller.onTextChanged),
              ),
            ),

            SizedBox(height: 10,),

            const MarketHeaderRow(),

            Obx(() {
              return _controller.marketList.isEmpty
                  ? handleEmptyViewWithLoading(_controller.isLoading.value)
                  : Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(Dimens.paddingMid),
                        separatorBuilder: (context, index) => const SizedBox.shrink(), 
                        itemCount: _controller.marketList.length,
                        itemBuilder: (context, index) {
                          if (_controller.hasMoreData && index == _controller.marketList.length - 1) {
                            WidgetsBinding.instance.addPostFrameCallback((t) => _controller.getMarketOverviewTopCoinList(true));
                          }
                          return Builder(
                            builder: (BuildContext newContext) {
                              return spot.MarketCoinItemViewBottom(
                                coin: _controller.marketList[index],
                                onFavChange: (message) => showToast(message, isError: false),
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
  return Container(
    height: 35,
    padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
    alignment: Alignment.centerLeft, 
     // Background black
    
    // Yahan IMPORTANT FIX: Bottom border ko Black set kar rahe hain
    decoration: const BoxDecoration(
      color: Colors.transparent,
      
    ),
    
    child: TabBar(
      controller: _filterTabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start, 
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white38,
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
      indicator: const BoxDecoration(), // Indicator hata diya
      dividerColor: Colors.transparent,
      
      tabs: _controller.getFilterList().map((title) {
        return Tab(text: title);
      }).toList(),
    ),
  );
}

  Widget _buildStaticCategoryList() {
    final categories = ["All", "AI", "Meme", "RWA", "DeFi", "NFT", "Layer 1", "Layer 2"];
    
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
      
      color: Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = false; 
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E2128) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E2128), width: 1),
            ),
            child: Text(
              categories[index],
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}


class MarketHeaderRow extends StatelessWidget {
  const MarketHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20, // Header ki height
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.transparent, // Background color (Black)
      child: const Row(
        children: [
          // Column 1: Pair / Vol (Left Side - takes more space)
          Expanded(
            flex: 3, // 30% space
            child: Text(
              "Pair/Vol",
              style: TextStyle(
                color: Colors.white54, // Muted Grey Color
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          
          // Column 2: Price (Center - takes medium space)
          Expanded(
            flex: 2, // 20% space
            child: Text(
              "Price",
              textAlign: TextAlign.right, // Right align (Price usually right side hota hai)
              style: TextStyle(
                color: Colors.white54, // Muted Grey Color
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: 20), // Thoda space between Price and Change
          // Column 3: 24h Change (Right Side - takes medium space)
          Expanded(
            flex: 2, // 20% space
            child: Text(
              "24h Change",
              textAlign: TextAlign.right, // Right align
              style: TextStyle(
                color: Colors.white54, // Muted Grey Color
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}