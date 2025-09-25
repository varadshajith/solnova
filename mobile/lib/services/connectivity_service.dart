import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final connectivityStreamProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  // Emit initial state
  final initial = await connectivity.checkConnectivity();
  yield initial != ConnectivityResult.none;

  // Listen for changes
  yield* connectivity.onConnectivityChanged.map((event) => event != ConnectivityResult.none);
});