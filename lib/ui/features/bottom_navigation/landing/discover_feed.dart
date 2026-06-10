import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/language_util.dart';

const _discoverBase = 'https://api.trapix.com/api/v1/discover';
const _green = Color(0xFFCCFF00);
const _card  = Color(0xFF15181D);
const _dim   = Color(0xFF6B7280);

Map<String, String> _headers() {
  final token = GetStorage().read(PreferenceKey.accessToken) ?? '';
  final type  = GetStorage().read(PreferenceKey.accessType)  ?? 'Bearer';
  return {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    APIKeyConstants.userApiSecret: dotenv.env[EnvKeyValue.kApiSecret] ?? '',
    APIKeyConstants.lang: LanguageUtil.getCurrentKey(),
    if (token.toString().isNotEmpty) APIKeyConstants.authorization: '$type $token',
  };
}

String _timeAgo(String? s) {
  if (s == null || s.isEmpty) return '';
  final iso = s.contains('T') ? s : s.replaceFirst(' ', 'T');
  final d = DateTime.tryParse(iso.endsWith('Z') ? iso : '${iso}Z');
  if (d == null) return '';
  final diff = DateTime.now().toUtc().difference(d);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${d.month}/${d.day}';
}

String _fmt(int n) {
  if (n >= 1000000) return '${(n/1000000).toStringAsFixed(1).replaceAll(RegExp(r"\.0$"),"" )}M';
  if (n >= 1000)    return '${(n/1000).toStringAsFixed(1).replaceAll(RegExp(r"\.0$"),"" )}k';
  return '$n';
}

Future<Map<String, dynamic>?> _apiGet(String url) async {
  try {
    final res = await http.get(Uri.parse(url), headers: _headers());
    if (res.statusCode == 200) return jsonDecode(res.body);
  } catch (_) {}
  return null;
}

Future<Map<String, dynamic>?> _apiPost(String url, Map body) async {
  try {
    final res = await http.post(Uri.parse(url), headers: _headers(), body: jsonEncode(body));
    if (res.statusCode == 200) return jsonDecode(res.body);
  } catch (_) {}
  return null;
}

class DiscoverPost {
  final int id;
  final String authorName;
  final String? authorAvatar;
  final String? authorHandle;
  final bool isVerified;
  final String authorType;
  final String? body;
  final String? image;
  final List<Map<String, String>> tickers;
  int likeCount, commentCount, repostCount, viewCount;
  bool liked;
  final String createdAt;
  final bool isMine;

  DiscoverPost({
    required this.id, required this.authorName, this.authorAvatar, this.authorHandle,
    required this.isVerified, required this.authorType, this.body, this.image,
    required this.tickers, required this.likeCount, required this.commentCount,
    required this.repostCount, required this.viewCount,
    required this.liked, required this.createdAt, required this.isMine,
  });

  factory DiscoverPost.fromJson(Map<String, dynamic> j) => DiscoverPost(
    id: j['id'] ?? 0, authorName: j['author_name'] ?? '',
    authorAvatar: j['author_avatar'], authorHandle: j['author_handle'],
    isVerified: j['is_verified'] == true,
    authorType: j['author_type'] ?? '', body: j['body'], image: j['image'],
    tickers: (j['tickers'] as List? ?? [])
        .map((t) => {'symbol': '${t['symbol']}', 'change': '${t['change']}'}).toList(),
    likeCount: j['like_count'] ?? 0, commentCount: j['comment_count'] ?? 0,
    repostCount: j['repost_count'] ?? 0, viewCount: j['view_count'] ?? 0,
    liked: j['liked'] == true, createdAt: j['created_at'] ?? '', isMine: j['is_mine'] == true,
  );
}

class ArticleItem {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? image;
  final String author;
  final String publishedAt;
  ArticleItem({required this.id, required this.title, required this.slug, this.excerpt, this.image, required this.author, required this.publishedAt});
  factory ArticleItem.fromJson(Map<String, dynamic> j) => ArticleItem(
    id: j['id'] ?? 0, title: j['title'] ?? '', slug: j['slug'] ?? '${j['id']}',
    excerpt: j['excerpt'], image: j['image'], author: j['author'] ?? '', publishedAt: j['published_at'] ?? '',
  );
}

// ─── Main tabbed widget ───────────────────────────────────────────────────────
class DiscoverTabsWidget extends StatefulWidget {
  const DiscoverTabsWidget({super.key});
  @override
  State<DiscoverTabsWidget> createState() => _DiscoverTabsWidgetState();
}

