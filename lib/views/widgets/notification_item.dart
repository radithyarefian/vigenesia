import 'package:flutter/material.dart';
import 'package:vigenesia/models/notification_model.dart';
import 'package:vigenesia/models/user_model.dart';
import 'package:vigenesia/theme/app_theme.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final UserModel? user;
  final String timeText;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    this.user,
    required this.timeText,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead
          ? null
          : AppTheme.primaryColor.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.tittle,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getNotificationBody(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      timeText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.close,
                  color: AppTheme.textSecondaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNotificationBody() {
    String body = notification.body;

    if (user != null) {
      switch (NotificationType) {
        case NotificationType.friendRequest:
          body = '${user!.displayName} telah mengirimkan permintaan pertemanan kepadamu';
          break;
        case NotificationType.friendRequestAccepted:
          body = '${user!.displayName} Telah menerima permintaan pertemanan Anda';
          break;
        case NotificationType.friendRequestDeclined:
          body = '${user!.displayName} menolak permintaan pertemanan Anda';
          break;
        case NotificationType.newMessage:
          body = '${user!.displayName} sudah mengirimkan pesan kepadamu';
          break;
        case NotificationType.friendRemoved:
          body = 'Kamu tidak lagi berteman dengan ${user!.displayName}';
          break;
      }
    }
    return body;
  }
}
