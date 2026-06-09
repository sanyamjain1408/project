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

  @override
  State<BannerPopup> createState() => _BannerPopupState();
}

class _BannerPopupState extends State<BannerPopup> with SingleTickerProviderStateMixin {
  List<BannerItem> _banners = [];
  int _index = 0;
  bool _ready = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))
      ..forward();
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      final res = await http.get(Uri.parse('https://api.trapix.com/api/banners/active'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List && (body['data'] as List).isNotEmpty) {
          final banners = (body['data'] as List).map((e) => BannerItem.fromJson(e)).toList();
          // preload all images before showing popup
          await _preloadAll(banners);
          if (mounted) setState(() { _banners = banners; _ready = true; });
        }
      }
    } catch (_) {}
  }

  Future<void> _preloadAll(List<BannerItem> banners) async {
    for (final b in banners) {
      if (b.imageUrl != null && b.imageUrl!.isNotEmpty) {
        try {
          await precacheImage(NetworkImage(b.imageUrl!), context);
        } catch (_) {}
      }
    }
  }

  void _handleClose() {
    if (_index < _banners.length - 1) {
      _animCtrl.reverse().then((_) {
        if (mounted) {
          setState(() => _index++);
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
    if (!_ready || _banners.isEmpty) return const SizedBox.shrink();

    final banner = _banners[_index];
    final remaining = _banners.length - _index - 1;
    final screenW = MediaQuery.of(context).size.width;
    final cardW = (screenW - 32).clamp(0.0, 340.0);
    final btnW = cardW - 48;

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
                    alignment: Alignment.topCenter,
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
                                  Image(
                                    image: NetworkImage(banner.imageUrl!),
                                    width: cardW,
                                    fit: BoxFit.fitWidth,
                                    frameBuilder: (ctx, child, frame, _) => child,
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
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.45),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 18,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () => widget.onClose?.call(),
                                      child: Container(
                                        width: btnW,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Colors.white, Color(0xFFCCFF00)],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(40),
                                        ),
                                        child: Center(
                                          child: Text(
                                            banner.buttonText,
                                            style: const TextStyle(
                                              color: Color(0xFF111111),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
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
                          width: isActive ? 18 : 6,
                          height: 6,
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
}
