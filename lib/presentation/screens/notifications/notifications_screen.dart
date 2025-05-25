import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/widgets/app_card.dart';
import 'package:capston_design/widgets/app_divider.dart';
import 'package:capston_design/presentation/providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;
    final unreadCount = notificationProvider.unreadCount;

    void markAsRead(String id) {
      notificationProvider.markAsRead(id);
    }

    void clearAllNotifications() {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('모든 알림 지우기'),
              content: const Text('모든 알림을 지우시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    notificationProvider.clearAllNotifications();
                    Navigator.pop(context);
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
      );
    }

    void showNotificationDetail(Map<String, dynamic> notification) {
      // 알림을 읽음으로 표시
      markAsRead(notification['id']);

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    notification['icon'] as IconData,
                    color: notification['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notification['title'] as String,
                      style: AppTypography.subhead(context),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['message'] as String,
                    style: AppTypography.body(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '시간: ${notification['time'] as String}',
                    style: AppTypography.small(
                      context,
                    ).copyWith(color: Colors.grey),
                  ),
                  if (notification['courseName'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '과목: ${notification['courseName'] as String}',
                      style: AppTypography.small(
                        context,
                      ).copyWith(color: Colors.grey),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
                if (notification['type'] == 'inactivity' ||
                    notification['type'] == 'attendance') ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // 해당 수업 출석 화면으로 이동하는 코드 추가
                      // (실제 구현에서는 Navigator를 사용해 해당 화면으로 이동)
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('수업으로 이동'),
                  ),
                ],
              ],
            ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: notifications.isNotEmpty ? clearAllNotifications : null,
            tooltip: '모든 알림 지우기',
          ),
        ],
      ),
      body:
          notifications.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('알림이 없습니다'),
                  ],
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 알림 요약 정보
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '알림 요약',
                              style: AppTypography.headline3(context),
                            ),
                            AppSpacing.verticalSpaceSM,
                            Row(
                              children: [
                                Icon(
                                  Icons.mark_email_unread,
                                  color:
                                      unreadCount > 0
                                          ? AppColors.primaryColor
                                          : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '읽지 않은 알림: $unreadCount',
                                  style: AppTypography.body(context),
                                ),
                              ],
                            ),
                            AppSpacing.verticalSpaceXS,
                            Row(
                              children: [
                                const Icon(
                                  Icons.notifications,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '전체 알림: ${notifications.length}',
                                  style: AppTypography.body(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 알림 목록 섹션 제목
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      '최근 알림',
                      style: AppTypography.headline3(context),
                    ),
                  ),

                  // 알림 목록
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: notifications.length,
                      separatorBuilder:
                          (context, index) => const AppDivider(hasIndent: true),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final bool isRead = notification['isRead'] as bool;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (notification['color'] as Color)
                                .withOpacity(0.1),
                            child: Icon(
                              notification['icon'] as IconData,
                              color: notification['color'] as Color,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'] as String,
                                  style: AppTypography.subhead(
                                    context,
                                  ).copyWith(
                                    fontWeight:
                                        isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            notification['time'] as String,
                            style: AppTypography.small(context),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => showNotificationDetail(notification),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
