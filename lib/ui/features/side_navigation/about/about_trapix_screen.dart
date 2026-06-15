import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _white = Colors.white;
const _grey = Color(0xFF8A8A8A);
const _green = Color(0xFFCCFF00);
const _font = 'DMSans';

// ── Content model ─────────────────────────────────────────────────────────────

abstract class _Block {}

class _SubtitleBlock extends _Block {
  final String text;
  _SubtitleBlock(this.text);
}

class _HeadingBlock extends _Block {
  final String text;
  _HeadingBlock(this.text);
}

class _ParaBlock extends _Block {
  final String text;
  _ParaBlock(this.text);
}

class _BulletBlock extends _Block {
  final List<String> items;
  _BulletBlock(this.items);
}

// ── Policy data ───────────────────────────────────────────────────────────────

final _terms = <_Block>[
  _SubtitleBlock('Our terms of service and conditions of use'),
  _HeadingBlock('1. Agreement to Terms'),
  _ParaBlock(
      'By accessing or using Trapix Exchange website, mobile application, or services, you agree to be bound by these Terms of Use, Privacy Policy, AML/KYC Policy, and any additional rules published by Trapix Exchange.'),
  _ParaBlock('If you do not agree with these terms, you must not use the Trapix platform.'),
  _HeadingBlock('2. Eligibility'),
  _BulletBlock([
    'You must be at least 18 years old',
    'You must comply with all applicable laws in your jurisdiction',
    'You must complete KYC verification when required',
    'Users from restricted jurisdictions may not access certain services.',
  ]),
  _HeadingBlock('3. Account Registration'),
  _BulletBlock([
    'You must create an account with valid information',
    'You are responsible for keeping your login credentials secure',
    'You must not share your account with other people',
    'Trapix Exchange may suspend accounts that violate these rules.',
  ]),
  _HeadingBlock('4. Services Provided'),
  _BulletBlock(['Spot trading', 'Futures trading', 'Token listing', 'Copy trading', 'Airdrop campaigns', 'Wallet services']),
  _ParaBlock('The platform acts as an intermediary for digital asset trading services.'),
  _HeadingBlock('5. Trading Risk Disclosure'),
  _ParaBlock('Cryptocurrency trading involves significant risk.'),
  _BulletBlock([
    'Prices may fluctuate rapidly',
    'Users may lose part or all of their funds',
    'Trapix Exchange does not provide financial advice',
  ]),
  _HeadingBlock('6. User Responsibilities'),
  _BulletBlock([
    'Do not engage in illegal activities',
    'Do not manipulate markets',
    'Do not use stolen funds',
    'Do not attempt to hack or damage the platform',
  ]),
  _HeadingBlock('7. AML & KYC Compliance'),
  _ParaBlock(
      'Trapix Exchange complies with Anti-Money Laundering (AML) regulations and Counter-Terrorism Financing rules. Users may be required to submit identification documents for verification.'),
  _HeadingBlock('8. Fees'),
  _BulletBlock(['Trading fees', 'Withdrawal fees', 'Listing fees']),
  _ParaBlock('All applicable fees will be displayed on the platform before transactions.'),
  _HeadingBlock('9. Limitation of Liability'),
  _BulletBlock(['Market losses caused by trading', 'Blockchain network delays', 'Third-party service interruptions']),
  _ParaBlock('Users accept that digital asset markets are volatile.'),
  _HeadingBlock('10. Platform Updates'),
  _ParaBlock('Trapix Exchange may modify these Terms at any time. Continued use of the platform means you accept the new terms.'),
  _HeadingBlock('11. Account Suspension'),
  _BulletBlock(['Freeze accounts suspected of fraud', 'Suspend users violating policies', 'Block accounts under legal investigation']),
  _HeadingBlock('12. Intellectual Property'),
  _BulletBlock(['logos', 'UI design', 'software']),
  _ParaBlock('All platform content are property of Trapix Exchange and may not be copied without permission.'),
  _HeadingBlock('13. Termination'),
  _ParaBlock('Users may close their account anytime. Trapix Exchange may terminate accounts that violate these Terms.'),
  _HeadingBlock('14. Governing Law'),
  _ParaBlock('These Terms shall be governed by the applicable laws of the jurisdiction where Trapix Exchange operates.'),
  _HeadingBlock('15. Contact'),
  _BulletBlock(['Support Email: support@trapix.com', 'Website: https://trapix.com']),
];

