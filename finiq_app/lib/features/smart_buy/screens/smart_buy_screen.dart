import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../services/api_service.dart';

enum SmartBuyState { capture, analyzing, result, error }

class SmartBuyScreen extends ConsumerStatefulWidget {
  const SmartBuyScreen({super.key});
  @override
  ConsumerState<SmartBuyScreen> createState() => _SmartBuyScreenState();
}

class _SmartBuyScreenState extends ConsumerState<SmartBuyScreen> {
  SmartBuyState _state = SmartBuyState.capture;
  Map<String, dynamic>? _analysis;
  String? _errorMessage;
  String? _imageBase64;

  Future<void> _captureAndAnalyse(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 80);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    _imageBase64 = base64Encode(bytes);

    setState(() => _state = SmartBuyState.analyzing);

    try {
      final res = await ApiService.instance.postData('/smart-buy/compare', {
        'image_base64': _imageBase64,
      });

      if (res['success'] == true && res['analysis'] != null) {
        setState(() {
          _analysis = res['analysis'] as Map<String, dynamic>;
          _state = SmartBuyState.result;
        });
      } else {
        setState(() {
          _errorMessage = res['error'] ?? 'Analysis failed';
          _state = SmartBuyState.error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _state = SmartBuyState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Smart Buy Lens 🔍', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildState(),
      ),
    );
  }

  Widget _buildState() {
    switch (_state) {
      case SmartBuyState.capture:
        return _buildCaptureState();
      case SmartBuyState.analyzing:
        return _buildAnalyzingState();
      case SmartBuyState.result:
        return _buildResultState();
      case SmartBuyState.error:
        return _buildErrorState();
    }
  }

  // ── Capture State ─────────────────────────────────────────
  Widget _buildCaptureState() {
    return Center(
      key: const ValueKey('capture'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryTeal.withOpacity(0.2), AppColors.primaryTeal.withOpacity(0.05)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.photo_camera_rounded, color: AppColors.primaryTeal, size: 48),
            ).animate().scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            const Text('Smart Buy Lens', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            const Text(
              'Snap a product photo and Artha will tell you\nif it\'s worth buying based on your budget.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _captureAndAnalyse(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _captureAndAnalyse(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 20),
                label: const Text('From Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  side: const BorderSide(color: AppColors.primaryTeal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  // ── Analyzing State ───────────────────────────────────────
  Widget _buildAnalyzingState() {
    return Center(
      key: const ValueKey('analyzing'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80, height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryTeal.withOpacity(0.8)),
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2000.ms),
          const SizedBox(height: 32),
          const Text('Analysing product...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Checking prices across platforms', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Result State ──────────────────────────────────────────
  Widget _buildResultState() {
    final a = _analysis!;
    final verdict = a['verdict'] ?? 'BUY';
    final verdictColor = verdict == 'BUY'
        ? AppColors.successGreen
        : verdict == 'WAIT'
            ? AppColors.warningAmber
            : AppColors.dangerRed;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [verdictColor.withOpacity(0.15), AppColors.cardColor],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: verdictColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(verdict, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: verdictColor, letterSpacing: 4)),
                const SizedBox(height: 8),
                Text(a['product_identified'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text(a['estimated_price'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: verdictColor)),
                const SizedBox(height: 12),
                Text(a['verdict_reason'] ?? '', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 16),

          // Affordability Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('AFFORDABILITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
                    Text(a['affordability_label'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: verdictColor)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ((a['affordability_score'] ?? 5) as num).toDouble() / 10,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1F2937),
                    valueColor: AlwaysStoppedAnimation(verdictColor),
                  ),
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 16),

          // Alternatives
          if ((a['alternatives'] as List?)?.isNotEmpty ?? false) ...[
            const Text('ALTERNATIVES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            ...(a['alternatives'] as List).asMap().entries.map((entry) {
              final alt = entry.value as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('${entry.key + 1}', style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alt['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(alt['why'] ?? '', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(alt['price'] ?? '', style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: 200 + entry.key * 80)).fadeIn().slideX(begin: 0.05, end: 0);
            }),
          ],

          const SizedBox(height: 16),

          // Smart Tip
          if (a['smart_tip'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryTeal.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AppColors.primaryTeal, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(a['smart_tip'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic))),
                ],
              ),
            ).animate(delay: 400.ms).fadeIn(),

          const SizedBox(height: 24),

          // Scan Again Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                _state = SmartBuyState.capture;
                _analysis = null;
              }),
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: const Text('Scan Another Product', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Error State ───────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.dangerRed, size: 64),
            const SizedBox(height: 16),
            const Text('Analysis Failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Unknown error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => setState(() => _state = SmartBuyState.capture),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
