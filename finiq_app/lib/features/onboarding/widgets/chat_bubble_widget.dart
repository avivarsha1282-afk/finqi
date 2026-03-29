import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/chat_message_model.dart';

class ChatBubbleWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatBubbleWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) return _LoadingBubble();
    return message.isArtha ? _ArthaBubble(message: message) : _UserBubble(message: message);
  }
}

class _ArthaBubble extends StatelessWidget {
  final ChatMessage message;
  const _ArthaBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryTeal),
            child: const Center(child: Text('A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black))),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: _buildContent(),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: AppTextStyles.chatMeta,
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichText(message.content),
        if (message.embeddedData?.miniStats != null) ...[
          const SizedBox(height: 12),
          _MiniStatsRow(stats: message.embeddedData!.miniStats!),
        ],
        if (message.embeddedData?.tableRows != null) ...[
          const SizedBox(height: 12),
          _EmbeddedTable(rows: message.embeddedData!.tableRows!),
        ],
        if (message.actionCard != null) ...[
          const SizedBox(height: 12),
          _ActionCardWidget(card: message.actionCard!),
        ],
      ],
    );
  }

  Widget _buildRichText(String text) {
    // Highlight ₹ amounts in teal 
    final spans = <TextSpan>[];
    final regex = RegExp(r'₹[\d,\.]+[LKCr]*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(color: AppColors.primaryTeal, fontFamily: 'monospace', fontWeight: FontWeight.w600),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: AppTextStyles.chatText,
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 40),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F2937),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(message.content, style: AppTextStyles.chatText),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(message.timestamp)} ✓✓',
                  style: AppTextStyles.chatMeta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

class _LoadingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryTeal),
            child: const Center(child: Text('A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black))),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.cardElevated,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: _TypingIndicator(),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (offset < 0.5) ? offset * 2 : (1 - offset) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _MiniStatsRow extends StatelessWidget {
  final List<dynamic> stats;
  const _MiniStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.take(2).map<Widget>((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label ?? '', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  s.value ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(int.parse((s.colorHex ?? '#00C896').replaceAll('#', '0xFF'))),
                    fontFamily: 'monospace',
                  ),
                ),
                if (s.subLabel != null)
                  Text(s.subLabel!, style: AppTextStyles.caption),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmbeddedTable extends StatelessWidget {
  final List<Map<String, String>> rows;
  const _EmbeddedTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final headers = rows.first.keys.toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
        children: [
          TableRow(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderColor))),
            children: headers.map((h) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(h, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 0.5)),
            )).toList(),
          ),
          ...rows.skip(1).map((row) => TableRow(
            children: headers.map((h) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(row[h] ?? '', style: AppTextStyles.bodySmall),
            )).toList(),
          )),
        ],
      ),
    );
  }
}

class _ActionCardWidget extends StatelessWidget {
  final ActionCard card;
  const _ActionCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.title, style: AppTextStyles.label.copyWith(color: AppColors.primaryTeal)),
          const SizedBox(height: 4),
          Text(card.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primaryTeal, fontFamily: 'monospace')),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () {}, child: Text(card.primaryButtonLabel, style: const TextStyle(fontSize: 14))),
          if (card.secondaryButtonLabel != null) ...[
            const SizedBox(height: 6),
            OutlinedButton(onPressed: () {}, child: Text(card.secondaryButtonLabel!, style: const TextStyle(fontSize: 14))),
          ],
        ],
      ),
    );
  }
}
