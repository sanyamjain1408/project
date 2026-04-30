import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'earn_controller.dart';
import 'earn_subscribe_modal.dart';
import 'dual_investment_screen.dart';

const String _baseUrl = 'https://api.trapix.com';

Color getLockColor(int days) {
  switch (days) {
    case 0: return const Color(0xFFCCFF00);
    case 30: return const Color(0xFF00CCFF);
    case 60: return const Color(0xFFAA88FF);
    case 90: return const Color(0xFFFF9900);
    case 120: return const Color(0xFFFF4488);
    default: return const Color(0xFFCCFF00);
  }
}

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  final _controller = Get.put(EarnController());

  int _selectedMainTab = 0;
  int _selectedEasyTab = 0;
  final List<String> _mainTabs = ["Overview", "Easy Earn", "Dual Investment"];
  final List<String> _easyTabs = ["Products", "Positions", "History"];

  String _searchCoin = "";
  String _filterStatus = "All";
  List<dynamic> _easyPositions = [];
  List<dynamic> _easyHistory = [];
  bool _isLoadingEasy = false;
  String _redeemError = "";
  String _historyError = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchProducts();
      if (gUserRx.value.id > 0) {
        _controller.fetchPositions();
        _controller.fetchBalances();
        _fetchEasyPositions();
      }
    });
  }

  String get _uid => gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';

  Future<void> _fetchEasyPositions() async {
    if (_uid.isEmpty) return;
    setState(() => _isLoadingEasy = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/tf/earn/positions?user_id=$_uid'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() => _easyPositions = json['data'] ?? []);
      } else {
        setState(() => _easyPositions = []);
      }
    } catch (e) {
      debugPrint('Error fetching positions: $e');
      setState(() => _easyPositions = []);
    }
    setState(() => _isLoadingEasy = false);
  }

  Future<void> _fetchEasyHistory() async {
    if (_uid.isEmpty) return;
    setState(() { 
      _isLoadingEasy = true;
      _historyError = "";
    });
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/tf/earn/history?user_id=$_uid'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        dynamic historyData;
        
        // Handle the nested data structure from your TypeScript API
        if (json['data'] != null) {
          if (json['data'] is Map && json['data']['data'] != null) {
            historyData = json['data']['data'];
          } else if (json['data'] is List) {
            historyData = json['data'];
          } else {
            historyData = json['data'];
          }
        } else {
          historyData = [];
        }
        
        setState(() => _easyHistory = historyData.toList());
        debugPrint('History loaded: ${_easyHistory.length} items');
      } else {
        setState(() => _easyHistory = []);
        debugPrint('History API returned status: ${res.statusCode}, body: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
      setState(() { 
        _easyHistory = [];
        _historyError = "Unable to load history. Please try again later.";
      });
    }
    setState(() => _isLoadingEasy = false);
  }

  Future<void> _handleRedeem(String subId) async {
    if (_uid.isEmpty) return;
    setState(() => _redeemError = "");
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tf/earn/redeem?user_id=$_uid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"subscription_id": subId}),
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          await _fetchEasyPositions();
          await _controller.fetchBalances();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Successfully redeemed!'), backgroundColor: Colors.green),
            );
          }
        } else {
          setState(() => _redeemError = json['message'] ?? "Redeem failed");
        }
      } else {
        setState(() => _redeemError = "Redeem failed. Please try again.");
      }
    } catch (e) {
      debugPrint('Redeem error: $e');
      setState(() => _redeemError = "Redeem failed: Network error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMainTabs(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedMainTab == 2
                  ? const DualInvestmentScreen()
                  : _selectedMainTab == 1
                      ? _buildEasyEarnContent()
                      : _buildOverviewContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text("Trapix Earn", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFF111318), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: List.generate(_mainTabs.length, (index) {
          final isSelected = _selectedMainTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedMainTab = index);
                if (index == 1 && _selectedEasyTab == 1) _fetchEasyPositions();
                if (index == 1 && _selectedEasyTab == 2) _fetchEasyHistory();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFB5F000) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(_mainTabs[index], style: TextStyle(color: isSelected ? Colors.black : const Color(0xFF6B7280), fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // OVERVIEW TAB
  // ==========================================
  Widget _buildOverviewContent() {
    return Obx(() {
      final products = _controller.products;
      final positions = _controller.positions;
      final isLoggedIn = gUserRx.value.id > 0;
      final totalAssets = positions.fold(0.0, (s, p) => s + p.amount);
      final totalInterest = positions.fold(0.0, (s, p) => s + p.accruedInterest);
      final recommended = [...products]..sort((a, b) => b.apr.compareTo(a.apr));
      final topRec = recommended.take(4).toList();

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const Align(alignment: Alignment.centerLeft, child: Text("Grow steadily. Let your wealth endure.", style: TextStyle(color: Color(0xFF6B7280), fontSize: 13))),
          const SizedBox(height: 20),
          
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeaderButton(icon: Icons.account_balance_wallet_outlined, label: "View My Earnings", onTap: () => setState(() { _selectedMainTab = 1; _selectedEasyTab = 1; _fetchEasyPositions(); })),
              const SizedBox(height: 10),
              _buildHeaderButton(icon: Icons.calculate_outlined, label: "Calculator", onTap: () => _showCalculatorDialog()),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF111318), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E2128))),
              child: Column(children: [
                _buildStatRow("Total Assets (USDT)", isLoggedIn ? coinFormat(totalAssets) : '--', Colors.white, 22),
                const SizedBox(height: 14), Container(height: 1, color: const Color(0xFF1E2128)), const SizedBox(height: 14),
                _buildStatRow("Total Interest (USDT)", isLoggedIn ? coinFormat(totalInterest) : '--', const Color(0xFFB5F000), 16),
                const SizedBox(height: 12),
                _buildStatRow("Active Positions", isLoggedIn ? positions.length.toString() : '--', const Color(0xFFB5F000), 16),
              ]),
            )),
          ]),
          const SizedBox(height: 28),

          const Align(alignment: Alignment.centerLeft, child: Text('Recommended', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
          const SizedBox(height: 14),
          if (_controller.isLoadingProducts.value)
            const Center(child: CircularProgressIndicator(color: Color(0xFFB5F000)))
          else
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.45),
              itemCount: topRec.length,
              itemBuilder: (context, index) => _buildRecommendedCard(topRec[index], [const Color(0xFFFF6F00), const Color(0xFF00C9FF), const Color(0xFF6C5CE7), const Color(0xFF00B894)][index % 4]),
            ),
          const SizedBox(height: 30)
        ],
      );
    });
  }

  // ==========================================
  // EASY EARN TAB
  // ==========================================
  Widget _buildEasyEarnContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFF111318), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: List.generate(_easyTabs.length, (index) {
                final isActive = _selectedEasyTab == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedEasyTab = index);
                      if (index == 1) _fetchEasyPositions();
                      if (index == 2) _fetchEasyHistory();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: isActive ? const Color(0xFFB5F000) : Colors.transparent, width: 2)),
                      ),
                      alignment: Alignment.center,
                      child: Text(_easyTabs[index], style: TextStyle(color: isActive ? const Color(0xFFB5F000) : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _selectedEasyTab == 0
              ? _buildEasyProductsTab()
              : _selectedEasyTab == 1
                  ? _buildEasyPositionsTab()
                  : _buildEasyHistoryTab(),
        ),
      ],
    );
  }

  Widget _buildEasyProductsTab() {
    return Obx(() {
      final products = _controller.products;
      final uniqueCoins = products.map((p) => p.coin).toSet().toList();
      
      final filteredCoins = uniqueCoins.where((coin) {
        if (_searchCoin.isNotEmpty && !coin.toLowerCase().contains(_searchCoin.toLowerCase())) return false;
        if (_filterStatus == "Flexible" && !products.any((p) => p.coin == coin && p.lockDays == 0)) return false;
        if (_filterStatus == "Fixed" && !products.any((p) => p.coin == coin && p.lockDays > 0)) return false;
        return true;
      }).toList();

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Row(children: [
            Expanded(child: _buildSearchBar()),
            const SizedBox(width: 10),
            _buildFilterDropdown(),
          ]),
          const SizedBox(height: 16),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8), 
            child: Row(
              children: [
                Flexible(flex: 3, child: Text('Coin', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Flexible(flex: 2, child: Text('APR', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Flexible(flex: 2, child: Text('Period', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E2128)),

          ...filteredCoins.map((coin) {
            final coinProducts = products.where((p) => p.coin == coin).toList()..sort((a, b) => a.lockDays.compareTo(b.lockDays));
            final aprs = coinProducts.map((p) => p.apr).toList();
            final minApr = aprs.reduce((a, b) => a < b ? a : b);
            final maxApr = aprs.reduce((a, b) => a > b ? a : b);
            final hasFlex = coinProducts.any((p) => p.lockDays == 0);
            final hasFixed = coinProducts.any((p) => p.lockDays > 0);
            final period = hasFlex && hasFixed ? 'Flex/Fixed' : hasFlex ? 'Flexible' : 'Fixed';

            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14), 
                child: Row(
                  children: [
                    Flexible(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32, 
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E2128)),
                            child: coinProducts.first.coinIcon != null 
                                ? ClipOval(child: Image.network(coinProducts.first.coinIcon!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.monetization_on, color: Color(0xFFB5F000), size: 18))) 
                                : const Icon(Icons.monetization_on, color: Color(0xFFB5F000), size: 18)
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(coin, 
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: Text(
                        minApr == maxApr ? '${minApr.toStringAsFixed(2)}%' : '${minApr.toStringAsFixed(2)}%~${maxApr.toStringAsFixed(2)}%', 
                        style: const TextStyle(color: Color(0xFFB5F000), fontSize: 12, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      flex: 2, 
                      child: GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context, 
                          isScrollControlled: true, 
                          backgroundColor: Colors.transparent, 
                          builder: (_) => _EasyEarnModal(coin: coin, plans: coinProducts)
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                          decoration: BoxDecoration(color: const Color(0xFFB5F000), borderRadius: BorderRadius.circular(16)),
                          child: Text(
                            period, 
                            style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700), 
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF111318)),
            ]);
          }).toList(),
          const SizedBox(height: 30),
        ],
      );
    });
  }

  Widget _buildEasyPositionsTab() {
    if (_uid.isEmpty) return const Center(child: Text("Login to view positions", style: TextStyle(color: Color(0xFF6B7280))));
    if (_isLoadingEasy) return const Center(child: CircularProgressIndicator(color: Color(0xFFB5F000)));
    if (_easyPositions.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_outlined, color: Color(0xFF6B7280), size: 48), SizedBox(height: 12),
      Text("No active positions", style: TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
      Text("Subscribe to a product to start earning", style: TextStyle(color: Color(0xFF555555), fontSize: 13)),
    ]));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_redeemError.isNotEmpty) 
          Container(
            margin: const EdgeInsets.only(bottom: 16), 
            padding: const EdgeInsets.all(12), 
            decoration: BoxDecoration(color: const Color(0xFF1A0000), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF330000))), 
            child: Text(_redeemError, style: const TextStyle(color: Color(0xFFFF6666), fontSize: 13))
          ),
        ..._easyPositions.map((pos) {
          final lockDays = (pos['lock_days'] ?? 0).toInt();
          final color = getLockColor(lockDays);
          final canRedeem = pos['is_redeemable'] == true;
          final isAutoReinvest = pos['auto_reinvest'] == 1;
          final reinvestCount = pos['reinvest_count'] ?? 0;
          final planType = pos['plan_type'] ?? 'flexible';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1A1A1A))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Container(
                        width: 46, height: 46, 
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)), 
                        child: Center(
                          child: Text(pos['coin']?.substring(0, 1) ?? '?', 
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)
                          ),
                        )
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(pos['coin'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                                  decoration: BoxDecoration(
                                    border: Border.all(color: color), 
                                    borderRadius: BorderRadius.circular(10), 
                                    color: Colors.transparent
                                  ), 
                                  child: Text(planType == 'flexible' ? 'Flexible' : '${lockDays}d Fixed', style: TextStyle(color: color, fontSize: 10))
                                ),
                                if (isAutoReinvest)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A2200), 
                                      border: Border.all(color: const Color(0xFFCCFF00)), 
                                      borderRadius: BorderRadius.circular(10)
                                    ), 
                                    child: const Text('🔄 Auto', style: TextStyle(color: Color(0xFFCCFF00), fontSize: 9))
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text("${coinFormat(double.tryParse(pos['amount']?.toString() ?? '0') ?? 0)} staked · ${double.tryParse(pos['apr']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0'}% APR", 
                              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (reinvestCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text("Re-invested $reinvestCount time${reinvestCount != 1 ? 's' : ''}", 
                                  style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
                                ),
                              ),
                            if (planType == 'locked' && !canRedeem)
                              Padding(
                                padding: const EdgeInsets.only(top: 4), 
                                child: Text("${pos['days_left']} days remaining · unlocks ${_formatDate(pos['lock_until'])}", 
                                  style: TextStyle(color: color, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (planType == 'locked' && canRedeem)
                              const Padding(
                                padding: EdgeInsets.only(top: 4), 
                                child: Text("Ready to redeem", style: TextStyle(color: Color(0xFF00FF88), fontSize: 11))
                              ),
                          ]
                        )
                      ),
                    ]
                  )
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end, 
                  children: [
                    const Text("EARNED", style: TextStyle(color: Color(0xFF555555), fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text("+${coinFormat(double.tryParse(pos['accrued_interest']?.toString() ?? '0') ?? 0)} ${pos['coin']}", 
                      style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 15, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: canRedeem ? () => _handleRedeem(pos['id'].toString()) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, 
                          disabledBackgroundColor: Colors.transparent, 
                          padding: const EdgeInsets.symmetric(horizontal: 16), 
                          elevation: 0, 
                          side: BorderSide(color: canRedeem ? const Color(0xFFCCFF00) : const Color(0xFF333333))
                        ),
                        child: Text(canRedeem ? "Redeem" : "Locked", 
                          style: TextStyle(color: canRedeem ? const Color(0xFFCCFF00) : const Color(0xFF444444), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  ]
                ),
              ]
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEasyHistoryTab() {
    if (_uid.isEmpty) return const Center(child: Text("Login to view history", style: TextStyle(color: Color(0xFF6B7280))));
    if (_isLoadingEasy) return const Center(child: CircularProgressIndicator(color: Color(0xFFB5F000)));
    
    if (_historyError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6666), size: 48),
            const SizedBox(height: 12),
            Text(_historyError, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchEasyHistory,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB5F000)),
              child: const Text('Retry', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
    
    if (_easyHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Color(0xFF6B7280), size: 48),
            SizedBox(height: 12),
            Text("No transactions yet", style: TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
            Text("Your transactions will appear here", style: TextStyle(color: Color(0xFF555555), fontSize: 13)),
          ],
        ),
      );
    }

    // Use a ListView instead of SingleChildScrollView for better performance
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF1E2128))),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('Type', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.08))),
              Expanded(flex: 2, child: Text('Coin', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.08))),
              Expanded(flex: 3, child: Text('Amount', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.08))),
              Expanded(flex: 4, child: Text('Time', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.08))),
            ],
          ),
        ),
        
        // Rows
        ..._easyHistory.map((tx) {
          final type = tx['type']?.toString().toLowerCase() ?? 
                      (tx['transaction_type']?.toString().toLowerCase() ?? 'subscribe');
          final coin = tx['coin'] ?? tx['currency'] ?? 'USDT';
          final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
          
          String timeStr = 'Unknown';
          if (tx['created_at'] != null) {
            try {
              final date = DateTime.parse(tx['created_at'].toString()).toLocal();
              timeStr = '${date.month}/${date.day}/${date.year}, ${_formatTime(date)}';
            } catch (e) {
              timeStr = tx['created_at'].toString();
            }
          } else if (tx['timestamp'] != null) {
            try {
              final date = DateTime.parse(tx['timestamp'].toString()).toLocal();
              timeStr = '${date.month}/${date.day}/${date.year}, ${_formatTime(date)}';
            } catch (e) {
              timeStr = tx['timestamp'].toString();
            }
          }
          
          final isSubscribe = type == 'subscribe';
          final bgColor = isSubscribe ? const Color(0xFF1A1A00) : const Color(0xFF001A1A);
          final txtColor = isSubscribe ? const Color(0xFFCCFF00) : const Color(0xFF00CCCC);
          final amtColor = isSubscribe ? const Color(0xFFFF6666) : const Color(0xFF00FF88);
          final amountPrefix = isSubscribe ? '-' : '+';

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF111318))),
            ),
            child: Row(
              children: [
                // Type
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        color: txtColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Coin with icon
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text(
                            coin.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          coin,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Expanded(
                  flex: 3,
                  child: Text(
                    "$amountPrefix${coinFormat(amount)} $coin",
                    style: TextStyle(
                      color: amtColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Time
                Expanded(
                  flex: 4,
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
      ],
    );
  }

  String _formatTime(DateTime date) {
    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute:$second $ampm';
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  // ==========================================
  // UI COMPONENTS
  // ==========================================
  Widget _buildSearchBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF111318), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E2128))),
      child: Row(children: [
        const Icon(Icons.search, color: Color(0xFF6B7280), size: 18),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          onChanged: (v) => setState(() => _searchCoin = v),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(border: InputBorder.none, hintText: "Search coin...", hintStyle: TextStyle(color: Color(0xFF555555), fontSize: 13), isDense: true, contentPadding: EdgeInsets.zero),
        )),
      ]),
    );
  }

  Widget _buildFilterDropdown() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context, 
          backgroundColor: const Color(0xFF111318), 
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: ["All", "Flexible", "Fixed"].map((s) => ListTile(
                title: Text(s, style: TextStyle(color: _filterStatus == s ? const Color(0xFFB5F000) : Colors.white, fontWeight: _filterStatus == s ? FontWeight.w700 : FontWeight.normal)), 
                onTap: () { setState(() => _filterStatus = s); Navigator.pop(context); }
              )).toList()
            )
          )
        );
      },
      child: Container(
        height: 40, 
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFF111318), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E2128))),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_filterStatus, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280), size: 18),
        ]),
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), 
        decoration: BoxDecoration(color: const Color(0xFF111318), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E2128))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: const Color(0xFFB5F000), size: 18), 
          const SizedBox(width: 8), 
          Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis))
        ])
      )
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor, double valueSize) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: valueColor, fontSize: valueSize, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildRecommendedCard(dynamic p, Color color) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context, 
        isScrollControlled: true, 
        backgroundColor: Colors.transparent, 
        builder: (_) => _EasyEarnModal(coin: p.coin, plans: _controller.products.where((pr) => pr.coin == p.coin).toList()..sort((a,b) => a.lockDays.compareTo(b.lockDays)))
      ),
      child: Container(
        padding: const EdgeInsets.all(12), 
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.15), const Color(0xFF111318)]), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)), child: p.coinIcon != null ? ClipOval(child: Image.network(p.coinIcon!, width: 28, height: 28, fit: BoxFit.cover)) : Icon(Icons.monetization_on, color: color, size: 18)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.coin, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(p.lockDays == 0 ? 'Easy Earn | Flexible' : 'Easy Earn | Fixed', style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w500)),
            ]),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('${p.apr.toStringAsFixed(2)}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(width: 4),
            Text('APR', style: TextStyle(color: color.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),
    );
  }

  void _showCalculatorDialog() {
    final c = TextEditingController();
    double calc = 0;
    showDialog(
      context: context, 
      builder: (ctx) => StatefulBuilder(
        builder: (context, set) => AlertDialog(
          backgroundColor: const Color(0xFF111318), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Earn Calculator", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              TextField(
                controller: c, 
                keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                style: const TextStyle(color: Colors.white), 
                decoration: InputDecoration(
                  hintText: "Enter amount (USDT)", 
                  hintStyle: const TextStyle(color: Color(0xFF6B7280)), 
                  filled: true, 
                  fillColor: const Color(0xFF1E2128), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), 
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFB5F000))
                ),
                onChanged: (v) { 
                  final a = double.tryParse(v) ?? 0; 
                  final apr = _controller.products.isNotEmpty ? _controller.products.first.apr : 0; 
                  calc = (a * apr) / (100 * 365); 
                  set(() {}); 
                }
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16), 
                decoration: BoxDecoration(color: const Color(0xFF1E2128), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    const Text("Estimated Daily Earning", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)), 
                    Text("${calc.toStringAsFixed(4)} USDT", style: const TextStyle(color: Color(0xFFB5F000), fontSize: 16, fontWeight: FontWeight.w700))
                  ]
                )
              ),
            ]
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("Close", style: TextStyle(color: Color(0xFF6B7280)))
            )
          ]
        )
      )
    );
  }
}

