import 'realtime_summary.dart';

class SummaryResult {
  final bool fromCache;
  final RealtimeSummary data;
  const SummaryResult({required this.data, required this.fromCache});
}