final _privacy = <_Block>[
  _SubtitleBlock('How we collect, use, and protect your information'),
  _HeadingBlock('Introduction'),
  _ParaBlock(
      'Trapix Exchange respects your privacy and is committed to protecting your personal information when you use our website, mobile application, and services.'),
  _HeadingBlock('1. Information We Collect'),
  _BulletBlock([
    'Personal Information: Full name, Email address, Phone number, Date of birth, Government ID documents (for KYC)',
    'Account Information: Login details, Account activity, Transaction history',
    'Technical Information: IP address, Device type, Browser information, Location data',
  ]),
  _HeadingBlock('2. How We Use Your Information'),
  _BulletBlock([
    'Create and manage your account',
    'Provide trading services',
    'Verify your identity (KYC)',
    'Improve platform performance',
    'Prevent fraud and illegal activities',
    'Provide customer support',
  ]),
  _HeadingBlock('3. Cookies and Tracking Technologies'),
  _BulletBlock(['Remember your login session', 'Improve user experience', 'Analyze website traffic']),
  _ParaBlock('You can disable cookies through your browser settings.'),
  _HeadingBlock('4. Sharing of Information'),
  _ParaBlock('Trapix Exchange does not sell your personal information. However, we may share information with:'),
  _BulletBlock([
    'Regulatory authorities (when required by law)',
    'Payment processors',
    'Identity verification providers',
    'Security and fraud prevention services',
  ]),
  _HeadingBlock('5. Data Security'),
  _BulletBlock(['Encryption protection', 'Multi-layer security systems', 'Secure servers']),
  _ParaBlock('We take reasonable steps to protect your personal data from unauthorized access.'),
  _HeadingBlock('6. User Rights'),
  _BulletBlock(['Access your personal data', 'Request corrections', 'Request account deletion', 'Withdraw consent']),
  _ParaBlock('To request changes, contact our support team.'),
  _HeadingBlock('7. Third-Party Services'),
  _ParaBlock('Trapix Exchange may contain links to third-party websites. We are not responsible for their privacy practices.'),
  _HeadingBlock('8. Updates to Privacy Policy'),
  _ParaBlock('Trapix Exchange may update this Privacy Policy at any time. Updates will be posted on this page.'),
  _HeadingBlock('9. Contact Us'),
  _BulletBlock(['Email: support@trapix.com', 'Website: https://trapix.com']),
];

final _aml = <_Block>[
  _SubtitleBlock('Anti-Money Laundering and Know Your Customer compliance'),
  _HeadingBlock('Introduction'),
  _ParaBlock(
      'Trapix Exchange is committed to preventing money laundering, terrorist financing, fraud, and other illegal activities.'),
  _HeadingBlock('1. Purpose of AML / KYC Policy'),
  _BulletBlock([
    'Prevent money laundering and financial crime',
    'Ensure compliance with international regulations',
    'Protect the integrity of the Trapix Exchange platform',
    'Maintain a secure trading environment',
  ]),
  _HeadingBlock('2. Know Your Customer (KYC)'),
  _ParaBlock('Trapix Exchange requires identity verification to ensure safe and compliant trading. Users may be required to provide:'),
  _BulletBlock([
    'Full legal name',
    'Date of birth',
    'Residential address',
    'Government issued ID (passport, national ID, or driving license)',
    'Selfie verification',
  ]),
  _HeadingBlock('3. Identity Verification Process'),
  _BulletBlock(['Automated verification systems', 'Third-party identity verification providers', 'Manual compliance review']),
  _ParaBlock('Users must ensure all information provided is accurate and truthful.'),
  _HeadingBlock('4. Monitoring of Transactions'),
  _BulletBlock(['Unusual trading behavior', 'Large transactions', 'Rapid deposits and withdrawals', 'Possible fraud or illegal activities']),
  _ParaBlock('Suspicious activities may be investigated by the compliance team.'),
  _HeadingBlock('5. Suspicious Activity Reporting'),
  _BulletBlock([
    'Freeze accounts suspected of illegal activity',
    'Report suspicious transactions to regulatory authorities',
    'Request additional verification from users',
  ]),
  _HeadingBlock('6. Restricted Countries'),
  _ParaBlock(
      'Users from certain jurisdictions may be restricted from accessing Trapix Exchange services due to regulatory requirements.'),
  _HeadingBlock('7. Account Suspension'),
  _BulletBlock(['False information is provided', 'Suspicious activity is detected', 'AML / KYC regulations are violated']),
  _HeadingBlock('8. Record Keeping'),
  _ParaBlock('Trapix Exchange may retain user verification and transaction records for compliance purposes as required by law.'),
  _HeadingBlock('9. Contact'),
  _BulletBlock(['Email: compliance@trapix.com', 'Website: https://trapix.com']),
];

