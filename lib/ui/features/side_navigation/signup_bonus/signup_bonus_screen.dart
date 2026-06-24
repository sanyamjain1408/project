import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_controller.dart';

const _kBg    = Color(0xFF0A0B0D);
const _kCard  = Color(0xFF1A1A1A);
const _kCard2 = Color(0xFF111111);
const _kGreen = Color(0xFFCCFF00);
const _kMuted = Color(0xFF555555);
const _base   = 'https://api.trapix.com';

class SignupBonusScreen extends StatefulWidget {
  const SignupBonusScreen({super.key});
  @override
  State<SignupBonusScreen> createState() => _SignupBonusScreenState();
}

class _SignupBonusScreenState extends State<SignupBonusScreen> {
  Map<String, dynamic>? _status;
  List<dynamic> _referralCoupons = [];
  List<dynamic> _referralNetwork = [];
  bool _loading = true;
  bool _claiming = false;
  int? _claimingCouponId;
  String? _message;
  bool _msgSuccess = false;

  String get _token  => GetStorage().read(PreferenceKey.accessToken) ?? '';
  String get _userId { try { return gUserRx.value.id > 0 ? gUserRx.value.id.toString() : ''; } catch (_) { return ''; } }

  Map<String, String> get _hdrs => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; });
    await Future.wait([_fetchStatus(), _fetchCoupons(), _fetchReferralNetwork()]);
    if (mounted) setState(() { _loading = false; });
  }

  Future<void> _fetchStatus() async {
    if (_userId.isEmpty) return;
    try {
      final r = await http.get(Uri.parse('$_base/api/signup-bonus/status?user_id=$_userId'), headers: _hdrs);
      if (mounted) setState(() => _status = jsonDecode(r.body));
    } catch (_) {}
  }

  Future<void> _fetchCoupons() async {
    try {
      final r = await http.get(Uri.parse('$_base/api/v1/rewards/my-rewards'), headers: _hdrs);
      final d = jsonDecode(r.body);
      if (mounted) setState(() {
        final all = (d['data']?['coupons'] as List?) ?? [];
        _referralCoupons = all.where((c) =>
          c['coupon_type'] == 'coupon_futures' &&
          (c['coupon_label'] ?? '').toString().contains('Referral')
        ).toList();
      });
    } catch (_) {}
  }

  Future<void> _fetchReferralNetwork() async {
    if (_userId.isEmpty) return;
    try {
      final r = await http.get(
        Uri.parse('$_base/api/simple-referral/network?user_id=$_userId'),
        headers: _hdrs,
      );
      final d = jsonDecode(r.body);
      if (mounted) setState(() {
        _referralNetwork = (d['success'] == true ? d['data'] : null) ?? [];
      });
    } catch (_) {}
  }

  Future<void> _claim() async {
    if (_userId.isEmpty) return;
    setState(() { _claiming = true; _message = null; });
    try {
      final r = await http.post(Uri.parse('$_base/api/signup-bonus/claim'),
          headers: _hdrs, body: jsonEncode({'user_id': _userId}));
      final d = jsonDecode(r.body);
      if (mounted) setState(() {
        _claiming = false;
        _msgSuccess = d['success'] == true;
        _message = d['message'] ?? d['error'] ?? 'Something went wrong';
      });
      if (d['success'] == true) _fetchStatus();
    } catch (_) {
      if (mounted) setState(() { _claiming = false; _message = 'Request failed'; _msgSuccess = false; });
    }
  }

  Future<void> _useCoupon(int id) async {
    setState(() { _claimingCouponId = id; });
    try {
      final r = await http.post(Uri.parse('$_base/api/v1/rewards/use-coupon'),
          headers: _hdrs, body: jsonEncode({'coupon_id': id}));
      final d = jsonDecode(r.body);
      _snack(d['message'] ?? 'Done!', d['success'] == true);
      if (d['success'] == true) _fetchCoupons();
    } catch (_) { _snack('Request failed', false); }
    if (mounted) setState(() { _claimingCouponId = null; });
  }

  void _snack(String msg, bool ok) => Get.snackbar('', msg,
    backgroundColor: (ok ? _kGreen : Colors.red).withOpacity(0.12),
    colorText: ok ? _kGreen : Colors.red,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(12),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: true,
    child: Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        scrolledUnderElevation: 0,
        surfaceTintColor: _kBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Signup Bonus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : RefreshIndicator(
              onRefresh: _load, color: _kGreen,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _heroCard(),
                  const SizedBox(height: 16),
                  _steps(),
                  const SizedBox(height: 16),
                  _claimBtn(),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (_msgSuccess ? _kGreen : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (_msgSuccess ? _kGreen : Colors.red).withOpacity(0.3)),
                      ),
                      child: Text(_message!, style: TextStyle(color: _msgSuccess ? _kGreen : Colors.red, fontSize: 13),
                        textAlign: TextAlign.center),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _leverageTiers(),
                  if (_referralCoupons.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _referralCouponsCard(),
                  ],
                  const SizedBox(height: 16),
                  _referralSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    ),
  );

  // ── HERO CARD ──────────────────────────────────────────────────────────────
  Widget _heroCard() {
    final bs      = _status?['bonus_status'] ?? 'none';
    final active  = bs == 'active';
    final bonus   = _dbl(_status?['bonus_balance']);
    final total   = _dbl(_status?['total_balance']);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGreen.withOpacity(0.15)),
      ),
      child: Column(children: [
        const Text('100 USDT', style: TextStyle(color: _kGreen, fontSize: 42, fontWeight: FontWeight.w900, height: 1)),
        const Text('Futures Trading Bonus', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 20),
        if (active) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _sc('Bonus Balance', '${bonus.toStringAsFixed(2)} USDT', _kGreen),
            Container(width: 1, height: 40, color: Colors.white12),
            _sc('Total Balance', '${total.toStringAsFixed(2)} USDT', Colors.white),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _kGreen.withOpacity(0.3)),
            ),
            child: const Text('✓ Bonus Active', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(12)),
            child: const Text(
              'Trade futures with 100 USDT — no deposit needed.\nProfits above your bonus balance are yours to keep.',
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
      ]),
    );
  }

  // ── STEPS ──────────────────────────────────────────────────────────────────
  Widget _steps() {
    final active = _status?['bonus_status'] == 'active';
    final steps  = [
      {'label': 'Create Account', 'done': true},
      {'label': 'Verify Email',   'done': true},
      {'label': 'Claim Bonus',    'done': active},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(steps.length, (i) {
          final done = steps[i]['done'] as bool;
          return Expanded(child: Row(children: [
            if (i > 0) Expanded(child: Container(height: 2, color: done ? _kGreen : Colors.white12)),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _kGreen : _kCard2,
                  border: Border.all(color: done ? _kGreen : Colors.white24, width: 2),
                ),
                child: Icon(done ? Icons.check : Icons.circle_outlined, size: 14, color: done ? Colors.black : Colors.white24),
              ),
              const SizedBox(height: 6),
              Text(steps[i]['label'] as String,
                style: TextStyle(color: done ? Colors.white : _kMuted, fontSize: 10, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            ]),
            if (i < steps.length - 1) Expanded(child: Container(height: 2, color: done ? _kGreen : Colors.white12)),
          ]));
        }),
      ),
    );
  }

  // ── CLAIM BUTTON ───────────────────────────────────────────────────────────
  Widget _claimBtn() {
    final bs       = _status?['bonus_status'] ?? 'none';
    final canClaim = _status?['can_claim'] == true;
    final active   = bs == 'active';
    final expired  = bs == 'expired';
    final consumed = bs == 'consumed';

    if (active) return _staticBtn('✓ Bonus Claimed & Active', Colors.green.withOpacity(0.15), Colors.green);
    if (expired || consumed) return _staticBtn(expired ? 'Bonus Expired' : 'Bonus Consumed', Colors.white.withOpacity(0.05), _kMuted);
    if (!canClaim) return _staticBtn('Bonus Not Available', _kCard2, _kMuted);

    return GestureDetector(
      onTap: _claiming ? null : _claim,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _claiming ? _kGreen.withOpacity(0.5) : _kGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: _claiming
          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)))
          : const Text('Claim 100 USDT Bonus →', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }

  Widget _staticBtn(String label, Color bg, Color fg) => Container(
    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
    child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
  );

  // ── LEVERAGE TIERS ─────────────────────────────────────────────────────────
  Widget _leverageTiers() {
    final lev = _status?['leverage'];
    if (lev == null) return const SizedBox.shrink();
    final currentMax = lev['current_max'] ?? 5;
    final reason     = lev['reason'] ?? '';
    final tiers      = (lev['tiers'] as List?) ?? [];
    final next       = lev['next'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Leverage Tier', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: _kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('${currentMax}x max', style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(reason, style: const TextStyle(color: _kMuted, fontSize: 12)),
        const SizedBox(height: 12),
        ...tiers.map((t) {
          final unlocked = t['unlocked'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: unlocked ? _kGreen.withOpacity(0.06) : _kCard2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: unlocked ? _kGreen.withOpacity(0.2) : Colors.transparent),
            ),
            child: Row(children: [
              Icon(unlocked ? Icons.lock_open_rounded : Icons.lock_rounded, size: 14, color: unlocked ? _kGreen : _kMuted),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${t['label']} · ${t['leverage']}x',
                  style: TextStyle(color: unlocked ? Colors.white : _kMuted, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(t['requirement'] ?? '', style: const TextStyle(color: _kMuted, fontSize: 11)),
              ])),
            ]),
          );
        }),
        if (next != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(10)),
            child: RichText(text: TextSpan(
              style: const TextStyle(color: _kMuted, fontSize: 12),
              children: [
                const TextSpan(text: 'Next: '),
                TextSpan(text: '${next['leverage']}x', style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
                TextSpan(text: ' — ${next['requirement']}'),
              ],
            )),
          ),
        ],
      ]),
    );
  }

  // ── REFERRAL BONUS COUPONS ─────────────────────────────────────────────────
  Widget _referralCouponsCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🎉 Referral Bonuses Ready to Claim',
        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      ..._referralCoupons.map((c) {
        final value = _dbl(c['coupon_value']);
        final id    = c['id'] as int;
        final busy  = _claimingCouponId == id;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('+${value.toStringAsFixed(0)} USDT Futures Bonus',
                style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(c['coupon_label'] ?? '', style: const TextStyle(color: _kMuted, fontSize: 11)),
              if (c['expires_at'] != null)
                Text('Expires ${c['expires_at'].toString().substring(0, 10)}',
                  style: const TextStyle(color: _kMuted, fontSize: 10)),
            ])),
            GestureDetector(
              onTap: busy ? null : () => _useCoupon(id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(color: busy ? _kGreen.withOpacity(0.5) : _kGreen, borderRadius: BorderRadius.circular(99)),
                child: busy
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Claim', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ]),
        );
      }),
    ]),
  );

  // ── REFERRAL LINK + NETWORK ────────────────────────────────────────────────
  Widget _referralSection() {
    final refCode = (_status?['referral_code'] ?? '').toString();
    if (refCode.isEmpty) return const SizedBox.shrink();
    final link = 'trapix.com/signup?ref_code=$refCode';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🎁 Refer & Earn More', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('Each friend who signs up gives you a 20 USDT futures coupon',
              style: TextStyle(color: _kMuted, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 12),
        // Referral link copy row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(child: Text(link,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: 'https://$link'));
                _snack('Link copied!', true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(8)),
                child: const Text('Copy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ]),
        ),

        // People you referred
        if (_referralNetwork.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('PEOPLE YOU REFERRED',
            style: TextStyle(color: _kMuted, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._referralNetwork.map((m) {
            final email = (m['email'] ?? m['username'] ?? '?').toString();
            // Mask email: show first 1 char + *** + domain
            String masked = email;
            if (email.contains('@')) {
              final parts = email.split('@');
              masked = '${parts[0].substring(0, 1)}***@${parts[1]}';
            } else if (email.length > 3) {
              masked = '${email.substring(0, 1)}***';
            }
            final initial = masked[0].toUpperCase();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kGreen.withOpacity(0.15),
                  ),
                  child: Center(child: Text(initial,
                    style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w800, fontSize: 15))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(masked, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(m['created_at'] != null ? 'Joined ${m['created_at'].toString().substring(0, 10)}' : 'Joined',
                    style: const TextStyle(color: _kMuted, fontSize: 11)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kGreen.withOpacity(0.2)),
                  ),
                  child: const Text('+20 USDT Bonus',
                    style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            );
          }),
        ] else ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: const Center(child: Text('No referrals yet — share your link to start earning',
              style: TextStyle(color: _kMuted, fontSize: 13), textAlign: TextAlign.center)),
          ),
        ],
      ]),
    );
  }

  Widget _sc(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
  ]);

  double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
