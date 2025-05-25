/// 성능 최적화 관련 상수
class PerformanceConstants {
  // 캐시 관련 설정
  static const Duration defaultCacheExpiry = Duration(minutes: 5);
  static const Duration backgroundRefreshInterval = Duration(minutes: 3);

  // 데이터 로딩 관련 설정
  static const int maxConcurrentRequests = 5;
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration retryDelay = Duration(seconds: 2);
  static const int maxRetryAttempts = 3;

  // UI 관련 설정
  static const Duration skeletonAnimationDuration = Duration(
    milliseconds: 1500,
  );
  static const Duration debounceDelay = Duration(milliseconds: 300);

  // 페이지네이션 설정
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // 메모리 관리
  static const int maxCacheSize = 100; // 캐시할 최대 항목 수
  static const Duration memoryCleanupInterval = Duration(minutes: 10);
}

/// 성능 메트릭 수집을 위한 유틸리티
class PerformanceTracker {
  static final Map<String, Stopwatch> _stopwatches = {};
  static final Map<String, List<int>> _metrics = {};

  /// 성능 측정 시작
  static void startTimer(String key) {
    _stopwatches[key] = Stopwatch()..start();
  }

  /// 성능 측정 종료 및 기록
  static void endTimer(String key) {
    final stopwatch = _stopwatches[key];
    if (stopwatch != null) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      _metrics[key] ??= [];
      _metrics[key]!.add(duration);

      print('Performance: $key took ${duration}ms');
      _stopwatches.remove(key);
    }
  }

  /// 평균 성능 메트릭 조회
  static double getAverageTime(String key) {
    final times = _metrics[key];
    if (times == null || times.isEmpty) return 0.0;

    return times.reduce((a, b) => a + b) / times.length;
  }

  /// 성능 메트릭 리셋
  static void clearMetrics() {
    _metrics.clear();
    _stopwatches.clear();
  }

  /// 성능 요약 출력
  static void printSummary() {
    print('\n=== 성능 요약 ===');
    for (final entry in _metrics.entries) {
      final avg = getAverageTime(entry.key);
      final count = entry.value.length;
      print('${entry.key}: 평균 ${avg.toStringAsFixed(1)}ms ($count회 측정)');
    }
    print('================\n');
  }
}