final _risk = <_Block>[
  _SubtitleBlock('Important risks associated with digital asset trading'),
  _HeadingBlock('Introduction'),
  _ParaBlock(
      'This Risk Disclosure Statement explains the potential risks associated with trading digital assets on Trapix Exchange. By using our services, you acknowledge and accept the risks described below.'),
  _HeadingBlock('1. Cryptocurrency Market Risk'),
  _ParaBlock('Digital assets are highly volatile and prices may fluctuate significantly within a short period of time.'),
  _BulletBlock(['Rapid price changes', 'Market instability', 'Loss of investment']),
  _ParaBlock('You should only trade funds that you can afford to lose.'),
  _HeadingBlock('2. Trading Risk'),
  _BulletBlock(['Market volatility', 'Incorrect trading decisions', 'Use of leverage in futures trading']),
  _ParaBlock('Trapix Exchange does not provide financial or investment advice.'),
  _HeadingBlock('3. Liquidity Risk'),
  _BulletBlock(['Difficulty executing trades', 'Price slippage', 'Delays in order execution']),
  _HeadingBlock('4. Technology Risk'),
  _BulletBlock(['System downtime', 'Internet connectivity issues', 'Software bugs or technical failures']),
  _HeadingBlock('5. Security Risk'),
  _ParaBlock('Users must take responsibility for protecting their login credentials and enabling security features such as two-factor authentication (2FA).'),
  _HeadingBlock('6. Regulatory Risk'),
  _BulletBlock(['The availability of services', 'Trading of certain digital assets']),
  _HeadingBlock('7. Blockchain Risk'),
  _BulletBlock(['Network congestion', 'Delayed transactions', 'Blockchain forks']),
  _ParaBlock('Trapix Exchange does not control blockchain networks.'),
  _HeadingBlock('8. Third-Party Risk'),
  _ParaBlock('Trapix Exchange is not responsible for failures or disruptions caused by third-party services.'),
  _HeadingBlock('9. No Financial Advice'),
  _ParaBlock('All information provided by Trapix Exchange is for informational purposes only. Users are responsible for making their own trading decisions.'),
  _HeadingBlock('10. Contact'),
  _BulletBlock(['Email: support@trapix.com', 'Website: https://trapix.com']),
];

final _verification = <_Block>[
  _SubtitleBlock('How to identify official Trapix representatives'),
  _HeadingBlock('Introduction'),
  _ParaBlock('Trapix Exchange is committed to protecting users from scams, impersonation, and fraudulent activities.'),
  _HeadingBlock('1. Official Communication Channels'),
  _ParaBlock('Trapix Exchange communicates with users only through official channels:'),
  _BulletBlock([
    'Official website: https://trapix.com',
    'Official email addresses ending with @trapix.com',
    'Verified social media accounts',
    'Official support system inside the Trapix platform',
  ]),
  _ParaBlock('Users should always verify the source of communication before responding.'),
  _HeadingBlock('2. No Private Investment Requests'),
  _ParaBlock('Trapix Exchange employees will never:'),
  _BulletBlock(['Ask users to send funds privately', 'Request deposits outside the official platform', 'Ask for passwords or security codes']),
  _ParaBlock('If anyone requests funds or personal information claiming to be from Trapix Exchange, it may be a scam.'),
  _HeadingBlock('3. Fake Manager Warning'),
  _ParaBlock('Scammers may impersonate Trapix staff on social media platforms such as:'),
  _BulletBlock(['Telegram', 'WhatsApp', 'Instagram', 'Discord']),
  _ParaBlock('Trapix Exchange does not guarantee profits and does not offer private trading services. Users should ignore any messages offering guaranteed profits.'),
  _HeadingBlock('4. Verification Badge'),
  _ParaBlock('Official Trapix representatives and social media pages may have:'),
  _BulletBlock(['Verified badges', 'Official branding', 'Links from the Trapix website']),
  _ParaBlock('Always confirm links through the official website.'),
  _HeadingBlock('5. Reporting Fraud'),
  _ParaBlock('If you encounter suspicious activity, please report it immediately. Provide the following if possible:'),
  _BulletBlock(['Username or profile', 'Screenshots of the conversation', 'Platform where the contact occurred']),
  _HeadingBlock('6. User Safety Guidelines'),
  _BulletBlock([
    'Never share your password',
    'Enable Two-Factor Authentication (2FA)',
    'Verify official communication channels',
    'Do not send funds outside the Trapix platform',
  ]),
  _HeadingBlock('7. Trapix Security Commitment'),
  _BulletBlock(['Security monitoring systems', 'Fraud detection tools', 'User education and awareness']),
  _HeadingBlock('8. Contact'),
  _BulletBlock(['Support Email: support@trapix.com', 'Website: https://trapix.com']),
];

