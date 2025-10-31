/// Domain model for tracking icon preference votes for a category
///
/// Used to implement the crowd-sourced icon voting system where
/// users implicitly vote for better category icons through customization.
/// When a threshold (3 votes) is reached, the global category icon updates.
///
/// Stored in Firestore: `/categoryIconPreferences/{categoryId}_{iconName}`
class CategoryIconPreference {
  /// Category ID this preference is for
  final String categoryId;

  /// Icon name that users are voting for (e.g., "restaurant", "fastfood")
  final String iconName;

  /// Number of users who have customized this category to use this icon
  final int voteCount;

  /// Whether this is currently the most popular icon for this category
  /// Used to determine which preference should trigger global icon updates
  final bool mostPopular;

  /// Timestamp of the last vote for this icon
  final DateTime lastVoteAt;

  /// Vote threshold - number of votes needed to update global icon
  static const int voteThreshold = 3;

  const CategoryIconPreference({
    required this.categoryId,
    required this.iconName,
    required this.voteCount,
    this.mostPopular = false,
    required this.lastVoteAt,
  });

  /// Returns the current vote count for this icon preference
  int getVoteCount() => voteCount;

  /// Returns true if this preference has reached the vote threshold
  /// and should trigger a global icon update
  bool hasReachedThreshold() => voteCount >= voteThreshold;

  /// Creates a copy with incremented vote count
  CategoryIconPreference incrementVote() {
    return copyWith(
      voteCount: voteCount + 1,
      lastVoteAt: DateTime.now(),
    );
  }

  /// Creates a copy with mostPopular flag set
  CategoryIconPreference markAsMostPopular() {
    return copyWith(mostPopular: true);
  }

  /// Creates a copy with mostPopular flag cleared
  CategoryIconPreference clearMostPopular() {
    return copyWith(mostPopular: false);
  }

  /// Creates a copy with updated fields
  CategoryIconPreference copyWith({
    String? categoryId,
    String? iconName,
    int? voteCount,
    bool? mostPopular,
    DateTime? lastVoteAt,
  }) {
    return CategoryIconPreference(
      categoryId: categoryId ?? this.categoryId,
      iconName: iconName ?? this.iconName,
      voteCount: voteCount ?? this.voteCount,
      mostPopular: mostPopular ?? this.mostPopular,
      lastVoteAt: lastVoteAt ?? this.lastVoteAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryIconPreference &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          iconName == other.iconName;

  @override
  int get hashCode => Object.hash(categoryId, iconName);

  @override
  String toString() {
    return 'CategoryIconPreference('
        'categoryId: $categoryId, '
        'iconName: $iconName, '
        'voteCount: $voteCount, '
        'mostPopular: $mostPopular, '
        'lastVoteAt: $lastVoteAt'
        ')';
  }
}
