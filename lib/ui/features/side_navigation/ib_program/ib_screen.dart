import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IGScreen extends StatefulWidget {
  const IGScreen({super.key});

  @override
  IGScreenState createState() => IGScreenState();
}

class IGScreenState extends State<IGScreen> {
  bool _showTerms = false;
  int _directCount = 7;
  String _ibLink = "https://trapix.com/signup?ib_code=TRX-5Q905R";
  String _ibCode = "TRX-5Q905R";
  double _pendingBalance = 0.00000000;
  int _totalIBs = 7;
  double _totalEarned = 6.70;
  String _currentTier = "Starter";
  int _activeIBs = 3;

  final List<Tier> tiers = [
    Tier(name: "Starter", min: 0, max: 9, commission: 30),
    Tier(name: "Pro", min: 10, max: 49, commission: 40),
    Tier(name: "Elite", min: 50, max: 199, commission: 50),
    Tier(name: "VIP", min: 200, max: 999999, commission: 60),
  ];

  final List<Map<String, dynamic>> _members = [
    {'name': 'tyty', 'email': 'tyt***', 'joined_at': '2026-04-02', 'trade_volume': 4960.07, 'you_earned': 4.464067},
    {'name': 'ghghg ghghg', 'email': 'ghg***', 'joined_at': '2026-04-10', 'trade_volume': 2480.04, 'you_earned': 2.232034},
    {'name': 'nmmn nmnm', 'email': 'nmn***', 'joined_at': '2026-04-10', 'trade_volume': 0, 'you_earned': 0},
    {'name': 'Test User', 'email': 'test***', 'joined_at': '2026-04-13', 'trade_volume': 0, 'you_earned': 0},
  ];

