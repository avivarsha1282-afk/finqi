import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/smart_buy_models.dart';
import '../../../services/api_service.dart';
import '../../../services/user_data_service.dart';

/// Screen D — Two-Product Comparison Result
/// Phase 4: Brand-based winner, card-per-feature table, winner buy section,
///          jump-to-verdict FAB, URL validation fallback.
class SmartBuyCompareResultScreen extends StatefulWidget {
  final List<Uint8List> images;
  const SmartBuyCompareResultScreen({super.key, required this.images});

  @override
  State<SmartBuyCompareResultScreen> createState() => _SmartBuyCompareResultScreenState();
}

class _SmartBuyCompareResultScreenState extends State<SmartBuyCompareResultScreen>
    with TickerProviderStateMixin {
  CompareProductResult? _result;
  bool _isLoading = true;
  String? _error;
  int _hintIndex = 0;
  Timer? _hintTimer;
  bool _showJumpButton = false;

  late AnimationController _ringController;
  AnimationController? _resultController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _verdictKey = GlobalKey();

  final _hints = [
    'Reading Product 1...',
    'Reading Product 2...',
    'Searching online prices...',
    'Comparing features...',
    'Finding the winner...',
  ];

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _hintTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
    });
    _scrollController.addListener(_onScroll);
    _compare();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _resultController?.dispose();
    _hintTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > 400 && !_showJumpButton) {
      setState(() => _showJumpButton = true);
    } else if (offset <= 400 && _showJumpButton) {
      setState(() => _showJumpButton = false);
    }
  }

  void _scrollToVerdict() {
    final ctx = _verdictKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
  }

  void _initResultAnimations() {
    _resultController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  Animation<double> _sOp(double s, double e) =>
      Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _resultController!, curve: Interval(s, e, curve: Curves.easeOut)));
  Animation<Offset> _sSl(double s, double e) =>
      Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _resultController!, curve: Interval(s, e, curve: Curves.easeOut)));

  double _num(Map<String, dynamic> p, String key) {
    final v = p[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    return 0;
  }

  bool _isValidProductUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
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

  Future<void> _compare() async {
    try {
      final profile = await UserDataService.getUserProfile();
      final income = _num(profile, 'monthly_income');
      final expenses = _num(profile, 'monthly_expense');
      final savings = _num(profile, 'current_savings');

      debugPrint('📤 Sending analyse/compare — income=$income');
      final response = await ApiService.instance.postData('/smart-buy/analyse/compare', {
        'image1': base64Encode(widget.images[0]),
        'image2': base64Encode(widget.images[1]),
        'monthlyIncome': income,
        'monthlyExpenses': expenses,
        'currentSavings': savings,
      });

      debugPrint('📥 Response: success=${response['success']}');
      if (response['success'] == true) {
        final analysis = response['analysis'] as Map<String, dynamic>;
        final corrupted = response['profileDataCorrupted'] as bool? ?? false;
        _initResultAnimations();
        setState(() {
          _result = CompareProductResult.fromJson(analysis,
              imageHash1: response['imageHash1'] as String? ?? '',
              imageHash2: response['imageHash2'] as String? ?? '',
              profileCorrupted: corrupted);
          _isLoading = false;
        });
      } else {
        setState(() { _error = response['error'] as String? ?? 'Comparison failed'; _isLoading = false; });
      }
    } catch (e) {
      debugPrint('❌ CONNECTION ERROR: $e');
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _saveReport() async {
    if (_result == null) return;
    try {
      final profile = await UserDataService.getUserProfile();
      await ApiService.instance.postData('/smart-buy/save', {
        'mode': 'compare',
        'product1': _result!.product1.toReportJson(),
        'product2': _result!.product2.toReportJson(),
        'winner': _result!.winner,
        'winnerReason': _result!.winnerReason,
        'financialSnapshot': {
          'monthlyIncome': _num(profile, 'monthly_income'),
          'monthlyExpenses': _num(profile, 'monthly_expense'),
          'monthlySurplus': _num(profile, 'monthly_income') - _num(profile, 'monthly_expense'),
        },
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comparison saved ✓'), backgroundColor: Color(0xFF00C896)));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    return _buildResult();
  }

  // ── LOADING ───────────────────────────────────────────────
  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
            child: const Icon(Icons.compare_arrows_rounded, size: 24, color: Color(0xFF00C896))),
        ])),
        const SizedBox(height: 40),
        const Text('Artha is comparing both products', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        AnimatedSwitcher(duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim,
            child: SlideTransition(position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim), child: child)),
          child: Text(_hints[_hintIndex], key: ValueKey(_hintIndex),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 15), textAlign: TextAlign.center)),
      ])),
    );
  }

  Widget _buildError() {
    return Scaffold(backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(backgroundColor: const Color(0xFF0A0A0A), elevation: 0, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop())),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_outlined, color: Colors.white38, size: 48),
        const SizedBox(height: 16),
        const Text("Couldn't compare products", style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text('$_error', style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center)),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: () { setState(() { _isLoading = true; _error = null; }); _compare(); },
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00C896))),
          child: const Text('Retry', style: TextStyle(color: Color(0xFF00C896)))),
      ])));
  }

  // ── RESULT ────────────────────────────────────────────────
  Widget _buildResult() {
    final r = _result!;
    final w = r.winnerProduct;
    final l = r.loserProduct;
    const teal = Color(0xFF00C896);

    Widget stagger(double s, double e, {required Widget child}) {
      if (_resultController == null) return child;
      return SlideTransition(position: _sSl(s, e), child: FadeTransition(opacity: _sOp(s, e), child: child));
    }

    Widget sectionLabel(String text) => Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.38), letterSpacing: 1.2));

    String cardTitle(ComparedProduct p) => p.brand;
    String cardSubtitle(ComparedProduct p) {
      final words = p.name.split(' ');
      if (words.length > 3) return words.skip(words.length > 6 ? 3 : 2).take(3).join(' ');
      return p.name;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: _showJumpButton ? Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: GestureDetector(
          onTap: _scrollToVerdict,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: teal.withValues(alpha: 0.40)),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: teal.withValues(alpha: 0.10), blurRadius: 12)],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Verdict', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: teal)),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, color: teal, size: 16),
            ]),
          ),
        ),
      ) : null,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(children: [
          // App bar
          SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()),
              const Expanded(child: Text('Comparison Result', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
            ]))),

          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Corruption banner
            if (r.profileDataCorrupted) ...[
              _CorruptionBanner(onFix: () => context.push('/profile/edit')),
              const SizedBox(height: 12),
            ],

            // ── WINNER DISPLAY — Brand, not product name ──
            stagger(0.0, 0.25, child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🏆 ', style: TextStyle(fontSize: 20)),
                Flexible(child: Text('${w.brand} wins',
                  style: const TextStyle(color: teal, fontSize: 20, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(w.name,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 13),
                  maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
            ])),

            const SizedBox(height: 20),

            // ── SCORE CARDS — Brand as primary title ──
            stagger(0.15, 0.40, child: Row(children: [
              Expanded(child: _ProductScoreCard(product: r.product1, isWinner: r.winner == 1, title: cardTitle(r.product1), subtitle: cardSubtitle(r.product1))),
              const SizedBox(width: 10),
              Expanded(child: _ProductScoreCard(product: r.product2, isWinner: r.winner == 2, title: cardTitle(r.product2), subtitle: cardSubtitle(r.product2))),
            ])),

            // ── FEATURE COMPARISON — Card-per-feature ──
            const SizedBox(height: 20),
            // Legend (split into two lines to prevent overflow with long brand names)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionLabel('FEATURE BREAKDOWN'),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: teal, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(r.product1.brand,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 14),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.30), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(r.product2.brand,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            stagger(0.30, 0.55, child: Column(
              children: r.comparisonTable.map((row) => _FeatureCard(
                row: row,
                p1Brand: r.product1.brand,
                p2Brand: r.product2.brand,
              )).toList(),
            )),

            // ── ARTHA'S FINAL VERDICT ──
            const SizedBox(height: 20),
            Container(key: _verdictKey, child: sectionLabel("ARTHA'S FINAL VERDICT")),
            const SizedBox(height: 8),
            stagger(0.45, 0.75, child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: teal.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: teal.withValues(alpha: 0.25))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  const CircleAvatar(radius: 14, backgroundColor: teal,
                    child: Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
                  const SizedBox(width: 10),
                  const Text('Artha recommends', style: TextStyle(color: teal, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                Container(width: double.infinity, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: teal.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
                  child: Text('Buy ${w.brand}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(height: 12),
                Text(r.winnerReason, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                Text(r.arthaInsight, style: const TextStyle(color: teal, fontSize: 13, fontStyle: FontStyle.italic, height: 1.5)),
              ]))),

            // ── WINNER BUY SECTION ──
            if (w.onlineListings.isNotEmpty) ...[
              const SizedBox(height: 20),
              _WinnerBuySection(
                winner: w,
                loser: l,
                onBuy: (url) => _launchUrl(url, fallbackProductName: '${w.brand} ${w.name}'),
              ),
            ] else ...[
              const SizedBox(height: 20),
              _SearchFallbackCard(
                brand: w.brand,
                fullName: '${w.brand} ${w.name}',
                onTap: () => _launchUrl('', fallbackProductName: '${w.brand} ${w.name}'),
              ),
            ],

            // SAVINGS CARD
            if (w.detectedPrice != null && l.detectedPrice != null && w.detectedPrice! < l.detectedPrice!) ...[
              const SizedBox(height: 12),
              _SavingsCard(
                amount: (l.detectedPrice! - w.detectedPrice!).toStringAsFixed(0),
                winnerName: w.brand,
                loserName: l.brand),
            ],

            // Actions
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _saveReport,
              icon: const Icon(Icons.bookmark_outline, size: 18),
              label: const Text('Save Comparison', maxLines: 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal, foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w600)))),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () { context.pop(); context.pop(); },
              icon: const Icon(Icons.compare_arrows_rounded, size: 18),
              label: const Text('Compare Others', maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                padding: const EdgeInsets.symmetric(vertical: 14)))),
            const SizedBox(height: 32),
          ])),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CORRUPTION BANNER
