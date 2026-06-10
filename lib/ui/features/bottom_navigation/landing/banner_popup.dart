import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BannerItem {
  final int id;
  final String title;
  final String? imageUrl;
  final String buttonText;
  final String buttonLink;

  BannerItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.buttonText,
    required this.buttonLink,
  });

  factory BannerItem.fromJson(Map<String, dynamic> j) => BannerItem(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        imageUrl: j['image_url'],
        buttonText: j['button_text'] ?? 'Learn More',
        buttonLink: j['button_link'] ?? '',
      );
}

class BannerPopup extends StatefulWidget {
  final VoidCallback? onClose;
  const BannerPopup({super.key, this.onClose});

  // Static cache so banners are only fetched once per app session
  static List<BannerItem>? _cachedBanners;

  @override
  State<BannerPopup> createState() => _BannerPopupState();
}

class _BannerPopupState extends State<BannerPopup> with SingleTickerProviderStateMixin {
  List<BannerItem> _banners = [];
  int _index = 0;
  // _ready = false means loading skeleton, true = real content, null = no banners → close
  bool? _ready;
  bool _animating = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..forward();
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    // Use cached banners if available, otherwise fetch
    if (BannerPopup._cachedBanners != null) {
      if (BannerPopup._cachedBanners!.isNotEmpty) {
        _banners = [BannerPopup._cachedBanners!.first];
        _ready = true;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onClose?.call());
      }
    } else {
      setState(() => _ready = false);
      _fetchBanners();
    }
  }

  Future<void> _fetchBanners() async {
    try {
      final res = await http.get(Uri.parse('https://api.trapix.com/api/banners/active'));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List && (body['data'] as List).isNotEmpty) {
          // Only show the first banner — no multi-swipe
        final items = [(body['data'] as List).map((e) => BannerItem.fromJson(e)).first];
          BannerPopup._cachedBanners = items;
          if (mounted) setState(() { _banners = items; _ready = true; });
          return;
        }
      }
      BannerPopup._cachedBanners = [];
      if (mounted) widget.onClose?.call();
    } catch (_) {
      BannerPopup._cachedBanners = [];
      if (mounted) widget.onClose?.call();
    }
  }

  void _handleClose() {
    if (_animating) return;
    if (_index < _banners.length - 1) {
      setState(() => _animating = true);
      _animCtrl.reverse().then((_) {
        if (mounted) {
          setState(() {
            _index++;
            _animating = false;
          });
          _animCtrl.forward();
        }
      });
    } else {
      _animCtrl.reverse().then((_) => widget.onClose?.call());
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Still loading → show skeleton popup immediately
    if (_ready == false) return _buildSkeleton(context);
    // No banners or null → nothing
    if (_ready == null || _banners.isEmpty) return const SizedBox.shrink();

    final banner = _banners[_index];
    final remaining = _banners.length - _index - 1;
    final screenW = MediaQuery.of(context).size.width;
    final cardW = (screenW - 32).clamp(0.0, 502.0);

    return GestureDetector(
      onTap: _handleClose,
      child: Container(
        color: Colors.black.withOpacity(0.72),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: cardW,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (remaining >= 2)
                        Positioned(
                          top: 12,
                          child: Container(
                            width: cardW - 32,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1a1a1a).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      if (remaining >= 1)
                        Positioned(
                          top: 6,
                          child: Container(
                            width: cardW - 16,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      AnimatedBuilder(
                        animation: _animCtrl,
                        builder: (_, child) => Opacity(
                          opacity: _opacityAnim.value,
                          child: Transform.scale(scale: _scaleAnim.value, child: child),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: cardW,
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, spreadRadius: 4)],
                            ),
                            child: Stack(
                              children: [
                                if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
                                  Image.network(
                                    banner.imageUrl!,
                                    width: cardW,
                                    fit: BoxFit.fitWidth,
                                    errorBuilder: (_, __, ___) => Container(height: 300, color: const Color(0xFF1a1a1a)),
                                  )
                                else
                                  Container(height: 300, color: const Color(0xFF1a1a1a)),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: _handleClose,
                                    child: Container(
                                      width: 34, height: 34,
                                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 18, left: 0, right: 0,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () => widget.onClose?.call(),
                                      child: Container(
                                        width: cardW - 48, height: 44,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Colors.white, Color(0xFFCCFF00)],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(40),
                                        ),
                                        child: Center(
                                          child: Text(banner.buttonText,
                                            style: const TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w700, fontSize: 15)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_banners.length > 1) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (i) {
                        final isActive = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 18 : 6, height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFCCFF00) : Colors.white30,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardW = (screenW - 32).clamp(0.0, 502.0);

    return GestureDetector(
      onTap: _handleClose,
      child: Container(
        color: Colors.black.withOpacity(0.72),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (_, child) => Opacity(
                opacity: _opacityAnim.value,
                child: Transform.scale(scale: _scaleAnim.value, child: child),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: cardW,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, spreadRadius: 4)],
                  ),
                  child: Stack(
                    children: [
                      // Skeleton image area
                      _Shimmer(width: cardW, height: 300),
                      // Close button
                      Positioned(
                        top: 12, right: 12,
                        child: GestureDetector(
                          onTap: () => widget.onClose?.call(),
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      // Skeleton button
                      Positioned(
                        bottom: 18, left: 0, right: 0,
                        child: Center(
                          child: _Shimmer(width: cardW - 48, height: 44, radius: 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final double width, height;
  final double radius;
  const _Shimmer({required this.width, required this.height, this.radius = 0});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [Color(0xFF1a1a1a), Color(0xFF2a2a2a), Color(0xFF1a1a1a)],
          ),
        ),
      ),
    );
  }
}
