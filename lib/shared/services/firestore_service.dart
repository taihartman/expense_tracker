import 'package:cloud_firestore/cloud_firestore.dart';

/// Wrapper service for Firestore operations
///
/// Provides centralized access to Firestore collections and common operations
/// Enables easy mocking for tests and potential migration to different backend
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get reference to trips collection
  CollectionReference get trips => _firestore.collection('trips');

  /// Get reference to expenses collection
  CollectionReference get expenses => _firestore.collection('expenses');

  /// Get reference to categories collection
  CollectionReference get categories => _firestore.collection('categories');

  /// Get reference to exchange rates collection
  CollectionReference get exchangeRates =>
      _firestore.collection('exchangeRates');

  /// Get reference to settlements collection (parent for summaries and transfers)
  CollectionReference get settlements =>
      _firestore.collection('settlements');

  /// Get reference to settlement summaries collection
  CollectionReference get settlementSummaries =>
      _firestore.collection('settlementSummaries');

  /// Get reference to pairwise debts collection
  CollectionReference get pairwiseDebts =>
      _firestore.collection('pairwiseDebts');

  /// Get reference to minimal transfers collection
  CollectionReference get minimalTransfers =>
      _firestore.collection('minimalTransfers');

  /// Execute a batch write
  WriteBatch batch() => _firestore.batch();

  /// Execute a transaction
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    return _firestore.runTransaction(transactionHandler, timeout: timeout);
  }

  /// Get server timestamp
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Get current timestamp
  Timestamp get now => Timestamp.now();
}