// ═══════════════════════════════════════════════════════════
class _CorruptionBanner extends StatelessWidget {
  final VoidCallback onFix;
  const _CorruptionBanner({required this.onFix});
  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFF9800);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: amber.withValues(alpha: 0.10),
        border: Border.all(color: amber.withValues(alpha: 0.30)), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.warning_amber_outlined, color: amber, size: 16),
        const SizedBox(width: 8),
        const Expanded(child: Text('Update your profile for personalised advice',
          style: TextStyle(color: Colors.white70, fontSize: 12))),
        TextButton(onPressed: onFix, child: const Text('Fix Now →', style: TextStyle(color: amber, fontSize: 12))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SCORE CARD — Brand as title, compact bars
// ═══════════════════════════════════════════════════════════
class _ProductScoreCard extends StatelessWidget {
  final ComparedProduct product;
  final bool isWinner;
  final String title;
  final String subtitle;
  const _ProductScoreCard({required this.product, required this.isWinner, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    final s = product.scores;
    final dims = [('Value', s.valueForMoney), ('Build', s.buildQuality), ('Brand', s.brandTrust),
        ('Features', s.featuresScore), ('Worth', s.longTermWorth)];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner ? teal.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isWinner ? teal.withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        // Brand name (primary)
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        // Short product type (secondary)
        Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 11),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        if (product.detectedPrice != null)
          Text('₹${product.detectedPrice!.toStringAsFixed(0)}', style: const TextStyle(color: teal, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Center(child: RichText(text: TextSpan(children: [
          TextSpan(text: s.overall.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300)),
          TextSpan(text: '/10', style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13)),
        ]))),
        Center(child: Text('Overall', style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 10))),
        const SizedBox(height: 8),
        // Compact bars — height 3px, font 10px
        ...dims.map((d) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
          SizedBox(width: 44, child: Text(d.$1, style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 10))),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: d.$2 / 10.0,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: isWinner ? teal : Colors.white38, minHeight: 3))),
          const SizedBox(width: 4),
          SizedBox(width: 14, child: Text(d.$2.toStringAsFixed(0),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 10))),
        ]))),
        const SizedBox(height: 6),
        // Top 2 pros only
        ...product.pros.take(2).map((p) => Text('✓ $p',
            style: TextStyle(color: isWinner ? teal : Colors.white38, fontSize: 11),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FEATURE CARD — One per comparison row
// ═══════════════════════════════════════════════════════════
class _FeatureCard extends StatelessWidget {
  final ComparisonRow row;
  final String p1Brand;
  final String p2Brand;
  const _FeatureCard({required this.row, required this.p1Brand, required this.p2Brand});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    final isTie = row.winner == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Feature header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          child: Row(children: [
            Expanded(child: Text(row.attribute.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.38), letterSpacing: 0.8))),
            if (isTie)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4)),
                child: Text('TIE', style: TextStyle(fontSize: 9,
                  fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.38))),
              ),
          ]),
        ),

        // Two value columns
        IntrinsicHeight(child: Row(children: [
          // P1
          Expanded(child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: row.winner == 1 ? teal.withValues(alpha: 0.08) : Colors.transparent,
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(p1Brand,
                  style: TextStyle(fontSize: 10,
                    color: row.winner == 1 ? teal : Colors.white.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (row.winner == 1) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.star_rounded, size: 10, color: teal),
                ],
              ]),
              const SizedBox(height: 4),
              Text(row.product1Value,
                style: TextStyle(fontSize: 13, height: 1.4,
                  color: row.winner == 1 ? Colors.white : Colors.white.withValues(alpha: 0.60),
                  fontWeight: row.winner == 1 ? FontWeight.w600 : FontWeight.w400)),
            ]),
          )),
          // P2
          Expanded(child: Container(
            padding: const EdgeInsets.all(12),
            color: row.winner == 2 ? teal.withValues(alpha: 0.08) : Colors.transparent,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(p2Brand,
                  style: TextStyle(fontSize: 10,
                    color: row.winner == 2 ? teal : Colors.white.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (row.winner == 2) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.star_rounded, size: 10, color: teal),
                ],
              ]),
              const SizedBox(height: 4),
              Text(row.product2Value,
                style: TextStyle(fontSize: 13, height: 1.4,
                  color: row.winner == 2 ? Colors.white : Colors.white.withValues(alpha: 0.60),
                  fontWeight: row.winner == 2 ? FontWeight.w600 : FontWeight.w400)),
            ]),
          )),
        ])),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WINNER BUY SECTION
