import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _kGold = Color(0xFFB8960C);
const _kGreen = Color(0xFFCCFF00);
const _kBg = Color(0xFF0A1A0A);

class McCertificateScreen extends StatelessWidget {
  final Map<String, dynamic> stake;
  const McCertificateScreen({super.key, required this.stake});

  String get _certNo => stake['cert_no'] ?? 'TRPX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  String get _planName => stake['plan_name'] ?? '—';
  String get _symbol => stake['coin_symbol'] ?? '';
  String get _amount => stake['amount']?.toString() ?? '0';
  String get _dailyRate => stake['daily_rate']?.toString() ?? '0';
  String get _totalReturn => stake['total_return']?.toString() ?? '';
  int get _durationDays => stake['duration_days'] ?? 0;
  String get _startDate => stake['start_date'] ?? '';
  String get _endDate => stake['end_date'] ?? '';
  int get _planType => stake['plan_type'] ?? 1;
  String get _userName => stake['user_name'] ?? 'Valued Staker';

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month-1]} ${dt.year}';
    } catch (_) { return d; }
  }

  String get _stakingType => _planType == 1 ? 'Flexible' : _planType == 2 ? 'Locked Staking' : 'Long-Term';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text('Staking Certificate', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _certNo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Certificate number copied'), backgroundColor: Color(0xFF1A1A1A)),
                      );
                    },
                    child: const Icon(Icons.copy, color: Color(0xFFCCFF00), size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A1A0A), Color(0xFF0D2010), Color(0xFF091505), Color(0xFF0A1A0A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kGold, width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      // Corner decorations
                      ..._corners(),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Logo + brand
                            _dividerRow(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF152010),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _kGold.withValues(alpha: 0.5)),
                                  ),
                                  child: const Center(child: Text('T', style: TextStyle(color: _kGreen, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'DMSans'))),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('TRAPIX', style: TextStyle(color: _kGreen, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'DMSans', letterSpacing: 3)),
                                    Text('EXCHANGE', style: TextStyle(color: _kGold, fontSize: 9, letterSpacing: 4, fontFamily: 'DMSans')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _dividerRow(),
                            const SizedBox(height: 16),

                            // Title
                            Text('DIGITAL STAKING CERTIFICATE', style: TextStyle(color: _kGold, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'DMSans')),
                            const SizedBox(height: 4),
                            Text('★ CERTIFICATE OF DIGITAL STAKING PARTICIPATION ★', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8, letterSpacing: 1.5, fontFamily: 'DMSans')),
                            const SizedBox(height: 8),
                            Text('This certificate is proudly presented to', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontFamily: 'DMSans')),
                            const SizedBox(height: 4),
                            Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontFamily: 'DMSans')),
                            const SizedBox(height: 4),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontFamily: 'DMSans'),
                                children: [
                                  const TextSpan(text: 'for successfully participating in the '),
                                  TextSpan(text: _planName, style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
                                  const TextSpan(text: ' staking program.'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                            Container(height: 1, color: _kGold.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),

                            // Details section
                            _sectionTitle('🌸  Certificate Details  🌸'),
                            const SizedBox(height: 10),
                            _detailRow('Certificate No.', _certNo, _kGold),
                            _detailRow('Asset', _symbol, Colors.white),
                            _detailRow('Staking Product', _planName, Colors.white),
                            _detailRow('Staked Amount', '${double.tryParse(_amount)?.toStringAsFixed(2) ?? _amount} $_symbol', _kGreen),
                            _detailRow('Daily Reward Rate', '${double.tryParse(_dailyRate)?.toStringAsFixed(4) ?? _dailyRate}% / Day', _kGold),
                            if (_totalReturn.isNotEmpty && _totalReturn != 'null')
                              _detailRow('Total Return', '$_totalReturn%', _kGold),
                            _detailRow('Subscription Type', _stakingType, Colors.white),

                            const SizedBox(height: 16),
                            _sectionTitle('📅  Important Dates'),
                            const SizedBox(height: 10),
                            if (_startDate.isNotEmpty) _detailRow('Start Date', _fmtDate(_startDate), Colors.white),
                            if (_durationDays > 0) _detailRow('Duration', '$_durationDays Days', Colors.white),
                            if (_endDate.isNotEmpty) _detailRow('Maturity Date', _fmtDate(_endDate), Colors.white),
                            _detailRow('Status', '● Active', const Color(0xFF00B052)),

                            const SizedBox(height: 16),
                            _sectionTitle('🛡  Verification Details'),
                            const SizedBox(height: 10),
                            _detailRow('Exchange', 'Trapix Exchange', Colors.white),
                            _detailRow('Certificate Type', 'Digital Subscription', Colors.white),
                            if (_startDate.isNotEmpty) _detailRow('Issued On', _fmtDate(_startDate), Colors.white),
                            _detailRow('Issued By', 'Trapix Exchange', _kGold),
                            _detailRow('Verification Status', '✓ Valid', _kGreen),

                            const SizedBox(height: 20),
                            Container(height: 1, color: _kGold.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),

                            // Declaration
                            Text(
                              'This certificate acknowledges the holder\'s enrollment in the designated Trapix staking plan and serves as an official record of participation. All rewards and benefits remain subject to the applicable Trapix Exchange terms and operational policies.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9, height: 1.6, fontFamily: 'DMSans'),
                            ),

                            const SizedBox(height: 16),
                            Container(height: 1, color: _kGold.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),

                            // Footer
                            const Text('TRAPIX EXCHANGE', style: TextStyle(color: _kGold, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 4, fontFamily: 'DMSans')),
                            const SizedBox(height: 4),
                            Text('TRADE RESPONSIBLY · STAKE SECURELY · GROW WITH TRAPIX', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 7, letterSpacing: 1.5, fontFamily: 'DMSans')),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _dividerRow() => Row(
    children: [
      Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _kGold])))),
      const SizedBox(width: 8),
      Container(width: 6, height: 6, decoration: BoxDecoration(color: _kGold, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [_kGold, Colors.transparent])))),
    ],
  );

  Widget _sectionTitle(String t) => Row(
    children: [
      Expanded(child: Container(height: 1, color: _kGold.withValues(alpha: 0.2))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(t, style: TextStyle(color: _kGold, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontFamily: 'DMSans')),
      ),
      Expanded(child: Container(height: 1, color: _kGold.withValues(alpha: 0.2))),
    ],
  );

  Widget _detailRow(String label, String value, Color valueColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, fontFamily: 'DMSans')),
        Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
      ],
    ),
  );

  List<Widget> _corners() {
    const s = 20.0;
    const t = 2.0;
    return [
      Positioned(top: 0, left: 0, child: _corner(top: true, left: true, s: s, t: t)),
      Positioned(top: 0, right: 0, child: _corner(top: true, left: false, s: s, t: t)),
      Positioned(bottom: 0, left: 0, child: _corner(top: false, left: true, s: s, t: t)),
      Positioned(bottom: 0, right: 0, child: _corner(top: false, left: false, s: s, t: t)),
    ];
  }

  Widget _corner({required bool top, required bool left, required double s, required double t}) =>
      SizedBox(
        width: s, height: s,
        child: CustomPaint(
          painter: _CornerPainter(top: top, left: left, color: _kGold, thickness: t),
        ),
      );
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  final Color color;
  final double thickness;
  _CornerPainter({required this.top, required this.left, required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thickness..style = PaintingStyle.stroke;
    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height); path.lineTo(0, 0); path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0); path.lineTo(size.width, 0); path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