final _tokenListing = <_Block>[
  _SubtitleBlock('Requirements and process for listing tokens'),
  _HeadingBlock('Introduction'),
  _ParaBlock('This Token Listing Agreement governs the listing of a digital asset on the Trapix Exchange platform. By submitting a token listing application, the Project agrees to the terms described in this Agreement.'),
  _HeadingBlock('1. Listing Application'),
  _ParaBlock('The Project must provide accurate and complete information including:'),
  _BulletBlock(['Project name', 'Token symbol', 'Blockchain network', 'Official website', 'Whitepaper', 'Smart contract address', 'Project team information']),
  _HeadingBlock('2. Due Diligence'),
  _BulletBlock(['Technology review', 'Team verification', 'Legal compliance checks', 'Market demand evaluation']),
  _ParaBlock('Trapix Exchange may reject any listing application without explanation.'),
  _HeadingBlock('3. Listing Requirements'),
  _BulletBlock(['Legitimate blockchain project', 'Transparent project team', 'Active development and community', 'Secure smart contract']),
  _HeadingBlock('4. Listing Fees'),
  _ParaBlock('Trapix Exchange may charge a token listing fee depending on the evaluation and listing package. All fees must be paid before the token is listed. Listing fees are non-refundable unless otherwise stated.'),
  _HeadingBlock('5. Project Responsibilities'),
  _BulletBlock([
    'Provide accurate and truthful information',
    'Maintain active development of the project',
    'Inform Trapix Exchange about major updates',
    'Avoid misleading or fraudulent marketing',
  ]),
  _HeadingBlock('6. Market Integrity'),
  _BulletBlock(['Do not engage in market manipulation', 'Do not create artificial trading volume', 'Do not engage in pump and dump schemes']),
  _ParaBlock('Violation may result in token delisting.'),
  _HeadingBlock('7. Delisting Rights'),
  _BulletBlock(['The project becomes inactive', 'Fraud or illegal activity is detected', 'Security risks are identified', 'Project fails to maintain listing standards']),
  _HeadingBlock('8. Liability Disclaimer'),
  _ParaBlock('Trapix Exchange does not guarantee the performance or success of any listed project. Users are responsible for their own investment decisions.'),
  _HeadingBlock('9. Marketing Support'),
  _ParaBlock('Trapix Exchange may provide optional promotional support including:'),
  _BulletBlock(['Listing announcements', 'Trading competitions', 'Airdrop campaigns']),
  _HeadingBlock('10. Contact'),
  _BulletBlock(['Email: listing@trapix.com', 'Website: https://trapix.com']),
];

