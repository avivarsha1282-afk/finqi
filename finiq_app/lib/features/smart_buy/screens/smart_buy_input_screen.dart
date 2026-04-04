import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Screen B — Product Input: Camera or Gallery capture.
/// Premium upload zone with compare mode progress indicator.
class SmartBuyInputScreen extends StatefulWidget {
  final String mode; // 'single' or 'compare'
  const SmartBuyInputScreen({super.key, required this.mode});

  @override
  State<SmartBuyInputScreen> createState() => _SmartBuyInputScreenState();
}

class _SmartBuyInputScreenState extends State<SmartBuyInputScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  int _currentProduct = 1;
  Uint8List? _currentImageBytes;
  Uint8List? _product1Bytes; // keep product 1 image for thumbnail
  final List<Uint8List> _scannedProducts = [];
  bool _isLoading = false;

  // Pulsing icon animation
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  bool get _isCompare => widget.mode == 'compare';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseScale = Tween(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      // Fresh picker instance every time (prevents caching issues)
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _currentImageBytes = bytes);
      }
    } catch (e) {
      debugPrint('IMAGE PICKER ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _clearImage() {
    setState(() => _currentImageBytes = null);
  }

  void _confirmProduct() {
    if (_currentImageBytes == null) return;

    _scannedProducts.add(_currentImageBytes!);

    if (!_isCompare || _currentProduct == 2) {
      // Navigate to result
      if (_isCompare) {
        context.push('/smart-buy/result/compare', extra: _scannedProducts);
      } else {
        context.push('/smart-buy/result/single', extra: _scannedProducts);
      }
    } else {
      // Save product 1 bytes for thumbnail, move to product 2
      setState(() {
        _product1Bytes = _currentImageBytes;
        _currentProduct = 2;
        _currentImageBytes = null;
      });
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _goBackToProduct1() {
    setState(() {
      _currentProduct = 1;
      _currentImageBytes = _product1Bytes;
      _product1Bytes = null;
      _scannedProducts.clear();
    });
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
        title: Text(
          _isCompare ? 'Compare Products' : 'Analyse Product',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Subtle teal glow
          Positioned(
            top: -60, left: 0, right: 0,
            child: Center(
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF00C896).withValues(alpha: 0.06),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compare progress indicator
                        if (_isCompare) ...[
                          const SizedBox(height: 8),
                          _CompareProgressIndicator(currentProduct: _currentProduct),
                          const SizedBox(height: 16),
                        ],

                        // Animated title
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            _isCompare
                                ? (_currentProduct == 1 ? 'Scan Product 1' : 'Now scan Product 2')
                                : 'Scan or share your product',
                            key: ValueKey('title_$_currentProduct'),
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Point your camera at the product label, or share a screenshot from Amazon, Flipkart, or any store',
                          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                        ),

                        const SizedBox(height: 24),

                        // Upload zone
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                          child: _currentImageBytes == null
                              ? _buildEmptyUploadZone()
                              : _buildImagePreview(),
                        ),

                        const SizedBox(height: 20),

                        // Camera & Gallery buttons
                        Row(
                          children: [
                            Expanded(child: _InputButton(
                              onTap: () => _pickImage(ImageSource.camera),
                              icon: Icons.camera_alt_outlined,
                              iconColor: const Color(0xFF00C896),
                              bgColor: const Color(0xFF00C896).withValues(alpha: 0.12),
                              borderColor: const Color(0xFF00C896).withValues(alpha: 0.30),
                              label: 'Camera',
                              sublabel: 'Take photo',
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _InputButton(
                              onTap: () => _pickImage(ImageSource.gallery),
                              icon: Icons.photo_library_outlined,
                              iconColor: Colors.white.withValues(alpha: 0.60),
                              bgColor: Colors.white.withValues(alpha: 0.04),
                              borderColor: Colors.white.withValues(alpha: 0.10),
                              label: 'Gallery',
                              sublabel: 'Pick screenshot',
                            )),
                          ],
                        ),

                        // Product 1 thumbnail (compare mode, product 2)
                        if (_isCompare && _currentProduct == 2 && _product1Bytes != null) ...[
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _goBackToProduct1,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(_product1Bytes!,
                                        width: 48, height: 48, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Product 1 scanned ✓',
                                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                        Text('Tap to change',
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.edit_outlined, color: Colors.white.withValues(alpha: 0.24), size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],

                        if (_isLoading) ...[
                          const SizedBox(height: 16),
                          const Center(child: CircularProgressIndicator(color: Color(0xFF00C896))),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Confirm button pinned to bottom
                AnimatedSlide(
                  offset: _currentImageBytes != null ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _currentImageBytes != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _currentImageBytes != null ? _confirmProduct : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C896),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            _getConfirmLabel(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getConfirmLabel() {
    if (!_isCompare) return 'Analyse This Product →';
    if (_currentProduct == 1) return 'Next: Scan Product 2 →';
    return 'Compare Both Products →';
  }

  Widget _buildEmptyUploadZone() {
    return Container(
      key: const ValueKey('empty'),
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseScale,
            child: Icon(Icons.add_photo_alternate_outlined,
                size: 48, color: Colors.white.withValues(alpha: 0.24)),
          ),
          const SizedBox(height: 12),
          Text('Tap below to add product',
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.38))),
          const SizedBox(height: 4),
          Text('Camera or screenshot both work',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.24))),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      key: const ValueKey('preview'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            _currentImageBytes!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Gradient overlay at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.87), Colors.transparent],
              ),
            ),
          ),
        ),
        // Product label
        Positioned(
          bottom: 12, left: 12,
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF00C896), size: 16),
              const SizedBox(width: 6),
              Text('Product $_currentProduct ready',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        // Close button
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: _clearImage,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.54),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// COMPARE PROGRESS INDICATOR
// ═══════════════════════════════════════════════════════════
class _CompareProgressIndicator extends StatelessWidget {
  final int currentProduct;
  const _CompareProgressIndicator({required this.currentProduct});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00C896);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Step 1
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentProduct >= 2 ? teal : teal.withValues(alpha: 0.15),
                  border: currentProduct == 1 ? Border.all(color: teal, width: 2) : null,
                ),
                child: Center(
                  child: currentProduct >= 2
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : const Text('1', style: TextStyle(color: teal, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 4),
              Text('Product 1', style: TextStyle(fontSize: 10,
                  color: currentProduct == 1 ? teal : Colors.white.withValues(alpha: 0.38))),
            ],
          ),
          // Connector
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              margin: const EdgeInsets.only(bottom: 16),
              color: currentProduct >= 2 ? teal : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          // Step 2
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentProduct == 2 ? teal.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06),
                  border: currentProduct == 2
                      ? Border.all(color: teal, width: 2)
                      : Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Center(
                  child: Text('2', style: TextStyle(
                      color: currentProduct == 2 ? teal : Colors.white.withValues(alpha: 0.38),
                      fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 4),
              Text('Product 2', style: TextStyle(fontSize: 10,
                  color: currentProduct == 2 ? teal : Colors.white.withValues(alpha: 0.38))),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// INPUT BUTTON
// ═══════════════════════════════════════════════════════════
class _InputButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String label;
  final String sublabel;
  const _InputButton({
    required this.onTap, required this.icon, required this.iconColor,
    required this.bgColor, required this.borderColor,
    required this.label, required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(sublabel, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