class _DiscoverTabsWidgetState extends State<DiscoverTabsWidget> {
  int _tab = 0;
  final _tabs = ['Discover', 'Blogs', 'News', 'Announcement'];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111111),
      child: Column(children: [
      Container(
        color: const Color(0xFF111111),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final active = i == _tab;
            return GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_tabs[i], style: TextStyle(
                  color: active ? Colors.white : _dim,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                )),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2, width: active ? 24 : 0,
                  decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(1)),
                ),
              ]),
            );
          }),
        ),
      ),
      if (_tab == 0) const DiscoverFeedWidget()
      else if (_tab == 1) const _ArticlesWidget(type: 'blog')
      else if (_tab == 2) const _ArticlesWidget(type: 'news')
      else const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No Announcements', style: TextStyle(color: _dim, fontSize: 13))),
      ),
    ]),
    );
  }
}

// ─── Discover feed ────────────────────────────────────────────────────────────
class DiscoverFeedWidget extends StatefulWidget {
  const DiscoverFeedWidget({super.key});
  @override
  State<DiscoverFeedWidget> createState() => _DiscoverFeedWidgetState();
}

class _DiscoverFeedWidgetState extends State<DiscoverFeedWidget> {
  List<DiscoverPost> _posts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    int page = 1;
    while (true) {
      final res = await _apiGet('$_discoverBase/feed?page=$page&limit=20');
      if (res?['success'] != true) break;
      final data = (res!['data'] as List).map((e) => DiscoverPost.fromJson(e)).toList();
      if (!mounted) break;
      final existing = _posts.map((p) => p.id).toSet();
      final fresh = data.where((p) => !existing.contains(p.id)).toList();
      setState(() { _posts.addAll(fresh); _loading = false; });
      if (data.length < 20) break;
      page++;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toggleLike(DiscoverPost post) {
    final tok = (GetStorage().read(PreferenceKey.accessToken) ?? '').toString();
    if (tok.isEmpty) return;
    setState(() { post.liked = !post.liked; post.likeCount += post.liked ? 1 : -1; });
    _apiPost('$_discoverBase/like', {'post_id': post.id});
  }

  void _openComments(DiscoverPost post) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: _card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _CommentsSheet(post: post),
  );

  void _openComposer() {
    final tok = (GetStorage().read(PreferenceKey.accessToken) ?? '').toString();
    if (tok.isEmpty) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ComposerSheet(onPosted: (p) => setState(() => _posts.insert(0, p))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_posts.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('No posts yet.', style: TextStyle(color: _dim, fontSize: 13))));
    return Column(children: [
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _posts.length,
        itemBuilder: (ctx, i) => _PostCard(
          post: _posts[i],
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiscoverPostScreen(postId: _posts[i].id, post: _posts[i]))),
          onLike: () => _toggleLike(_posts[i]),
          onComment: () => _openComments(_posts[i]),
          onDelete: () {
            _apiPost('$_discoverBase/delete', {'post_id': _posts[i].id});
            setState(() => _posts.removeAt(i));
          },
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, top: 8, bottom: 16),
          child: GestureDetector(
            onTap: _openComposer,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _green, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _green.withOpacity(0.4), blurRadius: 16, spreadRadius: 2)],
              ),
              child: const Icon(Icons.add, color: Color(0xFF0A0C0F), size: 28),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─── Articles ─────────────────────────────────────────────────────────────────
class _ArticlesWidget extends StatefulWidget {
  final String type;
  const _ArticlesWidget({required this.type});
  @override
  State<_ArticlesWidget> createState() => _ArticlesWidgetState();
}

class _ArticlesWidgetState extends State<_ArticlesWidget> {
  List<ArticleItem> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    int page = 1;
    while (true) {
      final res = await _apiGet('$_discoverBase/articles?type=${widget.type}&page=$page&limit=20');
      if (res?['success'] != true) break;
      final data = (res!['data'] as List).map((e) => ArticleItem.fromJson(e)).toList();
      if (!mounted) break;
      setState(() { _items.addAll(data); _loading = false; });
      if (data.length < 20) break;
      page++;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('Nothing here yet.', style: TextStyle(color: _dim, fontSize: 13))));
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final a = _items[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleScreen(slug: a.slug))),
          child: Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1C1F26)))),
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (a.image != null && a.image!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(a.image!, width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                Text(a.author, style: const TextStyle(color: _dim, fontSize: 12)),
                const SizedBox(width: 8),
                Text(_timeAgo(a.publishedAt), style: const TextStyle(color: _dim, fontSize: 12)),
              ]),
            ])),
          ]),
        ));
      },
    );
  }
}