final _referralTerms = <_Block>[
  _SubtitleBlock('Terms for participation in the referral program'),
  _HeadingBlock('Introduction'),
  _ParaBlock('This Affiliate / Referral Terms Agreement governs participation in the Trapix Exchange Referral Program. By participating, you agree to comply with these terms.'),
  _HeadingBlock('1. Referral Program Overview'),
  _ParaBlock('The Trapix Exchange Referral Program allows users to earn rewards by inviting new users to join the platform. Participants may receive:'),
  _BulletBlock(['Trading commission rewards', 'Referral bonuses', 'Promotional campaign rewards']),
  _HeadingBlock('2. Eligibility'),
  _BulletBlock(['Have an active Trapix Exchange account', 'Follow all platform policies and rules', 'Provide accurate information when required']),
  _HeadingBlock('3. Referral Rewards'),
  _ParaBlock('Users may earn a percentage of trading fees generated by referred users. Reward percentages may change based on platform policies.'),
  _HeadingBlock('4. Referral Link Usage'),
  _ParaBlock('Participants will receive a unique referral link or referral code. Users may share through social media, personal websites, and community groups. Referral links must not be used for spam or misleading promotions.'),
  _HeadingBlock('5. Prohibited Activities'),
  _BulletBlock(['Spam marketing', 'Fake accounts or self-referrals', 'Misleading advertising', 'Fraudulent or deceptive practices']),
  _ParaBlock('Violation may result in termination from the program.'),
  _HeadingBlock('6. Account Suspension'),
  _BulletBlock(['Violate referral program rules', 'Engage in fraudulent activities', 'Abuse the reward system']),
  _HeadingBlock('7. Limitation of Liability'),
  _ParaBlock('Trapix Exchange is not responsible for losses or damages related to participation in the referral program. Participation is voluntary.'),
  _HeadingBlock('8. Contact'),
  _BulletBlock(['Email: support@trapix.com', 'Website: https://trapix.com']),
];

final _listingPolicy = <_Block>[
  _SubtitleBlock('Policy for token listing on Trapix Exchange'),
  _HeadingBlock('Introduction'),
  _ParaBlock('Trapix Exchange is committed to providing a secure, transparent, and high-quality digital asset trading environment. This Listing Policy explains the requirements and evaluation process for token listing applications.'),
  _HeadingBlock('1. Listing Application Process'),
  _ParaBlock('Projects must submit a listing application with the following information:'),
  _BulletBlock([
    'Project name and token symbol',
    'Blockchain network',
    'Official website',
    'Whitepaper',
    'Smart contract address',
    'Tokenomics details',
    'Project team information',
  ]),
  _HeadingBlock('2. Evaluation Criteria'),
  _BulletBlock([
    'Technology and blockchain infrastructure',
    'Project development progress',
    'Team experience and credibility',
    'Community size and engagement',
    'Market demand and liquidity potential',
  ]),
  _HeadingBlock('3. Project Requirements'),
  _BulletBlock(['Legitimate blockchain project', 'Clear and transparent tokenomics', 'Secure smart contract', 'Active development and roadmap', 'Strong community support']),
  _HeadingBlock('4. Compliance Requirements'),
  _BulletBlock(['Anti-Money Laundering (AML) requirements', 'Legal compliance in their jurisdiction', 'Transparency regarding project operations']),
  _HeadingBlock('5. Listing Fees'),
  _ParaBlock('Trapix Exchange may charge listing fees depending on project evaluation, listing package, and marketing support. All fees must be paid before listing approval.'),
  _HeadingBlock('6. Marketing Support'),
  _BulletBlock(['Official listing announcement', 'Airdrop campaigns', 'Trading competitions', 'Social media promotions']),
  _HeadingBlock('7. Delisting Conditions'),
  _BulletBlock(['The project becomes inactive', 'Security vulnerabilities are discovered', 'Fraud or illegal activity is detected', 'Project fails to maintain listing standards']),
  _HeadingBlock('8. Disclaimer'),
  _ParaBlock('Listing a token on Trapix Exchange does not guarantee the success or performance of the project. Users must conduct their own research before trading digital assets.'),
  _HeadingBlock('9. Contact'),
  _BulletBlock(['Email: listing@trapix.com', 'Website: https://trapix.com']),
];

