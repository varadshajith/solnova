class AlertItem {
  final String id;
  final String message;
  final String? severity;
  final DateTime? timestamp;

  const AlertItem({required this.id, required this.message, this.severity, this.timestamp});

  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        id: (j['id'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        severity: j['severity']?.toString(),
        timestamp: j['timestamp'] != null ? DateTime.tryParse(j['timestamp'].toString()) : null,
      );
}
