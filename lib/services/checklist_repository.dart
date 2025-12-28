import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checklist.dart';
import 'firebase_service.dart';

/// Repository for checklist operations
class ChecklistRepository {
  final FirebaseService _firebaseService = FirebaseService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firebaseService.checklistsCollection;

  /// Get all checklists
  Future<List<Checklist>> getAllChecklists() async {
    final snapshot = await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Checklist.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Get checklist by ID
  Future<Checklist?> getChecklistById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Checklist.fromFirestore(doc.id, doc.data()!);
    }
    return null;
  }

  /// Get checklists by case ID
  Future<List<Checklist>> getChecklistsByCaseId(String caseId) async {
    final snapshot = await _collection
        .where('caseId', isEqualTo: caseId)
        .get();
    final checklists = snapshot.docs
        .map((doc) => Checklist.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    checklists.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return checklists;
  }

  /// Get checklist by case and type
  Future<Checklist?> getChecklistByCaseAndType(
      String caseId, ChecklistType type) async {
    // Get all checklists for the case and filter client-side
    // to avoid composite index requirement
    final snapshot = await _collection
        .where('caseId', isEqualTo: caseId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['type'] == type.name) {
        return Checklist.fromFirestore(doc.id, data);
      }
    }
    return null;
  }

  /// Get pending checklists (not completed)
  Future<List<Checklist>> getPendingChecklists() async {
    final snapshot = await _collection
        .where('isCompleted', isEqualTo: false)
        .get();
    final checklists = snapshot.docs
        .map((doc) => Checklist.fromFirestore(doc.id, doc.data()))
        .toList();
    // Sort client-side to avoid composite index requirement
    checklists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return checklists;
  }

  /// Create checklist
  Future<String> createChecklist(Checklist checklist) async {
    final docRef = await _collection.add(checklist.toFirestore());
    return docRef.id;
  }

  /// Update checklist
  Future<void> updateChecklist(Checklist checklist) async {
    await _collection.doc(checklist.id).update(checklist.toFirestore());
  }

  /// Update checklist item
  Future<void> updateChecklistItem(
    String checklistId,
    ChecklistItem updatedItem,
  ) async {
    final doc = await _collection.doc(checklistId).get();
    if (doc.exists && doc.data() != null) {
      final checklist = Checklist.fromFirestore(doc.id, doc.data()!);
      final updatedItems = checklist.items.map((item) {
        if (item.id == updatedItem.id) {
          return updatedItem;
        }
        return item;
      }).toList();

      final allCompleted = updatedItems.every((item) =>
          item.status == ChecklistItemStatus.done ||
          item.status == ChecklistItemStatus.notApplicable ||
          !item.isRequired);

      await _collection.doc(checklistId).update({
        'items': updatedItems.map((e) => e.toFirestore()).toList(),
        'isCompleted': allCompleted,
        'completedAt': allCompleted ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Mark checklist as completed
  Future<void> markAsCompleted(String checklistId, String completedBy) async {
    await _collection.doc(checklistId).update({
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
      'completedBy': completedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete checklist
  Future<void> deleteChecklist(String id) async {
    await _collection.doc(id).delete();
  }

  /// Stream of checklists by case
  Stream<List<Checklist>> watchChecklistsByCase(String caseId) {
    return _collection
        .where('caseId', isEqualTo: caseId)
        .snapshots()
        .map((snapshot) {
          final checklists = snapshot.docs
              .map((doc) => Checklist.fromFirestore(doc.id, doc.data()))
              .toList();
          // Sort client-side to avoid composite index requirement
          checklists.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return checklists;
        });
  }

  /// Stream of a single checklist
  Stream<Checklist?> watchChecklist(String id) {
    return _collection.doc(id).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? Checklist.fromFirestore(doc.id, doc.data()!)
              : null,
        );
  }
}
