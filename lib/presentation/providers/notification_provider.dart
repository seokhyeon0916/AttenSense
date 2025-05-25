import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  // 임시 알림 데이터
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': '캡스톤 디자인 수업에 2명의 학생이 비활동 상태입니다',
      'message': '학생 이름: 김학생, 이학생 - 15분 이상 움직임이 감지되지 않았습니다.',
      'time': '오늘 14:30',
      'icon': Icons.warning,
      'color': const Color(0xFFF59E0B), // AppColors.warningColor,
      'isRead': false,
      'type': 'inactivity',
      'courseId': 'cap_design_2023',
      'courseName': '캡스톤 디자인',
    },
    {
      'id': '2',
      'title': '데이터베이스 수업이 10분 후에 시작됩니다',
      'message': '오후 1시부터 데이터베이스 수업이 시작됩니다. 수업 준비를 완료해주세요.',
      'time': '오늘 12:50',
      'icon': Icons.notifications,
      'color': const Color(0xFF3B82F6), // AppColors.primaryColor,
      'isRead': true,
      'type': 'reminder',
      'courseId': 'database_2023',
      'courseName': '데이터베이스',
    },
    {
      'id': '3',
      'title': '캡스톤 디자인 수업 출석이 완료되었습니다',
      'message': '총 30명 중 28명 출석, 1명 지각, 1명 결석으로 기록되었습니다.',
      'time': '어제 12:15',
      'icon': Icons.check_circle,
      'color': const Color(0xFF10B981), // AppColors.successColor,
      'isRead': true,
      'type': 'attendance',
      'courseId': 'cap_design_2023',
      'courseName': '캡스톤 디자인',
    },
    {
      'id': '4',
      'title': '시스템 업데이트 안내',
      'message':
          '이번 주 금요일 오후 11시부터 시스템 업데이트가 진행됩니다. 업데이트 중에는 서비스 이용이 제한될 수 있습니다.',
      'time': '2일 전 09:00',
      'icon': Icons.system_update,
      'color': const Color(0xFF3B82F6), // AppColors.primaryColor,
      'isRead': false,
      'type': 'system',
      'courseId': null,
      'courseName': null,
    },
    {
      'id': '5',
      'title': '데이터베이스 수업 자료가 업로드되었습니다',
      'message': '오늘 수업에 사용된 자료가 업로드되었습니다. 학생들에게 공지가 전달되었습니다.',
      'time': '3일 전 16:20',
      'icon': Icons.upload_file,
      'color': const Color(0xFF3B82F6), // AppColors.primaryColor,
      'isRead': true,
      'type': 'material',
      'courseId': 'database_2023',
      'courseName': '데이터베이스',
    },
  ];

  // 알림 목록 가져오기
  List<Map<String, dynamic>> get notifications => _notifications;

  // 읽지 않은 알림 개수 계산
  int get unreadCount => _notifications.where((n) => !n['isRead']).length;

  // 알림 읽음 표시
  void markAsRead(String id) {
    final notificationIndex = _notifications.indexWhere((n) => n['id'] == id);
    if (notificationIndex != -1) {
      _notifications[notificationIndex]['isRead'] = true;
      notifyListeners();
    }
  }

  // 모든 알림 읽음 표시
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['isRead'] = true;
    }
    notifyListeners();
  }

  // 알림 추가 (새 알림이 생성될 때 사용)
  void addNotification(Map<String, dynamic> notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  // 알림 전체 삭제
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
