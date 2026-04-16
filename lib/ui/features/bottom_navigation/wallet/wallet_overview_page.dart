import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/history.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../../side_navigation/activity/activity_screen.dart';
import 'wallet_controller.dart';
import 'wallet_widgets.dart';

class WalletOverviewPage extends StatefulWidget {
  const WalletOverviewPage({super.key});

  @override
  State<WalletOverviewPage> createState() => _WalletOverviewPageState();
}

class _WalletOverviewPageState extends State<WalletOverviewPage> {
  final _controller = Get.find<WalletController>();
  Rx<WalletOverview> wOverview = WalletOverview().obs;
  RxString selectedCoin = "".obs;

  Future<void> _getOverviewData() async {
    _controller.refreshController.callRefresh();
    _controller.getWalletOverviewData(coinType: selectedCoin.value, (overview) {
      wOverview.value = overview;
      selectedCoin.value = wOverview.value.selectedCoin ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      controller: _controller.refreshController,
      refreshOnStart: true,
      onRefresh: _getOverviewData,
      header: ClassicHeader(
          showText: false,
          iconTheme: const IconThemeData().copyWith(color: Colors.white)),
      child: Obx(() {
        final data = wOverview.value;
        final settings = getSettingsLocal();
        return ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [
            // ── TOP HERO CARD with green wave ──
            Stack(
              children: [
                // green wave background
                Positioned.fill(
                  child: ClipRect(
                    child: CustomPaint(
                      painter: _GreenWavePainter(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Overview" label + history icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Overview'.tr,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          GestureDetector(
                            onTap: () => Get.to(() => const ActivityScreen()),
                            child: const Icon(Icons.history,
                                color: Colors.white70, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Big balance
                      Obx(() => TotalBalanceView(
                            gIsBalanceHide.value,
                            data.total,
                            title: 'Estimated Balance'.tr,
                            totalUsd: data.totalUsd,
                            onHistoryTap: () =>
                                Get.to(() => const ActivityScreen()),
                            coins: data.coins,
                            selectedCoin: selectedCoin.value,
                            onSelectCoin: (selected) {
                              selectedCoin.value = selected;
                              _getOverviewData();
                            },
                          )),
                      const SizedBox(height: 20),
                      // Action buttons
                      const WalletTopButtonsView(),
                    ],
                  ),
                ),
              ],
            ),

            // ── ASSET LIST ──
            Container(
              color: const Color(0xFF0F0F0F),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.spotWallet != null)
                    AssetItemView(
                        icon: Icons.dashboard_outlined,
                        name: "Spot".tr,
                        amount: data.spotWallet,
                        amountCurrency: data.spotWalletUsd,
                        coinType: data.selectedCoin,
                        isBalanceHide: gIsBalanceHide.value,
                        onTap: () =>
                            _controller.changeWalletTab(WalletViewType.spot)),
                  if (settings?.enableFutureTrade == 1 &&
                      data.futureWallet != null)
                    AssetItemView(
                        icon: Icons.update_outlined,
                        name: "Future".tr,
                        amount: data.futureWallet,
                        amountCurrency: data.futureWalletUsd,
                        coinType: data.selectedCoin,
                        isBalanceHide: gIsBalanceHide.value,
                        onTap: () => _controller
                            .changeWalletTab(WalletViewType.future)),
                  if (settings?.p2pModule == 1 && data.p2PWallet != null)
                    AssetItemView(
                        icon: Icons.people_outline,
                        name: "P2P".tr,
                        amount: data.p2PWallet,
                        amountCurrency: data.p2PWalletUsd,
                        coinType: data.selectedCoin,
                        isBalanceHide: gIsBalanceHide.value,
                        onTap: () =>
                            _controller.changeWalletTab(WalletViewType.p2p)),
                ],
              ),
            ),

            // ── WAVE DIVIDER ──
            CustomPaint(
              size: const Size(double.infinity, 50),
              painter: _BottomWavePainter(),
            ),

            // ── RECENT TRANSACTIONS ──
            if (data.spotWallet != null)
              Container(
                color: const Color(0xFF0F0F0F),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Report'.tr,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        buttonTextBordered("View All".tr, false, onPress: () {
                          TemporaryData.activityType =
                              HistoryType.transaction;
                          Get.to(() => const ActivityScreen());
                        },
                            radius: Dimens.radiusCorner,
                            visualDensity: VisualDensity.compact),
                      ],
                    ),
                    vSpacer5(),
                    if (data.withdraw.isValid)
                      for (final withdraw in data.withdraw!)
                        HistoryItemView(
                            history: withdraw,
                            isWithdraw: true,
                            coinType: data.selectedCoin),
                    if (data.deposit.isValid)
                      for (final deposit in data.deposit!)
                        HistoryItemView(
                            history: deposit,
                            isWithdraw: false,
                            coinType: data.selectedCoin),
                    if (!data.deposit.isValid && !data.withdraw.isValid)
                      const EmptyView(),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ── GREEN WAVE PAINTER (top hero bg) ──
class _GreenWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // dark base
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF0F0F0F));

    // right-side glowing green blob
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7FFF00).withOpacity(0.55),
          const Color(0xFF39FF14).withOpacity(0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.25),
          radius: size.height * 0.65));
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.25),
        size.height * 0.65,
        paint);

    // wave curve at bottom
    final wavePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.78);
    path.cubicTo(
      size.width * 0.25, size.height * 0.65,
      size.width * 0.75, size.height * 0.92,
      size.width, size.height * 0.78,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── SMALL WAVE between sections ──
class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF0F0F0F));

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF39FF14).withOpacity(0.15),
          Colors.transparent,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.cubicTo(
      size.width * 0.3, size.height * 0.1,
      size.width * 0.7, size.height * 0.9,
      size.width, size.height * 0.4,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── ASSET ITEM ──
class AssetItemView extends StatelessWidget {
  const AssetItemView(
      {super.key,
      required this.icon,
      required this.name,
      this.amount,
      this.amountCurrency,
      this.coinType,
      required this.onTap,
      this.isBalanceHide});

  final IconData icon;
  final String name;
  final double? amount;
  final double? amountCurrency;
  final String? coinType;
  final Function() onTap;
  final bool? isBalanceHide;

  @override
  Widget build(BuildContext context) {
    String currencyName =
        getSettingsLocal()?.currency ?? DefaultValue.currency;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // icon circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: const Color(0xFF39FF14), size: 20),
            ),
            const SizedBox(width: 12),
            // name
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            // balance
            isBalanceHide == true
                ? const Text("******",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${coinFormat(amount)} $coinType",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Text(currencyFormat(amountCurrency, name: currencyName),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// ── HISTORY ITEM ──
class HistoryItemView extends StatelessWidget {
  const HistoryItemView(
      {super.key,
      required this.history,
      required this.isWithdraw,
      this.coinType});

  final History history;
  final bool isWithdraw;
  final String? coinType;

  @override
  Widget build(BuildContext context) {
    final icon =
        isWithdraw ? Icons.file_upload_outlined : Icons.file_download_outlined;
    final title = isWithdraw ? "Withdraw".tr : "Deposit".tr;
    final sign = isWithdraw ? "-" : "+";
    final amountColor =
        isWithdraw ? Colors.redAccent : const Color(0xFF39FF14);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF39FF14), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(formatDate(history.createdAt),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$sign${coinFormat(history.amount)} $coinType",
                  style: TextStyle(
                      color: amountColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text("Completed".tr,
                  style: const TextStyle(
                      color: Colors.green, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}