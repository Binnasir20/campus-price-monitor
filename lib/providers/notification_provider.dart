import 'dart:async';

import 'package:flutter/material.dart';

import '../model/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<AppNotification> _notifications = [];

  StreamSubscription? _notificationSubscription;

  List<AppNotification> get notifications => _notifications;

  int get unreadCount {
    return _notifications
        .where((notification) => !notification.isRead)
        .length;
  }

  void fetchNotifications(String uid) {
    _notificationSubscription?.cancel();

    final stream =
    _firestoreService.getNotificationsByUser(uid);

    _notificationSubscription = stream.listen(
          (notificationData) {
        _notifications = notificationData;
        notifyListeners();
      },
      onError: (error) {
        print("Notification Error: $error");
        _notifications = [];
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestoreService.markNotificationAsRead(
        notificationId,
      );
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  void clearNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _notifications = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}