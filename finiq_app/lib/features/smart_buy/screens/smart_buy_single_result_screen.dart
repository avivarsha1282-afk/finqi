import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/smart_buy_models.dart';
import '../../../services/api_service.dart';
import '../../../services/user_data_service.dart';

/// Screen C — Single Product Analysis Result
/// Phase 4: URL validation fallback, hide empty sections, shimmer placeholders,
///          max 3 similar products, platform-colored cards.
class SmartBuySingleResultScreen extends StatefulWidget {
  final List<Uint8List> images;
  const SmartBuySingleResultScreen({super.key, required this.images});

  @override
  State<SmartBuySingleResultScreen> createState() => _SmartBuySingleResultScreenState();
}

class _SmartBuySingleResultScreenState extends State<SmartBuySingleResultScreen>
    with TickerProviderStateMixin {
  SingleProductResult? _result;
  bool _isLoading = true;
  String? _error;
  int _hintIndex = 0;
  Timer? _hintTimer;

  late AnimationController _ringController;
  AnimationController? _resultController;

  // Shimmer pulse for loading placeholders
  late AnimationController _shimmerController;

  final _hints = [
    'Reading product details...',
    'Checking quality indicators...',
    'Searching online prices...',
    'Calculating affordability...',
    'Writing your report...',
  ];

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _shimmerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _hintTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
    });
    _analyse();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _resultController?.dispose();
    _shimmerController.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  void _initResultAnimations() {
    _resultController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  Animation<double> _sOp(double s, double e) =>
      Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _resultController!, curve: Interval(s, e, curve: Curves.easeOut)));
  Animation<Offset> _sSl(double s, double e) =>
      Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _resultController!, curve: Interval(s, e, curve: Curves.easeOut)));

  bool _isValidProductUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _analyse() async {
    try {
      final profile = await UserDataService.getUserProfile();
      final income = _num(profile, 'monthly_income');
      final expenses = _num(profile, 'monthly_expense');
      final savings = _num(profile, 'current_savings');

      final imageB64 = base64Encode(widget.images.first);
      debugPrint('📤 Sending analyse/single — income=$income, expenses=$expenses');

      final response = await ApiService.instance.postData('/smart-buy/analyse/single', {
        'image': imageB64,
        'monthlyIncome': income,
        'monthlyExpenses': expenses,
        'currentSavings': savings,
      });

      debugPrint('📥 Response: success=${response['success']}');

      if (response['success'] == true) {
        final analysis = response['analysis'] as Map<String, dynamic>;
        final hash = response['imageHash'] as String? ?? '';
        final corrupted = response['profileDataCorrupted'] as bool? ?? false;
        _initResultAnimations();
        setState(() {
          _result = SingleProductResult.fromJson(analysis, imageHash: hash, profileCorrupted: corrupted);
          _isLoading = false;
        });
      } else {
        debugPrint('❌ API error: ${response['error']}');
        setState(() { _error = response['error'] as String? ?? 'Analysis failed'; _isLoading = false; });
      }
    } catch (e) {
      debugPrint('❌ CONNECTION ERROR: $e');
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double _num(Map<String, dynamic> p, String key) {
    final v = p[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    return 0;
  }

  Future<void> _launchUrl(String url, {String? fallbackProductName}) async {
    String targetUrl = url;
    if (!_isValidProductUrl(url) && fallbackProductName != null) {
      targetUrl = 'https://www.amazon.in/s?k=${Uri.encodeComponent(fallbackProductName)}';
    }
    final uri = Uri.parse(targetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open browser'), backgroundColor: Color(0xFFF44336)));
    }
  }

  Future<void> _saveReport() async {
    if (_result == null) return;
    try {
      final profile = await UserDataService.getUserProfile();
      await ApiService.instance.postData('/smart-buy/save', {
        'mode': 'single',
        'product1': _result!.toReportJson(),
        'product2': null, 'winner': null, 'winnerReason': null,
        'financialSnapshot': {
          'monthlyIncome': _num(profile, 'monthly_income'),
          'monthlyExpenses': _num(profile, 'monthly_expense'),
          'monthlySurplus': _num(profile, 'monthly_income') - _num(profile, 'monthly_expense'),
        },
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report saved ✓'), backgroundColor: Color(0xFF00C896)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e'), backgroundColor: const Color(0xFFF44336)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScreen();
    if (_error != null) return _buildErrorScreen();
    if (_result != null && _result!.isUnrecognised) return _buildUnrecognisedScreen();
    return _buildResultScreen();
  }

  // ═══════════════════════════════════════════════════════════
  // LOADING — 3 pulsing rings
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 140, height: 140, child: Stack(alignment: Alignment.center, children: [
            AnimatedBuilder(animation: _ringController, builder: (_, __) {
              final d = ((_ringController.value + 0.4) % 1.0);
              return Transform.scale(scale: 0.8 + 0.4 * d,
                child: Opacity(opacity: (0.3 * (1.0 - d)).clamp(0.0, 1.0),
                  child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.10))))));
            }),
            AnimatedBuilder(animation: _ringController, builder: (_, __) {
              final d = ((_ringController.value + 0.2) % 1.0);
              return Transform.scale(scale: 0.8 + 0.4 * d,
                child: Opacity(opacity: (0.5 * (1.0 - d)).clamp(0.0, 1.0),
                  child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.20), width: 2)))));
            }),
            Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle,
              color: const Color(0xFF00C896).withValues(alpha: 0.20),
              border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.60), width: 2)),
              child: const Icon(Icons.document_scanner_outlined, size: 24, color: Color(0xFF00C896))),
          ])),
          const SizedBox(height: 40),
          const Text('Artha is analysing your product',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AnimatedSwitcher(duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim), child: child)),
            child: Text(_hints[_hintIndex], key: ValueKey(_hintIndex),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 15), textAlign: TextAlign.center)),
        ]),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(backgroundColor: const Color(0xFF0A0A0A), elevation: 0, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop())),
      body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_outlined, color: Colors.white38, size: 48),
          const SizedBox(height: 16),
          const Text("Couldn't analyse the product", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('$_error', style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: () { setState(() { _isLoading = true; _error = null; }); _analyse(); },
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00C896))),
            child: const Text('Retry', style: TextStyle(color: Color(0xFF00C896)))),
        ]))));
  }

  Widget _buildUnrecognisedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(backgroundColor: const Color(0xFF0A0A0A), elevation: 0, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop())),
      body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 48),
          const SizedBox(height: 16),
          const Text("Couldn't identify this product", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Try better lighting or a closer shot', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: () => context.pop(),
            icon: const Icon(Icons.camera_alt_outlined, size: 18), label: const Text('Retake Photo'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C896), foregroundColor: Colors.black)),
        ]))));
  }

  // ═══════════════════════════════════════════════════════════
  // RESULT SCREEN
  // ═══════════════════════════════════════════════════════════
  Widget _buildResultScreen() {
    final r = _result!;
    final productFullName = '${r.brand} ${r.productName}';
    // Cap similar products at 3
    final similar = r.similarProducts.take(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0A0A0A), surfaceTintColor: Colors.transparent,
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()),
            title: const Text('Analysis', style: TextStyle(color: Colors.white, fontSize: 16)),
            pinned: true, elevation: 0),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Corruption banner
              if (r.profileDataCorrupted) ...[
                _CorruptionBanner(onFix: () => context.push('/profile/edit')),
                const SizedBox(height: 16),
              ],

              // Product name + price
              Row(children: [
                Expanded(child: Text(r.productName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
                if (r.detectedPrice != null)
                  Text('₹${r.detectedPrice!.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFF00C896), fontSize: 20, fontWeight: FontWeight.w700)),
              ]),

              // 1. Verdict
              const SizedBox(height: 20),
              _stagger(0.0, 0.33, child: _VerdictCard(verdict: r.verdict, reason: r.verdictReason)),

              // 2. Affordability
              if (r.affordabilityLevel != 'UNKNOWN') ...[
                const SizedBox(height: 20), _sectionLabel('AFFORDABILITY'),
                const SizedBox(height: 8),
                _stagger(0.17, 0.45, child: _AffordabilityCard(level: r.affordabilityLevel, percent: r.affordabilityPercent, animController: _resultController!)),
              ],

              // 3. Scores
              const SizedBox(height: 20), _sectionLabel('QUALITY ANALYSIS'),
              const SizedBox(height: 8),
              _stagger(0.29, 0.55, child: Row(children: [
                Expanded(child: _ScoreChip(label: 'Value for Money', score: r.valueForMoneyScore)),
                const SizedBox(width: 10),
                Expanded(child: _ScoreChip(label: 'Quality Score', score: r.qualityScore)),
              ])),

              // 4. Quality breakdown
              const SizedBox(height: 20), _sectionLabel('WHAT WE FOUND'),
              const SizedBox(height: 8),
              _stagger(0.37, 0.62, child: _QualityBreakdownCard(breakdown: r.qualityBreakdown)),

              // 5. Key specs
              if (r.keySpecs.isNotEmpty) ...[
                const SizedBox(height: 20), _sectionLabel('KEY SPECS'),
                const SizedBox(height: 8),
                _KeySpecsList(specs: r.keySpecs),
              ],

              // 6. Pros/Cons
              const SizedBox(height: 20),
              _stagger(0.46, 0.70, child: _ProsConsSection(pros: r.pros, cons: r.cons)),

              // 7. Artha insight
              const SizedBox(height: 20),
              _stagger(0.58, 0.82, child: _ArthaInsightCard(insight: r.arthaInsight)),

              // 8. Where to Buy — HIDE if empty (per correction 1)
              if (r.onlineListings.isNotEmpty) ...[
                const SizedBox(height: 20), _sectionLabel('WHERE TO BUY'),
                const SizedBox(height: 8),
                if (r.priceHistory.isGoodDeal) ...[
                  _PriceDealBadge(reason: r.priceHistory.dealReason),
                  const SizedBox(height: 8),
                ],
                ...r.onlineListings.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ListingCard(
                    listing: l,
                    onBuy: () => _launchUrl(l.url, fallbackProductName: productFullName)))),
              ],

              // 9. Similar Products — max 3, hide if empty
              if (similar.isNotEmpty) ...[
                const SizedBox(height: 20), _sectionLabel('CONSIDER THESE TOO'),
                const SizedBox(height: 8),
                SizedBox(height: 210, child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: similar.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _SimilarProductCard(
                    product: similar[i],
                    onTap: () => _launchUrl(similar[i].url, fallbackProductName: '${similar[i].brand} ${similar[i].name}')),
                )),
              ],

              // 10. Alternatives
              if (r.alternatives.isNotEmpty && r.verdict != 'BUY') ...[
                const SizedBox(height: 20), _sectionLabel('BETTER OPTIONS'),
                const SizedBox(height: 8),
                ...r.alternatives.asMap().entries.map((e) =>
                  _AlternativeCard(index: e.key + 1, alt: e.value)),
              ],

              // Actions
              const SizedBox(height: 32),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Scan Again', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: const Color(0xFF00C896).withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton.icon(
                  onPressed: _saveReport,
                  icon: const Icon(Icons.bookmark_outline, size: 18),
                  label: const Text('Save to Report', maxLines: 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C896), foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600)))),
              ]),
              const SizedBox(height: 40),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _stagger(double start, double end, {required Widget child}) {
    if (_resultController == null) return child;
    return SlideTransition(position: _sSl(start, end),
      child: FadeTransition(opacity: _sOp(start, end), child: child));
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.2));
  }
}

