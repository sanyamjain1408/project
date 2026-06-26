import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/root/prefetch_service.dart';

// ─────────────────────────── CONFIG ──────────────────────────────────────────
const _kBase = 'https://api.trapix.com';
const _lime = Color(0xFFCCFF00);
const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _grey = Color(0xFF888888);
const _border = Color(0xFF2A2A2A);

// ─────────────────────────── USER HELPER ─────────────────────────────────────
String get _uid {
  try {
    return gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';
  } catch (_) {
    return '';
  }
}

// ─────────────────────────── HTTP HELPERS ────────────────────────────────────
Future<Map<String, dynamic>> _get(String path) async {
  debugPrint('[AIRDROP API] GET $path');
  final res = await http.get(Uri.parse('$_kBase$path'));
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _post(String path, Map body) async {
  debugPrint('[AIRDROP API] POST $path');
  final res = await http.post(
    Uri.parse('$_kBase$path'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  return jsonDecode(res.body) as Map<String, dynamic>;
}

// ─────────────────────────── FORMAT HELPERS ──────────────────────────────────
String _formatReward(double r, String coin) {
  if (r == 0) return '0.00 $coin';
  if (r == r.truncateToDouble()) return '${r.toInt()} $coin';
  String s = r.toStringAsFixed(8);
  s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return '$s $coin';
}

// ─────────────────────────── ICON URL RESOLVER ───────────────────────────────
String? _resolveIconUrl(String coinType, dynamic airdropData) {
  final sym = coinType.toLowerCase();
  const keys = ['coin_icon', 'icon_url', 'icon', 'logo', 'coin_logo', 'image'];
  for (final key in keys) {
    final v = airdropData[key];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  // CoinCap sources (Fixed: removed const)
  final sources = [
    'https://assets.coincap.io/assets/icons/$sym@2x.png',
    'https://cdn.jsdelivr.net/gh/spothq/cryptocurrency-icons@master/32/color/$sym.png',
    'https://raw.githubusercontent.com/ErikThiart/cryptocurrency-icons/master/16/$sym.png',
  ];
  return sources[0];
}

String? _resolveTaskUrl(dynamic airdrop, String task) {
  final directKey = '${task}_url';
  final direct = airdrop[directKey];
  if (direct != null && direct.toString().isNotEmpty) return direct.toString();

  final urls = airdrop['urls'];
  if (urls is Map) {
    final v = urls[task];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return null;
}

String? _resolveBannerImage(dynamic airdrop) {
  const keys = [
    'banner_image',
    'banner',
    'cover_image',
    'image',
    'header_image',
    'thumbnail',
  ];
  for (final key in keys) {
    final v = airdrop[key];
    if (v != null && v.toString().isNotEmpty && v.toString() != 'null') {
      return v.toString().startsWith('http')
          ? v.toString()
          : '$_kBase/storage/${v.toString()}';
    }
  }
  return null;
}

// ─────────────────────────── COUNTDOWN WIDGET ────────────────────────────────
class _CountdownText extends StatefulWidget {
  final int initialSeconds;
  final TextStyle? style;
  const _CountdownText(this.initialSeconds, {this.style});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  late int _secs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secs = widget.initialSeconds;
    if (_secs > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _secs = (_secs - 1).clamp(0, 999999));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _d => (_secs ~/ 86400).toString();
  String get _h => ((_secs % 86400) ~/ 3600).toString().padLeft(2, '0');
  String get _m => ((_secs % 3600) ~/ 60).toString().padLeft(2, '0');
  String get _s => (_secs % 60).toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final bool hasDays = _secs >= 86400;
    final label = hasDays
        ? '${_d}D : ${_h}H : ${_m}M : ${_s}S'
        : '${_h}H : ${_m}M : ${_s}S';
    return Text(
      _secs <= 0 ? 'Ended' : label,
      style:
          widget.style ??
          const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
    );
  }
}

// ─────────────────────────── COIN ICON WIDGET ────────────────────────────────
class _CoinIcon extends StatelessWidget {
  final String coinType;
  final String? iconUrl;
  final double size;
  const _CoinIcon({required this.coinType, this.iconUrl, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final url = iconUrl?.isNotEmpty == true ? iconUrl! : null;
    return ClipOval(
      child: url != null
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
              loadingBuilder: (_, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _fallback();
              },
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    final gradients = {
      'BTC': [const Color(0xFFF7931A), const Color(0xFFE8820C)],
      'ETH': [const Color(0xFF627EEA), const Color(0xFF3B54C5)],
      'BNB': [const Color(0xFFF3BA2F), const Color(0xFFD4A017)],
      'SOL': [const Color(0xFF9945FF), const Color(0xFF14F195)],
      'USDT': [const Color(0xFF26A17B), const Color(0xFF1A7A5E)],
      'USDC': [const Color(0xFF2775CA), const Color(0xFF1A4F8A)],
      'XRP': [const Color(0xFF00AAE4), const Color(0xFF0077AA)],
      'ADA': [const Color(0xFF0033AD), const Color(0xFF001F6E)],
      'DOGE': [const Color(0xFFC2A633), const Color(0xFF8B7322)],
      'TRX': [const Color(0xFFEF0027), const Color(0xFFA00019)],
      'TPX': [const Color(0xFFCCFF00), const Color(0xFF66AA00)],
      'BONK': [const Color(0xFFFF9500), const Color(0xFFCC6600)],
    };
    final colors =
        gradients[coinType.toUpperCase()] ??
        [const Color(0xFF444444), const Color(0xFF222222)];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          coinType.isNotEmpty ? coinType[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── TASK META ───────────────────────────────────────
const Map<String, Map<String, dynamic>> _taskMeta = {
  'twitter': {
    'label': 'Follow on X (Twitter)',
    'desc': 'Follow us on X / Twitter',
    'btn': 'Follow & Verify',
    'social': true,
  },
  'telegram': {
    'label': 'Join Telegram Channel',
    'desc': 'Join our official Telegram channel',
    'btn': 'Join & Verify',
    'social': true,
  },
  'instagram': {
    'label': 'Follow on Instagram',
    'desc': 'Follow us on Instagram',
    'btn': 'Follow & Verify',
    'social': true,
  },
  'facebook': {
    'label': 'Like on Facebook',
    'desc': 'Like & follow us on Facebook',
    'btn': 'Like & Verify',
    'social': true,
  },
  'youtube': {
    'label': 'Subscribe on YouTube',
    'desc': 'Subscribe to our YouTube channel',
    'btn': 'Subscribe & Verify',
    'social': true,
  },
  'tiktok': {
    'label': 'Follow on TikTok',
    'desc': 'Follow us on TikTok',
    'btn': 'Follow & Verify',
    'social': true,
  },
  'discord': {
    'label': 'Join Discord Server',
    'desc': 'Join our Discord community',
    'btn': 'Join & Verify',
    'social': true,
  },
  'referral': {
    'label': 'Refer a Friend',
    'desc': 'Invite a friend who registers',
    'btn': 'Invite Friend',
    'social': true,
  },
  'email_verify': {
    'label': 'Verify Email',
    'desc': 'Verify your email address',
    'btn': 'Verify Now',
    'social': false,
    'hint': 'Settings → Security → Verify Email',
  },
  'phone_verify': {
    'label': 'Verify Phone Number',
    'desc': 'Verify your phone number',
    'btn': 'Verify Now',
    'social': false,
    'hint': 'Settings → Security → Phone Verification',
  },
  'kyc': {
    'label': 'Complete KYC',
    'desc': 'Complete identity verification',
    'btn': 'Verify Now',
    'social': false,
    'hint': 'Settings → KYC Verification',
  },
  'first_deposit': {
    'label': 'Make First Deposit',
    'desc': 'Deposit any cryptocurrency',
    'btn': 'Deposit Now',
    'social': false,
    'hint': 'Wallet → Deposit',
  },
  'first_trade': {
    'label': 'Place First Trade',
    'desc': 'Place your first buy or sell order',
    'btn': 'Trade Now',
    'social': false,
    'hint': 'Exchange → Spot Trading',
  },
  'two_fa': {
    'label': 'Enable 2FA',
    'desc': 'Enable Google Authenticator',
    'btn': 'Enable Now',
    'social': false,
    'hint': 'Settings → Security → Enable 2FA',
  },
  'profile_complete': {
    'label': 'Complete Profile',
    'desc': 'Fill in all profile details',
    'btn': 'Complete Now',
    'social': false,
    'hint': 'Settings → Profile',
  },
  'first_withdrawal': {
    'label': 'Make First Withdrawal',
    'desc': 'Withdraw any cryptocurrency',
    'btn': 'Withdraw Now',
    'social': false,
    'hint': 'Wallet → Withdraw',
  },
};

Map<String, dynamic> _getTaskMeta(String task) {
  return _taskMeta[task] ??
      {
        'label': task
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w,
            )
            .join(' '),
        'desc': 'Complete this task',
        'btn': 'Verify',
        'social': false,
      };
}

Widget _buildTaskIcon(String task) {
  switch (task) {
    case 'twitter':
      return const Center(
        child: Text(
          '𝕏',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    case 'telegram':
      return const Icon(Icons.send_rounded, color: Color(0xFF2AABEE), size: 30);
    case 'instagram':
      return ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [Color(0xFFE1306C), Color(0xFFF77737), Color(0xFF833AB4)],
        ).createShader(b),
        child: const Icon(
          Icons.camera_alt_outlined,
          color: Colors.white,
          size: 30,
        ),
      );
    case 'facebook':
      return const Icon(
        Icons.facebook_rounded,
        color: Color(0xFF1877F2),
        size: 40,
      );
    case 'youtube':
      return const Icon(
        Icons.play_circle_fill_rounded,
        color: Color(0xFFFF0000),
        size: 30,
      );
    case 'tiktok':
      return const Center(
        child: Text(
          'TT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    case 'discord':
      return const Icon(
        Icons.headset_mic_outlined,
        color: Color(0xFF5865F2),
        size: 30,
      );
    case 'referral':
      return const Icon(Icons.group_add_outlined, color: _lime, size: 20);
    case 'email_verify':
      return const Icon(Icons.email_outlined, color: Colors.white, size: 20);
    case 'phone_verify':
      return const Icon(Icons.phone_outlined, color: Colors.white, size: 20);
    case 'kyc':
      return const Icon(Icons.badge_outlined, color: Colors.white, size: 20);
    case 'first_deposit':
      return const Icon(
        Icons.account_balance_wallet_outlined,
        color: Colors.white,
        size: 20,
      );
    case 'first_trade':
      return const Icon(
        Icons.show_chart_rounded,
        color: Colors.white,
        size: 20,
      );
    case 'two_fa':
      return const Icon(Icons.lock_outlined, color: Colors.white, size: 20);
    case 'profile_complete':
      return const Icon(
        Icons.person_outline_rounded,
        color: Colors.white,
        size: 20,
      );
    case 'first_withdrawal':
      return const Icon(
        Icons.arrow_upward_rounded,
        color: Colors.white,
        size: 20,
      );
    default:
      return const Icon(Icons.star_outline_rounded, color: _lime, size: 20);
  }
}

bool _isClaimed(dynamic participant) {
  final s = participant?['claim_status'] ?? participant?['status'];
  return s == 'claimed' || s == 'transferred' || s == 'completed';
}

// ─────────────────────────── AIRDROP LIST SCREEN ─────────────────────────────
class AirdropScreen extends StatefulWidget {
  const AirdropScreen({super.key});

  @override
  State<AirdropScreen> createState() => _AirdropScreenState();
}

class _AirdropScreenState extends State<AirdropScreen> {
  List<dynamic> _airdrops = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PrefetchService>()) {
      final cached = PrefetchService.to.airdropList;
      if (cached.isNotEmpty) {
        _airdrops = List.from(cached);
        _loading = false;
      }
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      if (_airdrops.isEmpty) _loading = true;
      _error = null;
    });
    try {
      final data = await _get('/api/airdrops?user_id=$_uid');
      final list =
          (data['data'] ?? data['airdrops'] ?? data['result'] ?? []) as List;
      if (mounted) {
        setState(() => _airdrops = list);
        if (Get.isRegistered<PrefetchService>()) PrefetchService.to.airdropList.assignAll(list);
      }
    } catch (e) {
      debugPrint('[AirdropScreen] ERROR: $e');
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  int get _activeCount => _airdrops.where((a) {
    return a['is_active'] == true ||
        a['is_active'] == 1 ||
        a['status'] == 'active';
  }).length;

  int get _claimedCount => _airdrops.where((a) {
    return _isClaimed(a['participant']);
  }).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: RefreshIndicator(
        color: _lime,
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── HEADER (Bahas wale screen jaisa) ──
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Full Background Image
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/airdrop.png.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.transparent,
                        child: const Center(
                          child: Icon(
                            Icons.card_giftcard,
                            color: _lime,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.transparent],
                      ),
                    ),
                  ),
                  // Back Button
                  Positioned(
                    top: 45,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: Get.back,
                    ),
                  ),
                  // Title and Stats
                  Positioned(
                    left: 20,
                    bottom: 24,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Airdrops',
                          style: TextStyle(
                            color: _lime,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DMSans',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Complete tasks, claim free\ncrypto instantly to your\nAirdrop Wallet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'DMSans',
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _badge('Active : $_activeCount', filled: true),
                            const SizedBox(width: 10),
                            _badge('Claimed : $_claimedCount', filled: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── BODY ──
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _lime)),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: _grey,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Failed to load',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _error!,
                        style: const TextStyle(color: _grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lime,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_airdrops.isEmpty)
              SliverFillRemaining(child: _emptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _AirdropCard(
                        airdrop: _airdrops[i],
                        onTap: () => Get.to(
                          () => AirdropDetailScreen(
                            airdropId: _airdrops[i]['id'].toString(),
                          ),
                        )?.then((_) => _load()),
                      ),
                    ),
                    childCount: _airdrops.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.card_giftcard_rounded, color: _grey, size: 64),
        const SizedBox(height: 16),
        const Text(
          'No Active Airdrops',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Check back soon for upcoming campaigns',
          style: TextStyle(color: _grey, fontSize: 13),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, color: _lime),
          label: const Text('Refresh', style: TextStyle(color: _lime)),
        ),
      ],
    ),
  );

  Widget _badge(String text, {required bool filled}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: filled
          ? const Color(0xFF00FF04).withOpacity(0.3)
          : const Color(0xFFCCFF00).withOpacity(0.3),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: filled ? Colors.transparent : Colors.transparent,
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: filled ? const Color(0xFF00FF04) : const Color(0xFFCCFF00),
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: 'DMSans',
      ),
    ),
  );
}

// ─────────────────────────── AIRDROP CARD ────────────────────────────────────
class _AirdropCard extends StatelessWidget {
  final dynamic airdrop;
  final VoidCallback onTap;
  const _AirdropCard({required this.airdrop, required this.onTap});

  bool get _isActive =>
      airdrop['is_active'] == true ||
      airdrop['is_active'] == 1 ||
      airdrop['status'] == 'active';
  bool get _claimed => _isClaimed(airdrop['participant']);
  bool get _hasParticipant => airdrop['participant'] != null;
  int _parseInt(dynamic v) => int.tryParse(v.toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final double reward =
        double.tryParse(airdrop['reward_amount']?.toString() ?? '0') ?? 0;
    final String coin = (airdrop['coin_type'] ?? airdrop['coin'] ?? '')
        .toString();
    final String title = (airdrop['title'] ?? '').toString();
    final String description = (airdrop['description'] ?? '').toString();
    final int total = _parseInt(
      airdrop['total_slots'] ?? airdrop['max_participants'] ?? 0,
    );
    final int claimed = _parseInt(
      airdrop['claimed_slots'] ?? airdrop['participants_count'] ?? 0,
    );
    final int slotsLeft = _parseInt(
      airdrop['slots_left'] ?? airdrop['remaining_slots'] ?? (total - claimed),
    );
    final double progress = total > 0 ? (claimed / total).clamp(0.0, 1.0) : 0;
    final int secsLeft = _parseInt(
      airdrop['seconds_left'] ?? airdrop['time_left'] ?? 0,
    );
    final String? iconUrl = _resolveIconUrl(coin, airdrop);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0A6B9C)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CoinIcon(coinType: coin, iconUrl: iconUrl, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coin,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _liveBadge(_isActive, secsLeft),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  height: 1.4,
                  fontFamily: 'DMSans',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatReward(reward, coin),
                  style: const TextStyle(
                    color: _lime,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  'Per User',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$claimed Claimed',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DMSans',
                  ),
                ),
                Text(
                  '$slotsLeft Left',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 5,
                child: Stack(
                  children: [
                    // BACKGROUND
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),

                    // PROGRESS
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),

                          // BORDER
                          border: Border.all(
                            width: 1,
                            color: const Color(0xFF00B2E3),
                          ),

                          // GRADIENT
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF00B2E3),
                              Color(0xFFFFA600),
                              Color(0xFFF03A89),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _CountdownText(
                  secsLeft,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _claimed
                      ? const Color(0xFFCCFF00).withOpacity(0.5)
                      : _lime,
                  foregroundColor: _claimed
                      ? const Color(0xFF111111)
                      : const Color(0xFF111111),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _claimed
                      ? 'Claimed'
                      : (_hasParticipant ? 'Continue Tasks' : 'Claim Now'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: 'DMSans',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveBadge(bool active, int secsLeft) {
    if (!active || secsLeft <= 0) {
      return Text(
        'Ended',
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: "DMSans",
        ),
      );
    }
    return const Text(
      'Live',
      style: TextStyle(
        color: _lime,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: "DMSans",
      ),
    );
  }
}

// ─────────────────────────── AIRDROP DETAIL SCREEN (UPDATED UI) ───────────────
class AirdropDetailScreen extends StatefulWidget {
  final String airdropId;
  const AirdropDetailScreen({super.key, required this.airdropId});

  @override
  State<AirdropDetailScreen> createState() => _AirdropDetailScreenState();
}

class _AirdropDetailScreenState extends State<AirdropDetailScreen> {
  dynamic _airdrop;
  dynamic _participant;
  bool _loading = true;
  String? _error;
  String? _verifying;
  bool _claiming = false;
  double _airdropBalance = 0;
  final _transferCtrl = TextEditingController();
  bool _transferring = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _transferCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _get(
        '/api/airdrops/${widget.airdropId}?user_id=$_uid',
      );
      final d = data['data'] ?? data['airdrop'] ?? data['result'];
      if (d == null) throw Exception('Empty response');
      final part = d['participant'] ?? data['participant'];
      if (mounted) {
        setState(() {
          _airdrop = d;
          _participant = part;
        });
        if (_uid.isNotEmpty) {
          final coinType = (d['coin_type'] ?? d['coin'] ?? '').toString();
          if (coinType.isNotEmpty) _fetchBalance(coinType);
        }
      }
    } catch (e) {
      debugPrint('[AirdropDetail] ERROR: $e');
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchBalance(String coinType) async {
    try {
      final data = await _get('/api/airdrops/wallet-balance?user_id=$_uid');
      List list = [];
      if (data['data'] is List)
        list = data['data'] as List;
      else if (data['balances'] is List)
        list = data['balances'] as List;
      final w = list.firstWhereOrNull(
        (x) =>
            (x['coin_type'] ?? x['coin'] ?? '').toString().toUpperCase() ==
            coinType.toUpperCase(),
      );
      if (w != null && mounted) {
        setState(
          () => _airdropBalance =
              double.tryParse(w['balance']?.toString() ?? '0') ?? 0,
        );
      }
    } catch (e) {
      debugPrint('[AirdropDetail] balance ERROR: $e');
    }
  }

  bool _isTaskDone(String task) {
    final v1 = _participant?['task_$task'];
    if (v1 == true || v1 == 1) return true;
    final tasks = _participant?['tasks'];
    if (tasks is Map) {
      final v2 = tasks[task];
      if (v2 == true || v2 == 1) return true;
    }
    final v3 = _participant?[task];
    return v3 == true || v3 == 1;
  }

  List<String> get _enabledTasks {
    final raw = _airdrop?['enabled_tasks'] ?? _airdrop?['tasks_list'];
    if (raw is List) return raw.cast<String>();
    final tasksMap = _airdrop?['tasks'];
    if (tasksMap is Map) {
      return tasksMap.entries
          .where((e) => e.value == true || e.value == 1)
          .map((e) => e.key.toString())
          .toList();
    }
    const allTasks = [
      'twitter',
      'telegram',
      'instagram',
      'facebook',
      'youtube',
      'tiktok',
      'discord',
      'referral',
      'email_verify',
      'phone_verify',
      'kyc',
      'first_deposit',
      'first_trade',
      'two_fa',
      'profile_complete',
      'first_withdrawal',
    ];
    return allTasks.where((t) {
      final v = _airdrop?['task_$t'];
      return v == true || v == 1;
    }).toList();
  }

  bool get _allTasksDone =>
      _enabledTasks.isNotEmpty && _enabledTasks.every(_isTaskDone);
  int get _doneCount => _enabledTasks.where(_isTaskDone).length;
  bool get _claimed => _isClaimed(_participant);

  Future<void> _verify(String task) async {
    if (_uid.isEmpty) {
      _toast('Please login first', err: true);
      return;
    }
    if (_isTaskDone(task)) return;
    setState(() => _verifying = task);
    try {
      final data = await _post(
        '/api/airdrops/${widget.airdropId}/verify-task',
        {'user_id': _uid, 'task': task},
      );
      if (data['status'] == true || data['success'] == true) {
        final newPart = data['data'] ?? data['participant'] ?? _participant;
        setState(() => _participant = newPart);
        _toast('${_getTaskMeta(task)['label']} verified!');
      } else {
        _toast(
          (data['message'] ?? data['error'] ?? 'Verification failed')
              .toString(),
          err: true,
        );
      }
    } catch (e) {
      _toast('Verification failed', err: true);
    }
    if (mounted) setState(() => _verifying = null);
  }

  Future<void> _claim() async {
    if (_uid.isEmpty) {
      _toast('Please login first', err: true);
      return;
    }
    setState(() => _claiming = true);
    try {
      final data = await _post('/api/airdrops/${widget.airdropId}/claim', {
        'user_id': _uid,
      });
      if (data['status'] == true || data['success'] == true) {
        final d = data['data'] ?? {};
        final newBal =
            double.tryParse(
              (d['airdrop_balance'] ?? d['balance'] ?? '0').toString(),
            ) ??
            0;
        setState(() {
          _participant = {
            ...(_participant as Map? ?? {}),
            'claim_status': 'claimed',
          };
          if (newBal > 0) _airdropBalance = newBal;
        });
        final coin = (_airdrop?['coin_type'] ?? _airdrop?['coin'] ?? '')
            .toString();
        _toast('${_airdrop?['reward_amount']} $coin claimed!');
      } else {
        _toast(
          (data['message'] ?? data['error'] ?? 'Claim failed').toString(),
          err: true,
        );
      }
    } catch (e) {
      _toast('Claim failed', err: true);
    }
    if (mounted) setState(() => _claiming = false);
  }

  Future<void> _transfer() async {
    final amount = double.tryParse(_transferCtrl.text.trim()) ?? 0;
    if (amount <= 0 || amount > _airdropBalance) {
      _toast(
        'Enter a valid amount (max ${_airdropBalance.toStringAsFixed(8)})',
        err: true,
      );
      return;
    }
    final coin = (_airdrop?['coin_type'] ?? _airdrop?['coin'] ?? '').toString();
    setState(() => _transferring = true);
    try {
      final data = await _post('/api/airdrops/transfer-to-spot', {
        'user_id': _uid,
        'coin_type': coin,
        'amount': amount,
      });
      if (data['status'] == true || data['success'] == true) {
        final d = data['data'] ?? {};
        final newBal =
            double.tryParse(
              (d['airdrop_balance'] ?? d['balance'] ?? '0').toString(),
            ) ??
            0;
        setState(() {
          _airdropBalance = newBal;
          _transferCtrl.clear();
        });
        _toast('$amount $coin moved to Spot Wallet!');
      } else {
        _toast(
          (data['message'] ?? data['error'] ?? 'Transfer failed').toString(),
          err: true,
        );
      }
    } catch (e) {
      _toast('Transfer failed', err: true);
    }
    if (mounted) setState(() => _transferring = false);
  }

  void _toast(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontFamily: 'DMSans'),
        ),
        backgroundColor: err
            ? const Color(0xFF5C1A1A)
            : const Color(0xFF1A3A0A),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingScaffold();
    if (_error != null || _airdrop == null) return _errorScaffold();

    // Data Parsing
    final String coin = (_airdrop['coin_type'] ?? _airdrop['coin'] ?? '')
        .toString();
    final double reward =
        double.tryParse(_airdrop['reward_amount']?.toString() ?? '0') ?? 0;
    final bool isActive =
        _airdrop['is_active'] == true ||
        _airdrop['is_active'] == 1 ||
        _airdrop['status'] == 'active';
    final int secsLeft =
        int.tryParse(_airdrop['seconds_left']?.toString() ?? '0') ?? 0;

    final int slotsLeft =
        int.tryParse(
          (_airdrop['slots_left'] ?? _airdrop['remaining_slots'] ?? 0)
              .toString(),
        ) ??
        0;
    final int claimedSlots =
        int.tryParse(
          (_airdrop['claimed_slots'] ?? _airdrop['participants_count'] ?? 0)
              .toString(),
        ) ??
        0;
    final int totalSlots =
        int.tryParse(
          (_airdrop['total_slots'] ?? _airdrop['max_participants'] ?? 0)
              .toString(),
        ) ??
        0;
    final String? totalPool = _airdrop['total_pool']?.toString();
    final String? remainingPool = _airdrop['remaining_pool']?.toString();

    final String? iconUrl = _resolveIconUrl(coin, _airdrop);
    // final String? bannerUrl = _resolveBannerImage(_airdrop);
    final int totalTasks = _enabledTasks.length;
    final double taskProgress = totalTasks > 0 ? _doneCount / totalTasks : 0;
    final String description = (_airdrop['description'] ?? '').toString();
    final String title = (_airdrop['title'] ?? '').toString();

    // Calculate Stats for Header
    final int _activeCount = isActive ? 1 : 0;
    final int _claimedCount = _claimed ? 1 : 0;

    // ─── NEW STRUCTURE: FULL SCREEN SCROLL ───
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          // 1. BACKGROUND COLOR
          // Ye black background hoga jo image ke niche dikhega scroll karte waqt
          Container(color: _bg),

          // 2. SINGLE CHILD SCROLL VIEW
          // Isme pura content hai (Header Image + Niche ka data)
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER IMAGE SECTION ──
                // Ye bhi scroll hoga upar jaane par
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Background Image
                      Image.asset(
                        'assets/images/airdrop.png.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF0A1A2A),
                          child: const Center(
                            child: Icon(
                              Icons.card_giftcard,
                              color: _lime,
                              size: 80,
                            ),
                          ),
                        ),
                      ),
                      // Back Button
                      Positioned(
                        top: 45,
                        left: 10,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: Get.back,
                        ),
                      ),
                      // Bottom Text & Stats
                      Positioned(
                        left: 20,
                        bottom: 24,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Airdrops',
                              style: TextStyle(
                                color: _lime,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Complete tasks, claim free crypto instantly',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _badge('Active : $_activeCount', filled: true),
                                const SizedBox(width: 10),
                                _badge(
                                  'Claimed : $_claimedCount',
                                  filled: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── CONTENT SECTION (Scrolls with Header) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── AIRDROP CARD (Detailed View) ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Coin & Title Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CoinIcon(
                                  coinType: coin,
                                  iconUrl: iconUrl,
                                  size: 30,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        coin,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'DMSans',
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12,
                                          fontFamily: 'DMSans',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                _liveBadge(isActive, secsLeft),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatReward(reward, coin),
                                  style: const TextStyle(
                                    color: _lime,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    fontFamily: "DMSans",
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Per User',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 12,
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Stats Grid
                            Row(
                              children: [
                                _statTile('$claimedSlots Claimed', 'Claimed'),
                                const SizedBox(width: 10),
                                _statTile('$slotsLeft Left', 'Slots Remaining'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _statTile('$totalSlots Total', 'Total Slots'),
                                const SizedBox(width: 10),
                                _statTile(
                                  '${(claimedSlots / totalSlots * 100).toStringAsFixed(1)}%',
                                  'Filled',
                                ),
                              ],
                            ),
                            // Pools if available
                            if (totalPool != null && remainingPool != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _statTile('$totalPool $coin', 'Total Pool'),
                                  const SizedBox(width: 10),
                                  _statTile(
                                    '$remainingPool $coin',
                                    'Remaining Pool',
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Progress Bar

                            // Countdown
                            Row(
                              children: [
                                Text(
                                  'Ends in: ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                _CountdownText(
                                  secsLeft,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "DMSans",
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── TASKS SECTION ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Complete Tasks',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: "DMSans",
                            ),
                          ),
                          Text(
                            '$_doneCount / $totalTasks',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: "DMSans",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          height: 5,

                          // OUTER GRADIENT BORDER
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF00B2E3),
                                Color(0xFFFFA600),
                                Color(0xFFF03A89),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),

                          padding: const EdgeInsets.all(1), // border thickness

                          child: Stack(
                            children: [
                              // Background
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),

                              // Progress Fill
                              FractionallySizedBox(
                                widthFactor: taskProgress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF00B2E3),
                                        Color(0xFFFFA600),
                                        Color(0xFFF03A89),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      ..._enabledTasks.asMap().entries.map((entry) {
                        final i = entry.key;
                        final task = entry.value;
                        final meta = _getTaskMeta(task);
                        final done = _isTaskDone(task);
                        final isVerifying = _verifying == task;
                        final prevDone =
                            i == 0 || _isTaskDone(_enabledTasks[i - 1]);
                        final locked = !prevDone && !done;
                        final taskUrl = _resolveTaskUrl(_airdrop, task);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: done ? const Color(0xFF1A1A1A) : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: done ? Colors.transparent : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: _buildTaskIcon(task),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Opacity(
                                    opacity: locked ? 0.4 : 1.0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meta['label'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: "DMSans",
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          done
                                              ? '✓ Verified'
                                              : locked
                                              ? 'Complete previous task first'
                                              : taskUrl != null
                                              ? taskUrl
                                              : (meta['hint'] ?? meta['desc'])
                                                    as String,
                                          style: TextStyle(
                                            color: done
                                                ? Colors.white.withOpacity(0.5)
                                                : Colors.white.withOpacity(0.5),
                                            fontSize: 12,
                                            fontFamily: "DMSans",
                                            fontWeight: FontWeight.w400,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (done)
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: _lime,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                  )
                                else if (locked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF222222),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _border),
                                    ),
                                    child:  Text(
                                      'Locked',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: "DMSans",
                                      ),
                                    ),
                                  )
                                else if (isVerifying)
                                  const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: _lime,
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: () => _verify(task),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _lime,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Text(
                                        meta['btn'] as String,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      // ── CLAIM BAR ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.transparent
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatReward(reward, coin),
                                    style: const TextStyle(
                                      color: _lime,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: "DMSans",

                                    ),
                                  ),
                                 Text(
                                    'Your Reward',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                      fontFamily: "DMSans",
                                      fontWeight: FontWeight.w400,
                                    
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Opacity(
                              opacity: _allTasksDone ? 1.0 : 0.45,
                              child: ElevatedButton(
                                onPressed:
                                    _allTasksDone && !_claimed && !_claiming
                                    ? _claim
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _claimed
                                      ? _lime
                                      : _lime,
                                  foregroundColor: _claimed
                                      ? Colors.black
                                      : Colors.black,
                                  disabledBackgroundColor: _claimed
                                      ? _lime.withOpacity(0.5)
                                      : _lime.withOpacity(0.5),
                                  disabledForegroundColor: _claimed
                                      ? Colors.black.withOpacity(0.5)
                                      : Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _claimed
                                      ? '✓ Claimed'
                                      : (_claiming
                                            ? 'Claiming...'
                                            : (_allTasksDone
                                                  ? 'Claim $coin'
                                                  : 'Complete Tasks')),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── AIRDROP WALLET ──
                      if (_claimed) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                     
                                      Text(
                                        'Airdrop Wallet',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: "DMSans",
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _airdropBalance.toStringAsFixed(8),
                                        style: const TextStyle(
                                          color: _lime,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: "DMSans",
                                        ),
                                      ),
                                      Text(
                                        coin,
                                        style:  TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12,
                                          fontFamily: "DMSans",
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                               Text(
                                'Transfer to Spot Wallet for trading',
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: "DMSans", fontWeight: FontWeight.w400, height: 1.3,),
                              ),
                              if (_airdropBalance > 0) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _transferCtrl,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: _bg,
                                          hintText:
                                              'Amount (max ${_airdropBalance.toStringAsFixed(8)})',
                                          hintStyle: const TextStyle(
                                            color: _grey,
                                            fontSize: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: _border,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: _border,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: _lime,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                          suffixIcon: GestureDetector(
                                            onTap: () => setState(
                                              () => _transferCtrl.text =
                                                  _airdropBalance.toString(),
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                right: 12,
                                              ),
                                              child: Align(
                                                widthFactor: 1,
                                                child: Text(
                                                  'MAX',
                                                  style: TextStyle(
                                                    color: _lime,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _transferring ? null : _transfer,
                                    icon: _transferring
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.swap_horiz_rounded,
                                            size: 18,
                                          ),
                                    label: Text(
                                      _transferring
                                          ? 'Transferring...'
                                          : 'Transfer to Spot Wallet',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _card,
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: _border),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        fontFamily: 'DMSans',
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '✓ All funds transferred to Spot Wallet',
                                    style: TextStyle(
                                      color: _grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPER WIDGETS ───

  Widget _badge(String text, {required bool filled}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: filled
          ? const Color(0xFF00FF04).withOpacity(0.3)
          : const Color(0xFFCCFF00).withOpacity(0.3),
      borderRadius: BorderRadius.circular(40),
      border: Border.all(color: Colors.transparent),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: filled ? const Color(0xFF00FF04) : const Color(0xFFCCFF00),
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: 'DMSans',
      ),
    ),
  );

  Widget _statTile(String value, String label, {bool highlight = false}) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlight ? Colors.transparent : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: highlight ? _lime : _lime,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: "DMSans",
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _liveBadge(bool active, int secsLeft) {
    if (!active || secsLeft <= 0) {
      return Text(
        'Ended',
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: "DMSans",
        ),
      );
    }
    return Text(
      'Live',
      style: TextStyle(
        color: _lime,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: "DMSans",
      ),
    );
  }

  Widget _loadingScaffold() => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 0, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: Get.back,
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(child: CircularProgressIndicator(color: _lime)),
          ),
        ],
      ),
    ),
  );

  Widget _errorScaffold() => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 0, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: Get.back,
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: _grey,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load airdrop',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: _grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _lime,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
