import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/deposit_bonus/deposit_bonus_screen.dart';

// Alternates visibility with spin popup — shows for 4s, hides for 4s
class DepositContestPopup extends StatefulWidget {
  const DepositContestPopup({super.key});

  @override
  State<DepositContestPopup> createState() => _DepositContestPopupState();
}

class _DepositContestPopupState extends State<DepositContestPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _slide;

  bool _visible = false;
  bool _dismissed = false;
  bool _participated = false;
  Timer? _toggleTimer;

  static const _accent = Color(0xFFCCFF00);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slide = Tween<double>(begin: 1.15, end: 0.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );

    _checkParticipation();
    _startToggle();
  }

  void _startToggle() {
    // Show after 3 seconds delay, then alternate every 5s
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _dismissed) return;
      _show();
      _toggleTimer = Timer.periodic(const Duration(seconds: 9), (_) {
        if (!mounted || _dismissed) return;
        _visible ? _hide() : _show();
      });
    });
  }

  void _show() {
    if (_dismissed || !mounted) return;
    setState(() => _visible = true);
    _anim.forward();
  }

  void _hide() {
    if (!mounted) return;
    _anim.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _dismiss() {
    _toggleTimer?.cancel();
    setState(() => _dismissed = true);
    _anim.reverse();
  }

  Future<void> _checkParticipation() async {
    try {
      final token = GetStorage().read(PreferenceKey.accessToken) ?? '';
      if (token.isEmpty) return;
      final res = await http.get(
        Uri.parse('https://api.trapix.com/api/deposit-bonus/status'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final total = double.tryParse(body['total_deposited']?.toString() ?? '0') ?? 0;
        final yours = double.tryParse(body['your_deposits']?.toString() ?? '0') ?? 0;
        if (mounted) setState(() => _participated = total > 0 || yours > 0);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _toggleTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final title = _participated
        ? '🏆 Deposit Contest — Leaderboard'
        : '🏆 Participate now in Deposit Contest';

    return AnimatedBuilder(
      animation: _slide,
      builder: (_, __) => Transform.translate(
        offset: Offset(260 * _slide.value, 0),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => Get.to(() => const DepositBonusScreen()),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF161B22), Color(0xFF0E1117)],
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.white12),
                      left: BorderSide(color: Colors.white12),
                      bottom: BorderSide(color: Colors.white12),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(-4, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'DMSans',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _dismiss,
                        child: const Text(
                          '×',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 20,
                            height: 1,
                          ),
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
}