// ═══════════════════════════════════════════════════════════
// CORRUPTION WARNING BANNER
// ═══════════════════════════════════════════════════════════
class _CorruptionBanner extends StatelessWidget {
  final VoidCallback onFix;
  const _CorruptionBanner({required this.onFix});
  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFF9800);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.10),
        border: Border.all(color: amber.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.warning_amber_outlined, color: amber, size: 16),
        const SizedBox(width: 8),
        const Expanded(child: Text('Update your profile for personalised advice',
          style: TextStyle(color: Colors.white70, fontSize: 12))),
        TextButton(onPressed: onFix, child: const Text('Fix Now →',
          style: TextStyle(color: amber, fontSize: 12))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// VERDICT CARD
// ═══════════════════════════════════════════════════════════
class _VerdictCard extends StatelessWidget {
  final String verdict; final String reason;
  const _VerdictCard({required this.verdict, required this.reason});
  @override
  Widget build(BuildContext context) {
    Color color; IconData icon;
    switch (verdict) {
      case 'BUY': color = const Color(0xFF00C896); icon = Icons.check_circle_outline; break;
      case 'CONSIDER': color = const Color(0xFFFFC107); icon = Icons.info_outline; break;
      default: color = const Color(0xFFF44336); icon = Icons.cancel_outlined;
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.50), width: 1.5)),
      child: Row(children: [
        Container(width: 4, height: 60, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 16),
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(verdict, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
          if (reason.isNotEmpty) Text(reason, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ])),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// AFFORDABILITY
// ═══════════════════════════════════════════════════════════
Color _levelColor(String level) {
  switch (level) {
    case 'COMFORTABLE': return const Color(0xFF00C896);
    case 'MANAGEABLE': return const Color(0xFFFFC107);
    case 'STRETCH': return const Color(0xFFFF9800);
    default: return const Color(0xFFF44336);
  }
}

class _AffordabilityCard extends StatelessWidget {
  final String level; final double percent; final AnimationController animController;
  const _AffordabilityCard({required this.level, required this.percent, required this.animController});
  @override
  Widget build(BuildContext context) {
    final color = _levelColor(level);
    final clamped = percent.clamp(0.0, 100.0);
    final barAnim = Tween(begin: 0.0, end: clamped / 100.0).animate(
      CurvedAnimation(parent: animController, curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic)));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(level, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(child: Text('${percent.toStringAsFixed(1)}% of monthly surplus',
            style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: SizedBox(height: 8, child: AnimatedBuilder(animation: barAnim,
            builder: (_, __) => Stack(children: [
              Container(color: Colors.white.withValues(alpha: 0.08)),
              FractionallySizedBox(widthFactor: barAnim.value, child: Container(color: color)),
            ])))),
      ]),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label; final double score;
  const _ScoreChip({required this.label, required this.score});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        RichText(text: TextSpan(children: [
          TextSpan(text: score.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300)),
          TextSpan(text: '/10', style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 14)),
        ])),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 11)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// QUALITY BREAKDOWN