// ==========================================
// EASY EARN SUBSCRIBE MODAL
// ==========================================
class _EasyEarnModal extends StatefulWidget {
  final String coin;
  final List<dynamic> plans;
  const _EasyEarnModal({required this.coin, required this.plans});

  @override
  State<_EasyEarnModal> createState() => _EasyEarnModalState();
}

class _EasyEarnModalState extends State<_EasyEarnModal> {
  late dynamic _selectedPlan;
  final _amountCtrl = TextEditingController();
  bool _agreed = false;
  bool _autoReinvest = false;
  bool _loading = false;
  String _error = "";
  String _success = "";

  String get _uid => gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';
  
  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.plans.isNotEmpty ? widget.plans.first : null;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _amountNum => double.tryParse(_amountCtrl.text) ?? 0;
  double get _dailyProfit => _selectedPlan != null && _amountNum > 0 ? (_amountNum * _selectedPlan.apr) / 100 / 365 : 0;
  double? get _totalProfit => _selectedPlan != null && _amountNum > 0 && _selectedPlan.lockDays > 0 ? _dailyProfit * _selectedPlan.lockDays : null;

  void _handleConfirm() async {
    if (_selectedPlan == null || _amountNum <= 0 || !_agreed || _uid.isEmpty) return;
    setState(() { _loading = true; _error = ""; _success = ""; });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/tf/earn/subscribe?user_id=$_uid'), 
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode({"product_id": _selectedPlan.id, "amount": _amountCtrl.text, "auto_reinvest": _selectedPlan.lockDays > 0 ? _autoReinvest : false})
      );
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        setState(() => _success = "Subscribed successfully!");
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _error = json['message'] ?? "Failed");
      }
    } catch (e) {
      setState(() => _error = "Subscription failed");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getLockColor(_selectedPlan?.lockDays ?? 0);
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF141414), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)), child: const Icon(Icons.monetization_on, color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              Text("Easy Earn ${widget.coin}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Color(0xFF555555), size: 22)),
            ]),
            const Divider(color: Color(0xFF1E1E1E), height: 32),

            Wrap(spacing: 10, runSpacing: 10, children: widget.plans.map((p) {
              final isActive = _selectedPlan?.id == p.id;
              final c = getLockColor(p.lockDays);
              return GestureDetector(
                onTap: () => setState(() { _selectedPlan = p; _autoReinvest = false; _error = ""; }),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 60) / 3, 
                  padding: const EdgeInsets.all(12), 
                  decoration: BoxDecoration(color: isActive ? Colors.black.withOpacity(0.4) : const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? c : const Color(0xFF222222), width: 2)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.lockDays == 0 ? "Flexible" : "${p.lockDays}d Fixed", style: TextStyle(color: isActive ? c : const Color(0xFF555555), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text("${p.apr.toStringAsFixed(2)}%", style: TextStyle(color: isActive ? c : const Color(0xFF777777), fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    const Text("APR", style: TextStyle(color: Color(0xFF444444), fontSize: 10)),
                  ])
                )
              );
            }).toList()),
            
            if (_selectedPlan != null) 
              Padding(
                padding: const EdgeInsets.only(top: 16), 
                child: Container(
                  padding: const EdgeInsets.all(12), 
                  decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(10)),
                  child: Text(_selectedPlan.lockDays == 0 ? "Flexible plan. Redeem at any time." : "Fixed plan. Funds stay locked for ${_selectedPlan.lockDays} days.", style: const TextStyle(color: Color(0xFF555555), fontSize: 12))
                )
              ),

            const SizedBox(height: 20),
            
            const Text("Amount", style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF222222))),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _amountCtrl, 
                  keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                  style: const TextStyle(color: Colors.white, fontSize: 15), 
                  decoration: InputDecoration(
                    border: InputBorder.none, 
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
                    hintText: "Min ${_selectedPlan != null ? coinFormat(_selectedPlan.minAmount) : '0'}", 
                    hintStyle: const TextStyle(color: Color(0xFF555555))
                  )
                )),
                GestureDetector(
                  onTap: () {}, 
                  child: Container(
                    margin: const EdgeInsets.only(right: 12), 
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), border: Border.all(color: const Color(0xFF333333)), borderRadius: BorderRadius.circular(6)), 
                    child: const Text("MAX", style: TextStyle(color: Color(0xFFCCFF00), fontSize: 11, fontWeight: FontWeight.w700))
                  )
                ),
                Padding(padding: const EdgeInsets.only(right: 16), child: Text(widget.coin, style: const TextStyle(color: Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w700))),
              ])
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Text("Max ${_selectedPlan != null ? coinFormat(_selectedPlan.maxAmount) : '—'} ${widget.coin}", style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
                ]
              )
            ),

            if (_selectedPlan != null) 
              Container(
                margin: const EdgeInsets.only(bottom: 16), 
                padding: const EdgeInsets.all(16), 
                decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(10)),
                child: _selectedPlan.lockDays == 0
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Est. Daily Profit", style: TextStyle(color: Color(0xFF666666), fontSize: 13)), 
                        Text("+${_dailyProfit.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} ${widget.coin}", style: const TextStyle(color: Color(0xFF00FF88), fontSize: 14, fontWeight: FontWeight.w700))
                      ]),
                      const SizedBox(height: 10), 
                      const Text("Flexible yield with anytime access", style: TextStyle(color: Color(0xFF444444), fontSize: 11)),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Est. Total Profit after ${_selectedPlan.lockDays} days", style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                      const SizedBox(height: 6),
                      Text("+${_totalProfit != null ? _totalProfit!.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '') : '0.00'} ${widget.coin}", style: const TextStyle(color: Color(0xFF00FF88), fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4), 
                      Text("Daily: +${_dailyProfit.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} ${widget.coin}", style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
                    ])
              ),

            if (_selectedPlan != null && _selectedPlan.lockDays > 0) 
              GestureDetector(
                onTap: () => setState(() => _autoReinvest = !_autoReinvest),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16), 
                  padding: const EdgeInsets.all(16), 
                  decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(12), border: Border.all(color: _autoReinvest ? const Color(0xFFCCFF00) : const Color(0xFF1E1E1E))),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("🔄 Auto Re-invest", style: TextStyle(color: _autoReinvest ? const Color(0xFFCCFF00) : const Color(0xFFAAAAAA), fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3), 
                      const Text("Principal + interest auto re-invests when plan matures", style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
                    ])),
                    Container(
                      width: 44, height: 24, 
                      decoration: BoxDecoration(color: _autoReinvest ? const Color(0xFFCCFF00) : const Color(0xFF222222), borderRadius: BorderRadius.circular(12)),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200), 
                        alignment: _autoReinvest ? Alignment.centerRight : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(3), 
                          child: Container(width: 18, height: 18, decoration: BoxDecoration(color: _autoReinvest ? Colors.black : const Color(0xFF555555), shape: BoxShape.circle))
                        ),
                      ),
                    ),
                  ])
                )
              ),

            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed), 
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Container(
                    width: 18, height: 18, 
                    margin: const EdgeInsets.only(top: 1), 
                    decoration: BoxDecoration(color: _agreed ? const Color(0xFFCCFF00) : Colors.transparent, border: Border.all(color: _agreed ? const Color(0xFFCCFF00) : const Color(0xFF333333)), borderRadius: BorderRadius.circular(4)),
                    child: _agreed ? const Icon(Icons.check, size: 12, color: Colors.black) : null
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text.rich(TextSpan(style: TextStyle(color: Color(0xFF555555), fontSize: 12, height: 1.5), children: [TextSpan(text: "I have read and agree to the "), TextSpan(text: "Trapix Earn User Agreement", style: TextStyle(color: Color(0xFFCCFF00), decoration: TextDecoration.underline))])))
                ]
              )
            ),
          
            const SizedBox(height: 20),

            if (_error.isNotEmpty) 
              Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1A0000), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF330000))), child: Text(_error, style: const TextStyle(color: Color(0xFFFF6666), fontSize: 13))),
            if (_success.isNotEmpty) 
              Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF001A00), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF003300))), child: Text(_success, style: const TextStyle(color: Color(0xFF00FF88), fontSize: 13))),

            SizedBox(
              width: double.infinity, 
              height: 50,
              child: ElevatedButton(
                onPressed: (_loading || _amountNum <= 0 || !_agreed) ? null : _handleConfirm,
                style: ElevatedButton.styleFrom(backgroundColor: (_loading || _amountNum <= 0 || !_agreed) ? const Color(0xFF222222) : color, disabledBackgroundColor: const Color(0xFF222222), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: Text(_loading ? "Processing..." : "Confirm Subscribe", style: TextStyle(color: (_loading || _amountNum <= 0 || !_agreed) ? const Color(0xFF555555) : Colors.black, fontSize: 16, fontWeight: FontWeight.w700))
              )
            ),
          ]
        ),
      ),
    );
  }
}