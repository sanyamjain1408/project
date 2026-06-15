import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

const _bg = Color(0xFF111111);
const _white = Colors.white;
const _green = Color(0xFFCCFF00);
const _dmSans = 'DMSans';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.arrow_back, color: _white, size: 22),
          ),
        ),
        leadingWidth: 48,
        title: const Text(
          'Community',
          style: TextStyle(
            color: _white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: _dmSans,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _communityRow(
            'assets/images/community.png',
            'Join Telegram Channel',
            'Join',
            () => openUrlInBrowser('https://t.me/TrapixExchange'),
          ),
          _communityRow(
            'assets/images/community.png',
            'Follow us on X',
            'Follow',
            () => openUrlInBrowser('https://x.com/TrapixExchange'),
          ),
          _communityRow(
            'assets/images/community.png',
            'Follow us on Instagram',
            'Follow',
            null,
          ),
        ],
      ),
    );
  }

  Widget _communityRow(String iconPath, String label, String buttonLabel, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          Image.asset(iconPath, width: 20, height: 20),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: _dmSans,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: 70,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: onTap != null ? _green : _green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
