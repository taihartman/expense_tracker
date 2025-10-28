import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:expense_tracker/features/expenses/domain/models/item_assignment.dart';
import 'package:expense_tracker/features/expenses/domain/models/assignment_mode.dart';

void main() {
  group('ItemAssignment', () {
    group('even mode', () {
      test('creates valid even assignment', () {
        final assignment = ItemAssignment(
          mode: AssignmentMode.even,
          users: ['user1', 'user2', 'user3'],
        );

        expect(assignment.mode, AssignmentMode.even);
        expect(assignment.users, ['user1', 'user2', 'user3']);
        expect(assignment.shares, isNull);
      });

      test('validates at least one user required', () {
        expect(
          () => ItemAssignment(mode: AssignmentMode.even, users: []),
          throwsArgumentError,
        );
      });

      test('validates shares must be null for even mode', () {
        expect(
          () => ItemAssignment(
            mode: AssignmentMode.even,
            users: ['user1', 'user2'],
            shares: {
              'user1': Decimal.parse('0.5'),
              'user2': Decimal.parse('0.5'),
            },
          ),
          throwsArgumentError,
        );
      });
    });

    group('custom mode', () {
      test('creates valid custom assignment', () {
        final assignment = ItemAssignment(
          mode: AssignmentMode.custom,
          users: ['user1', 'user2'],
          shares: {
            'user1': Decimal.parse('0.6667'),
            'user2': Decimal.parse('0.3333'),
          },
        );

        expect(assignment.mode, AssignmentMode.custom);
        expect(assignment.shares!['user1'], Decimal.parse('0.6667'));
        expect(assignment.shares!['user2'], Decimal.parse('0.3333'));
      });

      test('validates shares must be provided for custom mode', () {
        expect(
          () => ItemAssignment(
            mode: AssignmentMode.custom,
            users: ['user1', 'user2'],
          ),
          throwsArgumentError,
        );
      });

      test('validates shares keys match users list', () {
        expect(
          () => ItemAssignment(
            mode: AssignmentMode.custom,
            users: ['user1', 'user2'],
            shares: {
              'user1': Decimal.parse('0.5'),
              'user3': Decimal.parse('0.5'), // Wrong user!
            },
          ),
          throwsArgumentError,
        );
      });

      test('validates shares sum to 1.0 (within tolerance)', () {
        // Valid: sums to 1.0
        expect(
          () => ItemAssignment(
            mode: AssignmentMode.custom,
            users: ['user1', 'user2'],
            shares: {
              'user1': Decimal.parse('0.5'),
              'user2': Decimal.parse('0.5'),
            },
          ),
          returnsNormally,
        );

        // Valid: sums to 1.0001 (within 0.01 tolerance)
        expect(
          () => ItemAssignment(
            mode: AssignmentMode.custom,
            users: ['user1', 'user2'],
            shares: {
              'user1': Decimal.parse('0.5001'),
              'user2': Decimal.parse('0.5'),
            },
          ),
          returnsNormally,
        );

        // Invalid: sums to 0.9
        expect(
          () => ItemAssignment(
            mode: AssignmentMode.custom,
            users: ['user1', 'user2'],
            shares: {
              'user1': Decimal.parse('0.5'),
              'user2': Decimal.parse('0.4'),
            },
          ),
          throwsArgumentError,
        );
      });

      test('validates all shares are positive', () {
        expect(
          () => ItemAssignment(
            mode: AssignmentMode.custom,
            users: ['user1', 'user2'],
            shares: {
              'user1': Decimal.parse('0.5'),
              'user2': Decimal.parse('-0.5'),
            },
          ),
          throwsArgumentError,
        );
      });
    });

    test('supports equality comparison', () {
      final assignment1 = ItemAssignment(
        mode: AssignmentMode.even,
        users: ['user1', 'user2'],
      );

      final assignment2 = ItemAssignment(
        mode: AssignmentMode.even,
        users: ['user1', 'user2'],
      );

      expect(assignment1, equals(assignment2));
    });

    test('supports copyWith', () {
      final assignment = ItemAssignment(
        mode: AssignmentMode.even,
        users: ['user1', 'user2'],
      );

      final updated = assignment.copyWith(users: ['user1', 'user2', 'user3']);

      expect(updated.users, ['user1', 'user2', 'user3']);
      expect(updated.mode, AssignmentMode.even);
    });
  });
}