// ─── Post card ────────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final DiscoverPost post;
  final VoidCallback onLike, onComment, onDelete;
  final VoidCallback? onTap;
  const _PostCard({required this.post, required this.onLike, required this.onComment, required this.onDelete, this.onTap});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final body = p.body ?? '';
    final long = body.length > 180;
    final shown = _expanded || !long ? body : '${body.substring(0, 180)}...';
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1C1F26)))),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _AvatarWidget(src: p.authorAvatar, name: p.authorName, brand: p.authorType == 'admin'),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(p.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14), overflow: TextOverflow.ellipsis)),
            if (p.isVerified) Container(
              width: 14, height: 14, margin: const EdgeInsets.only(left: 4),
              decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 9),
            ),
            const SizedBox(width: 4),
            Text('· ${_timeAgo(p.createdAt)}', style: const TextStyle(color: _dim, fontSize: 12)),
            if (p.isMine) GestureDetector(
              onTap: widget.onDelete,
              child: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.delete_outline, color: Color(0xFFEA3943), size: 16)),
            ),
          ]),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(shown, style: const TextStyle(color: Color(0xFFE6E8EC), fontSize: 13.5, height: 1.5)),
            if (long && !_expanded) GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: const Text('View More', style: TextStyle(color: _green, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
          if (p.image != null && p.image!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(p.image!, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ],
          if (p.tickers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 16, children: p.tickers.map((t) {
              final green = (t['change'] ?? '').startsWith('+');
              return RichText(text: TextSpan(children: [
                TextSpan(text: '${t['symbol']} ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                TextSpan(text: t['change'], style: TextStyle(color: green ? const Color(0xFF16C784) : const Color(0xFFEA3943), fontWeight: FontWeight.w700, fontSize: 12.5)),
              ]));
            }).toList()),
          ],
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _EngBtn(icon: Icons.chat_bubble_outline, count: p.commentCount, onTap: widget.onComment),
            _EngBtn(icon: Icons.repeat, count: p.repostCount, onTap: () {}),
            _EngBtn(icon: p.liked ? Icons.favorite : Icons.favorite_border, count: p.likeCount, color: p.liked ? const Color(0xFFEA3943) : null, onTap: widget.onLike),
            _EngBtn(icon: Icons.bar_chart, count: p.viewCount, onTap: () {}),
            const Row(children: [
              Icon(Icons.bookmark_border, color: _dim, size: 16),
              SizedBox(width: 14),
              Icon(Icons.ios_share, color: _dim, size: 16),
            ]),
          ]),
        ])),
      ]),
    ));
  }
}

class _EngBtn extends StatelessWidget {
  final IconData icon; final int count; final Color? color; final VoidCallback onTap;
  const _EngBtn({required this.icon, required this.count, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(children: [
      Icon(icon, color: color ?? _dim, size: 16),
      const SizedBox(width: 4),
      Text(_fmt(count), style: TextStyle(color: color ?? _dim, fontSize: 12.5)),
    ]),
  );
}

class _AvatarWidget extends StatefulWidget {
  final String? src; final String name; final bool brand;
  const _AvatarWidget({this.src, required this.name, required this.brand});
  @override
  State<_AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<_AvatarWidget> {
  bool _err = false;
  @override
  Widget build(BuildContext context) {
    if (widget.brand && (widget.src == null || widget.src!.isEmpty)) {
      return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0E1117), border: Border.all(color: const Color(0xFF232A36))),
        child: const Icon(Icons.account_circle, color: _green, size: 28),
      );
    }
    if (widget.src != null && widget.src!.isNotEmpty && !_err) {
      return ClipOval(child: Image.network(widget.src!, width: 40, height: 40, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _err = true); });
          return _fallback();
        }));
    }
    return _fallback();
  }
  Widget _fallback() => Container(
    width: 40, height: 40,
    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF2A3340), Color(0xFF3A4452)])),
    child: Center(child: Text((widget.name.isEmpty ? 'T' : widget.name[0]).toUpperCase(),
      style: const TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 15))),
  );
}

