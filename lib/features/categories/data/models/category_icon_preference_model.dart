import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/category_icon_preference.dart';

/// Firestore serialization model for CategoryIconPreference
///
/// Handles conversion between domain model and Firestore documents.
/// Document path: `/categoryIconPreferences/{categoryId}_{iconName}`
class CategoryIconPreferenceModel {
  /// Converts domain model to Firestore document data
  static Map<String, dynamic> toFirestore(CategoryIconPreference preference) {
    return {
      'categoryId': preference.categoryId,
      'iconName': preference.iconName,
      'voteCount': preference.voteCount,
      'mostPopular': preference.mostPopular,
      'lastVoteAt': Timestamp.fromDate(preference.lastVoteAt),
    };
  }

  /// Creates domain model from Firestore document
  static CategoryIconPreference fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CategoryIconPreference(
      categoryId: data['categoryId'] as String,
      iconName: data['iconName'] as String,
      voteCount: data['voteCount'] as int,
      mostPopular: data['mostPopular'] as bool? ?? false,
      lastVoteAt: (data['lastVoteAt'] as Timestamp).toDate(),
    );
  }

  /// Creates domain model from Firestore query document
  static CategoryIconPreference fromQueryDocumentSnapshot(
    QueryDocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    return CategoryIconPreference(
      categoryId: data['categoryId'] as String,
      iconName: data['iconName'] as String,
      voteCount: data['voteCount'] as int,
      mostPopular: data['mostPopular'] as bool? ?? false,
      lastVoteAt: (data['lastVoteAt'] as Timestamp).toDate(),
    );
  }

  /// Generates document ID from categoryId and iconName
  /// Format: {categoryId}_{iconName}
  static String generateDocumentId(String categoryId, String iconName) {
    return '${categoryId}_$iconName';
  }
}
