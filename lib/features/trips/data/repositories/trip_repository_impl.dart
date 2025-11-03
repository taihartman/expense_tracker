import 'package:flutter/material.dart';
import '../../../../core/models/currency_code.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../domain/exceptions/trip_exceptions.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/verified_member.dart';
import '../../domain/repositories/trip_repository.dart';
import '../models/trip_model.dart';

/// Helper function to log with timestamps
void _log(String message) {
  debugPrint('[${DateTime.now().toIso8601String()}] [TripRepository] $message');
}

/// Firestore implementation of TripRepository
class TripRepositoryImpl implements TripRepository {
  final FirestoreService _firestoreService;

  TripRepositoryImpl({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  @override
  Future<Trip> createTrip(Trip trip) async {
    try {
      // Validate trip data
      final error = trip.validate();
      if (error != null) {
        throw ArgumentError(error);
      }

      // Create document reference with auto-generated ID
      final docRef = _firestoreService.trips.doc();

      // Create trip with generated ID and current timestamps
      final now = DateTime.now();
      final newTrip = trip.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await docRef.set(TripModel.toJson(newTrip));

      return newTrip;
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  @override
  Future<Trip?> getTripById(String tripId) async {
    try {
      final doc = await _firestoreService.trips.doc(tripId).get();

      if (!doc.exists) {
        return null;
      }

      return TripModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get trip: $e');
    }
  }

  @override
  Stream<List<Trip>> getAllTrips() {
    try {
      _log(
        '🔍 getAllTrips() called - creating Firestore stream with cache-first strategy',
      );

      // Use snapshots with metadata changes to get cache data immediately
      // This emits cache data first, then server data when available
      return _firestoreService.trips
          .orderBy('createdAt', descending: true)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            // Timer starts here when data actually arrives, not when stream is created
            final mapStart = DateTime.now();
            final source = snapshot.metadata.isFromCache ? 'cache' : 'server';
            final trips = snapshot.docs
                .map((doc) => TripModel.fromFirestore(doc))
                .toList();
            final mapDuration = DateTime.now()
                .difference(mapStart)
                .inMilliseconds;
            _log(
              '📦 Stream emitted ${trips.length} trips from $source (mapping took ${mapDuration}ms)',
            );
            return trips;
          });
    } catch (e) {
      _log('❌ Error creating trips stream: $e');
      throw Exception('Failed to get trips stream: $e');
    }
  }

  @override
  Future<Trip> updateTrip(Trip trip) async {
    try {
      // Validate trip data
      final error = trip.validate();
      if (error != null) {
        throw ArgumentError(error);
      }

      // Check if trip exists
      final exists = await tripExists(trip.id);
      if (!exists) {
        throw Exception('Trip not found: ${trip.id}');
      }

      // Update timestamp
      final updatedTrip = trip.copyWith(updatedAt: DateTime.now());

      // Save to Firestore
      await _firestoreService.trips
          .doc(trip.id)
          .update(TripModel.toJson(updatedTrip));

      return updatedTrip;
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      await _firestoreService.trips.doc(tripId).delete();
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  @override
  Future<bool> tripExists(String tripId) async {
    try {
      final doc = await _firestoreService.trips.doc(tripId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check if trip exists: $e');
    }
  }

  @override
  Future<void> addVerifiedMember({
    required String tripId,
    required String participantId,
    required String participantName,
  }) async {
    try {
      _log(
        '➕ Adding verified member: $participantName (ID: $participantId) to trip $tripId',
      );

      final verifiedMember = VerifiedMember(
        participantId: participantId,
        participantName: participantName,
        verifiedAt: DateTime.now(),
      );

      // Use participantId as document ID for deduplication
      await _firestoreService.trips
          .doc(tripId)
          .collection('verifiedMembers')
          .doc(participantId)
          .set(verifiedMember.toFirestore());

      _log('✅ Successfully added verified member: $participantName');
    } catch (e) {
      _log('❌ Failed to add verified member: $e');
      throw Exception('Failed to add verified member: $e');
    }
  }

  @override
  Future<List<VerifiedMember>> getVerifiedMembers(String tripId) async {
    try {
      _log('📥 Getting verified members for trip: $tripId');

      final snapshot = await _firestoreService.trips
          .doc(tripId)
          .collection('verifiedMembers')
          .orderBy('verifiedAt', descending: true)
          .get();

      final members = snapshot.docs
          .map((doc) => VerifiedMember.fromFirestore(doc.data(), doc.id))
          .toList();

      _log('✅ Retrieved ${members.length} verified members');
      return members;
    } catch (e) {
      _log('❌ Failed to get verified members: $e');
      throw Exception('Failed to get verified members: $e');
    }
  }

  @override
  Future<void> removeVerifiedMember({
    required String tripId,
    required String participantId,
  }) async {
    try {
      _log(
        '🗑️ Removing verified member (ID: $participantId) from trip $tripId',
      );

      await _firestoreService.trips
          .doc(tripId)
          .collection('verifiedMembers')
          .doc(participantId)
          .delete();

      _log('✅ Successfully removed verified member');
    } catch (e) {
      _log('❌ Failed to remove verified member: $e');
      throw Exception('Failed to remove verified member: $e');
    }
  }

  @override
  Future<List<CurrencyCode>> getAllowedCurrencies(String tripId) async {
    try {
      _log('💱 Getting allowed currencies for trip: $tripId');

      // Reuse getTripById to get the trip
      final trip = await getTripById(tripId);

      if (trip == null) {
        throw TripNotFoundException(tripId);
      }

      // Handle migration logic via TripModel.fromFirestore
      // If allowedCurrencies exists, use it
      if (trip.allowedCurrencies.isNotEmpty) {
        _log('✅ Found ${trip.allowedCurrencies.length} allowed currencies');
        return trip.allowedCurrencies;
      }

      // Fallback to baseCurrency for legacy trips
      if (trip.baseCurrency != null) {
        _log('✅ Using legacy baseCurrency: ${trip.baseCurrency}');
        return [trip.baseCurrency!];
      }

      // Data integrity error: neither field exists
      throw DataIntegrityException(
        'Trip has neither allowedCurrencies nor baseCurrency',
        tripId: tripId,
      );
    } catch (e) {
      if (e is TripNotFoundException || e is DataIntegrityException) {
        rethrow;
      }
      _log('❌ Failed to get allowed currencies: $e');
      throw Exception('Failed to get allowed currencies: $e');
    }
  }

  @override
  Future<void> updateAllowedCurrencies(
    String tripId,
    List<CurrencyCode> currencies,
  ) async {
    try {
      _log('💱 Updating allowed currencies for trip: $tripId');
      _log('   New currencies: ${currencies.map((c) => c.code).join(", ")}');

      // Validate: minimum 1 currency
      if (currencies.isEmpty) {
        throw ArgumentError('At least 1 currency is required');
      }

      // Validate: maximum 10 currencies
      if (currencies.length > 10) {
        throw ArgumentError('Maximum 10 currencies allowed');
      }

      // Validate: no duplicates
      final uniqueCurrencies = currencies.toSet();
      if (uniqueCurrencies.length != currencies.length) {
        throw ArgumentError('Duplicate currencies are not allowed');
      }

      // Check if trip exists
      final tripExists = await this.tripExists(tripId);
      if (!tripExists) {
        throw TripNotFoundException(tripId);
      }

      // Update Firestore with new allowedCurrencies array
      await _firestoreService.trips.doc(tripId).update({
        'allowedCurrencies': currencies.map((c) => c.code).toList(),
        'updatedAt': DateTime.now(),
      });

      _log('✅ Successfully updated allowed currencies');
    } catch (e) {
      if (e is ArgumentError || e is TripNotFoundException) {
        rethrow;
      }
      _log('❌ Failed to update allowed currencies: $e');
      throw Exception('Failed to update allowed currencies: $e');
    }
  }
}
