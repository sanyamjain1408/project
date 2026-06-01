// Multi-Coin Staking Models

class McStakingCoin {
  final int id;
  final String symbol;
  final String coinName;
  final String? logo;

  McStakingCoin({required this.id, required this.symbol, required this.coinName, this.logo});

  factory McStakingCoin.fromJson(Map<String, dynamic> j) => McStakingCoin(
        id: j['id'] ?? 0,
        symbol: j['symbol'] ?? '',
        coinName: j['coin_name'] ?? '',
        logo: j['logo'],
      );
}

class McRateRule {
  final int? id;
  final double minAmount;
  final double maxAmount;
  final double dailyRate;

  McRateRule({this.id, required this.minAmount, required this.maxAmount, required this.dailyRate});

  factory McRateRule.fromJson(Map<String, dynamic> j) => McRateRule(
        id: j['id'],
        minAmount: double.tryParse(j['min_amount'].toString()) ?? 0,
        maxAmount: double.tryParse(j['max_amount'].toString()) ?? 0,
        dailyRate: double.tryParse(j['daily_rate'].toString()) ?? 0,
      );
}

class McStakingPlan {
  final int id;
  final String planName;
  final int planType;
  final int durationDays;
  final double minStake;
  final double maxStake;
  final double rewardCap;
  final List<McRateRule> rateRules;

  McStakingPlan({
    required this.id,
    required this.planName,
    required this.planType,
    required this.durationDays,
    required this.minStake,
    required this.maxStake,
    required this.rewardCap,
    required this.rateRules,
  });

  factory McStakingPlan.fromJson(Map<String, dynamic> j) => McStakingPlan(
        id: j['id'] ?? 0,
        planName: j['plan_name'] ?? '',
        planType: j['plan_type'] ?? 1,
        durationDays: j['duration_days'] ?? 0,
        minStake: double.tryParse(j['min_stake'].toString()) ?? 0,
        maxStake: double.tryParse(j['max_stake'].toString()) ?? 0,
        rewardCap: double.tryParse(j['reward_cap'].toString()) ?? 0,
        rateRules: (j['rate_rules'] as List? ?? []).map((r) => McRateRule.fromJson(r)).toList(),
      );
}

class McCalcResult {
  final double dailyRate;
  final double dailyReward;
  final double totalReward;

  McCalcResult({required this.dailyRate, required this.dailyReward, required this.totalReward});

  factory McCalcResult.fromJson(Map<String, dynamic> j) => McCalcResult(
        dailyRate: double.tryParse(j['daily_rate'].toString()) ?? 0,
        dailyReward: double.tryParse(j['daily_reward'].toString()) ?? 0,
        totalReward: double.tryParse(j['total_reward'].toString()) ?? 0,
      );
}

class McStake {
  final String uid;
  final int status;
  final String? startDate;
  final String? endDate;
  final double amount;
  final double dailyRate;
  final double totalRewardEarned;
  final McStakingCoin? coin;
  final McStakingPlan? plan;

  McStake({
    required this.uid,
    required this.status,
    this.startDate,
    this.endDate,
    required this.amount,
    required this.dailyRate,
    required this.totalRewardEarned,
    this.coin,
    this.plan,
  });

  factory McStake.fromJson(Map<String, dynamic> j) => McStake(
        uid: j['uid'] ?? '',
        status: j['status'] ?? 1,
        startDate: j['start_date'],
        endDate: j['end_date'],
        amount: double.tryParse(j['amount'].toString()) ?? 0,
        dailyRate: double.tryParse(j['daily_rate'].toString()) ?? 0,
        totalRewardEarned: double.tryParse(j['total_reward_earned'].toString()) ?? 0,
        coin: j['coin'] != null ? McStakingCoin.fromJson(j['coin']) : null,
        plan: j['plan'] != null ? McStakingPlan.fromJson(j['plan']) : null,
      );
}

class McPortfolioItem {
  final String stakeUid;
  final String coinSymbol;
  final int coinId;
  final String? coinLogo;
  final double stakedAmount;
  final double dailyRate;
  final double dailyReward;
  final String planName;
  final int planType;
  final String? endDate;
  final String? stakedAt;
  final double totalWithdrawn;
  final double coinPriceUsdt;
  final double usdtValue;
  final double totalEarned;

  McPortfolioItem({
    required this.stakeUid,
    required this.coinSymbol,
    required this.coinId,
    this.coinLogo,
    required this.stakedAmount,
    required this.dailyRate,
    required this.dailyReward,
    required this.planName,
    required this.planType,
    this.endDate,
    this.stakedAt,
    required this.totalWithdrawn,
    required this.coinPriceUsdt,
    required this.usdtValue,
    required this.totalEarned,
  });

  factory McPortfolioItem.fromJson(Map<String, dynamic> j) => McPortfolioItem(
        stakeUid: j['stake_uid'] ?? '',
        coinSymbol: j['coin_symbol'] ?? '',
        coinId: j['coin_id'] ?? 0,
        coinLogo: j['coin_logo'],
        stakedAmount: double.tryParse(j['staked_amount'].toString()) ?? 0,
        dailyRate: double.tryParse(j['daily_rate'].toString()) ?? 0,
        dailyReward: double.tryParse(j['daily_reward'].toString()) ?? 0,
        planName: j['plan_name'] ?? '',
        planType: j['plan_type'] ?? 1,
        endDate: j['end_date'],
        stakedAt: j['staked_at'] ?? j['start_date'],
        totalWithdrawn: double.tryParse(j['total_withdrawn'].toString()) ?? 0,
        coinPriceUsdt: double.tryParse(j['coin_price_usdt'].toString()) ?? 1,
        usdtValue: double.tryParse(j['usdt_value'].toString()) ?? 0,
        totalEarned: double.tryParse(j['total_reward_earned'].toString()) ?? 0,
      );

