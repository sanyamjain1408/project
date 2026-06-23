import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/card_container/home_grid_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/swap/swap_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/buy_crypto_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transfer_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_overview_page.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_controller.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/referrals/referral_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/spin_win/spin_win_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/profile/profile_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/airdrop/airdrop_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/giveaway/giveaway_screen.dart';
import 'package:tradexpro_flutter/ui/features/root/root_controller.dart';
import 'package:tradexpro_flutter/helper/bottom_nav_helper.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/live_chat_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/price_alerts/price_alerts_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/history_sheet.dart';

const _bgcolor = Color(0xFF111111);
const _green = Color(0xFFCCFF00);

class MoreCardScreen extends StatefulWidget {
  const MoreCardScreen({super.key});

  @override
  State<MoreCardScreen> createState() => _MoreCardScreenState();
}

class _MoreCardScreenState extends State<MoreCardScreen> {
  final HomeGridController _gridController = Get.put(HomeGridController());
  bool _isEditMode = false;

  void _navigateTo(String title) {
    switch (title) {
      case "Earn":
        if (!Get.isRegistered<WalletController>()) Get.put(WalletController());
        Get.to(() => const WalletDetailScreen(initialType: WalletViewType.earn));
        break;
      case "Deposit":
        Get.to(() => WalletCryptoDepositScreen());
        break;
      case "Swap":
        Get.to(() => const SwapScreen());
        break;
      case "Transfer":
        Get.to(() => const TransferScreen());
        break;
      case "Spin":
        Get.to(() => const SpinWinScreen());
        break;
      case "Referals":
        Get.to(() => const ReferralScreen());
        break;
      case "KYC":
        Get.to(() => const ProfileScreen(initialTab: 3));
        break;
      case "Security":
        Get.to(() => const ProfileScreen(initialTab: 0));
        break;
      case "Price Alert":
        Get.to(() => const PriceAlertsScreen());
        break;
      case "Deposit Fiat":
        Get.to(() => WalletCryptoDepositScreen());
        break;
      case "Withdraw":
        Get.to(() => WalletCryptoDepositScreen());
        break;
      case "Giveaway":
        Get.to(() => const GiveawayScreen());
        break;
      case "History":
        showHistorySheet();
        break;
      case "Buy":
        Get.to(() => const BuyCryptoScreen());
        break;
      case "Help":
        Get.to(() => const LiveChatScreen());
        break;
      case "Easy Earn":
        if (!Get.isRegistered<WalletController>()) Get.put(WalletController());
        Get.to(() => const WalletDetailScreen(initialType: WalletViewType.earn));
        break;
      case "Airdrop":
        Get.to(() => const AirdropScreen());
        break;
      case "Future":
        Get.back();
        Get.find<RootController>().changeBottomNavIndex(AppBottomNavKey.future);
        break;
      case "Spot":
        Get.back();
        Get.find<RootController>().changeBottomNavIndex(AppBottomNavKey.trade);
        break;
      default:
        break;
    }
  }

  void _handleIconTap(String image, String title) {
    if (_isEditMode) {
      final isSelected = _gridController.selectedIcons.any((i) => i['title'] == title);
      if (isSelected) {
        _gridController.removeIcon(title);
      } else {
        _gridController.addIcon(image, title);
      }
    } else {
      _navigateTo(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgcolor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text(
          "More",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSectionTitle("Homepage"),
            _buildAddToHomepageSection(),
            const SizedBox(height: 10),

            _buildSectionTitle("Recommend"),
            const SizedBox(height: 5),
            _buildGridview([
              _buildGridItem("assets/images/swap.png", "Swap"),
              _buildGridItem("assets/images/earn.png", "Earn"),
              _buildGridItem("assets/images/transfer.png", "Transfer"),
              _buildGridItem("assets/images/deposit.png", "Deposit"),
              _buildGridItem("assets/icons/spin.png", "Spin"),
              _buildGridItem("assets/icons/referals.png", "Referals"),
              _buildGridItem("assets/images/buy.png", "Buy"),
            ]),

            _buildSectionTitle("Common"),
            _buildGridview([
              _buildGridItem("assets/icons/security.png", "Security"),
              _buildGridItem("assets/icons/kyc.png", "KYC"),
              _buildGridItem("assets/icons/price.png", "Price Alert"),
              _buildGridItem("assets/icons/deposit.png", "Deposit Fiat"),
              _buildGridItem("assets/icons/referals.png", "Referals"),
              _buildGridItem("assets/icons/history.png", "History"),
            ]),

            _buildSectionTitle("Trade"),
            _buildGridview([
              _buildGridItem("assets/images/swap.png", "Swap"),
              _buildGridItem("assets/images/spot.png", "Spot"),
              _buildGridItem("assets/images/future.png", "Future"),
            ]),

            _buildSectionTitle("Other"),
            _buildGridview([
              _buildGridItem("assets/icons/earn.png", "Earn"),
              _buildGridItem("assets/icons/easy.png", "Easy Earn"),
              _buildGridItem("assets/icons/referals.png", "Referals"),
              _buildGridItem("assets/icons/spin.png", "Spin"),
              _buildGridItem("assets/icons/help.png", "Help"),
              _buildGridItem("assets/icons/airdrop.png", "Airdrop"),
              _buildGridItem("assets/icons/deposit_withdraw.png", "Withdraw"),
              _buildGridItem("assets/images/giveaway.png", "Giveaway"),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToHomepageSection() {
    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 150),
      padding: const EdgeInsets.only(top: 15, left: 5, right: 15, bottom: 0),
      margin: const EdgeInsets.only(left: 15, right: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Expanded(
            child: Obx(() {
              if (_gridController.selectedIcons.isEmpty) {
                return const Center(
                  child: Text("Tap icons below to add", style: TextStyle(color: Colors.grey, fontSize: 12)),
                );
              }
              final icons = _gridController.selectedIcons;
              return GridView.count(
                crossAxisCount: icons.length < 5 ? icons.length : 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 0,
                childAspectRatio: 1.5,
                children: icons.map((item) {
                  return GestureDetector(
                    onTap: () => _isEditMode ? _gridController.removeIcon(item['title']) : null,
                    child: Center(
                      child: Image.asset(
                        item['image'],
                        height: 20,
                        width: 20,
                        errorBuilder: (c, o, s) => const Icon(Icons.error, size: 20, color: Colors.grey),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ),
          const SizedBox(width: 50),
          GestureDetector(
            onTap: () => setState(() => _isEditMode = !_isEditMode),
            child: Image.asset(
              _isEditMode ? 'assets/icons/done.png' : 'assets/icons/edit.png',
              height: 25,
              width: 25,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10, top: 0),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFFFFFFFF), fontFamily: "DMSans", fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildGridview(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 5,
      crossAxisSpacing: 1,
      children: children,
    );
  }

  Widget _buildGridItem(String imagePath, String title) {
    return Obx(() {
      final isSelected = _gridController.selectedIcons.any((i) => i['title'] == title);

      return GestureDetector(
        onTap: () => _handleIconTap(imagePath, title),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(1),
                  child: Image.asset(
                    imagePath,
                    height: 25,
                    width: 25,
                    errorBuilder: (c, o, s) => const Icon(Icons.error_outline, color: Colors.grey, size: 24),
                  ),
                ),
                // Edit mode ON only: show + or - badge
                if (_isEditMode)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red : _green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.remove : Icons.add,
                        size: 9,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: (_isEditMode && isSelected) ? _green : Colors.white60,
                  fontSize: 12,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    });
  }
}
