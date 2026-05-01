import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  ReferralScreenState createState() => ReferralScreenState();
}

class ReferralScreenState extends State<ReferralScreen> {
  bool _showStartCalendar = false;
  bool _showEndCalendar = false;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _startMonth = DateTime.now();
  DateTime _endMonth = DateTime.now();
  
  // Mock data - replace with API call
  int _totalReferrals = 1;
  double _totalEarned = 1.49;
  double _pendingBalance = 0.00595209;
  int _activeReferrals = 1;
  
  final List<Map<String, dynamic>> _members = [
    {'name': 'tytyty', 'email': 'tyt***', 'joined_at': '2026-04-02', 'trade_volume': 0, 'you_earned': 0},
    {'name': 'gghgghgghgghg', 'email': 'ggh***', 'joined_at': '2026-04-10', 'trade_volume': 2480.04, 'you_earned': 1.488022},
    {'name': 'nnmnnmnmnmnmnm', 'email': 'nnm***', 'joined_at': '2026-04-13', 'trade_volume': 0, 'you_earned': 0},
    {'name': 'Test User', 'email': 'ver***', 'joined_at': '2026-04-13', 'trade_volume': 0, 'you_earned': 0},
    {'name': 'hbhbhbhbhbh', 'email': 'hbh***', 'joined_at': '2026-04-13', 'trade_volume': 0, 'you_earned': 0},
    {'name': 'rtrt rtrt', 'email': 'rtr***', 'joined_at': '2026-04-14', 'trade_volume': 0, 'you_earned': 0},
  ];

  String _referralLink = "https://trapix.com/signup?ref=TRX-5Q905R";
  String _referralCode = "TRX-5Q905R";

  List<Map<String, dynamic>> get _filteredMembers {
    return _members.where((member) {
      if (_startDate == null && _endDate == null) return true;
      final joinedAt = DateTime.tryParse(member['joined_at'] ?? '');
      if (joinedAt == null) return true;
      if (_startDate != null && joinedAt.isBefore(_startDate!)) return false;
      if (_endDate != null && joinedAt.isAfter(_endDate!)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        title: const Text("Referral Program", style: TextStyle(color: Colors.white)),
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
          const SizedBox(height: 16),
          _buildHowItWorksSection(),
          const SizedBox(height: 16),
          _buildStatsSection(),
          const SizedBox(height: 16),
          _buildPendingRewards(),
          const SizedBox(height: 16),
          _buildHistorySection(),
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
                "Referral Program",
                style: TextStyle(color: Color(0xFFCCFF00), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Refer Friends.",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Earn 20% Forever.",
              style: TextStyle(color: Color(0xFFCCFF00), fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Invite anyone to Trapix. Every time they trade, you earn 20% of the 0.3% exchange fee — automatically, for life.",
              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 16),
            
            _buildCopyRow("Referral Link", _referralLink),
            const SizedBox(height: 12),
            _buildCopyRow("Referral Code", _referralCode),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFCCFF00), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.white, fontSize: 11),
                        children: [
                          TextSpan(text: "Receive "),
                          TextSpan(text: "20%", style: TextStyle(color: Color(0xFFCCFF00), fontWeight: FontWeight.bold)),
                          TextSpan(text: " commission on all trades made through your referrals"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.snackbar("Copied", "Referral Link copied",
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
                  value.length > 35 ? "${value.substring(0, 30)}..." : value,
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

  Widget _buildHowItWorksSection() {
    final steps = [
      {'icon': '📤', 'title': 'Share links', 'desc': 'Invite friends to register with Trapix.'},
      {'icon': '✅', 'title': 'Invitation accepted', 'desc': 'Complete registration and start trading.'},
      {'icon': '💰', 'title': 'Unlock earnings', 'desc': 'Earn commission on every friend\'s trades.'},
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: steps.map((step) {
          return Expanded(
            child: Column(
              children: [
                Text(step['icon']!, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 6),
                Text(step['title']!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(step['desc']!, style: const TextStyle(color: Colors.white54, fontSize: 9), textAlign: TextAlign.center),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Total Referral", "$_totalReferrals", const Color(0xFFFF6F00))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard("Total Earned", "$_totalEarned USDT", const Color(0xFF00E5FF))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard("Commission", "20%", const Color(0xFF0062FF))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard("Active Referrals", "$_activeReferrals", const Color(0xFFCCFF00))),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pending Rewards", style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_pendingBalance.toStringAsFixed(8)} USDT",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pendingBalance > 0 ? () {} : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCCFF00),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Withdraw", style: TextStyle(fontSize: 10)),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("View Wallet", style: TextStyle(color: Colors.white, fontSize: 9)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("View My Earnings", style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final filteredMembers = _filteredMembers;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Referral History", style: TextStyle(color: Color(0xFFCCFF00), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          // Date filters
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCCFF00).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFCCFF00), size: 12),
                        const SizedBox(width: 6),
                        Text(
                          _startDate != null ? _formatDate(_startDate!) : "Start Date",
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCCFF00).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFCCFF00), size: 12),
                        const SizedBox(width: 6),
                        Text(
                          _endDate != null ? _formatDate(_endDate!) : "End Date",
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          filteredMembers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text("No referrals yet", style: TextStyle(color: Colors.white54, fontSize: 11))),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 12,
                    headingRowColor: WidgetStateProperty.all(Colors.transparent),
                    columns: const [
                      DataColumn(label: Text("#", style: TextStyle(color: Colors.white54, fontSize: 9))),
                      DataColumn(label: Text("Referral", style: TextStyle(color: Colors.white54, fontSize: 9))),
                      DataColumn(label: Text("Joined", style: TextStyle(color: Colors.white54, fontSize: 9))),
                      DataColumn(label: Text("Volume", style: TextStyle(color: Colors.white54, fontSize: 9))),
                      DataColumn(label: Text("Earned", style: TextStyle(color: Colors.white54, fontSize: 9))),
                    ],
                    rows: List.generate(filteredMembers.length, (index) {
                      final m = filteredMembers[index];
                      final name = m['name']?.toString() ?? "";
                      final email = m['email']?.toString() ?? "";
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : (email.isNotEmpty ? email[0].toUpperCase() : "?");
                      final volume = (m['trade_volume'] ?? 0).toDouble();
                      final earned = (m['you_earned'] ?? 0).toDouble();
                      
                      return DataRow(cells: [
                        DataCell(Text("${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 10))),
                        DataCell(Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFCCFF00).withOpacity(0.2),
                              ),
                              child: Center(child: Text(initial, style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 9))),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name.length > 10 ? "${name.substring(0, 8)}..." : name, 
                                    style: const TextStyle(color: Colors.white, fontSize: 10)),
                                Text(email, style: const TextStyle(color: Colors.white54, fontSize: 8)),
                              ],
                            ),
                          ],
                        )),
                        DataCell(Text(m['joined_at'] ?? "—", style: const TextStyle(color: Colors.white, fontSize: 9))),
                        DataCell(Text("\$${volume.toStringAsFixed(2)}", 
                            style: const TextStyle(color: Color(0xFF4BC0FF), fontSize: 9))),
                        DataCell(Text("+${earned.toStringAsFixed(6)}", 
                            style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 9))),
                      ]);
                    }),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startMonth = picked;
        } else {
          _endDate = picked;
          _endMonth = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );
  }
}