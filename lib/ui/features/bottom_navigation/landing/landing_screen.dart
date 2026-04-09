import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:k_chart_plus/k_chart_plus.dart';

import '../../../../addons/ico/ico_ui/ico_screen.dart';
import '../../../../data/local/constants.dart';
import '../../../../helper/app_helper.dart';
import '../../../../ui/features/auth/sign_in/sign_in_screen.dart';
import '../../../../utils/button_util.dart';
import '../../../../utils/common_utils.dart';
import '../../../../utils/decorations.dart';
import '../../../../utils/dimens.dart';
import '../../../../utils/extensions.dart';
import '../../../../utils/image_util.dart';
import '../../../../utils/shimmer_loading/shimmer_view.dart';
import '../../../../utils/spacers.dart';
import '../../../../utils/text_util.dart';
import '../../../../utils/web_view.dart';
import '../../side_navigation/activity/activity_screen.dart';
import '../../side_navigation/blog/blog_screen.dart';
import '../../side_navigation/faq/faq_page.dart';
import '../../side_navigation/gift_cards/gift_cards_screen.dart';
import '../../side_navigation/profile/profile_screen.dart';
import '../../side_navigation/referrals/referrals_screen.dart';
import '../../side_navigation/staking/staking_screen.dart';
import '../../side_navigation/fiat/fiat_screen.dart';
import '../wallet/swap/swap_screen.dart';
import '../wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import '../wallet/wallet_crypto_withdraw/wallet_crypto_withdraw_screen.dart';
import 'announcement_view.dart';
import 'landing_controller.dart';
import 'landing_market_view.dart';
import 'landing_widgets.dart';
import 'package:video_player/video_player.dart';


const _bg        = Color(0xFF0A0B0D);
const _card      = Color(0xFF111318);
const _green     = Color(0xFFB5F000);
const _border    = Color(0xFF1E2128);
const _textDim   = Color(0xFF6B7280);
const _textMid   = Color(0xFFB0B8C1);

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _controller = Get.put(LandingController());

  @override
  void initState() {
    super.initState();
    _controller.getLandingSettings();
    if (getSettingsLocal()?.blogNewsModule == 1) _controller.getLatestBlogList();
  }

  @override
  void dispose() {
    _controller.handleSocketChannels(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
      
        children: [
        const AppBarHomeView(),
        Expanded(child: Obx(() {
          final lData = _controller.landingData.value;
          return _controller.isLoading.value
              ? const ShimmerViewLanding()
              : ListView(
                  shrinkWrap: true,
                  children: [
                   
                    if (lData.landingSecondSectionStatus == 1) const CryptoTrustBannerView(),
                    buildViewCard(),
                    if (lData.announcementList.isValid) AnnouncementView(announcementList: lData.announcementList!), 
                   ///_exploreView(),
                    if (lData.landingThirdSectionStatus == 1) const LandingMarketView(),
                    const MarketEmptyStateWidget(),
                    
                   ///  _getLandingButtonView(),
                    ///_featureView(),
                   ///_latestBlogView()
                  ],
                );
        })),
      ]),
    );
  }
