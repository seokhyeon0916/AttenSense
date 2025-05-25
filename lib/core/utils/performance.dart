import 'dart:io';

class PerformanceTracker {
  static final Map<String, Stopwatch> _stopwatches = {};
  static final Map<String, List<int>> _performanceHistory = {};
  static final Map<String, DateTime> _lastLogTime = {};

  /// 성능 측정 시작
  static void startMeasurement(String key) {
    _stopwatches[key] = Stopwatch()..start();
  }

  /// 성능 측정 종료 및 결과 반환
  static int endMeasurement(String key) {
    final stopwatch = _stopwatches[key];
    if (stopwatch == null) return 0;

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;

    // 기록 저장
    _performanceHistory.putIfAbsent(key, () => []);
    _performanceHistory[key]!.add(elapsedMs);

    // 최근 10개 기록만 유지
    if (_performanceHistory[key]!.length > 10) {
      _performanceHistory[key]!.removeAt(0);
    }

    _stopwatches.remove(key);
    return elapsedMs;
  }

  /// 성능 측정 및 로깅
  static Future<T> measureAsync<T>(
    String key,
    Future<T> Function() operation, {
    bool logResult = true,
    int? warnThresholdMs,
  }) async {
    startMeasurement(key);

    try {
      final result = await operation();
      final elapsedMs = endMeasurement(key);

      if (logResult) {
        _logPerformance(key, elapsedMs, warnThresholdMs);
      }

      return result;
    } catch (e) {
      endMeasurement(key);
      rethrow;
    }
  }

  /// 동기 작업 성능 측정
  static T measureSync<T>(
    String key,
    T Function() operation, {
    bool logResult = true,
    int? warnThresholdMs,
  }) {
    startMeasurement(key);

    try {
      final result = operation();
      final elapsedMs = endMeasurement(key);

      if (logResult) {
        _logPerformance(key, elapsedMs, warnThresholdMs);
      }

      return result;
    } catch (e) {
      endMeasurement(key);
      rethrow;
    }
  }

  /// 성능 로깅 (과도한 로깅 방지)
  static void _logPerformance(String key, int elapsedMs, int? warnThresholdMs) {
    final now = DateTime.now();
    final lastLog = _lastLogTime[key];

    // 같은 키에 대해 1초 이내 중복 로깅 방지
    if (lastLog != null && now.difference(lastLog).inSeconds < 1) {
      return;
    }

    _lastLogTime[key] = now;

    // 경고 임계값 체크
    if (warnThresholdMs != null && elapsedMs > warnThresholdMs) {
      print(
        '⚠️ PERFORMANCE WARNING: $key took ${elapsedMs}ms (threshold: ${warnThresholdMs}ms)',
      );
    } else {
      print('📊 PERFORMANCE: $key completed in ${elapsedMs}ms');
    }

    // 평균 성능 출력
    final history = _performanceHistory[key];
    if (history != null && history.length >= 3) {
      final average =
          (history.reduce((a, b) => a + b) / history.length).round();
      print(
        '📈 AVERAGE: $key averages ${average}ms over last ${history.length} runs',
      );
    }
  }

  /// 메모리 사용량 체크
  static void logMemoryUsage(String context) {
    try {
      // Android/iOS에서만 사용 가능
      if (Platform.isAndroid || Platform.isIOS) {
        print('💾 MEMORY: $context - Memory info available on device only');
      } else {
        print(
          '💾 MEMORY: $context - Memory monitoring on ${Platform.operatingSystem}',
        );
      }
    } catch (e) {
      print('💾 MEMORY: $context - Unable to get memory info: $e');
    }
  }

  /// 성능 통계 리포트
  static Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};

    for (final entry in _performanceHistory.entries) {
      final key = entry.key;
      final history = entry.value;

      if (history.isNotEmpty) {
        report[key] = {
          'count': history.length,
          'average': (history.reduce((a, b) => a + b) / history.length).round(),
          'min': history.reduce((a, b) => a < b ? a : b),
          'max': history.reduce((a, b) => a > b ? a : b),
          'latest': history.last,
        };
      }
    }

    return report;
  }

  /// 성능 기록 초기화
  static void clearHistory() {
    _performanceHistory.clear();
    _lastLogTime.clear();
    _stopwatches.clear();
  }
}

/// 성능 관련 상수
class PerformanceConstants {
  static const int dataLoadWarningMs = 2000; // 2초 이상 경고
  static const int uiRenderWarningMs = 500; // 0.5초 이상 경고
  static const int cacheHitTargetMs = 100; // 캐시 히트 목표 시간
  static const int backgroundTaskMs = 5000; // 백그라운드 작업 최대 시간

  // 메모리 관련
  static const int memoryCheckIntervalSec = 30; // 30초마다 메모리 체크
}