// ─── Comments sheet ───────────────────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final DiscoverPost post;
  const _CommentsSheet({required this.post});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<dynamic> _comments = [];
  final _ctrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    _apiGet('$_discoverBase/comments?post_id=${widget.post.id}').then((res) {
      if (res?['success'] == true && mounted) setState(() => _comments = res!['data'] ?? []);
    });
  }
  void _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    final res = await _apiPost('$_discoverBase/comment', {'post_id': widget.post.id, 'body': _ctrl.text.trim()});
    if (res?['success'] == true && mounted) { setState(() => _comments.insert(0, res!['data'])); _ctrl.clear(); }
  }
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
    builder: (_, sc) => Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF232A36)))),
        child: Row(children: [
          const Text('Comments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: _dim)),
        ]),
      ),
      Expanded(child: _comments.isEmpty
        ? const Center(child: Text('Be the first to comment.', style: TextStyle(color: _dim, fontSize: 13)))
        : ListView.builder(controller: sc, itemCount: _comments.length, itemBuilder: (_, i) {
            final c = _comments[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1C1F26)))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _AvatarWidget(src: c['author_avatar'], name: c['author_name'] ?? '', brand: false),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['author_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(c['body'] ?? '', style: const TextStyle(color: Color(0xFFCBD0D8), fontSize: 13)),
                ])),
              ]),
            );
          })),
      Container(
        padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF232A36)))),
        child: Row(children: [
          Expanded(child: TextField(controller: _ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Add a comment...', hintStyle: const TextStyle(color: _dim, fontSize: 13),
              filled: true, fillColor: const Color(0xFF0E1117),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF232A36))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF232A36))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _green)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ))),
          const SizedBox(width: 8),
          GestureDetector(onTap: _submit, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(20)),
            child: const Text('Send', style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w700, fontSize: 13)),
          )),
        ]),
      ),
    ]),
  );
}

// ─── Discover post detail screen ─────────────────────────────────────────────
class DiscoverPostScreen extends StatefulWidget {
  final int postId;
  final DiscoverPost? post;
  const DiscoverPostScreen({super.key, required this.postId, this.post});
  @override
  State<DiscoverPostScreen> createState() => _DiscoverPostScreenState();
}