// ═══════════════════════════════════════════════════════════
Color _platformColor(String p) {
  switch (p.toLowerCase()) {
    case 'amazon': return const Color(0xFFFF9900);
    case 'flipkart': return const Color(0xFF2874F0);
    case 'meesho': return const Color(0xFFF43397);
    default: return const Color(0xFF00C896);
  }
}

class _WinnerBuySection extends StatelessWidget {
  final ComparedProduct winner;
  final ComparedProduct loser;
  final void Function(String url) onBuy;
  const _WinnerBuySection({required this.winner, required this.loser, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    final listing = winner.onlineListings.first;
    final pc = _platformColor(listing.platform);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [teal.withValues(alpha: 0.12), teal.withValues(alpha: 0.04)],
        ),
        border: Border.all(color: teal.withValues(alpha: 0.30), width: 1.5),
        borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Icon(Icons.shopping_bag_outlined, color: teal, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Best price for ${winner.brand}',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        // Cheapest listing card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: pc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(listing.platform, style: TextStyle(color: pc, fontSize: 12, fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
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
                Text(listing.discount!, style: const TextStyle(color: teal, fontSize: 11)),
              if (listing.rating > 0)
                Text('★ ${listing.rating} · ${listing.reviewCount} reviews',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 11)),
            ])),
            SizedBox(height: 36, child: ElevatedButton(
              onPressed: () => onBuy(listing.url),
              style: ElevatedButton.styleFrom(
                backgroundColor: pc.withValues(alpha: 0.80), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Buy →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
          ]),
        ),
      ]),
    );
  }
}

class _SearchFallbackCard extends StatelessWidget {
  final String brand;
  final String fullName;
  final VoidCallback onTap;
  const _SearchFallbackCard({required this.brand, required this.fullName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [teal.withValues(alpha: 0.08), teal.withValues(alpha: 0.03)],
          ),
          border: Border.all(color: teal.withValues(alpha: 0.20)),
          borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.search_rounded, color: teal, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('Search $brand on Amazon →',
            style: const TextStyle(color: teal, fontSize: 13, fontWeight: FontWeight.w500))),
          const Icon(Icons.open_in_new_rounded, color: teal, size: 14),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SAVINGS CARD
// ═══════════════════════════════════════════════════════════
class _SavingsCard extends StatelessWidget {
  final String amount; final String winnerName; final String loserName;
  const _SavingsCard({required this.amount, required this.winnerName, required this.loserName});
  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: teal.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teal.withValues(alpha: 0.20))),
      child: Row(children: [
        const Icon(Icons.savings_outlined, color: teal, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('You save ₹$amount by choosing $winnerName',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          Text('over $loserName', style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 12)),
        ])),
      ]),
    );
  }
}
