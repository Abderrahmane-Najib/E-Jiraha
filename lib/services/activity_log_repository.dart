import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_log.dart';
import 'firebase_service.dart';

/// Repository for activity logs
class ActivityLogRepository {
  final FirebaseService _firebaseService = FirebaseService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firebaseService.activityLogsCollection;

  /// Log an activity
  Future<void> logActivity({
    required ActivityType type,
    required String description,
    String? userId,
    String? userName,
    String? targetId,
    String? targetName,
    Map<String, dynamic>? metadata,
  }) async {
    final log = ActivityLog(
      id: '',
      type: type,
      description: description,
      userId: userId,
      userName: userName,
      targetId: targetId,
      targetName: targetName,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    await _collection.add(log.toFirestore());
  }

  /// Get recent activity logs
  Future<List<ActivityLog>> getRecentLogs({int limit = 50}) async {
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ActivityLog.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get logs by user
  Future<List<ActivityLog>> getLogsByUser(String userId, {int limit = 20}) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ActivityLog.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get logs by type
  Future<List<ActivityLog>> getLogsByType(ActivityType type, {int limit = 20}) async {
    final snapshot = await _collection
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ActivityLog.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get logs from today
  Future<List<ActivityLog>> getTodayLogs() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _collection
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ActivityLog.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Stream of recent logs for real-time updates
  Stream<List<ActivityLog>> watchRecentLogs({int limit = 20}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLog.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Delete old logs (keep last N days)
  Future<void> deleteOldLogs({int keepDays = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

    final snapshot = await _collection
        .where('createdAt', isLessThan: cutoffDate)
        .get();

    final batch = _firebaseService.firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