class _DiscoverPostScreenState extends State<DiscoverPostScreen> {
  DiscoverPost? _post;
  List<dynamic> _comments = [];
  bool _loading = true;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loading = widget.post == null;
    _load();
  }

  Future<void> _load() async {
    final res = await _apiGet('$_discoverBase/post/${widget.postId}');
    if (res?['success'] == true && mounted) {
      setState(() { _post = DiscoverPost.fromJson(res!['data']); _loading = false; });
    } else if (mounted) setState(() => _loading = false);
    final cr = await _apiGet('$_discoverBase/comments?post_id=${widget.postId}');
    if (cr?['success'] == true && mounted) setState(() => _comments = cr!['data'] ?? []);
  }

  void _toggleLike() {
    if (_post == null) return;
    final tok = (GetStorage().read(PreferenceKey.accessToken) ?? '').toString();
    if (tok.isEmpty) return;
    setState(() { _post!.liked = !_post!.liked; _post!.likeCount += _post!.liked ? 1 : -1; });
    _apiPost('$_discoverBase/like', {'post_id': _post!.id});
  }

  void _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    final res = await _apiPost('$_discoverBase/comment', {'post_id': widget.postId, 'body': _ctrl.text.trim()});
    if (res?['success'] == true && mounted) {
      setState(() { _comments.insert(0, res!['data']); _post?.commentCount += 1; });
      _ctrl.clear();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C0F),
      body: SafeArea(
        child: Column(children: [
          // header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1C1F26)))),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: const Row(children: [
                  Icon(Icons.chevron_left, color: Color(0xFFCFD4DC), size: 24),
                  Text('Post', style: TextStyle(color: Color(0xFFCFD4DC), fontSize: 15, fontWeight: FontWeight.w600)),
                ])),
            ]),
          ),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _green, strokeWidth: 2))
            : _post == null
              ? const Center(child: Text('Post not found.', style: TextStyle(color: _dim)))
              : _buildContent()),
          // comment composer
          Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF232A36)))),
            child: Row(children: [
              Expanded(child: TextField(controller: _ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Add a comment...', hintStyle: const TextStyle(color: _dim, fontSize: 13),
                  filled: true, fillColor: const Color(0xFF161B22),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF232A36))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF232A36))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _green)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                ))),
              const SizedBox(width: 8),
              GestureDetector(onTap: _submit, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(20)),
                child: const Text('Send', style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w700, fontSize: 13)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    final p = _post!;
    return ListView(padding: EdgeInsets.zero, children: [
      // post body
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _AvatarWidget(src: p.authorAvatar, name: p.authorName, brand: p.authorType == 'admin'),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(p.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis)),
                if (p.isVerified) Container(
                  width: 14, height: 14, margin: const EdgeInsets.only(left: 4),
                  decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 9),
                ),
              ]),
              if (p.authorHandle != null && p.authorHandle!.isNotEmpty)
                Text('@${p.authorHandle}', style: const TextStyle(color: _dim, fontSize: 12)),
            ])),
          ]),
          if (p.body != null && p.body!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p.body!, style: const TextStyle(color: Color(0xFFE6E8EC), fontSize: 16, height: 1.55)),
          ],
          if (p.image != null && p.image!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(p.image!, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ],
          if (p.tickers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 16, children: p.tickers.map((t) {
              final green = (t['change'] ?? '').startsWith('+');
              return RichText(text: TextSpan(children: [
                TextSpan(text: '${t['symbol']} ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                TextSpan(text: t['change'], style: TextStyle(color: green ? const Color(0xFF16C784) : const Color(0xFFEA3943), fontWeight: FontWeight.w700, fontSize: 13)),
              ]));
            }).toList()),
          ],
          const SizedBox(height: 14),
          Text('${_timeAgo(p.createdAt)} · ${_fmt(p.viewCount)} views', style: const TextStyle(color: _dim, fontSize: 12.5)),
          const SizedBox(height: 14),
          Row(children: [
            _EngBtn(icon: Icons.chat_bubble_outline, count: p.commentCount, onTap: () {}),
            const SizedBox(width: 20),
            _EngBtn(icon: Icons.repeat, count: p.repostCount, onTap: () {}),
            const SizedBox(width: 20),
            _EngBtn(icon: p.liked ? Icons.favorite : Icons.favorite_border, count: p.likeCount, color: p.liked ? const Color(0xFFEA3943) : null, onTap: _toggleLike),
            const SizedBox(width: 20),
            _EngBtn(icon: Icons.bar_chart, count: p.viewCount, onTap: () {}),
          ]),
        ]),
      ),
      const Divider(color: Color(0xFF1C1F26), height: 1),
      // comments section
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Text('Comments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
      if (_comments.isEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text('No comments yet. Be the first.', style: TextStyle(color: _dim, fontSize: 13)),
        )
      else
        ..._comments.map((c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1C1F26)))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _AvatarWidget(src: c['author_avatar'], name: c['author_name'] ?? '', brand: false),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['author_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(c['body'] ?? '', style: const TextStyle(color: Color(0xFFCBD0D8), fontSize: 13)),
            ])),
          ]),
        )).toList(),
    ]);
  }
}

