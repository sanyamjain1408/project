import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transaction_history_screen.dart';

const _dmSans = 'DMSans';
const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);

// SVG original dimensions
const double _svgNW = 362.0;
const double _svgNH = 204.0;

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  final TextEditingController _amountCtrl = TextEditingController();

  // fund_from / fund_to: 1=Spot, 2=Future
  int _fundFrom = 1;
  int _fundTo = 2;

  List<Map<String, dynamic>> _coins = [];
  Map<String, dynamic>? _selectedCoin;
  double _availableBalance = 0;
  bool _loadingCoins = false;
  bool _processing = false;

  String get _baseUrl => APIURLConstants.baseUrl;

  Map<String, String> _authHeaders() {
    final box = GetStorage();
    final token = box.read(PreferenceKey.accessToken) ?? '';
    final type = box.read(PreferenceKey.accessType) ?? 'Bearer';
    final secret = dotenv.env[EnvKeyValue.kApiSecret] ?? '';
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'userapisecret': secret,
      if (token.isNotEmpty) 'Authorization': '$type $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCoins());
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCoins() async {
    if (!mounted) return;
    setState(() {
      _loadingCoins = true;
      _coins = [];
      _selectedCoin = null;
      _availableBalance = 0;
    });
    try {
      final res = await http.get(
        Uri.parse(
          '$_baseUrl/api/get-coin-list?transfer=1&from_fund_type=$_fundFrom&to_fund_type=$_fundTo',
        ),
        headers: _authHeaders(),
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final raw = j['data'] is List
            ? j['data']
            : (j['data']?['data'] ?? j['coins'] ?? []);
        final list = (raw as List)
            .map<Map<String, dynamic>>(
              (e) => {
                'coin_type': e['coin_type']?.toString() ?? '',
                'name':
                    e['name']?.toString() ?? e['coin_name']?.toString() ?? '',
                'balance':
                    double.tryParse(e['balance']?.toString() ?? '0') ?? 0,
                'coin_icon':
                    e['coin_icon']?.toString() ?? e['icon']?.toString() ?? '',
              },
            )
            .toList();
        if (mounted) {
          setState(() => _coins = list);
          if (list.isNotEmpty) await _selectCoin(list.first);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingCoins = false);
  }

  Future<void> _selectCoin(Map<String, dynamic> coin) async {
    if (!mounted) return;
    setState(() {
      _selectedCoin = coin;
      _availableBalance = 0;
    });
    _amountCtrl.clear();
    double bal = 0;
    try {
      final coinType = coin['coin_type'] as String;
      final res = await http.get(
        Uri.parse(
          '$_baseUrl/api/get-fund-transfer-wallet-balance?coin_type=$coinType&to_fund_type=$_fundTo&from_fund_type=$_fundFrom',
        ),
        headers: _authHeaders(),
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['success'] == true) {
          bal =
              double.tryParse(j['data']?['from_balance']?.toString() ?? '0') ??
              0;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _availableBalance = bal);
  }

  void _swap() {
    final tmp = _fundFrom;
    _fundFrom = _fundTo;
    _fundTo = tmp;
    _loadCoins();
  }

  void _openCurrencySheet() {
    if (_coins.isEmpty) {
      Get.snackbar(
        'Loading',
        'Please wait...',
        backgroundColor: _card,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CoinSelectSheet(
        coins: _coins,
        onSelect: (c) {
          _selectCoin(c);
          Get.back();
        },
      ),
    );
  }

  Future<void> _onConfirm() async {
    final coin = _selectedCoin;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (coin == null || amount <= 0) {
      Get.snackbar(
        'Error',
        'Enter a valid amount',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (amount > _availableBalance) {
      Get.snackbar(
        'Error',
        'Amount exceeds available balance',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    setState(() => _processing = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/wallet-fund-transfer'),
        headers: _authHeaders(),
        body: jsonEncode({
          'fund_from': _fundFrom,
          'fund_to': _fundTo,
          'coin_type': coin['coin_type'],
          'amount': amount,
        }),
      );
      final j = jsonDecode(res.body);
      if (j['success'] == true) {
        Get.snackbar(
          'Success',
          j['message'] ?? 'Transfer successful',
          backgroundColor: const Color(0xFF4ED78E),
          colorText: Colors.black,
        );
        _amountCtrl.clear();
        _loadCoins();
      } else {
        Get.snackbar(
          'Failed',
          j['message'] ?? 'Transfer failed',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Something went wrong',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    final screenW = MediaQuery.of(context).size.width - 32;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Get.back(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.transparent,
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back, color: _white, size: 22),
          ),
        ),
        title: Transform.translate(
          offset: Offset(-20, 0),
          child: const Text(
            'Transfer',
            style: TextStyle(
              color: _white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: _dmSans,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => Get.to(
                () => const TransactionHistoryScreen(initialTab: 'transfer'),
              ),
              child: Container(
                width: 40,
                height: 40,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: RotationTransition(
                  turns: _spinCtrl,
                  child: Image.asset(
                    'assets/icons/time.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.history, color: _white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── CONFIRM BUTTON ──────────────────────────────────────────────────────
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            // ── NEW BANNER ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF53F8A0), Color(0xFF00E5AB)],
                      ),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        fontFamily: _dmSans,
                        height: 12 / 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Financial Account transfer are now supported. Transfers in or out will automatically subscribe to redeem from their respective flexible-term Earn products.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontFamily: _dmSans,
                        fontWeight: FontWeight.w400,
                        height: 16 / 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── TRANSFER DIRECTION CARD ─────────────────────────────────────
            _TransferDirectionCard(
              screenW: screenW,
              fundFrom: _fundFrom,
              onSwap: _swap,
            ),

            const SizedBox(height: 40),

            // ── CURRENCY SELECTOR ───────────────────────────────────────────
            GestureDetector(
              onTap: _openCurrencySheet,
              child: Container(
                height: 50,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (_loadingCoins)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: _green,
                          strokeWidth: 2,
                        ),
                      )
                    else if (_selectedCoin != null &&
                        (_selectedCoin!['coin_icon'] as String).isNotEmpty) ...[
                      showImageNetwork(
                        imagePath: _selectedCoin!['coin_icon'],
                        height: 30,
                        width: 30,
                        bgColor: Colors.transparent,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        _selectedCoin?['coin_type'] ?? 'Select Currency',
                        style: const TextStyle(
                          color: _white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                          height: 24 / 16,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: _white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── AMOUNT INPUT ────────────────────────────────────────────────
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        color: _white,
                        fontFamily: _dmSans,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 20 / 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Min : 0.0000001',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontFamily: _dmSans,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 20 / 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCoin?['coin_type'] ?? 'USDT',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontFamily: _dmSans,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 20 / 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _amountCtrl.text = _availableBalance
                              .toStringAsFixed(8),
                          child: const Text(
                            'Max',
                            style: TextStyle(
                              color: Color(0xFF4ED78E),
                              fontFamily: _dmSans,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 20 / 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── AVAILABLE ───────────────────────────────────────────────────
            Text(
              'Available: ${_availableBalance.toStringAsFixed(2)} ${_selectedCoin?['coin_type'] ?? 'USDT'}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontFamily: _dmSans,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
              ),
            ),

            const SizedBox(height: 20),

            // ── HOLD TO EARN CARD ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x3377D215), Color(0x33DEFF9E)],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Hold to Earn',
                          style: TextStyle(
                            color: _white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: _dmSans,
                            height: 24 / 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'No lock-up. Trade anytime with daily earnings credited automatically.',
                          style: TextStyle(
                            color: _white,
                            fontSize: 12,
                            fontFamily: _dmSans,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF53F8A0), Color(0xFF00E5AB)],
                      ),
                    ),
                    child: const Text(
                      'APR up to 3.2%',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: _dmSans,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _processing ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: _green.withOpacity(0.5),
                  elevation: 0,
                  overlayColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: _dmSans,
                          height: 24 / 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── COIN SELECT BOTTOM SHEET ────────────────────────────────────────────────────
class _CoinSelectSheet extends StatelessWidget {
  const _CoinSelectSheet({required this.coins, required this.onSelect});
  final List<Map<String, dynamic>> coins;
  final void Function(Map<String, dynamic>) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Select Currency',
              style: TextStyle(
                color: _white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans,
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: coins.length,
              itemBuilder: (_, i) {
                final coin = coins[i];
                return InkWell(
                  onTap: () => onSelect(coin),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        showImageNetwork(
                          imagePath: coin['coin_icon'],
                          height: 36,
                          width: 36,
                          bgColor: Colors.transparent,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coin['coin_type'] ?? '',
                              style: const TextStyle(
                                color: _white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: _dmSans,
                                height: 24 / 16,
                              ),
                            ),
                            Text(
                              coin['name'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontFamily: _dmSans,
                                fontWeight: FontWeight.w400,
                                height: 16 / 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${(coin['balance'] as double).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontFamily: _dmSans,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── TRANSFER DIRECTION CARD ─────────────────────────────────────────────────────
class _TransferDirectionCard extends StatelessWidget {
  const _TransferDirectionCard({
    required this.screenW,
    required this.fundFrom,
    required this.onSwap,
  });
  final double screenW;
  final int fundFrom;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final cardH = screenW * _svgNH / _svgNW;
    final sx = screenW / _svgNW;
    final sy = cardH / _svgNH;

    final circleCx = 181.0 * sx;
    final circleCy = 102.0 * sy;
    final circleR = 20.0 * sx;

    final fromLabel = fundFrom == 1 ? 'Spot' : 'Future';
    final toLabel = fundFrom == 1 ? 'Future' : 'Spot';

    // Wave width
    final waveW = screenW * 0.36;

    return SizedBox(
      width: screenW,
      height: cardH,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── 1. Dark base ─────────────────────────────────────────────────
          Positioned.fill(
            child: ClipPath(
              clipper: _TransferOuterClipper(sx: sx, sy: sy),
              child: Container(color: _bg),
            ),
          ),

          // ── 2. Left wave — clipped to card outer shape ───────────────────
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: waveW,
            child: ClipPath(
              clipper: _TransferOuterClipper(sx: sx, sy: sy),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                child: Image.asset(
                  'assets/images/wallet_green_wave.png',
                  width: waveW,
                  height: cardH,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ── 3. Right wave — clipped properly to card right boundary ──────
          // ✅ FIX: _RightWaveClipper translates the card path into the
          //         right-wave widget's local coordinate space so the clip
          //         exactly follows the card's right curved edge.
          Positioned(
            right: -2,
            top: 0,
            bottom: 1,
            width: waveW,
            child: ClipPath(
              clipper: _RightWaveClipper(
                sx: sx,
                sy: sy,
                cardW: screenW,
                waveW: waveW,
              ),
              child: Image.asset(
                'assets/images/wallet_green_wave.png',
                width: waveW,
                height: cardH,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ── 4. SVG card shape (dark fill + circle hole) ──────────────────
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/svg/transfer.svg',
              width: screenW,
              height: cardH,
              fit: BoxFit.fill,
            ),
          ),

          // ── 5. Border glow + center divider lines ────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _TransferBorderGlowPainter(
                sx: sx,
                sy: sy,
                cardW: screenW,
                cardH: cardH,
                circleCx: circleCx,
                circleCy: circleCy,
                circleR: circleR,
              ),
            ),
          ),

          // ── 6. "From" + fromLabel — top half ─────────────────────────────
          Positioned(
            top: 10,
            left: 5,
            right: 0,
            height: circleCy - circleR,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'From',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: _dmSans,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fromLabel,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: _dmSans,
                    height: 28 / 20,
                  ),
                ),
              ],
            ),
          ),

          // ── 7. Swap arrows — inside the SVG circle hole ──────────────────
          Positioned(
            left: circleCx - circleR,
            top: circleCy - circleR,
            width: circleR * 2,
            height: circleR * 2,
            child: GestureDetector(
              onTap: onSwap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  'assets/icons/arrow.png',
                  width: circleR * 1.1,
                  height: circleR * 1.1,
                  color: _white,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ── 8. toLabel + "To" — bottom half ─────────────────────────────
          Positioned(
            bottom: 10,
            left: 5,
            right: 0,
            height: cardH - (circleCy + circleR),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  toLabel,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: _dmSans,
                    height: 28 / 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'To',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: _dmSans,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── STANDALONE PATH BUILDER ─────────────────────────────────────────────────────
Path _buildTransferCardOuterPath(double sx, double sy) {
  return Path()
    ..moveTo(132.716 * sx, 0)
    ..cubicTo(
      138.02 * sx,
      0,
      143.107 * sx,
      2.107 * sy,
      146.857 * sx,
      5.857 * sy,
    )
    ..lineTo(155.143 * sx, 14.143 * sy)
    ..cubicTo(
      158.893 * sx,
      17.893 * sy,
      163.98 * sx,
      20 * sy,
      169.284 * sx,
      20 * sy,
    )
    ..lineTo(192.716 * sx, 20 * sy)
    ..cubicTo(
      198.02 * sx,
      20 * sy,
      203.107 * sx,
      17.893 * sy,
      206.857 * sx,
      14.143 * sy,
    )
    ..lineTo(215.143 * sx, 5.857 * sy)
    ..cubicTo(218.893 * sx, 2.107 * sy, 223.98 * sx, 0, 229.284 * sx, 0)
    ..lineTo(342 * sx, 0)
    ..cubicTo(353.046 * sx, 0, 362 * sx, 8.954 * sy, 362 * sx, 20 * sy)
    ..lineTo(362 * sx, 184 * sy)
    ..cubicTo(
      362 * sx,
      195.046 * sy,
      353.046 * sx,
      204 * sy,
      342 * sx,
      204 * sy,
    )
    ..lineTo(229.284 * sx, 204 * sy)
    ..cubicTo(
      223.98 * sx,
      204 * sy,
      218.893 * sx,
      201.893 * sy,
      215.143 * sx,
      198.143 * sy,
    )
    ..lineTo(206.857 * sx, 189.857 * sy)
    ..cubicTo(
      203.107 * sx,
      186.107 * sy,
      198.02 * sx,
      184 * sy,
      192.716 * sx,
      184 * sy,
    )
    ..lineTo(169.284 * sx, 184 * sy)
    ..cubicTo(
      163.98 * sx,
      184 * sy,
      158.893 * sx,
      186.107 * sy,
      155.143 * sx,
      189.857 * sy,
    )
    ..lineTo(146.857 * sx, 198.143 * sy)
    ..cubicTo(
      143.107 * sx,
      201.893 * sy,
      138.02 * sx,
      204 * sy,
      132.716 * sx,
      204 * sy,
    )
    ..lineTo(20 * sx, 204 * sy)
    ..cubicTo(8.954 * sx, 204 * sy, 0, 195.046 * sy, 0, 184 * sy)
    ..lineTo(0, 20 * sy)
    ..cubicTo(0, 8.954 * sy, 8.954 * sx, 0, 20 * sx, 0)
    ..lineTo(132.716 * sx, 0)
    ..close();
}

// ── LEFT / OUTER CARD CLIPPER ───────────────────────────────────────────────────
// Used for the left wave and the dark base — path origin = (0,0) = card origin.
class _TransferOuterClipper extends CustomClipper<Path> {
  const _TransferOuterClipper({required this.sx, required this.sy});
  final double sx, sy;

  @override
  Path getClip(Size size) => _buildTransferCardOuterPath(sx, sy);

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ── RIGHT WAVE CLIPPER ──────────────────────────────────────────────────────────
// ✅ The right wave widget is positioned at `right: 0` with width = waveW.
//    Its local origin (0,0) corresponds to (cardW - waveW, 0) in card space.
//    We shift the full card path left by (cardW - waveW) so the clip aligns
//    perfectly with the card's right curved boundary.
class _RightWaveClipper extends CustomClipper<Path> {
  const _RightWaveClipper({
    required this.sx,
    required this.sy,
    required this.cardW,
    required this.waveW,
  });
  final double sx, sy, cardW, waveW;

  @override
  Path getClip(Size size) {
    final fullPath = _buildTransferCardOuterPath(sx, sy);
    // Translate so that the card's right edge aligns with this widget's bounds
    final shift = cardW - waveW;
    return fullPath.shift(Offset(-shift, 0));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ── BORDER GLOW PAINTER ─────────────────────────────────────────────────────────
class _TransferBorderGlowPainter extends CustomPainter {
  const _TransferBorderGlowPainter({
    required this.sx,
    required this.sy,
    required this.cardW,
    required this.cardH,
    required this.circleCx,
    required this.circleCy,
    required this.circleR,
  });
  final double sx, sy, cardW, cardH;
  final double circleCx, circleCy, circleR;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildTransferCardOuterPath(sx, sy);
    final glowH = 26.0 * sy;

    // top glow
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, cardW, glowH));
    _drawGlow(canvas, path);
    canvas.restore();

    // bottom glow
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, cardH - glowH, cardW, glowH));
    _drawGlow(canvas, path);
    canvas.restore();

    // center horizontal divider lines
    final linePaint = Paint()
      ..color = const Color(0xFF5E5955)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, circleCy),
      Offset(circleCx - circleR, circleCy),
      linePaint,
    );
    canvas.drawLine(
      Offset(circleCx + circleR, circleCy),
      Offset(cardW, circleCy),
      linePaint,
    );
  }

  void _drawGlow(Canvas canvas, Path path) {
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      const steps = 1000;
      for (int i = 0; i < steps; i++) {
        final t = i / steps;
        final dist = metric.length * t;
        final tangent = metric.getTangentForOffset(dist);
        if (tangent == null) continue;

        final x = tangent.position.dx;
        final distFromCenter = ((x - cardW / 2) / (cardW / 2)).abs();
        final opacity = (0.02 + (1.0 - distFromCenter) * 0.18).clamp(0.0, 1.0);
        final strokeW = 0.3 + (1.0 - distFromCenter) * 0.9;

        final start = t * metric.length;
        final end = ((t + 1 / steps) * metric.length).clamp(0.0, metric.length);

        canvas.drawPath(
          metric.extractPath(start, end),
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.square,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
