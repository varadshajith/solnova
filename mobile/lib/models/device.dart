class DeviceItem {
  final String id;
  final String name;
  final String? status; // Connected/Disconnected
  final DateTime? lastSeen;
  // Optional detail fields
  final String? type;
  final String? firmware;

  const DeviceItem({required this.id, required this.name, this.status, this.lastSeen, this.type, this.firmware});

  factory DeviceItem.fromJson(Map<String, dynamic> j) => DeviceItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        status: j['status']?.toString(),
        lastSeen: j['last_seen'] != null ? DateTime.tryParse(j['last_seen'].toString()) : null,
        type: j['type']?.toString(),
        firmware: j['firmware']?.toString(),
      );
}
