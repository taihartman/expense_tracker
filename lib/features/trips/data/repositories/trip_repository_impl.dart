import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../shared/services/firestore_service.dart';
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
      _log('➕ Adding verified member: $participantName (ID: $participantId) to trip $tripId');

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
      _log('🗑️ Removing verified member (ID: $participantId) from trip $tripId');

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
}
