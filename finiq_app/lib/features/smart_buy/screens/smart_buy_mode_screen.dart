import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen A — Mode Selector: Analyse or Compare
/// Premium dark UI with staggered entry animations.
class SmartBuyModeScreen extends StatefulWidget {
  const SmartBuyModeScreen({super.key});

  @override
  State<SmartBuyModeScreen> createState() => _SmartBuyModeScreenState();
}

class _SmartBuyModeScreenState extends State<SmartBuyModeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _card1Slide;
  late Animation<double> _card1Opacity;
  late Animation<Offset> _card2Slide;
  late Animation<double> _card2Opacity;
  late Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _iconScale = Tween(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    _iconOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    _titleSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.5, curve: Curves.easeOut)));
    _titleOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.5, curve: Curves.easeOut)));
    _subtitleSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.55, curve: Curves.easeOut)));
    _subtitleOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.55, curve: Curves.easeOut)));
    _card1Slide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.7, curve: Curves.easeOut)));
    _card1Opacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.7, curve: Curves.easeOut)));
    _card2Slide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.8, curve: Curves.easeOut)));
    _card2Opacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.8, curve: Curves.easeOut)));
    _bottomOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Smart Buy Lens',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Subtle teal glow at top
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00C896).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Icon with layered glow
                FadeTransition(
                  opacity: _iconOpacity,
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00C896).withValues(alpha: 0.10),
                          ),
                        ),
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00C896).withValues(alpha: 0.20),
                          ),
                        ),
                        const Icon(Icons.document_scanner_outlined,
                            size: 28, color: Color(0xFF00C896)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleOpacity,
                    child: const Text('What do you want to do?',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                SlideTransition(
                  position: _subtitleSlide,
                  child: FadeTransition(
                    opacity: _subtitleOpacity,
                    child: const Text('Scan a product or compare two before buying',
                        style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.4),
                        textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(height: 36),

                // Card 1 — Analyse
                SlideTransition(
                  position: _card1Slide,
                  child: FadeTransition(
                    opacity: _card1Opacity,
                    child: _PressableCard(
                      onTap: () => context.push('/smart-buy/input', extra: 'single'),
                      child: _AnalyseCardContent(),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Card 2 — Compare
                SlideTransition(
                  position: _card2Slide,
                  child: FadeTransition(
                    opacity: _card2Opacity,
                    child: _PressableCard(
                      onTap: () => context.push('/smart-buy/input', extra: 'compare'),
                      child: _CompareCardContent(),
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom section
                FadeTransition(
                  opacity: _bottomOpacity,
                  child: Column(
                    children: [
                      Divider(color: Colors.white.withValues(alpha: 0.10), indent: 60, endIndent: 60),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14,
                              color: Colors.white.withValues(alpha: 0.30)),
                          const SizedBox(width: 6),
                          Text('Works with live camera or screenshots from any app',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PlatformBadge('Amazon'),
                          const SizedBox(width: 8),
                          _PlatformBadge('Flipkart'),
                          const SizedBox(width: 8),
                          _PlatformBadge('Meesho'),
                          const SizedBox(width: 8),
                          _PlatformBadge('Any App'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PRESSABLE CARD — scale on tap
// ═══════════════════════════════════════════════════════════
class _PressableCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _PressableCard({required this.onTap, required this.child});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CARD CONTENTS
// ═══════════════════════════════════════════════════════════
class _AnalyseCardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            teal.withValues(alpha: 0.15),
            teal.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: teal.withValues(alpha: 0.40), width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: teal.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.qr_code_scanner, size: 22, color: teal),
                ),
                const SizedBox(height: 14),
                const Text('Analyse a Product',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Get full quality & affordability report',
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FeatureChip('Quality Check', teal),
                    const SizedBox(width: 8),
                    _FeatureChip('Affordability', teal),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: teal),
        ],
      ),
    );
  }
}

class _CompareCardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Icon(Icons.compare_arrows_rounded, size: 22,
                      color: Colors.white.withValues(alpha: 0.70)),
                ),
                const SizedBox(height: 14),
                const Text('Compare Two Products',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Find which gives better value for money',
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FeatureChip('Side-by-side', Colors.white.withValues(alpha: 0.20),
                        textColor: Colors.white54),
                    const SizedBox(width: 8),
                    _FeatureChip('Winner Verdict', Colors.white.withValues(alpha: 0.20),
                        textColor: Colors.white54),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16,
              color: Colors.white.withValues(alpha: 0.38)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SMALL WIDGETS
// ═══════════════════════════════════════════════════════════
class _FeatureChip extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Color? textColor;
  const _FeatureChip(this.text, this.borderColor, {this.textColor});

  @override
  Widget build(BuildContext context) {
    final c = textColor ?? borderColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withValues(alpha: 0.30), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: c)),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final String name;
  const _PlatformBadge(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(name,
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
    );
  }
}
