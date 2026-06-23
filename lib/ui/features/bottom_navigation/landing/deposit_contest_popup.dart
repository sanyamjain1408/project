import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/deposit_bonus/deposit_bonus_screen.dart';

// Global controller — tracks inactivity across all screens
class InactivityController extends GetxController {
  static InactivityController get to => Get.find();

  Timer? _inactivityTimer;
  void Function()? _onInactive;
  void Function()? _onInteract; // called when user touches while popup is visible

  void registerCallbacks({
    required void Function() onInactive,
    required void Function() onInteract,
  }) {
    _onInactive = onInactive;
    _onInteract = onInteract;
    _resetTimer();
  }

  void unregister() {
    _inactivityTimer?.cancel();
    _onInactive = null;
    _onInteract = null;
  }

  // Called from root Listener on every pointer event
  void onUserInteraction() {
    // Only reset timer — don't call _onInteract here
    // _onInteract is triggered separately via isPopupVisible check
    _onInteract?.call();
    _resetTimer();
  }

  // Called after popup hides (auto or manual) to restart the 10s inactivity timer
  void restartAfterHide() {
    _resetTimer();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      _onInactive?.call();
    });
  }

  @override
  void onClose() {
    _inactivityTimer?.cancel();
    super.onClose();
  }
}

class DepositContestPopup extends StatefulWidget {
  const DepositContestPopup({super.key});

  @override
  State<DepositContestPopup> createState() => _DepositContestPopupState();
}

class _DepositContestPopupState extends State<DepositContestPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _slide;

  bool _dismissed = false;
  bool _participated = false;
  Timer? _autoHideTimer;

  static const _accent = Color(0xFFCCFF00);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );

    _checkParticipation();

    // Register inactivity callback — show popup after 10s of no touch
    if (!Get.isRegistered<InactivityController>()) {
      Get.put(InactivityController(), permanent: true);
    }
    InactivityController.to.registerCallbacks(
      onInactive: _onInactive,
      onInteract: hideOnInteraction,
    );
  }

  void _onInactive() {
    if (_dismissed || !mounted) return;
    _show();
  }

  void _show() {
    if (!mounted) return;
    _anim.forward();
    _autoHideTimer?.cancel();
    // Auto hide after 5 sec
    _autoHideTimer = Timer(const Duration(seconds: 5), _hide);
  }

  void _hide() {
    if (!mounted) return;
    _anim.reverse().whenComplete(() {
      // After hiding, restart the 10s inactivity timer so popup can show again
      if (!_dismissed && mounted) {
        InactivityController.to.restartAfterHide();
      }
    });
  }

  // Called from InactivityController when user touches screen while popup is visible
  void hideOnInteraction() {
    if (_anim.value > 0) {
      _autoHideTimer?.cancel();
      _hide();
    }
  }

  void _dismiss() {
    _autoHideTimer?.cancel();
    InactivityController.to.unregister();
    setState(() => _dismissed = true);
    _anim.reverse();
  }

  Future<void> _checkParticipation() async {
    try {
      final storage = GetStorage();
      final token = storage.read(PreferenceKey.accessToken) ?? '';
      final userObj = storage.read(PreferenceKey.userObject);
      final uid = userObj != null ? (userObj['id']?.toString() ?? '') : '';
      if (uid.isEmpty) return;

      final res = await http.get(
        Uri.parse('https://api.trapix.com/api/deposit-bonus/status?user_id=$uid'),
        headers: {'Accept': 'application/json', if (token.toString().isNotEmpty) 'Authorization': 'Bearer $token'},
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
    _autoHideTimer?.cancel();
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
        child: Material(
          color: Colors.transparent,
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
                          decoration: TextDecoration.none,
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
                          decoration: TextDecoration.none,
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
      ),
    );
  }
}
