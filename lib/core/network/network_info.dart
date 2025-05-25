import 'package:internet_connection_checker/internet_connection_checker.dart';

/// 네트워크 연결 상태를 확인하는 추상 클래스
abstract class NetworkInfo {
  /// 인터넷 연결 여부를 확인합니다.
  Future<bool> get isConnected;
}

/// [NetworkInfo]의 구현체
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  /// [InternetConnectionChecker]를 주입받는 생성자
  NetworkInfoImpl(this.connectionChecker);

  @override
  // 테스트를 위해 항상 인터넷 연결이 있다고 가정
  Future<bool> get isConnected async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      print('NetworkInfo: 인터넷 연결 확인 - $hasConnection');
      return hasConnection;
    } catch (e) {
      print('NetworkInfo: 인터넷 연결 확인 중 오류 - $e');
      // 오류 발생 시에는 네트워크 문제로 간주
      return false;
    }
  }
}