// ═══════════════════════════════════════════════════════════
class _QualityBreakdownCard extends StatelessWidget {
  final QualityBreakdown breakdown;
  const _QualityBreakdownCard({required this.breakdown});
  Color _repColor(String rep) {
    switch (rep) { case 'EXCELLENT': return const Color(0xFF00C896); case 'GOOD': return const Color(0xFF8BC34A);
      case 'AVERAGE': return const Color(0xFFFFC107); default: return Colors.white38; }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _row('Brand', breakdown.brandReputation, _repColor(breakdown.brandReputation)),
        Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
        _row('Packaging', breakdown.packaging, _repColor(
          breakdown.packaging == 'PREMIUM' ? 'EXCELLENT' : breakdown.packaging == 'STANDARD' ? 'GOOD' : 'AVERAGE')),
        if (breakdown.buildOrIngredients.isNotEmpty) ...[
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Build / Ingredients', style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 12)),
              const SizedBox(height: 4),
              Text(breakdown.buildOrIngredients, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400, height: 1.5)),
            ])),
        ],
        if (breakdown.redFlags.isNotEmpty) ...[
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('⚠ Red Flags', style: TextStyle(color: Color(0xFFF44336), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ...breakdown.redFlags.map((f) => Padding(padding: const EdgeInsets.only(top: 2),
                child: Text('· $f', style: const TextStyle(color: Color(0xFFF44336), fontSize: 13)))),
            ])),
        ],
      ]),
    );
  }
  Widget _row(String label, String value, Color color) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 13)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
      ]));
  }
}

