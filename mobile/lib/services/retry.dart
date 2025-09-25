import 'dart:async';

Future<T> retryAsync<T>(Future<T> Function() fn, {int retries = 3, List<Duration>? delays}) async {
  delays ??= const [Duration(milliseconds: 200), Duration(milliseconds: 500), Duration(milliseconds: 1000)];
  int attempt = 0;
  while (true) {
    try {
      return await fn();
    } catch (e) {
      if (attempt >= retries - 1) rethrow;
      await Future.delayed(delays[attempt < delays.length ? attempt : delays.length - 1]);
      attempt++;
    }
  }
}