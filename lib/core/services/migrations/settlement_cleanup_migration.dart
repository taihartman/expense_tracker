import 'package:flutter/foundation.dart';
import '../../../features/settlements/domain/repositories/settlement_repository.dart';
import '../../../features/trips/domain/repositories/trip_repository.dart';

/// Migration to clean up duplicate settlement transfers and recalculate
///
/// This migration:
/// 1. Fetches all trips
/// 2. For each trip, triggers settlement recalculation
/// 3. Uses the nuclear option (delete-all-and-recreate) to ensure clean state
/// 4. Validates results with SettlementValidator
class SettlementCleanupMigration {
  final TripRepository _tripRepository;
  final SettlementRepository _settlementRepository;

  SettlementCleanupMigration({
    required TripRepository tripRepository,
    required SettlementRepository settlementRepository,
  })  : _tripRepository = tripRepository,
        _settlementRepository = settlementRepository;

  /// Run the migration
  ///
  /// Returns (successCount, errorCount, errors)
  Future<({int successCount, int errorCount, List<String> errors})> run() async {
    _log('🚀 Starting settlement cleanup migration...\n');

    int successCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    try {
      // Fetch all trips (one-time snapshot, not stream)
      _log('📦 Fetching all trips...');
      final tripsStream = _tripRepository.getAllTrips();
      final trips = await tripsStream.first;
      _log('✅ Found ${trips.length} trips\n');

      // Process each trip
      for (int i = 0; i < trips.length; i++) {
        final trip = trips[i];
        _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _log('🔄 Processing trip ${i + 1}/${trips.length}: ${trip.name} (${trip.id})');

        try {
          // Trigger settlement recalculation
          // This will:
          // 1. Delete all existing transfers (nuclear option)
          // 2. Recalculate from scratch with fixed logic
          // 3. Validate results
          // If trip has no expenses, it will create empty settlement (no transfers)
          _log('🧮 Recalculating settlement...');
          await _settlementRepository.computeSettlement(trip.id);

          successCount++;
          _log('✅ Settlement recalculated successfully\n');
        } catch (e) {
          errorCount++;
          final error = 'Trip ${trip.id} (${trip.name}): $e';
          errors.add(error);
          _log('❌ Error: $e\n');
        }
      }

      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('✅ Migration complete!');
      _log('   Success: $successCount trips');
      _log('   Errors: $errorCount trips');

      if (errors.isNotEmpty) {
        _log('\n❌ Errors encountered:');
        for (final error in errors) {
          _log('   - $error');
        }
      }

      return (successCount: successCount, errorCount: errorCount, errors: errors);
    } catch (e) {
      _log('❌ Fatal error during migration: $e');
      rethrow;
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SettlementCleanupMigration] $message');
    }
  }
}
