import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';

const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF161616);
const _card2 = Color(0xFF1C1C1E);
const _green = Color(0xFFCCFF00);
const _white = Colors.white;
const _grey = Color(0xFF8E8E93);
const _red = Color(0xFFFF453A);
const _upGreen = Color(0xFF07B961);
const _dmSans = 'DMSans';
const _api = 'https://api.trapix.com';

// ─── Models ──────────────────────────────────────────────────────────────────

class _TrapixPair {
  final String label;
  final String value;
  final String apiKey;
  final String icon;
  const _TrapixPair({
    required this.label,
    required this.value,
    required this.apiKey,
    required this.icon,
  });
}

class _PriceAlert {
  final int id;
  final String pair;
  final String alertType;
  final String? direction;
  final double? targetPrice;
  final double? spikePct;
  final String frequency;
  final String status;

  _PriceAlert({
    required this.id,
    required this.pair,
    required this.alertType,
    this.direction,
    this.targetPrice,
    this.spikePct,
    required this.frequency,
    required this.status,
  });

  factory _PriceAlert.fromJson(Map<String, dynamic> j) => _PriceAlert(
        id: j['id'] ?? 0,
        pair: j['pair'] ?? '',
        alertType: j['alert_type'] ?? 'price',
        direction: j['direction'],
        targetPrice: j['target_price'] != null
            ? double.tryParse(j['target_price'].toString())
            : null,
        spikePct: j['spike_pct'] != null
            ? double.tryParse(j['spike_pct'].toString())
            : null,
        frequency: j['frequency'] ?? 'everytime',
        status: j['status'] ?? 'active',
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class PriceAlertsScreen extends StatefulWidget {
  const PriceAlertsScreen({super.key});

  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen> {
  // Pairs
  List<_TrapixPair> _pairs = [
    const _TrapixPair(label: 'BTC/USDT', value: 'BTCUSDT', apiKey: 'BTC_USDT', icon: ''),
  ];
  bool _pairsLoading = true;
  _TrapixPair _selectedPair =
      const _TrapixPair(label: 'BTC/USDT', value: 'BTCUSDT', apiKey: 'BTC_USDT', icon: '');

  // Live price
  double? _livePrice;
  double? _livePct;

  // Spot price map
  Map<String, Map<String, double>> _spotMap = {};
  Timer? _spotTimer;

  // Form
  String _tab = 'price'; // 'price' | 'spike'
  String _direction = 'rises_to';
  final _targetCtrl = TextEditingController();
  final _spikeCtrl = TextEditingController();
  String _frequency = 'everytime';
  bool _freqOpen = false;

  // Alerts
  List<_PriceAlert> _alerts = [];
  bool _alertsLoading = false;
  bool _submitting = false;
  String _error = '';
  String _success = '';

  // Coin drawer
  bool _showCoins = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPairs();
    _startSpotPolling();
    _fetchAlerts();
    _targetCtrl.addListener(_autoDirection);
  }

  @override
  void dispose() {
    _spotTimer?.cancel();
    _targetCtrl.dispose();
    _spikeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Auto direction based on target vs live price ──────────────────────────
  void _autoDirection() {
    final val = double.tryParse(_targetCtrl.text);
    if (val == null || _livePrice == null) return;
    final dir = val >= _livePrice! ? 'rises_to' : 'falls_to';
    if (dir != _direction) setState(() => _direction = dir);
  }

  // ── Load pairs from spot API ──────────────────────────────────────────────
  Future<void> _loadPairs() async {
    setState(() => _pairsLoading = true);
    try {
      final res = await http.get(Uri.parse('$_api/api/v1/spot/pairs'));
      final json = jsonDecode(res.body);
      final raw = (json['data'] ?? json['pairs'] ?? (json is List ? json : [])) as List? ?? [];
      final formatted = <_TrapixPair>[];
      for (final p in raw) {
        final base = (p['base_currency'] ?? '') as String;
        final quote = (p['quote_currency'] ?? 'USDT') as String;
        if (base.isEmpty) continue;
        final value = '$base$quote';
        final apiKey = '${base}_$quote';
        final label = '$base/$quote';
        final icon = (p['icon'] ?? '') as String;
        formatted.add(_TrapixPair(label: label, value: value, apiKey: apiKey, icon: icon));
      }
      if (formatted.isNotEmpty) {
        final def = formatted.firstWhere(
          (p) => p.value == 'BTCUSDT',
          orElse: () => formatted.first,
        );
        setState(() {
          _pairs = formatted;
          _selectedPair = def;
          _pairsLoading = false;
        });
        _updateLivePrice();
      } else {
        setState(() => _pairsLoading = false);
      }
    } catch (_) {
      setState(() => _pairsLoading = false);
    }
  }

  // ── Spot price polling ────────────────────────────────────────────────────
  void _startSpotPolling() {
    _fetchSpotPrices();
    _spotTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchSpotPrices());
  }

  Future<void> _fetchSpotPrices() async {
    try {
      final res = await http.get(Uri.parse('$_api/api/v1/spot/pairs'));
      final json = jsonDecode(res.body);
      final arr = (json['data'] ?? json['pairs'] ?? (json is List ? json : [])) as List? ?? [];
      final map = <String, Map<String, double>>{};
      for (final p in arr) {
        final key = (p['symbol'] ?? '${p['base_currency'] ?? ''}${p['quote_currency'] ?? ''}')
            .toString()
            .toUpperCase();
        if (key.isNotEmpty) {
          map[key] = {
            'price': double.tryParse(p['current_price']?.toString() ?? '0') ?? 0,
            'change': double.tryParse(p['price_change_24h']?.toString() ?? '0') ?? 0,
            'volume': double.tryParse(p['volume_24h']?.toString() ?? '0') ?? 0,
          };
        }
      }
      if (!mounted) return;
      setState(() {
        _spotMap = map;
        _updateLivePrice();
      });
    } catch (_) {}
  }

  void _updateLivePrice() {
    final live = _getLive(_selectedPair);
    if (live != null) {
      _livePrice = live['price'];
      _livePct = live['change'];
    }
  }

  Map<String, double>? _getLive(_TrapixPair p) {
    return _spotMap[p.value.toUpperCase()] ??
        _spotMap[p.apiKey.replaceAll('_', '').toUpperCase()] ??
        _spotMap[p.label.replaceAll('/', '').toUpperCase()];
  }

  // ── Switch pair ───────────────────────────────────────────────────────────
  void _switchPair(_TrapixPair p) {
    setState(() {
      _selectedPair = p;
      _showCoins = false;
      _targetCtrl.clear();
      _error = '';
      _success = '';
      _updateLivePrice();
    });
  }

  // ── Fetch alerts ──────────────────────────────────────────────────────────
  Future<void> _fetchAlerts() async {
    final userId = gUserRx.value.id;
    if (userId == 0) return;
    setState(() => _alertsLoading = true);
    try {
      final res = await http.get(Uri.parse('$_api/api/price-alerts?user_id=$userId'));
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final data = (json['data'] as List?) ?? [];
        setState(() => _alerts = data.map((e) => _PriceAlert.fromJson(e)).toList());
      }
    } catch (_) {}
    setState(() => _alertsLoading = false);
  }

  // ── Create alert ──────────────────────────────────────────────────────────
  Future<void> _create() async {
    final userId = gUserRx.value.id;
    if (userId == 0) {
      setState(() => _error = 'Please log in to create alerts');
      return;
    }
    setState(() { _error = ''; _success = ''; _submitting = true; });

    final body = <String, dynamic>{
      'user_id': userId,
      'pair': _selectedPair.value,
      'alert_type': _tab == 'price' ? 'price' : 'spike_plunge',
      'frequency': _frequency,
    };

    if (_tab == 'price') {
      final price = double.tryParse(_targetCtrl.text);
      if (price == null || price <= 0) {
        setState(() { _error = 'Enter a valid target price'; _submitting = false; });
        return;
      }
      body['direction'] = _direction;
      body['target_price'] = price;
    } else {
      final pct = double.tryParse(_spikeCtrl.text);
      if (pct == null || pct <= 0) {
        setState(() { _error = 'Enter a valid volatility %'; _submitting = false; });
        return;
      }
      body['spike_pct'] = pct;
    }

    try {
      final res = await http.post(
        Uri.parse('$_api/api/price-alerts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final newAlert = _PriceAlert.fromJson(json['data']);
        setState(() {
          _alerts = [newAlert, ..._alerts];
          _success = 'Alert created!';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _success = '');
        });
      } else {
        setState(() => _error = json['message'] ?? 'Failed to create alert');
      }
    } catch (_) {
      setState(() => _error = 'Network error');
    }
    setState(() => _submitting = false);
  }

  // ── Delete alert ──────────────────────────────────────────────────────────
  Future<void> _delete(int id) async {
    final userId = gUserRx.value.id;
    try {
      final res = await http.delete(
          Uri.parse('$_api/api/price-alerts/$id?user_id=$userId'));
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        setState(() => _alerts = _alerts.where((a) => a.id != id).toList());
      }
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatPrice(double v) {
    if (v >= 100) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(4);
    if (v >= 0.01) return v.toStringAsFixed(4);
    if (v >= 0.0001) return v.toStringAsFixed(6);
    return v.toStringAsFixed(8);
  }

  String _formatVolume(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}k';
    return v.toStringAsFixed(2);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_freqOpen) setState(() => _freqOpen = false);
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Stack(
            children: [
              _buildMain(),
              if (_showCoins) _buildCoinsDrawer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMain() {
    final pctColor = (_livePct ?? 0) >= 0 ? _upGreen : _red;
    final priceDisplay = _livePrice != null ? _formatPrice(_livePrice!) : '–';
    final pctDisplay =
        _livePct != null ? '${_livePct! >= 0 ? '+' : ''}${_livePct!.toStringAsFixed(2)}%' : '+0.00%';

    return Column(
      children: [
        // ── Top bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 8, 11, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back, color: _white, size: 24),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _tab = 'price'),
                child: Text(
                  'Price Alert',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: _tab == 'price' ? FontWeight.bold : FontWeight.w400,
                    color: _tab == 'price' ? _white : _white.withOpacity(0.4),
                    fontFamily: _dmSans,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _tab = 'spike'),
                child: Text(
                  'Spike / Plunge',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: _tab == 'spike' ? FontWeight.bold : FontWeight.w400,
                    color: _tab == 'spike' ? _white : _white.withOpacity(0.4),
                    fontFamily: _dmSans,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Coin header ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              // Coin icon
              GestureDetector(
                onTap: () => setState(() => _showCoins = true),
                child: _selectedPair.icon.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _selectedPair.icon,
                          width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _coinPlaceholder(_selectedPair.label),
                        ),
                      )
                    : _coinPlaceholder(_selectedPair.label),
              ),
              const SizedBox(height: 11),
              // Pair selector
              GestureDetector(
                onTap: () => setState(() => _showCoins = true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedPair.label,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: _white, fontFamily: _dmSans)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: _white.withOpacity(0.7), size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Price row
              SizedBox(
                width: 170,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          priceDisplay,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: pctColor,
                            fontFamily: _dmSans,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (_livePct ?? 0) >= 0 ? '↑' : '↓',
                          style: TextStyle(fontSize: 22, color: pctColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '≈ ${_livePrice != null ? _formatPrice(_livePrice!) : '0.00'}',
                          style: const TextStyle(fontSize: 13, color: _grey, fontFamily: _dmSans),
                        ),
                        Text(
                          pctDisplay,
                          style: TextStyle(fontSize: 13, color: pctColor, fontWeight: FontWeight.w600, fontFamily: _dmSans),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Form + Alerts ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(11, 0, 11, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target price / spike input
                if (_tab == 'price') ...[
                  _buildPriceInput(),
                  const SizedBox(height: 4),
                  Text(
                    "Alert Price can't be more than 100x the current price",
                    style: TextStyle(fontSize: 12, color: _white.withOpacity(0.4), fontFamily: _dmSans),
                  ),
                ] else ...[
                  _buildSpikeInput(),
                  const SizedBox(height: 4),
                  Text(
                    'Supported range: 1.00% to 5.00%',
                    style: TextStyle(fontSize: 12, color: _white.withOpacity(0.4), fontFamily: _dmSans),
                  ),
                ],

                const SizedBox(height: 14),

                // Alert Frequency row
                _buildFrequencyRow(),

                const SizedBox(height: 14),

                // Error / Success
                if (_error.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error,
                        style: const TextStyle(color: _red, fontSize: 13, fontFamily: _dmSans),
                        textAlign: TextAlign.center),
                  ),
                if (_success.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_success,
                        style: const TextStyle(color: _green, fontSize: 13, fontFamily: _dmSans),
                        textAlign: TextAlign.center),
                  ),

                const SizedBox(height: 14),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _submitting ? null : _create,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: _submitting ? const Color(0xFF3A3A3C) : _green,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _submitting
                            ? null
                            : [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: Text(
                          _submitting ? 'Creating...' : 'Create Alert',
                          style: TextStyle(
                            color: _submitting ? _grey : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: _dmSans,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── All Alerts section ──
                if (_alerts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(11, 10, 11, 8),
                          child: Text(
                            'All Alert',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _white,
                              fontFamily: _dmSans,
                            ),
                          ),
                        ),
                        ..._alerts.map((a) => _buildAlertItem(a)).toList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Price input ───────────────────────────────────────────────────────────
  Widget _buildPriceInput() {
    final hasValue = _targetCtrl.text.isNotEmpty;
    final isRises = _direction == 'rises_to';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616).withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minHeight: 44),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasValue)
            Positioned(
              left: 11,
              child: GestureDetector(
                onTap: () => setState(
                    () => _direction = isRises ? 'falls_to' : 'rises_to'),
                child: Row(
                  children: [
                    Icon(
                      isRises ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isRises ? _upGreen : _red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRises ? 'Rises' : 'Falls',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isRises ? _upGreen : _red,
                        fontFamily: _dmSans,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hasValue ? 80 : 11, vertical: 8),
            child: TextField(
              controller: _targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: !hasValue
                    ? _white.withOpacity(0.6)
                    : isRises
                        ? _upGreen
                        : _red,
                fontFamily: _dmSans,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter Price',
                hintStyle: TextStyle(
                  fontSize: 18,
                  color: _white.withOpacity(0.6),
                  fontFamily: _dmSans,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (hasValue)
            Positioned(
              right: 11,
              child: GestureDetector(
                onTap: () {
                  _targetCtrl.clear();
                  setState(() {});
                },
                child: const Icon(Icons.close, color: _grey, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ── Spike input ───────────────────────────────────────────────────────────
  Widget _buildSpikeInput() {
    final hasValue = _spikeCtrl.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616).withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minHeight: 44),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasValue)
            Positioned(
              left: 11,
              child: Row(
                children: [
                  const Icon(Icons.swap_vert, size: 16, color: _grey),
                  const SizedBox(width: 4),
                  const Text('5 Min Volatility',
                      style: TextStyle(fontSize: 14, color: _grey, fontFamily: _dmSans)),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hasValue ? 140 : 11, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: TextField(
                    controller: _spikeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: hasValue ? TextAlign.right : TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: _white.withOpacity(0.66),
                      fontFamily: _dmSans,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '5 Min Volatility %',
                      hintStyle: TextStyle(
                          fontSize: 18, color: _white.withOpacity(0.6), fontFamily: _dmSans),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (hasValue)
                  const Text('%',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _white, fontFamily: _dmSans)),
              ],
            ),
          ),
          if (hasValue)
            Positioned(
              right: 11,
              child: GestureDetector(
                onTap: () {
                  _spikeCtrl.clear();
                  setState(() {});
                },
                child: const Icon(Icons.close, color: _grey, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ── Frequency row ─────────────────────────────────────────────────────────
  Widget _buildFrequencyRow() {
    final freqLabel = _frequency == 'everytime'
        ? 'Everytime'
        : _frequency == 'once'
            ? 'Once'
            : 'Daily';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Alert Frequency',
            style: TextStyle(fontSize: 15, color: _grey, fontWeight: FontWeight.w500, fontFamily: _dmSans)),
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => setState(() => _freqOpen = !_freqOpen),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _card2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(freqLabel,
                    style: const TextStyle(fontSize: 15, color: _white, fontWeight: FontWeight.w500, fontFamily: _dmSans)),
              ),
            ),
            if (_freqOpen)
              Positioned(
                bottom: 48,
                right: 0,
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24)],
                  ),
                  child: Column(
                    children: ['everytime', 'once', 'daily'].map((opt) {
                      final isActive = _frequency == opt;
                      return GestureDetector(
                        onTap: () => setState(() { _frequency = opt; _freqOpen = false; }),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? _white.withOpacity(0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            opt[0].toUpperCase() + opt.substring(1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _white,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontFamily: _dmSans,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Alert item ────────────────────────────────────────────────────────────
  Widget _buildAlertItem(_PriceAlert a) {
    final isPrice = a.alertType == 'price';
    final isRises = a.direction == 'rises_to';
    final pairLabel = a.pair.contains('/')
        ? a.pair
        : a.pair.replaceAllMapped(RegExp(r'(USDT|BTC|ETH|BNB|USDC)$'), (m) => '/${m.group(0)}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pairLabel,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _white, fontFamily: _dmSans)),
              const SizedBox(height: 2),
              if (isPrice)
                Row(
                  children: [
                    Icon(isRises ? Icons.trending_up : Icons.trending_down,
                        size: 10, color: isRises ? _upGreen : _red),
                    const SizedBox(width: 3),
                    Text(isRises ? 'Rises' : 'Falls',
                        style: TextStyle(fontSize: 11, color: isRises ? _upGreen : _red, fontWeight: FontWeight.w500, fontFamily: _dmSans)),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(Icons.swap_vert, size: 10, color: _grey),
                    const SizedBox(width: 3),
                    const Text('5 Min Volatility',
                        style: TextStyle(fontSize: 11, color: _grey, fontWeight: FontWeight.w500, fontFamily: _dmSans)),
                  ],
                ),
            ],
          ),
          Row(
            children: [
              if (isPrice && a.targetPrice != null)
                Text(
                  a.targetPrice!.toStringAsFixed(a.targetPrice! >= 100 ? 2 : 6),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isRises ? _upGreen : _red,
                    fontFamily: _dmSans,
                  ),
                )
              else if (!isPrice && a.spikePct != null)
                Text(
                  '${a.spikePct!.toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _white, fontFamily: _dmSans),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _delete(a.id),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 10, color: _grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Coin placeholder ──────────────────────────────────────────────────────
  Widget _coinPlaceholder(String label) {
    final sym = label.split('/').first;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _green.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          sym.length >= 2 ? sym.substring(0, 2) : sym,
          style: const TextStyle(fontSize: 22, color: _green, fontWeight: FontWeight.bold, fontFamily: _dmSans),
        ),
      ),
    );
  }

  // ── Coins drawer ──────────────────────────────────────────────────────────
  Widget _buildCoinsDrawer() {
    final query = _searchCtrl.text.toLowerCase();
    final filtered = _pairs
        .where((p) => p.label.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) {
        final pa = _getLive(a)?['price'] ?? 0;
        final pb = _getLive(b)?['price'] ?? 0;
        return pb.compareTo(pa);
      });

    return Stack(
      children: [
        // backdrop
        GestureDetector(
          onTap: () => setState(() => _showCoins = false),
          child: Container(color: Colors.black.withOpacity(0.65)),
        ),
        // drawer
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              children: [
                // header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Coins',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _white, fontFamily: _dmSans)),
                    GestureDetector(
                      onTap: () => setState(() => _showCoins = false),
                      child: const Icon(Icons.close, color: _grey, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // search
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: _grey, size: 18),
                      const SizedBox(width: 7),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(color: _white, fontSize: 15, fontFamily: _dmSans),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search',
                            hintStyle: TextStyle(color: _grey, fontSize: 15, fontFamily: _dmSans),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // column headers
                const Padding(
                  padding: EdgeInsets.only(bottom: 10, left: 4, right: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('Pair/Vol', style: TextStyle(fontSize: 13, color: _grey, fontFamily: _dmSans))),
                      SizedBox(
                        width: 96,
                        child: Text('Price', style: TextStyle(fontSize: 13, color: _grey, fontFamily: _dmSans), textAlign: TextAlign.right),
                      ),
                      SizedBox(
                        width: 88,
                        child: Text('24h Change', style: TextStyle(fontSize: 13, color: _grey, fontFamily: _dmSans), textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
                // coin list
                Expanded(
                  child: _pairsLoading
                      ? const Center(child: Text('Loading coins...', style: TextStyle(color: _grey, fontFamily: _dmSans)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _buildCoinRow(filtered[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoinRow(_TrapixPair p) {
    final symbol = p.label.split('/').first;
    final quote = p.label.contains('/') ? p.label.split('/').last : 'USDT';
    final live = _getLive(p);
    final price = live?['price'] ?? 0;
    final change = live?['change'] ?? 0;
    final volume = live?['volume'] ?? 0;
    final isPositive = change >= 0;

    return GestureDetector(
      onTap: () {
        _searchCtrl.clear();
        _switchPair(p);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Pair/Vol
            Expanded(
              child: Row(
                children: [
                  p.icon.isNotEmpty
                      ? ClipOval(
                          child: Image.network(p.icon,
                              width: 30, height: 30, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _miniPlaceholder(symbol)))
                      : _miniPlaceholder(symbol),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: symbol,
                                  style: const TextStyle(fontSize: 16, color: Color(0xFFF2F2F2), fontFamily: _dmSans)),
                              TextSpan(text: '/$quote',
                                  style: const TextStyle(fontSize: 16, color: _grey, fontFamily: _dmSans)),
                            ],
                          ),
                        ),
                        Text('\$${_formatVolume(price * volume)}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF777777), fontFamily: _dmSans)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Price
            SizedBox(
              width: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatPrice(price),
                      style: const TextStyle(fontSize: 16, color: _white, fontFamily: _dmSans)),
                  Text('\$${_formatPrice(price)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF777777), fontFamily: _dmSans)),
                ],
              ),
            ),
            // 24h change
            Container(
              width: 85,
              padding: const EdgeInsets.symmetric(vertical: 1),
              decoration: BoxDecoration(
                color: isPositive ? _upGreen : const Color(0xFFE53D43),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _white,
                    height: 1.9,
                    fontFamily: _dmSans),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPlaceholder(String sym) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _green.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          sym.length >= 2 ? sym.substring(0, 2) : sym,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _green, fontFamily: _dmSans),
        ),
      ),
    );
  }
}
