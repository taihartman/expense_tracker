import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/categories/domain/models/category_icon_preference.dart';

void main() {
  group('CategoryIconPreference', () {
    final now = DateTime(2025, 10, 31, 12, 0, 0);

    test('should create instance with required fields', () {
      // Arrange & Act
      final preference = CategoryIconPreference(
        categoryId: 'cat-123',
        iconName: 'restaurant',
        voteCount: 5,
        lastVoteAt: now,
      );

      // Assert
      expect(preference.categoryId, 'cat-123');
      expect(preference.iconName, 'restaurant');
      expect(preference.voteCount, 5);
      expect(preference.mostPopular, false); // Default
      expect(preference.lastVoteAt, now);
    });

    test('should create instance with mostPopular flag', () {
      // Arrange & Act
      final preference = CategoryIconPreference(
        categoryId: 'cat-123',
        iconName: 'restaurant',
        voteCount: 5,
        mostPopular: true,
        lastVoteAt: now,
      );

      // Assert
      expect(preference.mostPopular, true);
    });

    group('getVoteCount', () {
      test('should return current vote count', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 7,
          lastVoteAt: now,
        );

        // Act & Assert
        expect(preference.getVoteCount(), 7);
      });
    });

    group('hasReachedThreshold', () {
      test('should return false when vote count is below threshold', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 2,
          lastVoteAt: now,
        );

        // Act & Assert
        expect(preference.hasReachedThreshold(), false);
      });

      test('should return true when vote count equals threshold', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 3, // Threshold is 3
          lastVoteAt: now,
        );

        // Act & Assert
        expect(preference.hasReachedThreshold(), true);
      });

      test('should return true when vote count exceeds threshold', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 10,
          lastVoteAt: now,
        );

        // Act & Assert
        expect(preference.hasReachedThreshold(), true);
      });
    });

    group('incrementVote', () {
      test('should increment vote count by 1', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          lastVoteAt: now,
        );

        // Act
        final updated = preference.incrementVote();

        // Assert
        expect(updated.voteCount, 6);
        expect(updated.categoryId, 'cat-123');
        expect(updated.iconName, 'restaurant');
      });

      test('should update lastVoteAt timestamp', () {
        // Arrange
        final oldTimestamp = DateTime(2025, 10, 30);
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          lastVoteAt: oldTimestamp,
        );

        // Act
        final updated = preference.incrementVote();

        // Assert
        expect(updated.lastVoteAt.isAfter(oldTimestamp), true);
      });

      test('should preserve other fields', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          mostPopular: true,
          lastVoteAt: now,
        );

        // Act
        final updated = preference.incrementVote();

        // Assert
        expect(updated.mostPopular, true);
      });
    });

    group('markAsMostPopular', () {
      test('should set mostPopular flag to true', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          mostPopular: false,
          lastVoteAt: now,
        );

        // Act
        final updated = preference.markAsMostPopular();

        // Assert
        expect(updated.mostPopular, true);
        expect(updated.voteCount, 5); // Unchanged
      });
    });

    group('clearMostPopular', () {
      test('should set mostPopular flag to false', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          mostPopular: true,
          lastVoteAt: now,
        );

        // Act
        final updated = preference.clearMostPopular();

        // Assert
        expect(updated.mostPopular, false);
        expect(updated.voteCount, 5); // Unchanged
      });
    });

    group('copyWith', () {
      test('should create copy with updated voteCount', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          lastVoteAt: now,
        );

        // Act
        final updated = preference.copyWith(voteCount: 10);

        // Assert
        expect(updated.voteCount, 10);
        expect(updated.categoryId, 'cat-123');
        expect(updated.iconName, 'restaurant');
      });

      test('should create copy with all fields updated', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          mostPopular: false,
          lastVoteAt: now,
        );

        final newTimestamp = DateTime(2025, 11, 1);

        // Act
        final updated = preference.copyWith(
          categoryId: 'cat-456',
          iconName: 'fastfood',
          voteCount: 10,
          mostPopular: true,
          lastVoteAt: newTimestamp,
        );

        // Assert
        expect(updated.categoryId, 'cat-456');
        expect(updated.iconName, 'fastfood');
        expect(updated.voteCount, 10);
        expect(updated.mostPopular, true);
        expect(updated.lastVoteAt, newTimestamp);
      });

      test('should preserve unspecified fields', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          mostPopular: true,
          lastVoteAt: now,
        );

        // Act
        final updated = preference.copyWith(voteCount: 10);

        // Assert
        expect(updated.categoryId, 'cat-123');
        expect(updated.iconName, 'restaurant');
        expect(updated.mostPopular, true);
        expect(updated.lastVoteAt, now);
      });
    });

    group('equality', () {
      test('should be equal when categoryId and iconName match', () {
        // Arrange
        final preference1 = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          lastVoteAt: now,
        );

        final preference2 = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 10, // Different vote count
          lastVoteAt: DateTime(2025, 11, 1), // Different timestamp
        );

        // Act & Assert
        expect(preference1, equals(preference2));
        expect(preference1.hashCode, equals(preference2.hashCode));
      });

      test('should not be equal when categoryId differs', () {
        // Arrange
        final preference1 = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          lastVoteAt: now,
        );

        final preference2 = CategoryIconPreference(
          categoryId: 'cat-456',
          iconName: 'restaurant',
          voteCount: 5,
          lastVoteAt: now,
        );

        // Act & Assert
        expect(preference1, isNot(equals(preference2)));
      });

      test('should not be equal when iconName differs', () {
        // Arrange
        final preference1 = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          lastVoteAt: now,
        );

        final preference2 = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'fastfood',
          voteCount: 5,
          lastVoteAt: now,
        );

        // Act & Assert
        expect(preference1, isNot(equals(preference2)));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        // Arrange
        final preference = CategoryIconPreference(
          categoryId: 'cat-123',
          iconName: 'restaurant',
          voteCount: 5,
          mostPopular: true,
          lastVoteAt: now,
        );

        // Act
        final string = preference.toString();

        // Assert
        expect(string, contains('cat-123'));
        expect(string, contains('restaurant'));
        expect(string, contains('5'));
        expect(string, contains('true'));
      });
    });

    group('vote threshold constant', () {
      test('should have threshold of 3', () {
        // Assert
        expect(CategoryIconPreference.voteThreshold, 3);
      });
    });
  });
}
