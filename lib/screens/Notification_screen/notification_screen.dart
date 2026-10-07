import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider =
    Provider.of<NotificationProvider>(context);

    final notifications = notificationProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: notifications.isEmpty
          ? const Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                notification.type == 'price_report'
                    ? Icons.price_check
                    : Icons.notifications,
                color: notification.isRead
                    ? Colors.grey
                    : Colors.blue,
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                notification.message,
              ),
              trailing: notification.isRead
                  ? null
                  : const Icon(
                Icons.circle,
                size: 10,
                color: Colors.blue,
              ),
            ),
          );
        },
      ),
    );
  }
}