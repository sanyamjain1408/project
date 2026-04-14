import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/card_container/home_grid_controller.dart';

const _bgcolor =Color(0xFF111111);


class MoreCardScreen extends StatefulWidget {
  const MoreCardScreen({super.key});

  @override
  State<MoreCardScreen> createState() => _MoreCardScreenState();
}

class _MoreCardScreenState extends State<MoreCardScreen> {
  // Controller Instance
  final HomeGridController _gridController = Get.put(HomeGridController());

  // Edit Mode on/off karne ke liye
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgcolor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text(
          "More",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _buildSectionTitle("Homepage"),

            // ── NEW SECTION: ADD TO HOMEPAGE ──
            _buildAddToHomepageSection(),

            const SizedBox(height: 10),

            // ── CATEGORY 1: RECOMMEND ──
            _buildSectionTitle("Recommend"),
            const SizedBox(
              height: 5,
            ), // <--- CHANGE: Pehle 10 tha, ab 5 kar diya (Gap kam)
            _buildGridview([
              _buildGridItem("assets/images/swap.png", "Swap"),
              _buildGridItem("assets/images/earn.png", "Earn"),
              _buildGridItem("assets/images/transfer.png", "Transfer"),
              _buildGridItem("assets/images/deposit.png", "Deposit"),
              _buildGridItem("assets/icons/spin.png", "Spin"),
              _buildGridItem("assets/icons/referals.png", "Referals"),
              _buildGridItem("assets/images/buy.png", "Buy"),
            ]),

            // <--- CHANGE: Pehle 0 tha, thoda gap add kiya taaki categories alag lagen

            // ── CATEGORY 2: COMMON ──
            _buildSectionTitle("Common"),
            _buildGridview([
              _buildGridItem("assets/icons/security.png", "Security"),
              _buildGridItem("assets/icons/kyc.png", "KYC"),
              _buildGridItem("assets/icons/price.png", "Price Alert"),
              _buildGridItem("assets/icons/deposit.png", "Deposit Fiat"),
              _buildGridItem("assets/icons/p2p.png", "P2P"),
              _buildGridItem("assets/icons/referals.png", "Referals"),
              _buildGridItem("assets/icons/history.png", "History"),
            ]),

            // ── CATEGORY 3: TRADE ──
            _buildSectionTitle("Trade"),
            _buildGridview([
              _buildGridItem("assets/images/swap.png", "Swap"),
              _buildGridItem("assets/images/spot.png", "Spot"),
              _buildGridItem("assets/images/future.png", "Future"),
              _buildGridItem("assets/icons/p2p.png", "P2P"),
              _buildGridItem("assets/images/funds.png", "Funds"),
            ]),

            // ── CATEGORY 4: OTHER ──
            _buildSectionTitle("Other"),
            _buildGridview([
              _buildGridItem("assets/icons/earn.png", "Earn"),
              _buildGridItem("assets/icons/easy.png", "Easy Earn"),
              _buildGridItem("assets/icons/referals.png", "Referals"),
              _buildGridItem("assets/icons/spin.png", "Spin"),
              _buildGridItem("assets/icons/help.png", "Help"),
              _buildGridItem("assets/icons/airdrop.png", "Airdrop"),
              _buildGridItem("assets/icons/self.png", "Self Service"),
              _buildGridItem(
                "assets/icons/deposit_withdraw.png",
                "Withdraw ",
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── NEW WIDGET: ADD TO HOMEPAGE SECTION (CORRECTED ASPECT RATIO) ──
  Widget _buildAddToHomepageSection() {
    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 150),
      padding: const EdgeInsets.only(top: 15, left: 5, right: 15, bottom: 0),
      margin: EdgeInsets.only(
        left: 15,
        right: 15,
        top: 0,
        bottom: 0,
      ), // <--- CHANGE: Top margin 10 se 0 kar diya
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(width: 15),
          Expanded(
            child: Obx(() {
              if (_gridController.selectedIcons.isEmpty) {
                return const Center(
                  child: Text(
                    "Tap icons below to add",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              }

              final icons = _gridController.selectedIcons;
              final int count = icons.length;

              return GridView.count(
                crossAxisCount: count < 5
                    ? count
                    : 5, // <--- Jitne icons utne columns, max 5
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,

                crossAxisSpacing: 0,
                childAspectRatio: 1.5, // <--- CHANGE: Aspect ratio thoda adjust kiya taaki icons aur text dono fit ho jayeinr
                children: icons.map((item) {
                  return GestureDetector(
                    onTap: () => _gridController.removeIcon(item['title']),
                    child: _buildSmallIcon(item['image']),
                  );
                }).toList(),
              );
            }),
          ),
          const SizedBox(width: 50),

          // Edit Button
           GestureDetector(
            onTap: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
            child: Image.asset(
              // Condition: Edit hai to Edit icon, nahi to Done icon
              _isEditMode ? 'assets/icons/done.png' : 'assets/icons/edit.png', 
              // Apni actual asset path yahan check kar lena
              height: 25, 
              width: 25,
              // Agar icon load na ho to default color ke liye:
              
            ),
          ),


          SizedBox(width: 10),
        ],
      ),
    );
  }

  // ── UPDATED SMALL ICON WIDGET ──
  Widget _buildSmallIcon(String image) {
    return Container(
      child: Center(
        child: Image.asset(
          image,
          height: 20,
          width: 20,
          errorBuilder: (c, o, s) =>
              const Icon(Icons.error, size: 20, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10, top: 0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontFamily: "DMSans",
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
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
    return GestureDetector(
      onTap: () {
        // Icon add karein list mein
        _gridController.addIcon(imagePath, title);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            child: Image.asset(
              imagePath,
              height: 25,
              width: 25,
              errorBuilder: (c, o, s) =>
                  const Icon(Icons.error_outline, color: Colors.grey, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
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
  }
}