Widget buildViewCard() {
  return InkWell(
    child: Container(
      // --- CARD STYLING ---
      
      decoration: BoxDecoration(
         color: const Color(0xFF1A1A1A), // Dark Background (Image jaisa)
        borderRadius: BorderRadius.circular(16), // Rounded Corners
        border: Border.all(
          color: const Color(0xFF1A1A1A),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(15), // Inside Padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TOP SECTION: LOGO + TITLE ---
          Row(
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                 "assets/images/usdt.png", 
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              // Title
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                "USDT",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Simple Earn",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              ],
              )
            ],
          ),
          
          const SizedBox(height: 20), // Gap between Title and Graph

          // --- MIDDLE SECTION: GRAPH ---
          // Graph ko center rakha hai taaki flow sahi lage
          Align(
            alignment: Alignment.center,
            child: Image.asset(
             "assets/images/graph.png",
              width: double.infinity, // Full width
              height: 70, // Fixed height for graph
              fit: BoxFit.fitWidth,
            ),
          ),

          const SizedBox(height: 20), // Gap between Graph and Bottom Text

          // --- BOTTOM SECTION: TEXT + PERCENTAGE ---
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle Text
              Text(
                "Highest APR",
                style: const TextStyle(
                  color: Color(0xFF9CA3AF), // Grey Color
                  fontSize: 15,
                ),
              ),
              // Percentage Text
              Text(
                "2.8%",
                style: const TextStyle(
                  color: Color(0xFF4ED78E), // Green Color
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  

  Padding _getLandingButtonView() {
    final hasUser = gUserRx.value.id > 0;
    final title = hasUser ? "Start Trading Now".tr : "Sign_Up_Sign_In".tr;
    return Padding(
        padding: const EdgeInsets.all(Dimens.paddingLargeExtra),
        child: buttonRoundedMain(
            text: title,
            buttonHeight: Dimens.btnHeightMid,
            textColor: Colors.white,
            onPress: () => hasUser ? getRootController().changeBottomNavIndex(AppBottomNavKey.trade) : Get.offAll(() => const SignInPage())));
  }

  Widget _featureView() {
    final lData = _controller.landingData.value;
    if (lData.landingSixSectionStatus == 1 && lData.featureList.isValid) {
      return Container(
          decoration: boxDecorationRoundCorner(color: context.theme.dialogTheme.backgroundColor),
          padding: const EdgeInsets.all(Dimens.paddingMid),
          margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (lData.landingFeatureTitle.isValid)
                Align(alignment: Alignment.centerLeft, child: TextRobotoAutoBold(lData.landingFeatureTitle ?? "")),
              vSpacer10(),
              Wrap(
                spacing: Dimens.paddingMid,
                runSpacing: Dimens.paddingMid,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: List.generate(lData.featureList!.length, (index) => LatestFeatureItemView(feature: lData.featureList![index])),
              )
            ],
          ));
    } else {
      return vSpacer0();
    }
  }

  Container _exploreView() {
    final settings = getSettingsLocal();
    final hasUser = gUserRx.value.id > 0;
    return Container(
      decoration: boxDecorationRoundCorner(context: context),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.symmetric(vertical: Dimens.paddingLarge),
      alignment: Alignment.center,
      child: Column(
        children: [
          Wrap(
            spacing: Dimens.paddingMid,
            runSpacing: Dimens.paddingLargeExtra,
            crossAxisAlignment: WrapCrossAlignment.start,
            runAlignment: WrapAlignment.center,
            children: [
              ExploreItemView(title: "Deposit".tr, icon: Icons.file_download, onTap: () => checkLoggedInStatus(context, () => Get.to(() => WalletCryptoDepositScreen()))),
              ExploreItemView(title: "Withdraw".tr, icon: Icons.file_upload, onTap: () => checkLoggedInStatus(context, () => Get.to(() => WalletCryptoWithdrawScreen()))),
              if (settings?.swapStatus == 1)
                ExploreItemView(
                    title: "Swap".tr,
                    icon: Icons.swap_horizontal_circle,
                    onTap: () => checkLoggedInStatus(context, () => Get.to(() => const SwapScreen()))),
              if (settings?.enableGiftCard == 1)
                ExploreItemView(title: "Gift Card".tr, icon: Icons.card_giftcard, onTap: () => Get.to(() => const GiftCardsScreen())),
              if (hasUser)
                ExploreItemView(
                    title: "Wallet".tr,
                    icon: Icons.wallet,
                    onTap: () {
                      TemporaryData.changingPageId = 1;
                      getRootController().changeBottomNavIndex(AppBottomNavKey.wallet);
                    }),
              if (settings?.enableStaking == 1)
                ExploreItemView(title: "Staking".tr, icon: Icons.punch_clock_outlined, onTap: () => Get.to(() => const StakingScreen())),

              if (hasUser) ExploreItemView(title: "Fiat".tr, icon: Icons.account_balance, onTap: () => Get.to(() => const FiatScreen())),
              if (hasUser) ExploreItemView(title: "Reports".tr, icon: Icons.history, onTap: () => Get.to(() => const ActivityScreen())),
              if (hasUser) ExploreItemView(title: "Profile".tr, icon: Icons.person, onTap: () => Get.to(() => const ProfileScreen())),

              if (settings?.blogNewsModule == 1) ExploreItemView(title: "Blog".tr, icon: Icons.rss_feed, onTap: () => Get.to(() => const BlogScreen())),
              ExploreItemView(title: "FAQ".tr, icon: Icons.help, onTap: () => Get.to(() => const FAQPage())),
              if (settings?.p2pModule == 1)
                ExploreItemView(title: "P2P".tr, icon: Icons.people, onTap: () {
                  TemporaryData.changingPageId = 1;
                  getRootController().changeBottomNavIndex(AppBottomNavKey.trade);
                }),
              if (settings?.navbar?["ico"]?.status == true)
                ExploreItemView(title: "ICO".tr, icon: Icons.local_atm, onTap: () => Get.to(() => const ICOScreen())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _latestBlogView() {
    return Obx(() {
      final settings = getSettingsLocal();
      if (_controller.latestBlogList.isNotEmpty && settings?.blogNewsModule == 1) {
        return Container(
            decoration: boxDecorationRoundCorner(color: context.theme.dialogTheme.backgroundColor),
            padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
            child: Column(
              children: [
                vSpacer10(),
                Row(
                  children: [
                    TextRobotoAutoBold(settings?.blogSectionHeading ?? "", maxLines: 2),
                    hSpacer5(),
                    const Spacer(),
                    buttonOnlyIcon(
                        iconData: Icons.arrow_forward_ios,
                        onPress: () => Get.to(() => const BlogScreen()),
                        visualDensity: minimumVisualDensity,
                        size: Dimens.iconSizeMin)
                  ],
                ),
                dividerHorizontal(),
                for (final blog in _controller.latestBlogList) LatestBlogItemView(blog: blog)
              ],
            ));
      } else {
        return vSpacer0();
      }
    });
  }
}

// ─────────────────────────────────────────────
// NEW CRYPTO TRUST BANNER UI WIDGET
// ─────────────────────────────────────────────
class CryptoTrustBannerView extends StatelessWidget {
  const CryptoTrustBannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
  // color: Colors.black, // <--- COLOR HATA DIYA (Yahan decoration use karenge)
  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
  decoration: const BoxDecoration(
    color: Colors.black, // <--- COLOR IDHER DAALA
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(30), // Neeche left side round
      bottomRight: Radius.circular(30), // Neeche right side round
    ),
  ),
  child: Column(
    children: [
      RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
          children: [
            TextSpan(text: "Unleash ", style: TextStyle(color: _green)),
            TextSpan(text: "the ", style: TextStyle(color: Colors.white)),
            TextSpan(text: "Power ", style: TextStyle(color: _green)),
            TextSpan(text: "of ", style: TextStyle(color: Colors.white)),
            TextSpan(text: "Crypto ", style: TextStyle(color: _green)),
          ],
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        "Most Secure. Transparent. Compliant.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      const SizedBox(height: 24),
      _bigXHero(),
      const SizedBox(height: 28),
      _badgeRow(),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(child: _signInBtn()),
          const SizedBox(width: 12),
          Expanded(child: _signUpBtn()),
        ],
      ),
    ],
  ),
  
);

  }



  Widget _bigXHero() {
  // Video Controller banana padega, isliye Widget ko StatefulWidget banana padega
  // Niche diya gaya pura class copy karein:
  return const VideoHeroWidget();
}

  Widget _badge({required String imagePath, required String title, required String sub}) {
    return Column(
      children: [

        Row(
          children: [
            Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: showImageAsset(
            imagePath: imagePath,
            height: 30,
            width: 30,
            boxFit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 5,),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
          ],
        ),
        //  Square rounded box instead of Circle
        SizedBox(height: 8,),
        //  Chhota aur dim text
        if (sub.isNotEmpty)
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 10,
            ),
          ),
      ],
    );
  }
  

  Widget _badgeRow() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _badge(
          imagePath: "assets/images/user.png",
          title: "1M+",
          sub: "REGISTERED USER",
        ),
        _badge(
          imagePath: "assets/images/crypto.png",
          title: "500+",
          sub: "CRYPTO ASSETS",
        ),
        _badge(
          imagePath: "assets/images/iec.png",
          title: "ISO/IEC ",
          sub: "27001:2022",
        ),
      ],
    ),
  );
}