  @override
  Widget build(BuildContext context) {
    Tier currentTier = _getCurrentTier(_directCount);
    Tier? nextTier = _getNextTier(_directCount);
    double directProgress = nextTier != null
        ? ((_directCount - currentTier.min) / (nextTier.min - currentTier.min) * 100).clamp(0, 100).toDouble()
        : 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        title: const Text("IB Program", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B0B0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeroSection(),
          const SizedBox(height: 12),
          _buildStatsSection(),
          const SizedBox(height: 12),
          _buildPendingRewards(),
          const SizedBox(height: 12),
          _buildFlowSection(),
          const SizedBox(height: 12),
          _buildRulesSection(),
          const SizedBox(height: 12),
          _buildLevel1Section(_directCount, currentTier, nextTier, directProgress),
          const SizedBox(height: 12),
          _buildLevel2Section(),
          const SizedBox(height: 12),
          _buildHistoryTable(),
          const SizedBox(height: 12),
          _buildTermsSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "IB Program",
                style: TextStyle(color: Color(0xFFCCFF00), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Earn 30–60% Forever",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Introduce traders and earn up to 60% of the 0.3% trading fee",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 12),
            _buildCopyRow("Your IB Link", _ibLink),
            const SizedBox(height: 8),
            _buildCopyRow("IB Code", _ibCode),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.snackbar("Copied", "IB Link copied",
                    backgroundColor: const Color(0xFFCCFF00), colorText: Colors.black);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Invite Now", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCCFF00).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.length > 30 ? "${value.substring(0, 25)}..." : value,
                  style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 10),
                ),
              ),
              InkWell(
                onTap: () {
                  Get.snackbar("Copied", "$label copied",
                    backgroundColor: const Color(0xFFCCFF00), colorText: Colors.black);
                },
                child: const Icon(Icons.copy, color: Color(0xFFCCFF00), size: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Total IBs", "$_totalIBs", const Color(0xFFFF6F00))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard("Total Earned", "$_totalEarned USDT", const Color(0xFF00E5FF))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard("Current Tier", _currentTier, const Color(0xFF0062FF))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard("Active IBs", "$_activeIBs", const Color(0xFFCCFF00))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.white54, fontSize: 9)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPendingRewards() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF600050), Color(0xFF931A7E)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pending Rewards", style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 4),
              Text(
                "${_pendingBalance.toStringAsFixed(8)} USDT",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _pendingBalance > 0 ? () {} : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCCFF00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Withdraw", style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("How IB Rewards Flow", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildFlowStep("A", "30-60% from Level 1 + 10% from Level 2", const Color(0xFFFF6F00)),
          const SizedBox(height: 6),
          _buildFlowStep("B", "30-60% from their Level 1 trades", const Color(0xFF00E5FF)),
          const SizedBox(height: 6),
          _buildFlowStep("C", "Trading continues normally", const Color(0xFF0062FF)),
        ],
      ),
    );
  }

  Widget _buildFlowStep(String letter, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(letter, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10))),
      ],
    );
  }

  Widget _buildRulesSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Key Rules", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildRule("Rewards from 0.3% exchange fee only"),
          _buildRule("Max 2 levels deep"),
          _buildRule("Commission upgrades automatically"),
          _buildRule("Withdraw anytime to wallet"),
        ],
      ),
    );
  }

  Widget _buildRule(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Text("•", style: TextStyle(color: Color(0xFFCCFF00), fontSize: 10)),
          const SizedBox(width: 6),
          Expanded(child: Text(rule, style: const TextStyle(color: Colors.white54, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildLevel1Section(int directCount, Tier currentTier, Tier? nextTier, double progress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Level 1 — Direct IBs", style: TextStyle(color: Color(0xFFCCFF00), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("$directCount Direct IB${directCount == 1 ? "" : "s"} • Tier: ${currentTier.name}",
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Progress", style: TextStyle(color: Colors.white54, fontSize: 9)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCCFF00)),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text("${progress.toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tiers.map((tier) {
                final isActive = tier.name == currentTier.name;
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFCCFF00).withOpacity(0.15) : Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isActive ? const Color(0xFFCCFF00) : Colors.white24, width: isActive ? 1 : 0.5),
                  ),
                  child: Column(
                    children: [
                      Text(tier.name, style: TextStyle(color: isActive ? const Color(0xFFCCFF00) : Colors.white54, fontSize: 9)),
                      const SizedBox(height: 2),
                      Text("${tier.commission}%", style: TextStyle(color: isActive ? const Color(0xFFCCFF00) : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevel2Section() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FF66).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Level 2 — Indirect IBs", style: TextStyle(color: Color(0xFFCCFF00), fontSize: 12, fontWeight: FontWeight.bold)),
              Text("Fixed commission", style: TextStyle(color: Colors.white54, fontSize: 9)),
            ],
          ),
          const Text("10%", style: TextStyle(color: Color(0xFF00FF66), fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("IB History", style: TextStyle(color: Color(0xFFCCFF00), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _members.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("No IBs yet", style: TextStyle(color: Colors.white54, fontSize: 11))),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 8,
                    headingRowColor: WidgetStateProperty.all(Colors.transparent),
                    columns: const [
                      DataColumn(label: Text("#", style: TextStyle(color: Colors.white54, fontSize: 9))),
                      DataColumn(label: Text("IB", style: TextStyle(color: Colors.white54, fontSize: 9))),
                      DataColumn(label: Text("Volume", style: TextStyle(color: Colors.white54, fontSize: 9))),
                      DataColumn(label: Text("Earned", style: TextStyle(color: Colors.white54, fontSize: 9))),
                    ],
                    rows: List.generate(_members.length, (index) {
                      final m = _members[index];
                      final name = m['name']?.toString() ?? "";
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
                      final volume = (m['trade_volume'] ?? 0).toDouble();
                      final earned = (m['you_earned'] ?? 0).toDouble();
                      return DataRow(cells: [
                        DataCell(Text("${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 10))),
                        DataCell(Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFCCFF00).withOpacity(0.2),
                              ),
                              child: Center(child: Text(initial, style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 9))),
                            ),
                            const SizedBox(width: 6),
                            Text(name.length > 8 ? "${name.substring(0, 6)}..." : name, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        )),
                        DataCell(Text("\$${volume.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFF4BC0FF), fontSize: 10))),
                        DataCell(Text("+${earned.toStringAsFixed(4)}", style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 10))),
                      ]);
                    }),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _showTerms = !_showTerms),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.description, color: Color(0xFFCCFF00), size: 16),
                const SizedBox(width: 8),
                const Expanded(child: Text("Terms & Conditions", style: TextStyle(color: Colors.white, fontSize: 12))),
                Icon(_showTerms ? Icons.expand_less : Icons.expand_more, color: const Color(0xFFCCFF00), size: 18),
              ],
            ),
          ),
        ),
        if (_showTerms)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(),
            child: const Text(
              "• Open to registered KYC verified users\n"
              "• Level 1: 30-60% of 0.3% fee\n"
              "• Level 2: 10% fixed commission\n"
              "• Self-referrals & wash trading prohibited",
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );
  }

  Tier _getCurrentTier(int count) {
    for (Tier tier in tiers) {
      if (count >= tier.min && count <= tier.max) return tier;
    }
    return tiers[0];
  }

  Tier? _getNextTier(int count) {
    for (Tier tier in tiers) {
      if (count < tier.min) return tier;
    }
    return null;
  }
}

class Tier {
  final String name;
  final int min;
  final int max;
  final int commission;
  Tier({required this.name, required this.min, required this.max, required this.commission});
}