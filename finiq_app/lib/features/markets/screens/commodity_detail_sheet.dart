import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/market_models.dart';
import '../services/markets_service.dart';

const _teal = Color(0xFF00C896);
const _red = Color(0xFFEF4444);

String _fmtPrice(double p) => '₹${NumberFormat('#,##,###', 'en_IN').format(p.round())}';

/// Bottom sheet with chart for commodity detail (Gold, Silver, Crude, NatGas)
class CommodityDetailSheet extends StatefulWidget {
  final String name;
  final CommodityQuote quote;
  const CommodityDetailSheet({super.key, required this.name, required this.quote});
  @override
  State<CommodityDetailSheet> createState() => _CommodityDetailSheetState();
}

class _CommodityDetailSheetState extends State<CommodityDetailSheet> {
  String _selectedPeriod = '1mo';
  bool _loadingChart = true;
  ChartData? _chartData;

  static const _symbols = {'Gold': 'GC=F', 'Silver': 'SI=F', 'Crude Oil': 'CL=F', 'Natural Gas': 'NG=F'};
  static const _emojis = {'Gold': '💛', 'Silver': '⚪', 'Crude Oil': '🛢️', 'Natural Gas': '🔥'};
  static const _periods = ['1mo', '3mo', '6mo', '1y'];
  static const _periodLabels = {'1mo': '1 month', '3mo': '3 months', '6mo': '6 months', '1y': '1 year'};
  static const _notes = {
    'Gold': 'Indicative 24K gold price (pre-GST). Retail prices include 3% GST + making charges. Source: COMEX Gold Futures.',
    'Silver': 'Indicative silver price (per kg). Retail price varies with local taxes. Source: COMEX Silver Futures.',
    'Crude Oil': 'WTI Crude Oil futures price per barrel. Domestic petrol/diesel prices are regulated by the Indian government.',
    'Natural Gas': 'NYMEX Natural Gas futures (per MMBtu). Domestic PNG/CNG prices are separately regulated.',
  };

  @override
  void initState() { super.initState(); _loadChart(_selectedPeriod); }

  Future<void> _loadChart(String period) async {
    setState(() { _loadingChart = true; _selectedPeriod = period; });
    try {
      final sym = _symbols[widget.name] ?? 'GC=F';
      final data = await MarketsService.instance.getChart(symbol: sym, period: period);
      if (mounted) setState(() { _chartData = data; _loadingChart = false; });
    } catch (_) { if (mounted) setState(() => _loadingChart = false); }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    final c = q.isPositive ? _teal : _red;
    final sign = q.isPositive ? '+' : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.70, maxChildSize: 0.92, minChildSize: 0.40,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: _teal.withValues(alpha: 0.20)))),
        child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
          // Drag handle
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          // Header
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(_emojis[widget.name] ?? '📊', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(widget.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
              const SizedBox(height: 4),
              Text(q.unit, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmtPrice(q.priceINR),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(q.isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                  color: c, size: 16),
                Text('$sign${q.changePct.toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c)),
              ]),
            ]),
          ]),
          const SizedBox(height: 12),
          // International reference
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Text('USD: \$${q.current.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.54))),
            ]),
          ),
          const SizedBox(height: 16),
          // Period selector
          Row(children: _periods.map((p) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _loadChart(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedPeriod == p ? _teal.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedPeriod == p ? _teal : Colors.white.withValues(alpha: 0.12),
                    width: _selectedPeriod == p ? 1.5 : 1)),
                child: Text(_shortLabel(p),
                  style: TextStyle(fontSize: 12, fontWeight: _selectedPeriod == p ? FontWeight.w700 : FontWeight.w400,
                    color: _selectedPeriod == p ? _teal : Colors.white.withValues(alpha: 0.38))),
              ),
            ),
          )).toList()),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 200,
            child: _loadingChart
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _teal))
              : (_chartData != null && _chartData!.candles.isNotEmpty)
                ? _buildChart(_chartData!)
                : Center(child: Text('Chart unavailable', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.38)))),
          ),
          // Period performance
          if (_chartData != null && _chartData!.candles.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPerfRow(_chartData!),
          ],
          const SizedBox(height: 20),
          // Stats grid
          Row(children: [
            _StatCard(label: 'USD Price', value: '\$${q.current.toStringAsFixed(2)}'),
            const SizedBox(width: 10),
            _StatCard(label: 'Day Change', value: '$sign${q.changePct.toStringAsFixed(2)}%'),
          ]),
          const SizedBox(height: 16),
          // Info note
          if (_notes[widget.name] != null) Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              border: Border(left: BorderSide(color: _teal.withValues(alpha: 0.40), width: 3)),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))),
            child: Text(_notes[widget.name]!, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.54), height: 1.5)),
          ),
          const SizedBox(height: 16),
          Center(child: Text('Prices delayed ~15 min · Data via Yahoo Finance',
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.24)))),
        ]),
      ),
    );
  }

  String _shortLabel(String p) => {'1mo': '1M', '3mo': '3M', '6mo': '6M', '1y': '1Y'}[p] ?? p;

  Widget _buildChart(ChartData data) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.candles.length; i++) {
      spots.add(FlSpot(i.toDouble(), data.candles[i].close));
    }
    final isPos = data.isPositive;
    final color = isPos ? _teal : _red;
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1A1A1A),
          getTooltipItems: (spots) => spots.map((s) =>
            LineTooltipItem('\$${s.y.toStringAsFixed(2)}', TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))).toList(),
        ),
      ),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, color: color, barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true,
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)])),
      )],
    ));
  }

  Widget _buildPerfRow(ChartData data) {
    final change = data.change;
    final pct = data.changePct;
    final isPos = change >= 0;
    final c = isPos ? _teal : _red;
    final sign = isPos ? '+' : '';
    return Row(children: [
      Text('$sign\$${change.abs().toStringAsFixed(2)}',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Text('$sign${pct.toStringAsFixed(2)}%',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
      ),
      const SizedBox(width: 8),
      Text('in ${_periodLabels[_selectedPeriod] ?? _selectedPeriod}',
        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label; final String value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
    ]),
  ));
}