Widget _signInBtn() {
    return GestureDetector(
      onTap: () => Get.offAll(() => const SignInPage()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          
        ),
        child: const Center(child: Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _signUpBtn() {
    return GestureDetector(
      onTap: () => Get.offAll(() => const SignInPage()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text("Sign Up", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color iconColor, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 26),
        const SizedBox(height: 6),
        Text(
          value, 
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w700, 
            fontSize: 16
          )
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5), 
            fontSize: 9, 
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40, 
      width: 1, 
      color: Colors.white.withOpacity(0.15)
    );
  }
}




 // <--- Import karein file ke upar

// ... purane code ...

Widget _bigXHero() {
  // Video Controller banana padega, isliye Widget ko StatefulWidget banana padega
  // Niche diya gaya pura class copy karein:
  return const VideoHeroWidget();
}

// --- NAYA STATEFUL WIDGET FOR VIDEO ---
class VideoHeroWidget extends StatefulWidget {
  const VideoHeroWidget({super.key});

  @override
  State<VideoHeroWidget> createState() => _VideoHeroWidgetState();
}

class _VideoHeroWidgetState extends State<VideoHeroWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

    void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/hero.mp4')
        ..initialize().then((_) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
        });
    } catch (e) {
      // Agar error aayi to console print hogi
      print("Video Error: $e"); 
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Container
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
          ),
          
          // --- GESTURE DETECTOR WRAPPER ---
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause(); // Agar chal rahi hai to RUKO
                } else {
                  _controller.play(); // Agar ruki hai to CHALAO
                }
              });
            },
            child: _isInitialized
                ? SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
          // -------------------------------

          // OPTIONAL: Agar pause ho to ek Icon dikhana chahte hain
          if (!_isInitialized)
             const SizedBox() // Loading state
          else if (!_controller.value.isPlaying)
             const Icon(Icons.play_arrow, color: Colors.white, size: 50), // Play Icon jab pause ho
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// UPDATED MARKET EMPTY STATE WIDGET (With Controller)
// ─────────────────────────────────────────────
class MarketEmptyStateWidget extends StatefulWidget {
  const MarketEmptyStateWidget({super.key});

