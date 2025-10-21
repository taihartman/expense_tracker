import 'package:flutter/material.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] [ExpenseRepository] $message');
}

/// Firestore implementation of ExpenseRepository
class ExpenseRepositoryImpl implements ExpenseRepository {
  final FirestoreService _firestoreService;

  ExpenseRepositoryImpl({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  @override
  Future<Expense> createExpense(Expense expense) async {
    try {
      // Validate expense data
      final error = expense.validate();
      if (error != null) {
        throw ArgumentError(error);
      }

      // Create document reference with auto-generated ID
      final docRef = _firestoreService.expenses.doc();

      // Create expense with generated ID and current timestamps
      final now = DateTime.now();
      final newExpense = expense.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await docRef.set(ExpenseModel.toJson(newExpense));

      return newExpense;
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  @override
  Future<Expense?> getExpenseById(String expenseId) async {
    try {
      final doc = await _firestoreService.expenses.doc(expenseId).get();

      if (!doc.exists) {
        return null;
      }

      return ExpenseModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get expense: $e');
    }
  }

  @override
  Stream<List<Expense>> getExpensesByTrip(String tripId) {
    try {
      _log('🔍 getExpensesByTrip() called for tripId: $tripId - creating Firestore stream with cache-first strategy');

      // Use snapshots with metadata changes to get cache data immediately
      // This emits cache data first, then server data when available
      return _firestoreService.expenses
          .where('tripId', isEqualTo: tripId)
          .orderBy('date', descending: true)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
        // Timer starts here when data actually arrives, not when stream is created
        final mapStart = DateTime.now();
        final source = snapshot.metadata.isFromCache ? 'cache' : 'server';
        final expenses = snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();
        final mapDuration = DateTime.now().difference(mapStart).inMilliseconds;
        _log('📦 Stream emitted ${expenses.length} expenses from $source (mapping took ${mapDuration}ms)');
        return expenses;
      });
    } catch (e) {
      _log('❌ Error creating expenses stream: $e');
      throw Exception('Failed to get expenses stream: $e');
    }
  }

  @override
  Future<Expense> updateExpense(Expense expense) async {
    try {
      // Validate expense data
      final error = expense.validate();
      if (error != null) {
        throw ArgumentError(error);
      }

      // Check if expense exists
      final exists = await expenseExists(expense.id);
      if (!exists) {
        throw Exception('Expense not found: ${expense.id}');
      }

      // Update timestamp
      final updatedExpense = expense.copyWith(updatedAt: DateTime.now());

      // Save to Firestore
      await _firestoreService.expenses
          .doc(expense.id)
          .update(ExpenseModel.toJson(updatedExpense));

      return updatedExpense;
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestoreService.expenses.doc(expenseId).delete();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  @override
  Future<bool> expenseExists(String expenseId) async {
    try {
      final doc = await _firestoreService.expenses.doc(expenseId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check if expense exists: $e');
    }
  }

  @override
  Stream<List<Expense>> getExpensesByCategory(
      String tripId, String categoryId) {
    try {
      _log('🔍 getExpensesByCategory() called for tripId: $tripId, categoryId: $categoryId');
      final streamStart = DateTime.now();

      return _firestoreService.expenses
          .where('tripId', isEqualTo: tripId)
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('date', descending: true)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
        final source = snapshot.metadata.isFromCache ? 'cache' : 'server';
        final expenses = snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();
        _log('📦 Stream emitted ${expenses.length} expenses by category from $source (${DateTime.now().difference(streamStart).inMilliseconds}ms)');
        return expenses;
      });
    } catch (e) {
      _log('❌ Error creating expenses by category stream: $e');
      throw Exception('Failed to get expenses by category stream: $e');
    }
  }

  @override
  Stream<List<Expense>> getExpensesByPayer(String tripId, String payerUserId) {
    try {
      _log('🔍 getExpensesByPayer() called for tripId: $tripId, payerUserId: $payerUserId');
      final streamStart = DateTime.now();

      return _firestoreService.expenses
          .where('tripId', isEqualTo: tripId)
          .where('payerUserId', isEqualTo: payerUserId)
          .orderBy('date', descending: true)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
        final source = snapshot.metadata.isFromCache ? 'cache' : 'server';
        final expenses = snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();
        _log('📦 Stream emitted ${expenses.length} expenses by payer from $source (${DateTime.now().difference(streamStart).inMilliseconds}ms)');
        return expenses;
      });
    } catch (e) {
      _log('❌ Error creating expenses by payer stream: $e');
      throw Exception('Failed to get expenses by payer stream: $e');
    }
  }
}
