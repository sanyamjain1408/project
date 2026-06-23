import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/faq.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'faq_controller.dart';

const _bg   = Color(0xFF111111);
const _white = Colors.white;
const _grey  = Color(0xFF8A8A8A);
const _green = Color(0xFFCCFF00);
const _font  = 'DMSans';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  FAQPageState createState() => FAQPageState();
}

class FAQPageState extends State<FAQPage> {
  final FAQController _controller = Get.put(FAQController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getFAQList(false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.arrow_back, color: _white, size: 22),
          ),
        ),
        leadingWidth: 48,
        title: const Text(
          'FAQ',
          style: TextStyle(
            color: _white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: _font,
          ),
        ),
      ),
      body: Obx(() {
        if (_controller.faqList.isEmpty) {
          return handleEmptyViewWithLoading(_controller.isLoading);
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 40),
          itemCount: _controller.faqList.length,
          itemBuilder: (context, index) {
            if (_controller.hasMoreData && index == (_controller.faqList.length - 1)) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _controller.getFAQList(true));
            }
            return FAQItemView(faq: _controller.faqList[index]);
          },
        );
      }),
    );
  }
}

// Hardcoded FAQs shown when API returns empty list
const _depositFaqs = [
  {'q': 'What is the minimum deposit amount?', 'a': 'The minimum deposit amount varies by coin and network. Please check the network details on the deposit page for the exact minimum.'},
  {'q': 'How long does it take for a deposit to be credited?', 'a': 'Most deposits are credited within 10–30 minutes depending on blockchain confirmations. Some networks may take longer during high traffic.'},
  {'q': "Why hasn't my deposit arrived yet?", 'a': 'If your deposit has not arrived, please check the transaction status on the blockchain explorer. You can also use the "Check Deposit" feature to verify manually.'},
  {'q': 'Do I need a memo for my deposit?', 'a': 'Some coins (e.g. XRP, XLM) require a memo/tag in addition to the wallet address. Sending without a memo may result in loss of funds.'},
];

const _withdrawFaqs = [
  {'q': 'What is the minimum withdrawal amount?', 'a': 'The minimum withdrawal amount varies by coin and network. Please check the network details before submitting a withdrawal.'},
  {'q': 'How long does a withdrawal take?', 'a': 'Most withdrawals are processed within 30 minutes. Processing time depends on the blockchain network and current traffic.'},
  {'q': 'Why is my withdrawal pending?', 'a': 'Withdrawals may be pending due to manual review, network congestion, or security checks. Contact support if it stays pending for more than 24 hours.'},
  {'q': 'What are the withdrawal fees?', 'a': 'Network fees are shown on the withdrawal page before you confirm. Fees vary by coin and selected network.'},
];

class FAQRelatedView extends StatelessWidget {
  const FAQRelatedView(this.faqList, {super.key, this.type = 'deposit'});

  final List<FAQ> faqList;
  final String type;

  @override
  Widget build(BuildContext context) {
    final fallback = type == 'withdraw' ? _withdrawFaqs : _depositFaqs;
    final items = faqList.isNotEmpty
        ? faqList.map((f) => FAQItemView(faq: f, margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin))).toList()
        : fallback.map((f) => FAQItemView(
              faq: FAQ()
                ..question = f['q']
                ..answer = f['a'],
              margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
            )).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        vSpacer20(),
        const Text(
          'FAQ',
          style: TextStyle(
            color: _white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: _font,
            height: 24 / 16,
          ),
        ),
        vSpacer10(),
        ...items,
      ],
    );
  }
}

class FAQItemView extends StatefulWidget {
  const FAQItemView({super.key, required this.faq, this.margin});

  final FAQ faq;
  final EdgeInsets? margin;

  @override
  State<FAQItemView> createState() => _FAQItemViewState();
}

class _FAQItemViewState extends State<FAQItemView> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _rotate = Tween<double>(begin: 0, end: 0.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question ?? '',
                      style: TextStyle(
                        color: _expanded ? _green : _white,
                        fontSize: 12,
                        fontFamily: _font,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotate,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _expanded ? _green : _grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 12),
                  Text(
                    widget.faq.answer ?? '',
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontFamily: _font,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
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