  @override
  State<MarketEmptyStateWidget> createState() => _MarketEmptyStateWidgetState();
}

class _MarketEmptyStateWidgetState extends State<MarketEmptyStateWidget> {
  int _currentTab = 0; // 0=Discover, 1=Blogs, 2=News, 3=Announcement

  // --- CONTROLLER LENE KE LIYE GET.PUT ---
  // Yeh LandingScreen ka same controller hai
  final LandingController _controller = Get.find<LandingController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      color: Colors.black,
      child: Column(
        children: [
          // --- 1. HEADER ---
          CommonTabHeader(
            onTabChanged: (index) {
              setState(() {
                _currentTab = index;
              });
            },
          ),

          // --- 2. CONTENT LOGIC ---
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentTab) {
      case 0: // DISCOVER
        return const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.folder_off, color: Colors.grey, size: 40),
             SizedBox(height: 10),
             Text("No Data", style: TextStyle(color: Colors.grey)),
          ],
        ));
      
      case 1: // BLOGS
        // --- BLOGS WIDGET ---
        return _buildBlogsContent();

      case 2: // NEWS
        return const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.newspaper, color: Colors.grey, size: 40),
             SizedBox(height: 10),
             Text("No News Data", style: TextStyle(color: Colors.grey)),
          ],
        ));

      case 3: // ANNOUNCEMENT
        return const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.announcement, color: Colors.grey, size: 40),
             SizedBox(height: 10),
             Text("No Announcements", style: TextStyle(color: Colors.grey)),
          ],
        ));

      default:
        return const SizedBox();
    }
  }

  // --- LOCAL METHOD JO REAL DATA BLOGS SE LAAYEGA ---
  Widget _buildBlogsContent() {
    return Obx(() {
      final settings = getSettingsLocal();
      // Controller ki list check karein
      if (_controller.latestBlogList.isNotEmpty && settings?.blogNewsModule == 1) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Header Row
              Row(
                children: [
                  Text(
                    settings?.blogSectionHeading ?? "Latest Blogs",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ],
              ),
              const SizedBox(height: 10),
              // Divider
              Container(height: 1, color: Colors.grey.withOpacity(0.2)),
              
              // Blog List
              Expanded(
                child: ListView.builder(
                  itemCount: _controller.latestBlogList.length,
                  itemBuilder: (context, index) {
                    final blog = _controller.latestBlogList[index];
                    // Yahan 'LatestBlogItemView' use ho raha hai jo imports me hai
                    return LatestBlogItemView(blog: blog); 
                  },
                ),
              ),
            ],
          ),
        );
      } else {
        // Agar data nahi hai
        return const Center(child: Text("No Blogs Available", style: TextStyle(color: Colors.grey)));
      }
    });
  }
}


// ─────────────────────────────────────────────
// COMMON HEADER WIDGET (Reusable)
// ─────────────────────────────────────────────
class CommonTabHeader extends StatefulWidget {
  final Function(int) onTabChanged; // Callback function

  const CommonTabHeader({super.key, required this.onTabChanged});

  @override
  State<CommonTabHeader> createState() => _CommonTabHeaderState();
}

class _CommonTabHeaderState extends State<CommonTabHeader> {
  int _selectedIndex = 0;
  final List<String> _tabs = ["Discover", "Blogs", "News", "Announcement"];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.black, // Background color
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
              // Parent ko batao ki index change ho gaya
              widget.onTabChanged(_selectedIndex); 
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}