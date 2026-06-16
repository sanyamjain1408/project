class Giveaway {
  final dynamic id;
  final String? title;
  final String? slug;
  final String? description;
  final String? bannerImage;
  final String? status;
  final bool? comingSoon;
  final String? endDate;
  final int? winnerCount;
  final double? rewardAmount;
  final String? rewardLabel;
  final String? coinIcon;
  final String? coinSymbol;
  final int? participants;
  final bool? joined;
  final bool? leaderboardEnabled;
  final String? terms;
  final List<int> completedTaskIds;

  Giveaway({
    this.id, this.title, this.slug, this.description, this.bannerImage,
    this.status, this.comingSoon, this.endDate, this.winnerCount,
    this.rewardAmount, this.rewardLabel, this.coinIcon, this.coinSymbol,
    this.participants, this.joined, this.leaderboardEnabled, this.terms,
    this.completedTaskIds = const [],
  });

  factory Giveaway.fromJson(Map<String, dynamic> j) => Giveaway(
    id: j['id'],
    title: j['title'],
    slug: j['slug'],
    description: j['description'],
    bannerImage: j['banner_image'],
    status: j['status'],
    comingSoon: j['coming_soon'] == true || j['coming_soon'] == 1,
    endDate: j['end_date'],
    winnerCount: _toInt(j['winner_count']),
    rewardAmount: _toDouble(j['reward_amount']),
    rewardLabel: j['reward_label'],
    coinIcon: j['coin_icon'],
    coinSymbol: j['coin_symbol'],
    participants: _toInt(j['participants']),
    joined: j['joined'] == true || j['joined'] == 1,
    leaderboardEnabled: j['leaderboard_enabled'] == true || j['leaderboard_enabled'] == 1,
    terms: j['terms'],
    completedTaskIds: (j['completed_task_ids'] as List?)?.map((e) => e as int).toList() ?? [],
  );

  Duration get timeLeft {
    if (endDate == null) return Duration.zero;
    return DateTime.tryParse(endDate!)?.difference(DateTime.now()) ?? Duration.zero;
  }

  bool get isEnded => (status == 'ended' || timeLeft.isNegative) && comingSoon != true;
  bool get isLive => status == 'active' && !isEnded && comingSoon != true;
}

class GiveawayTask {
  final int id;
  final String? name;
  final String? description;
  final String? icon;
  final String? taskLink;
  final bool required;

  GiveawayTask({required this.id, this.name, this.description, this.icon, this.taskLink, this.required = false});

  factory GiveawayTask.fromJson(Map<String, dynamic> j) => GiveawayTask(
    id: _toInt(j['id']) ?? 0,
    name: j['name'],
    description: j['description'],
    icon: j['icon'],
    taskLink: j['task_link'],
    required: j['required'] == true || j['required'] == 1,
  );
}

class GiveawayEntry {
  final String? username;
  GiveawayEntry({this.username});
  factory GiveawayEntry.fromJson(Map<String, dynamic> j) => GiveawayEntry(username: j['username']);
}

class GiveawayWinner {
  final int? rank;
  final String? username;
  final double? rewardAmount;
  final String? rewardStatus;
  GiveawayWinner({this.rank, this.username, this.rewardAmount, this.rewardStatus});
  factory GiveawayWinner.fromJson(Map<String, dynamic> j) => GiveawayWinner(
    rank: _toInt(j['rank']),
    username: j['username'],
    rewardAmount: _toDouble(j['reward_amount']),
    rewardStatus: j['reward_status'],
  );
}

int? _toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());
double? _toDouble(dynamic v) => v == null ? null : double.tryParse(v.toString());
