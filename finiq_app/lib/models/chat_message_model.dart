enum MessageRole { artha, user }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isLoading;
  final EmbeddedData? embeddedData;
  final ActionCard? actionCard;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
    this.embeddedData,
    this.actionCard,
  });

  bool get isArtha => role == MessageRole.artha;
  bool get isUser => role == MessageRole.user;

  factory ChatMessage.artha(String content, {EmbeddedData? embedded, ActionCard? action}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.artha,
      content: content,
      timestamp: DateTime.now(),
      embeddedData: embedded,
      actionCard: action,
    );
  }

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.loading() {
    return ChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.artha,
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.artha,
      content: json['content'] ?? json['reply'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      embeddedData: json['embedded_data'] != null
          ? EmbeddedData.fromJson(json['embedded_data'])
          : null,
      actionCard: json['action_card'] != null
          ? ActionCard.fromJson(json['action_card'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role == MessageRole.user ? 'user' : 'artha',
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };
}

class EmbeddedData {
  final String type; // TABLE | MINI_STATS | CHART
  final String? title;
  final List<Map<String, String>>? tableRows;
  final List<MiniStat>? miniStats;

  const EmbeddedData({
    required this.type,
    this.title,
    this.tableRows,
    this.miniStats,
  });

  factory EmbeddedData.fromJson(Map<String, dynamic> json) {
    return EmbeddedData(
      type: json['type'] ?? 'TABLE',
      title: json['title'],
      tableRows: (json['table_rows'] as List<dynamic>?)
          ?.map((row) => Map<String, String>.from(row))
          .toList(),
      miniStats: (json['mini_stats'] as List<dynamic>?)
          ?.map((s) => MiniStat.fromJson(s))
          .toList(),
    );
  }
}

class MiniStat {
  final String label;
  final String value;
  final String? subLabel;
  final String colorHex;

  const MiniStat({
    required this.label,
    required this.value,
    this.subLabel,
    this.colorHex = '#00C896',
  });

  factory MiniStat.fromJson(Map<String, dynamic> json) {
    return MiniStat(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
      subLabel: json['sub_label'],
      colorHex: json['color_hex'] ?? '#00C896',
    );
  }
}

class ActionCard {
  final String title;
  final String value;
  final String primaryButtonLabel;
  final String? secondaryButtonLabel;

  const ActionCard({
    required this.title,
    required this.value,
    required this.primaryButtonLabel,
    this.secondaryButtonLabel,
  });

  factory ActionCard.fromJson(Map<String, dynamic> json) {
    return ActionCard(
      title: json['title'] ?? '',
      value: json['value'] ?? '',
      primaryButtonLabel: json['primary_button'] ?? 'YES, ADD TO PLAN',
      secondaryButtonLabel: json['secondary_button'],
    );
  }
}