// ═══════════════════════════════════════════════════════════
// KEY SPECS LIST
// ═══════════════════════════════════════════════════════════
class _KeySpecsList extends StatelessWidget {
  final List<KeySpec> specs;
  const _KeySpecsList({required this.specs});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: specs.length,
        separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
        itemBuilder: (_, i) {
          final s = specs[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 110, child: Text(s.label,
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38)),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 12),
              Expanded(child: Text(s.value,
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                maxLines: 3, overflow: TextOverflow.ellipsis)),
            ]),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROS/CONS — SINGLE COLUMN
// ═══════════════════════════════════════════════════════════
class _ProsConsSection extends StatelessWidget {
  final List<String> pros; final List<String> cons;
  const _ProsConsSection({required this.pros, required this.cons});
  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    const red = Color(0xFFF44336);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 20, height: 20, decoration: BoxDecoration(color: teal.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 12, color: teal)),
          const SizedBox(width: 8),
          const Text('Pros', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: teal)),
        ]),
        const SizedBox(height: 10),
        ...pros.map((p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 3),
              child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: teal, shape: BoxShape.circle))),
            const SizedBox(width: 10),
            Expanded(child: Text(p, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5))),
          ]))),
        const SizedBox(height: 16),
        Divider(color: Colors.white.withValues(alpha: 0.06)),
        const SizedBox(height: 16),
        Row(children: [
          Container(width: 20, height: 20, decoration: BoxDecoration(color: red.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 12, color: red)),
          const SizedBox(width: 8),
          const Text('Cons', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: red)),
        ]),
        const SizedBox(height: 10),
        ...cons.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 3),
              child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: red, shape: BoxShape.circle))),
            const SizedBox(width: 10),
            Expanded(child: Text(c, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5))),
          ]))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ARTHA INSIGHT
