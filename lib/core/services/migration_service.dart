import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/services/firestore_service.dart';
import '../models/participant.dart';
import '../../features/trips/data/models/trip_model.dart';
import '../../features/expenses/data/models/expense_model.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint(
    '[${DateTime.now().toIso8601String()}] [MigrationService] $message',
  );
}

/// Service to handle data migrations
class MigrationService {
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;

  // Migration keys
  static const String _migrationV1Key = 'migration_v1_completed';

  // Fixed participants from MVP (to be removed after migration)
  static const List<Participant> _fixedParticipants = [
    Participant(id: 'tai', name: 'Tai'),
    Participant(id: 'khiet', name: 'Khiet'),
    Participant(id: 'bob', name: 'Bob'),
    Participant(id: 'ethan', name: 'Ethan'),
    Participant(id: 'ryan', name: 'Ryan'),
    Participant(id: 'izzy', name: 'Izzy'),
  ];

  MigrationService({
    required FirestoreService firestoreService,
    required SharedPreferences prefs,
  }) : _firestoreService = firestoreService,
       _prefs = prefs;

  /// Run all necessary migrations
  Future<void> runMigrations() async {
    try {
      _log('🚀 Starting migration check...');

      // Run migration v1 if not completed
      if (_prefs.getBool(_migrationV1Key) != true) {
        await _migrationV1ParticipantsPerTrip();
        await _prefs.setBool(_migrationV1Key, true);
        _log('✅ Migration v1 completed and marked as done');
      } else {
        _log('ℹ️ Migration v1 already completed, skipping');
      }

      _log('✅ All migrations completed successfully');
    } catch (e) {
      _log('❌ Migration failed: $e');
      // Don't throw - allow app to continue even if migration fails
      // This prevents the app from being unusable if migration has issues
    }
  }

  /// Migration v1: Move from fixed participants to per-trip participants
  /// - Add fixed participants to trips with empty participant lists
  /// - Scan expenses and add any missing participant IDs to trips
  Future<void> _migrationV1ParticipantsPerTrip() async {
    _log('🔄 Running migration v1: Participants per trip');

    try {
      // Get all trips
      final tripsSnapshot = await _firestoreService.trips.get();
      final totalTrips = tripsSnapshot.docs.length;
      _log('📦 Found $totalTrips trips to migrate');

      if (totalTrips == 0) {
        _log('ℹ️ No trips found, migration complete');
        return;
      }

      int migratedCount = 0;
      int skippedCount = 0;

      // Process each trip
      for (final tripDoc in tripsSnapshot.docs) {
        try {
          final trip = TripModel.fromFirestore(tripDoc);
          final tripId = trip.id;

          _log('🔍 Processing trip: ${trip.name} (ID: $tripId)');

          // Start with existing participants or empty list
          final participants = List<Participant>.from(trip.participants);
          final participantIds = participants.map((p) => p.id).toSet();

          bool needsUpdate = false;

          // Step 1: If no participants, add all fixed participants
          if (participants.isEmpty) {
            _log('  ➕ Trip has no participants, adding fixed participants');
            participants.addAll(_fixedParticipants);
            participantIds.addAll(_fixedParticipants.map((p) => p.id));
            needsUpdate = true;
          } else {
            _log('  ✓ Trip already has ${participants.length} participants');
          }

          // Step 2: Scan expenses for this trip and add missing participants
          final expensesSnapshot = await _firestoreService.expenses
              .where('tripId', isEqualTo: tripId)
              .get();

          _log('  📋 Found ${expensesSnapshot.docs.length} expenses to scan');

          final uniqueExpenseParticipants = <String>{};

          for (final expenseDoc in expensesSnapshot.docs) {
            try {
              final expense = ExpenseModel.fromFirestore(expenseDoc);

              // Add payer ID
              uniqueExpenseParticipants.add(expense.payerUserId);

              // Add all participants from split
              uniqueExpenseParticipants.addAll(expense.participants.keys);
            } catch (e) {
              _log('  ⚠️ Failed to parse expense ${expenseDoc.id}: $e');
              // Continue with other expenses
            }
          }

          _log(
            '  🔍 Found ${uniqueExpenseParticipants.length} unique participant IDs in expenses',
          );

          // Add missing participants from expenses
          for (final participantId in uniqueExpenseParticipants) {
            if (!participantIds.contains(participantId)) {
              _log('  ➕ Adding missing participant: $participantId');

              // Create participant with ID as name (best we can do)
              // The ID is often a lowercase version of the name
              final name = _capitalizeFirstLetter(participantId);
              participants.add(
                Participant(
                  id: participantId,
                  name: name,
                  createdAt: DateTime.now(),
                ),
              );
              participantIds.add(participantId);
              needsUpdate = true;
            }
          }

          // Step 3: Update trip if needed
          if (needsUpdate) {
            _log('  💾 Updating trip with ${participants.length} participants');

            await _firestoreService.trips.doc(tripId).update({
              'participants': participants.map((p) => p.toJson()).toList(),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });

            migratedCount++;
            _log('  ✅ Trip migrated successfully');
          } else {
            skippedCount++;
            _log('  ⏭️ Trip already has all participants, skipping');
          }
        } catch (e) {
          _log('❌ Failed to migrate trip ${tripDoc.id}: $e');
          // Continue with other trips
        }
      }

      _log(
        '🎉 Migration v1 complete: $migratedCount trips migrated, $skippedCount skipped',
      );
    } catch (e) {
      _log('❌ Fatal error in migration v1: $e');
      rethrow;
    }
  }

  /// Capitalize first letter of a string
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