final _ibProgram = <_Block>[
  _SubtitleBlock('Terms and conditions for participation in the Introducing Broker program'),
  _HeadingBlock('01 Eligibility & Enrollment'),
  _BulletBlock([
    'The Trapix IB Program is open to all registered Trapix users who have completed identity verification (KYC) where required.',
    'Each user receives a unique IB code and IB link upon registration. This code is non-transferable and tied to the user\'s account.',
    'Users must be at least 18 years of age to participate.',
    'Trapix reserves the right to deny participation to users in jurisdictions where IB incentive programs are prohibited by law.',
  ]),
  _HeadingBlock('02 How the Program Works'),
  _BulletBlock([
    'When a new user signs up using your IB code or link, they become your Level 1 (direct) client.',
    'When your Level 1 client signs up their own clients, those users become your Level 2 (indirect) clients.',
    'The IB structure is limited to a maximum of 2 levels. No commissions are paid beyond Level 2.',
    'Commissions are calculated as a percentage of the 0.3% trading fee charged on each spot trade.',
  ]),
  _HeadingBlock('03 Commission Structure & Tier System'),
  _ParaBlock('Level 1 Commission scales with total number of direct clients:'),
  _BulletBlock([
    'Starter (0–9 direct clients): 30% of 0.3% fee',
    'Pro (10–49 direct clients): 40% of 0.3% fee',
    'Elite (50–199 direct clients): 50% of 0.3% fee',
    'VIP (200+ direct clients): 60% of 0.3% fee',
  ]),
  _ParaBlock('Level 2 Commission is fixed at 10% of the 0.3% trading fee for all tiers. Tier upgrades are applied automatically in real-time.'),
  _HeadingBlock('04 Reward Calculation & Settlement'),
  _BulletBlock([
    'IB commissions are credited to your Pending IB Rewards balance in real-time as each qualifying trade is executed.',
    'Commissions are denominated in USDT.',
    'Pending IB Rewards must be transferred to your IB Rewards Wallet via the "Withdraw to IB Rewards Wallet" button before use.',
  ]),
  _HeadingBlock('05 Withdrawal of Rewards'),
  _BulletBlock([
    'IBs may withdraw Pending Rewards to their IB Rewards Wallet at any time, subject to a minimum of 0.01 USDT.',
    'Rewards that are not withdrawn remain in the Pending balance indefinitely with no expiration, unless the account is terminated.',
  ]),
  _HeadingBlock('06 Prohibited Activities'),
  _BulletBlock(['Self-referrals', 'Wash trading', 'Spam marketing', 'Misrepresentation', 'Exploiting system bugs']),
  _ParaBlock('Violations result in immediate disqualification and forfeiture of all rewards.'),
  _HeadingBlock('07 Program Modifications'),
  _ParaBlock('Trapix reserves the right to modify, suspend, or terminate the IB Program at any time. Material changes will be communicated at least 7 days in advance.'),
  _HeadingBlock('08 Tax Obligations'),
  _ParaBlock('IB rewards constitute taxable income in many jurisdictions. You are solely responsible for determining and paying any applicable taxes.'),
  _HeadingBlock('09 Governing Law'),
  _ParaBlock('Any disputes shall be governed by the laws specified in the Trapix Terms of Service. Trapix\'s decisions regarding IB attribution and commissions are final and binding.'),
  _HeadingBlock('Important Notice'),
  _ParaBlock('By using your IB link or earning IB rewards, you explicitly acknowledge that you have read, understood, and agree to be bound by all of the above Terms & Conditions.'),
  _HeadingBlock('Contact'),
  _BulletBlock(['Email: support@trapix.com']),
];

