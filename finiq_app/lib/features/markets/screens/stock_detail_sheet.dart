import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/market_models.dart';
import '../providers/markets_providers.dart';
import '../services/markets_service.dart';

const _teal = Color(0xFF00C896);
const _red = Color(0xFFF44336);

class StockDetailSheet extends ConsumerStatefulWidget {
  final StockQuote quote;
  const StockDetailSheet({super.key, required this.quote});
  @override
  ConsumerState<StockDetailSheet> createState() => _StockDetailSheetState();
}

class _StockDetailSheetState extends ConsumerState<StockDetailSheet> {
  StockQuote? _detail;
  bool _loadingDetail = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() async {
    try {
      final detail = await MarketsService.instance.getStockDetail(widget.quote.symbol);
      if (mounted) setState(() { _detail = detail; _loadingDetail = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  String _fmtPrice(double p) {
    if (p >= 1000) return '₹${NumberFormat('#,##0', 'en_IN').format(p.round())}';
    return '₹${p.toStringAsFixed(2)}';
  }

  String _fmtVol(int v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)} Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)} L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} K';
    return '$v';
  }

  String _fmtMarketCap(int? mc) {
    if (mc == null) return 'N/A';
    final cr = mc / 10000000;
    if (cr >= 100000) return '₹${(cr / 100000).toStringAsFixed(1)}L Cr';
    if (cr >= 1000) return '₹${NumberFormat('#,##0', 'en_IN').format(cr.round())} Cr';
    return '₹${cr.toStringAsFixed(0)} Cr';
  }

  String _microInsight(String name, double pct, double high, double low, double current) {
    if (pct > 3) return 'Strong momentum today. Monitor for continuation above ${_fmtPrice(high)}.';
    if (pct < -3) return 'Under pressure today. Watch ${_fmtPrice(low)} as support level.';
    if (pct.abs() < 1) return 'Consolidating near ${_fmtPrice(current)}. Low volatility session.';
    if (pct > 0) return 'Positive bias today. Next resistance near ${_fmtPrice(high)}.';
    return 'Mild selling pressure. Support near ${_fmtPrice(low)}.';
  }

  @override
  Widget build(BuildContext context) {
    final q = _detail ?? widget.quote;
    final c = q.isPositive ? _teal : _red;
    final sign = q.isPositive ? '+' : '';
    final isWatching = ref.watch(watchlistProvider).any((s) => s.symbol == q.symbol);

    return DraggableScrollableSheet(
      initialChildSize: 0.7, maxChildSize: 0.92, minChildSize: 0.4,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A)))),
        child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(20, 14, 20, 32), children: [
          // Drag handle
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          // Header
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(q.cleanSymbol, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.38))),
            ])),
            IconButton(
              icon: Icon(isWatching ? Icons.bookmark_rounded : Icons.bookmark_border_outlined,
                color: isWatching ? _teal : Colors.white.withValues(alpha: 0.38), size: 24),
              onPressed: () {
                final n = ref.read(watchlistProvider.notifier);
                isWatching ? n.removeStock(q.symbol) : n.addStock(WatchlistStock(symbol: q.symbol, displayName: q.displayName));
              }),
          ]),
          const SizedBox(height: 20),

          // Price
          Text(_fmtPrice(q.current), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text('$sign${q.change.toStringAsFixed(2)} ($sign${q.changePct.toStringAsFixed(2)}%)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c))),
            const SizedBox(width: 8),
            Flexible(child: Text('vs prev close ${_fmtPrice(q.prevClose)}',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38)), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 24),

          // Large sparkline
          if (q.sparkline.length >= 2) ...[
            SizedBox(height: 180, child: CustomPaint(
              painter: _LargeSparkPainter(data: q.sparkline, isPositive: q.isPositive, prevClose: q.prevClose),
              size: Size.infinite)),
            const SizedBox(height: 24),
          ],

          // Day stats
          Row(children: [
            Expanded(child: _StatCell(label: 'Day High', value: _fmtPrice(q.high))),
            const SizedBox(width: 12),
            Expanded(child: _StatCell(label: 'Day Low', value: _fmtPrice(q.low))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCell(label: 'Avg Volume', value: _fmtVol(q.volume))),
            const SizedBox(width: 12),
            Expanded(child: _StatCell(label: 'Prev Close', value: _fmtPrice(q.prevClose))),
          ]),

          // 52-week range
          if (!_loadingDetail && q.week52High > 0 && q.week52Low > 0) ...[
            const SizedBox(height: 20),
            Text('52-WEEK RANGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.38), letterSpacing: 0.8)),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (_, constraints) {
              final barW = constraints.maxWidth - 100; // space for labels
              final range = q.week52High - q.week52Low;
              final pos = range > 0 ? ((q.current - q.week52Low) / range).clamp(0.0, 1.0) : 0.5;
              final pctFrom52H = q.week52High > 0 ? ((q.week52High - q.current) / q.week52High * 100) : 0;
              return Column(children: [
                Row(children: [
                  SizedBox(width: 50, child: Text(_fmtPrice(q.week52Low), style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.54)))),
                  Expanded(child: SizedBox(height: 16, child: Stack(children: [
                    Positioned(top: 5, left: 0, right: 0, child: Container(height: 4,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(2)))),
                    Positioned(top: 2, left: pos * (barW > 0 ? barW : constraints.maxWidth - 112),
                      child: Container(width: 12, height: 12,
                        decoration: BoxDecoration(color: _teal, shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0A0A0A), width: 2)))),
                  ]))),
                  SizedBox(width: 50, child: Text(_fmtPrice(q.week52High),
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.54)), textAlign: TextAlign.right)),
                ]),
                const SizedBox(height: 6),
                Text('Current: ${_fmtPrice(q.current)} · ${pctFrom52H.toStringAsFixed(1)}% from year high',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
              ]);
            }),
          ],

          // PE + Market Cap
          if (!_loadingDetail && (q.pe != null || q.marketCap != null)) ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _StatCell(label: 'P/E Ratio', value: q.pe != null ? q.pe!.toStringAsFixed(1) : 'N/A')),
              const SizedBox(width: 12),
              Expanded(child: _StatCell(label: 'Market Cap', value: _fmtMarketCap(q.marketCap))),
            ]),
          ],

          // Loading indicator for detail data
          if (_loadingDetail) ...[
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white.withValues(alpha: 0.24))),
              const SizedBox(width: 8),
              Text('Loading extended data...', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.24))),
            ]),
          ],

          // Artha micro-insight
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.06),
              border: Border.all(color: _teal.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CircleAvatar(radius: 12, backgroundColor: _teal,
                child: Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10))),
              const SizedBox(width: 8),
              Expanded(child: Text(_microInsight(q.displayName, q.changePct, q.high, q.low, q.current),
                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5))),
            ])),

          const SizedBox(height: 16),
          Text('Prices delayed ~15 min · Data via Yahoo Finance',
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.20)), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}


