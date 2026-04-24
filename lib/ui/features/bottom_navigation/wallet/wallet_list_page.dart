import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../../side_navigation/activity/activity_screen.dart';
import 'wallet_controller.dart';
import 'wallet_widgets.dart';

const double _svgW = 362.0;
const double _svgH = 204.0;
const double _cardH = 220.0;

class WalletListView extends StatefulWidget {
  const WalletListView({super.key, required this.fromType});
  final int fromType;

  @override
  State<WalletListView> createState() => _WalletListViewState();
}

class _WalletListViewState extends State<WalletListView> {
  final _controller = Get.find<WalletController>();
  final RxBool isLoading = false.obs;
  Timer? searchTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initViewData());
  }

  @override
  void didUpdateWidget(covariant WalletListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => initViewData());
  }

  void initViewData({bool? keepSearch}) {
    if (keepSearch != true) _controller.searchController.text = '';
    if (widget.fromType == WalletViewType.spot)
      _controller.getWalletTotalValue();
    _getWalletListData();
  }

  Future<void> _getWalletListData() async {
    isLoading.value = true;
    _controller.getWalletList(
      widget.fromType,
      () => isLoading.value = false,
      isFromLoadMore: false,
    );
  }

  Future<void> _onRefresh() async {
    initViewData(keepSearch: true);
    // wait until loading done
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return isLoading.value;
    });
  }

  void _onTextChanged(String text) {
    if (searchTimer?.isActive ?? false) searchTimer?.cancel();
    searchTimer = Timer(const Duration(seconds: 1), () => _getWalletListData());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fromType == WalletViewType.spot) {
      return _buildSpotView(context);
    }
    return _buildOtherView(context);
  }

  // ── SPOT VIEW — SingleChildScrollView with RefreshIndicator ──
  Widget _buildSpotView(BuildContext context) {
   return Theme(
  data: Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
      primary: const Color(0xFFCCFF00),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFFCCFF00),
      refreshBackgroundColor: Color(0xFF1A1A1A),
    ),
  ),
  child: RefreshIndicator(
    onRefresh: _onRefresh,
    color: const Color(0xFFCCFF00),
    backgroundColor: const Color(0xFF1A1A1A),
    strokeWidth: 2.5,
        child: Obx(() {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── HERO CARD ──
                    _SpotHeroCard(
                      isHide: gIsBalanceHide.value,
                      total: _controller.totalBalance.value,
                      onHistoryTap: () => Get.to(() => const ActivityScreen()),
                      onHide: (_) => _controller.walletList.refresh(),
                    ),
      
                    // ── INVITE CARD ──
                    const _InviteCard(),
      
                    // ── BALANCE + SEARCH BAR ──
                    _BalanceSearchBar(
                      controller: _controller.searchController,
                      onTextChanged: _onTextChanged,
                      onRefresh: () => initViewData(keepSearch: true),
                    ),
      
                    vSpacer10(),
                  ],
                ),
              ),
      
              // ── WALLET LIST ──
              _controller.walletList.isEmpty
                  ? SliverFillRemaining(
                      child: handleEmptyViewWithLoading(
                        isLoading.value,
                        message: "Your wallets will listed here".tr,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (_controller.hasMoreData &&
                              index == (_controller.walletList.length - 1)) {
                            _controller.getWalletList(
                              widget.fromType,
                              () {},
                              isFromLoadMore: true,
                            );
                          }
                          final item = _controller.walletList[index];
                          return SpotWalletItemView(
                            wallet: item,
                            isHide: gIsBalanceHide.value,
                          );
                        },
                        childCount: _controller.walletList.length,
                      ),
                    ),
            ],
          );
        }),
      ),
    );
  }

  // ── OTHER VIEW (Future, P2P) ──
  Widget _buildOtherView(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
          child: Row(
            children: [
              textFieldSearch(
                controller: _controller.searchController,
                height: Dimens.btnHeightMid,
                width: context.width - 60 - (Dimens.paddingMid * 2),
                borderRadius: Dimens.radiusCornerMid,
                onTextChange: _onTextChanged,
                onSearch: () => _onTextChanged(''),
              ),
              buttonOnlyIcon(
                iconData: Icons.refresh,
                visualDensity: minimumVisualDensity,
                onPress: () {
                  if (isLoading.value) return;
                  initViewData(keepSearch: true);
                },
              ),
            ],
          ),
        ),
        vSpacer10(),
        Obx(() {
          return _controller.walletList.isEmpty
              ? handleEmptyViewWithLoading(
                  isLoading.value,
                  message: "Your wallets will listed here".tr,
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: _controller.walletList.length,
                    itemBuilder: (context, index) {
                      if (_controller.hasMoreData &&
                          index == (_controller.walletList.length - 1)) {
                        _controller.getWalletList(
                          widget.fromType,
                          () {},
                          isFromLoadMore: true,
                        );
                      }
                      final item = _controller.walletList[index];
                      if (widget.fromType == WalletViewType.future ||
                          widget.fromType == WalletViewType.p2p) {
                        return CommonWalletItemView(
                          wallet: item,
                          fromType: widget.fromType,
                          isHide: gIsBalanceHide.value,
                        );
                      }
                      return vSpacer0();
                    },
                  ),
                );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INVITE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _InviteCard extends StatefulWidget {
  const _InviteCard();

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bubbleController;
  late Animation<double> _bubbleAnim;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bubbleAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF0F3D0F),
            Color(0xFF2E7D12),
            Color(0xFF77D215),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Invite Friends and Earn!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Get ",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      const TextSpan(
                        text: "\$10 ",
                        style: TextStyle(
                          color: Color(0xFFCCFF00),
                          fontSize: 11,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      TextSpan(
                        text: "in Crypto for Every Successful Referral",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 22,
            top: 0,
            bottom: 10,
            child: AnimatedBuilder(
              animation: _bubbleAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bubbleAnim.value),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/icons/bubble.png',
                width: 60,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BALANCE SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceSearchBar extends StatefulWidget {
  const _BalanceSearchBar({
    required this.controller,
    required this.onTextChanged,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final Function(String) onTextChanged;
  final VoidCallback onRefresh;

  @override
  State<_BalanceSearchBar> createState() => _BalanceSearchBarState();
}

class _BalanceSearchBarState extends State<_BalanceSearchBar>
    with SingleTickerProviderStateMixin {
  bool _showSearch = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _showSearch = !_showSearch);
    if (_showSearch) {
      _animController.forward();
    } else {
      _animController.reverse();
      widget.controller.clear();
      widget.onTextChanged('');
    }
  }

  void _showFilterDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _FilterDrawer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
         Text(
              "Balance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.5,
                fontFamily: 'DMSans',
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          

          const Spacer(),

          // ── Search bar slide in ──
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                width: _animation.value *
                    (MediaQuery.of(context).size.width - 130),
                child: Opacity(
                  opacity: _animation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: widget.controller,
                autofocus: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'DMSans',
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Search...",
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 15,
                    fontFamily: 'DMSans',
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: widget.onTextChanged,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Search / Close icon ──
          GestureDetector(
            onTap: _toggleSearch,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showSearch ? Icons.close : Icons.search,
                key: ValueKey(_showSearch),
                color: Colors.white.withOpacity(0.7),
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 10),

          if (!_showSearch)
            GestureDetector(
              onTap: () => _showFilterDrawer(context),
              child: Icon(
                Icons.tune_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 22,
              ),
            ),

          if (!_showSearch) const SizedBox(width: 12),

          if (!_showSearch)
            GestureDetector(
              onTap: widget.onRefresh,
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER DRAWER
// ─────────────────────────────────────────────────────────────────────────────
class _FilterDrawer extends StatelessWidget {
  const _FilterDrawer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Filter & Settings",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 20),
          _DrawerOption(
            icon: Icons.visibility_outlined,
            title: "Hide Zero Balances",
            onTap: () => Get.back(),
          ),
          _DrawerOption(
            icon: Icons.sort_rounded,
            title: "Sort by Value",
            onTap: () => Get.back(),
          ),
          _DrawerOption(
            icon: Icons.swap_vert_rounded,
            title: "Sort by Name",
            onTap: () => Get.back(),
          ),
          _DrawerOption(
            icon: Icons.settings_outlined,
            title: "Settings",
            onTap: () => Get.back(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAWER OPTION
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerOption extends StatelessWidget {
  const _DrawerOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontFamily: 'DMSans',
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPOT HERO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SpotHeroCard extends StatelessWidget {
  const _SpotHeroCard({
    required this.isHide,
    required this.total,
    this.onHide,
    this.onHistoryTap,
  });

  final bool isHide;
  final TotalBalance? total;
  final Function(bool)? onHide;
  final VoidCallback? onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final String currencyName =
        gUserRx.value.currency ?? total?.currency ?? DefaultValue.currency;

    return SizedBox(
      width: screenW,
      height: _cardH,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: _HeroCardClipper(cardW: screenW, cardH: _cardH),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: CustomPaint(
                  painter: _HeroCardPainter(
                    cardW: screenW,
                    cardH: _cardH,
                    fillColor: const Color(0x4D1A1A1A),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 25,
            top: 30,
            width: screenW * 0.40,
            height: _cardH * 1.3,
            child: Transform.rotate(
              angle: 1.250,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/wallet_green_wave.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _HeroBorderPainter(cardW: screenW, cardH: _cardH),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Est. Total Value",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.33,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              GetStorage().write(
                                PreferenceKey.isBalanceHide,
                                !isHide,
                              );
                              gIsBalanceHide.value = !isHide;
                              if (onHide != null) onHide!(!isHide);
                            },
                            child: Icon(
                              isHide
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withOpacity(0.5),
                              size: 14,
                            ),
                          ),
                          const Spacer(),
                          if (onHistoryTap != null)
                            GestureDetector(
                              onTap: onHistoryTap,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                    width: 1,
                                  ),
                                ),
                                child: const RotatingIcon(),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      isHide
                          ? const Text(
                              "******",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'DMSans',
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    "\$${currencyFormat(total?.total)}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'DMSans',
                                      height: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "USDT",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 16,
                                ),
                              ],
                            ),
                      if (!isHide) ...[
                        const SizedBox(height: 2),
                        Text(
                          "≈ \$${currencyFormat(total?.total)}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontFamily: 'DMSans',
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Today's PnL  ",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                              const TextSpan(
                                text: "+\$8.84 (0.71%)",
                                style: TextStyle(
                                  color: Color(0xFF4ED78E),
                                  fontSize: 12,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const WalletTopButtonsView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BORDER PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBorderPainter extends CustomPainter {
  const _HeroBorderPainter({required this.cardW, required this.cardH});
  final double cardW, cardH;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = cardW / _svgW;
    final sy = cardH / _svgH;
    final path = _HeroCardPainter._buildPath(sx, sy);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCardPainter extends CustomPainter {
  const _HeroCardPainter({
    required this.cardW,
    required this.cardH,
    required this.fillColor,
  });
  final double cardW, cardH;
  final Color fillColor;

  static Path _buildPath(double sx, double sy) => Path()
    ..moveTo(0, 20 * sy)
    ..cubicTo(0, 8.9543 * sy, 8.95431 * sx, 0, 20 * sx, 0)
    ..lineTo(132.716 * sx, 0)
    ..cubicTo(
      138.02 * sx, 0,
      143.107 * sx, 2.10714 * sy,
      146.858 * sx, 5.85786 * sy,
    )
    ..lineTo(155.142 * sx, 14.1421 * sy)
    ..cubicTo(
      158.893 * sx, 17.8929 * sy,
      163.98 * sx, 20 * sy,
      169.284 * sx, 20 * sy,
    )
    ..lineTo(192.716 * sx, 20 * sy)
    ..cubicTo(
      198.02 * sx, 20 * sy,
      203.107 * sx, 17.8929 * sy,
      206.858 * sx, 14.1421 * sy,
    )
    ..lineTo(215.142 * sx, 5.85786 * sy)
    ..cubicTo(218.893 * sx, 2.10713 * sy, 223.98 * sx, 0, 229.284 * sx, 0)
    ..lineTo(342 * sx, 0)
    ..cubicTo(353.046 * sx, 0, 362 * sx, 8.95431 * sy, 362 * sx, 20 * sy)
    ..lineTo(362 * sx, 184 * sy)
    ..cubicTo(
      362 * sx, 195.046 * sy,
      353.046 * sx, 204 * sy,
      342 * sx, 204 * sy,
    )
    ..lineTo(20 * sx, 204 * sy)
    ..cubicTo(8.9543 * sx, 204 * sy, 0, 195.046 * sy, 0, 184 * sy)
    ..lineTo(0, 20 * sy)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = cardW / _svgW;
    final sy = cardH / _svgH;
    final path = _buildPath(sx, sy);
    canvas.drawPath(path, Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIPPER
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCardClipper extends CustomClipper<Path> {
  const _HeroCardClipper({required this.cardW, required this.cardH});
  final double cardW, cardH;

  @override
  Path getClip(Size size) =>
      _HeroCardPainter._buildPath(cardW / _svgW, cardH / _svgH);

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}