// ─── Article detail screen ────────────────────────────────────────────────────
class ArticleScreen extends StatefulWidget {
  final String slug;
  const ArticleScreen({super.key, required this.slug});
  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  Map<String, dynamic>? _article;
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await _apiGet('$_discoverBase/article/${widget.slug}');
    if (res?['success'] == true && mounted) {
      setState(() { _article = res!['data']; _loading = false; });
    } else if (mounted) setState(() { _loading = false; _notFound = true; });
  }

  String _fmt(String? s) {
    if (s == null || s.isEmpty) return '';
    try {
      final iso = s.contains('T') ? s : s.replaceFirst(' ', 'T');
      final d = DateTime.parse(iso.endsWith('Z') || iso.contains('+') ? iso : '${iso}Z');
      return '${_monthName(d.month)} ${d.day}, ${d.year}';
    } catch (_) { return s; }
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C0F),
      body: SafeArea(child: Column(children: [
        // back header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(color: Color(0xFF0A0C0F), border: Border(bottom: BorderSide(color: Color(0xFF1C1F26)))),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context),
              child: const Row(children: [
                Icon(Icons.chevron_left, color: Color(0xFFCFD4DC), size: 24),
                Text('Back', style: TextStyle(color: Color(0xFFCFD4DC), fontSize: 15, fontWeight: FontWeight.w600)),
              ])),
          ]),
        ),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _green, strokeWidth: 2))
          : _notFound || _article == null
            ? const Center(child: Text('Article not found.', style: TextStyle(color: _dim)))
            : _buildArticle()),
      ])),
    );
  }

  Widget _buildArticle() {
    final a = _article!;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 32), children: [
      // type chip
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(5)),
        child: Text((a['type'] == 'blog' ? 'BLOG' : 'NEWS'),
          style: const TextStyle(color: Color(0xFF0A0C0F), fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
      ).let((w) => Align(alignment: Alignment.centerLeft, child: w)),
      const SizedBox(height: 12),
      // title
      Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, height: 1.28)),
      const SizedBox(height: 14),
      // author row
      Row(children: [
        Container(
          width: 34, height: 34,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF11151B)),
          child: const Icon(Icons.currency_exchange, color: _green, size: 18),
        ),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Trapix Exchange', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(width: 5),
            Container(
              width: 14, height: 14,
              decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 9),
            ),
          ]),
          Text(_fmt(a['published_at']), style: const TextStyle(color: _dim, fontSize: 11.5)),
        ])),
      ]),
      const SizedBox(height: 18),
      // image
      if (a['image'] != null && (a['image'] as String).isNotEmpty) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(a['image'], width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
        ),
        const SizedBox(height: 18),
      ],
      // body
      Text(a['body'] ?? a['excerpt'] ?? '', style: const TextStyle(color: Color(0xFFD4D9E0), fontSize: 15.5, height: 1.7)),
      // source link
      if (a['source_url'] != null && (a['source_url'] as String).isNotEmpty) ...[
        const SizedBox(height: 26),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(10)),
            child: const Text('Read the full story →', style: TextStyle(color: Color(0xFF0A0C0F), fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      ],
      const SizedBox(height: 30),
      const Divider(color: Color(0xFF16191F)),
      const SizedBox(height: 12),
      const Text('Curated by Trapix Exchange · Crypto news & insights', style: TextStyle(color: _dim, fontSize: 12)),
    ]);
  }
}

extension _WidgetLet on Widget {
  Widget let(Widget Function(Widget) fn) => fn(this);
}

// ─── Composer sheet ───────────────────────────────────────────────────────────
class _ComposerSheet extends StatefulWidget {
  final void Function(DiscoverPost) onPosted;
  const _ComposerSheet({required this.onPosted});
  @override
  State<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<_ComposerSheet> {
  final _ctrl = TextEditingController();
  XFile? _image;
  bool _posting = false;

  void _submit() async {
    if (_ctrl.text.trim().isEmpty && _image == null) return;
    setState(() => _posting = true);
    try {
      final uri = Uri.parse('$_discoverBase/post');
      final request = http.MultipartRequest('POST', uri);
      final h = _headers()..remove('Content-Type');
      request.headers.addAll(h);
      request.fields['body'] = _ctrl.text.trim();
      if (_image != null) request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      final res = jsonDecode(await (await request.send()).stream.bytesToString());
      if (res['success'] == true && mounted) { widget.onPosted(DiscoverPost.fromJson(res['data'])); Navigator.pop(context); }
    } catch (_) {}
    if (mounted) setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        GestureDetector(onTap: () => Navigator.pop(context), child: const Text('x', style: TextStyle(color: Colors.white, fontSize: 24))),
        const Spacer(),
        const Text('New Post', style: TextStyle(color: _dim, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 14),
      TextField(controller: _ctrl, autofocus: true, maxLines: 5,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(hintText: "What's happening?", hintStyle: TextStyle(color: _dim), border: InputBorder.none)),
      if (_image != null) ...[
        const SizedBox(height: 10),
        Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(_image!.path), width: double.infinity, height: 200, fit: BoxFit.cover)),
          Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => setState(() => _image = null),
            child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
        ]),
      ],
      const Divider(color: Color(0xFF232A36)),
      Row(children: [
        GestureDetector(
          onTap: () async { final p = await ImagePicker().pickImage(source: ImageSource.gallery); if (p != null) setState(() => _image = p); },
          child: const Row(children: [Icon(Icons.image_outlined, color: _green, size: 22), SizedBox(width: 6), Text('Photo', style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600))])),
        const Spacer(),
        GestureDetector(onTap: _posting ? null : _submit, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 9),
          decoration: BoxDecoration(color: _posting ? _green.withOpacity(0.5) : _green, borderRadius: BorderRadius.circular(22)),
          child: Text(_posting ? 'Posting...' : 'Post', style: const TextStyle(color: Color(0xFF0A0C0F), fontWeight: FontWeight.w800, fontSize: 14)),
        )),
      ]),
    ])),
  );
}
