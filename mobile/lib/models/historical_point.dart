class HistoricalPoint {
  final DateTime time;
  final double value;

  const HistoricalPoint({required this.time, required this.value});

  factory HistoricalPoint.fromJson(Map<String, dynamic> j) => HistoricalPoint(
        time: DateTime.parse(j['time'].toString()),
        value: (j['value'] as num).toDouble(),
      );
}