// ═══════════════════════════════════════════════════════════
class _ArthaInsightCard extends StatelessWidget {
  final String insight;
  const _ArthaInsightCard({required this.insight});
  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: teal.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: teal.withValues(alpha: 0.20))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const CircleAvatar(radius: 14, backgroundColor: teal,
            child: Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
          const SizedBox(width: 10),
          const Text("Artha's Verdict", style: TextStyle(color: teal, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text(insight, style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic, height: 1.6)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ONLINE LISTING CARD
// ═══════════════════════════════════════════════════════════
Color _platformColor(String p) {
  switch (p.toLowerCase()) {
    case 'amazon': return const Color(0xFFFF9900);
    case 'flipkart': return const Color(0xFF2874F0);
    case 'meesho': return const Color(0xFFF43397);
    default: return const Color(0xFF00C896);
  }
}

class _ListingCard extends StatelessWidget {
  final OnlineListing listing; final VoidCallback onBuy;
  const _ListingCard({required this.listing, required this.onBuy});
  @override
  Widget build(BuildContext context) {
    final pc = _platformColor(listing.platform);
    return GestureDetector(
      onTap: onBuy,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Platform badge
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: pc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(listing.platform, style: TextStyle(color: pc, fontSize: 12, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          // Price + details
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              if (listing.price != null)
                Text('₹${listing.price!.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              if (listing.originalPrice != null) ...[
                const SizedBox(width: 8),
                Text('₹${listing.originalPrice!.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13, decoration: TextDecoration.lineThrough)),
              ],
            ]),
            if (listing.discount != null)
              Text(listing.discount!, style: const TextStyle(color: Color(0xFF00C896), fontSize: 11)),
            if (listing.rating > 0)
              Row(children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 12),
                const SizedBox(width: 3),
                Text('${listing.rating}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(' · ${listing.reviewCount} reviews',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 11)),
              ]),
            if (listing.badge != null)
              Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFF9900).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                child: Text(listing.badge!, style: const TextStyle(color: Color(0xFFFF9900), fontSize: 10, fontWeight: FontWeight.w600))),
          ])),
          const SizedBox(width: 8),
          // Buy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: pc.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Buy', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 12),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PriceDealBadge extends StatelessWidget {
  final String reason;
  const _PriceDealBadge({required this.reason});
  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: teal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: teal.withValues(alpha: 0.20))),
      child: Row(children: [
        const Icon(Icons.trending_down, color: teal, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(reason, style: const TextStyle(color: teal, fontSize: 13))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SIMILAR PRODUCT CARD
// ═══════════════════════════════════════════════════════════
class _SimilarProductCard extends StatelessWidget {
  final SimilarProduct product; final VoidCallback onTap;
  const _SimilarProductCard({required this.product, required this.onTap});
  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    final pc = _platformColor(product.platform);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Platform badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: pc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(product.platform, style: TextStyle(color: pc, fontSize: 10, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          Text(product.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(product.brand, style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 11)),
          const Spacer(),
          Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(color: teal, fontSize: 16, fontWeight: FontWeight.w700)),
          if (product.rating > 0)
            Row(children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 11),
              const SizedBox(width: 3),
              Text('${product.rating}', style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 11)),
            ]),
          const SizedBox(height: 6),
          Text(product.whyConsider, style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 11, height: 1.4),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Container(
            width: double.infinity, height: 30, alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: teal.withValues(alpha: 0.40)),
              borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
              Text('View on ${product.platform}', style: const TextStyle(color: teal, fontSize: 11)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, color: teal, size: 11),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ALTERNATIVE CARD
// ═══════════════════════════════════════════════════════════
class _AlternativeCard extends StatelessWidget {
  final int index; final Alternative alt;
  const _AlternativeCard({required this.index, required this.alt});
  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Row(children: [
        CircleAvatar(radius: 14, backgroundColor: teal.withValues(alpha: 0.15),
          child: Text('$index', style: const TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(alt.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(alt.reason, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
        Text(alt.priceRange, style: const TextStyle(color: teal, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
