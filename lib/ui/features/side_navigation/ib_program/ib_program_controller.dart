import 'package:get/get.dart';

class IBController extends GetxController {
  var stats = IBStats().obs;
  var networkMembers = <dynamic>[].obs;

  void getIBData() {
    // TODO: Implement your API call here
    stats.value = IBStats(
      referralLink: "https://trapix.com/signup?ib_code=TEST123",
      referralCode: "TRX-5Q905R",
      totalReferrals: 7,
      totalEarned: 6.70,
      tierName: "Starter",
      activeReferrals: 3,
      pendingBalance: 0.0,
    );
    
    networkMembers.value = [
      {'name': 'tyty', 'email': 'tyt***', 'joined_at': '2026-04-02', 'trade_volume': 4960.07, 'you_earned': 4.464067, 'their_referrals': 0},
      {'name': 'ghghg ghghg', 'email': 'ghg***', 'joined_at': '2026-04-10', 'trade_volume': 2480.04, 'you_earned': 2.232034, 'their_referrals': 0},
      {'name': 'nmmn nmnm', 'email': 'nmn***', 'joined_at': '2026-04-10', 'trade_volume': 0, 'you_earned': 0, 'their_referrals': 0},
      {'name': 'Test User', 'email': 'test***', 'joined_at': '2026-04-13', 'trade_volume': 0, 'you_earned': 0, 'their_referrals': 0},
    ];
  }
}

class IBStats {
  String? referralLink;
  String? referralCode;
  int? totalReferrals;
  double? totalEarned;
  String? tierName;
  int? activeReferrals;
  double? pendingBalance;
  
  IBStats({
    this.referralLink,
    this.referralCode,
    this.totalReferrals,
    this.totalEarned,
    this.tierName,
    this.activeReferrals,
    this.pendingBalance,
  });
}