  double get perSecUsdt {
    final price = coinPriceUsdt > 0 ? coinPriceUsdt : 1;
    return (stakedAmount * (dailyRate / 100)) / 86400 * price;
  }
}

class McUserTier {
  final String tierName;
  final double level1Percent;
  final double level2Percent;
  final double level3Percent;

  McUserTier({required this.tierName, required this.level1Percent, required this.level2Percent, required this.level3Percent});

  factory McUserTier.fromJson(Map<String, dynamic> j) => McUserTier(
        tierName: j['tier_name'] ?? 'Basic',
        level1Percent: double.tryParse(j['level1_percent'].toString()) ?? 0,
        level2Percent: double.tryParse(j['level2_percent'].toString()) ?? 0,
        level3Percent: double.tryParse(j['level3_percent'].toString()) ?? 0,
      );
}

class McPortfolioData {
  final List<McPortfolioItem> portfolio;
  final double totalUsdtValue;
  final McUserTier? userTier;

  McPortfolioData({required this.portfolio, required this.totalUsdtValue, this.userTier});

  factory McPortfolioData.fromJson(Map<String, dynamic> j) => McPortfolioData(
        portfolio: (j['portfolio'] as List? ?? []).map((e) => McPortfolioItem.fromJson(e)).toList(),
        totalUsdtValue: double.tryParse(j['total_usdt_value'].toString()) ?? 0,
        userTier: j['user_tier'] != null ? McUserTier.fromJson(j['user_tier']) : null,
      );
}

class McStakingReward {
  final int id;
  final double rewardAmount;
  final double dailyRate;
  final String? rewardDate;
  final McStakingCoin? coin;

  McStakingReward({required this.id, required this.rewardAmount, required this.dailyRate, this.rewardDate, this.coin});

  factory McStakingReward.fromJson(Map<String, dynamic> j) => McStakingReward(
        id: j['id'] ?? 0,
        rewardAmount: double.tryParse(j['reward_amount'].toString()) ?? 0,
        dailyRate: double.tryParse(j['daily_rate'].toString()) ?? 0,
        rewardDate: j['reward_date'],
        coin: j['coin'] != null ? McStakingCoin.fromJson(j['coin']) : null,
      );
}

class McReferralReward {
  final int id;
  final int referralLevel;
  final double rewardAmount;
  final double fromEarning;
  final double? commissionPct;
  final String? rewardDate;
  final String? fromName;
  final String? fromEmail;
  final McStakingCoin? coin;

  McReferralReward({
    required this.id,
    required this.referralLevel,
    required this.rewardAmount,
    required this.fromEarning,
    this.commissionPct,
    this.rewardDate,
    this.fromName,
    this.fromEmail,
    this.coin,
  });

  factory McReferralReward.fromJson(Map<String, dynamic> j) => McReferralReward(
        id: j['id'] ?? 0,
        referralLevel: j['referral_level'] ?? 1,
        rewardAmount: double.tryParse(j['reward_amount'].toString()) ?? 0,
        fromEarning: double.tryParse(j['from_earning'].toString()) ?? 0,
        commissionPct: double.tryParse(j['commission_pct'].toString()),
        rewardDate: j['reward_date'],
        fromName: j['from_name'],
        fromEmail: j['from_email'],
        coin: j['coin'] != null ? McStakingCoin.fromJson(j['coin']) : null,
      );
}

class McWithdrawRecord {
  final int id;
  final double grossAmount;
  final double feeAmount;
  final double rewardAmount;
  final String? createdAt;
  final String? txRef;
  final McStakingCoin? coin;

  McWithdrawRecord({
    required this.id,
    required this.grossAmount,
    required this.feeAmount,
    required this.rewardAmount,
    this.createdAt,
    this.txRef,
    this.coin,
  });

  factory McWithdrawRecord.fromJson(Map<String, dynamic> j) => McWithdrawRecord(
        id: j['id'] ?? 0,
        grossAmount: double.tryParse(j['gross_amount']?.toString() ?? j['reward_amount'].toString()) ?? 0,
        feeAmount: double.tryParse(j['fee_amount'].toString()) ?? 0,
        rewardAmount: double.tryParse(j['reward_amount'].toString()) ?? 0,
        createdAt: j['created_at'],
        txRef: j['tx_ref'],
        coin: j['coin'] != null ? McStakingCoin.fromJson(j['coin']) : null,
      );
}

class McStatistics {
  final int totalActiveStakes;
  final double totalRewardEarned;
  final int totalReferralCommissions;

  McStatistics({required this.totalActiveStakes, required this.totalRewardEarned, required this.totalReferralCommissions});

  factory McStatistics.fromJson(Map<String, dynamic> j) => McStatistics(
        totalActiveStakes: j['total_active_stakes'] ?? 0,
        totalRewardEarned: double.tryParse(j['total_reward_earned'].toString()) ?? 0,
        totalReferralCommissions: j['total_referral_commissions'] ?? 0,
      );
}