final _userAgreement = <_Block>[
  _SubtitleBlock('Legal agreement between you and Trapix Exchange'),
  _HeadingBlock('Introduction'),
  _ParaBlock(
      'This User Agreement is a legally binding agreement between you and Trapix Exchange. By accessing or using the platform, you agree to comply with and be bound by this Agreement.'),
  _HeadingBlock('1. Acceptance of Agreement'),
  _BulletBlock([
    'You have read and understood this Agreement',
    'You agree to comply with all applicable policies and rules',
    'You accept the risks associated with cryptocurrency trading',
  ]),
  _HeadingBlock('2. Account Registration'),
  _BulletBlock([
    'You must create an account with accurate information',
    'Maintain the confidentiality of your login credentials',
    'Users are responsible for all activities conducted through their account',
  ]),
  _HeadingBlock('3. User Obligations'),
  _BulletBlock([
    'Use the platform only for lawful purposes',
    'Provide accurate and truthful information',
    'Protect your account credentials',
    'Follow all platform rules and policies',
  ]),
  _HeadingBlock('4. Prohibited Activities'),
  _BulletBlock([
    'Market manipulation',
    'Fraud or illegal activities',
    'Money laundering',
    'Unauthorized access to the system',
    'Using automated bots without permission',
  ]),
  _HeadingBlock('5. Trading Services'),
  _BulletBlock(['Spot trading', 'Futures trading', 'Digital asset deposits and withdrawals', 'Referral and reward programs', 'Token listing services']),
  _ParaBlock('Trapix Exchange acts as a trading platform and does not guarantee profits.'),
  _HeadingBlock('6. Fees'),
  _BulletBlock(['Trading fees', 'Withdrawal fees', 'Listing or service fees (if applicable)']),
  _HeadingBlock('7. Security Responsibilities'),
  _BulletBlock(['Enable two-factor authentication (2FA)', 'Protect passwords', 'Avoid phishing websites']),
  _HeadingBlock('8. Account Suspension or Termination'),
  _BulletBlock(['Users violate platform rules', 'Fraud or suspicious activity is detected', 'AML / KYC regulations are not followed']),
  _HeadingBlock('9. Limitation of Liability'),
  _BulletBlock(['Market volatility', 'Technical failures', 'Third-party service disruptions', 'User trading decisions']),
  _HeadingBlock('10. Amendments'),
  _ParaBlock('Trapix Exchange may update this Agreement at any time. Continued use of the platform means you accept the updated terms.'),
  _HeadingBlock('11. Contact'),
  _BulletBlock(['Email: support@trapix.com', 'Website: https://trapix.com']),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AboutTrapixScreen extends StatelessWidget {
  const AboutTrapixScreen({super.key});

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
          'About Trapix',
          style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _font),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const ShapeDecoration(color: _card, shape: OvalBorder()),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset('assets/images/icon.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 10),
                  const Text('Trapix',
                      style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _font)),
                  const SizedBox(height: 4),
                  Text('Version:1.36.0',
                      style: TextStyle(color: _white.withValues(alpha: 0.5), fontSize: 12, fontFamily: _font)),
                  Text('2026.124325.124325346',
                      style: TextStyle(color: _white.withValues(alpha: 0.5), fontSize: 12, fontFamily: _font)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _PolicyItem(title: 'Terms & Conditions', blocks: _terms),
            _PolicyItem(title: 'Privacy Policy', blocks: _privacy),
            _PolicyItem(title: 'AML/KYC Policy', blocks: _aml),
            _PolicyItem(title: 'Risk Disclosure', blocks: _risk),
            _PolicyItem(title: 'User Agreement', blocks: _userAgreement),
            _PolicyItem(title: 'Verification Policy', blocks: _verification),
            _PolicyItem(title: 'Token Listing Agreement', blocks: _tokenListing),
            _PolicyItem(title: 'Referral Terms', blocks: _referralTerms),
            _PolicyItem(title: 'Listing Policy', blocks: _listingPolicy),
            _PolicyItem(title: 'IB Program — Terms & Conditions', blocks: _ibProgram),
          ],
        ),
      ),
    );
  }
}

// ── Expandable item ───────────────────────────────────────────────────────────

class _PolicyItem extends StatefulWidget {
  const _PolicyItem({required this.title, required this.blocks});
  final String title;
  final List<_Block> blocks;

  @override
  State<_PolicyItem> createState() => _PolicyItemState();
}

class _PolicyItemState extends State<_PolicyItem> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: _expanded ? _green : _white,
                        fontSize: 15,
                        fontFamily: _font,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotate,
                    child: Icon(Icons.keyboard_arrow_down, color: _expanded ? _green : _grey, size: 22),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: widget.blocks.isEmpty
                  ? Text('Content coming soon.',
                      style: TextStyle(color: _white.withValues(alpha: 0.5), fontSize: 13, fontFamily: _font))
                  : _PolicyContent(blocks: widget.blocks),
            ),
        ],
      ),
    );
  }
}

// ── Rich content renderer ─────────────────────────────────────────────────────

class _PolicyContent extends StatelessWidget {
  const _PolicyContent({required this.blocks});
  final List<_Block> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((b) {
        if (b is _SubtitleBlock) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              b.text,
              style: TextStyle(color: _white.withValues(alpha: 0.5), fontSize: 13, fontFamily: _font, height: 1.5),
            ),
          );
        }
        if (b is _HeadingBlock) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.text,
                  style: const TextStyle(
                      color: _white, fontSize: 14, fontFamily: _font, fontWeight: FontWeight.w700, height: 1.4),
                ),
                const SizedBox(height: 6),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              ],
            ),
          );
        }
        if (b is _ParaBlock) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              b.text,
              style: TextStyle(color: _white.withValues(alpha: 0.75), fontSize: 13, fontFamily: _font, height: 1.6),
            ),
          );
        }
        if (b is _BulletBlock) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: b.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6, right: 8),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                    color: _white.withValues(alpha: 0.75), fontSize: 13, fontFamily: _font, height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}