class _StatCell extends StatelessWidget {
  final String label; final String value;
  const _StatCell({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
    ]));
}


class _LargeSparkPainter extends CustomPainter {
  final List<double> data; final bool isPositive; final double prevClose;
  _LargeSparkPainter({required this.data, required this.isPositive, required this.prevClose});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final c = isPositive ? _teal : _red;
    final mn = data.reduce(min); final mx = data.reduce(max); final r = mx - mn;
    if (r == 0) return;

    if (prevClose >= mn && prevClose <= mx) {
      final ry = size.height - ((prevClose - mn) / r) * size.height;
      canvas.drawLine(Offset(0, ry), Offset(size.width, ry),
        Paint()..color = Colors.white.withValues(alpha: 0.10)..strokeWidth = 1);
    }

    final path = Path(); final fill = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - mn) / r) * size.height;
      if (i == 0) { path.moveTo(x, y); fill.moveTo(x, size.height); fill.lineTo(x, y); }
      else { path.lineTo(x, y); fill.lineTo(x, y); }
    }
    fill.lineTo(size.width, size.height); fill.close();

    canvas.drawPath(fill, Paint()..color = c.withValues(alpha: 0.10)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = c..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    final lastX = size.width;
    final lastY = size.height - ((data.last - mn) / r) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = c);
  }
  @override
  bool shouldRepaint(covariant _LargeSparkPainter old) => old.data != data;
}
