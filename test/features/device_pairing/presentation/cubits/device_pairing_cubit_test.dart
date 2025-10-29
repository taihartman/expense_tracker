import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/features/device_pairing/presentation/cubits/device_pairing_cubit.dart';
import 'package:expense_tracker/features/device_pairing/presentation/cubits/device_pairing_state.dart';
import 'package:expense_tracker/features/device_pairing/domain/repositories/device_link_code_repository.dart';
import 'package:expense_tracker/features/device_pairing/domain/models/device_link_code.dart';
import 'package:expense_tracker/core/services/local_storage_service.dart';

import 'device_pairing_cubit_test.mocks.dart';

@GenerateMocks([DeviceLinkCodeRepository, LocalStorageService])
void main() {
  group('T026: DevicePairingCubit.generateCode() -', () {
    late DevicePairingCubit cubit;
    late MockDeviceLinkCodeRepository mockRepository;
    late MockLocalStorageService mockLocalStorageService;

    setUp(() {
      mockRepository = MockDeviceLinkCodeRepository();
      mockLocalStorageService = MockLocalStorageService();
      cubit = DevicePairingCubit(
        repository: mockRepository,
        localStorageService: mockLocalStorageService,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state should be DevicePairingInitial', () {
      expect(cubit.state, equals(const DevicePairingInitial()));
    });

    group('generateCode() -', () {
      blocTest<DevicePairingCubit, DevicePairingState>(
        'should emit [CodeGenerating, CodeGenerated] when code generation succeeds',
        build: () {
          // Arrange - Mock successful code generation
          final mockCode = DeviceLinkCode(
            id: 'code-123',
            code: '1234-5678',
            tripId: 'trip-456',
            memberName: 'Alice',
            createdAt: DateTime(2025, 1, 15, 10, 0),
            expiresAt: DateTime(2025, 1, 15, 10, 15),
            used: false,
            usedAt: null,
          );

          when(mockRepository.generateCode('trip-456', 'Alice'))
              .thenAnswer((_) async => mockCode);

          return cubit;
        },
        act: (cubit) => cubit.generateCode('trip-456', 'Alice'),
        expect: () => [
          const CodeGenerating(),
          isA<CodeGenerated>().having(
            (state) => state.code.id,
            'code id',
            'code-123',
          ).having(
            (state) => state.code.code,
            'code value',
            '1234-5678',
          ).having(
            (state) => state.code.tripId,
            'trip id',
            'trip-456',
          ).having(
            (state) => state.code.memberName,
            'member name',
            'Alice',
          ),
        ],
        verify: (_) {
          verify(mockRepository.generateCode('trip-456', 'Alice')).called(1);
        },
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should emit [CodeGenerating, CodeGenerationError] when repository throws exception',
        build: () {
          // Arrange - Mock repository failure
          when(mockRepository.generateCode(any, any))
              .thenThrow(Exception('Firestore connection failed'));

          return cubit;
        },
        act: (cubit) => cubit.generateCode('trip-456', 'Bob'),
        expect: () => [
          const CodeGenerating(),
          isA<CodeGenerationError>().having(
            (state) => state.message,
            'error message',
            contains('Firestore connection failed'),
          ),
        ],
        verify: (_) {
          verify(mockRepository.generateCode('trip-456', 'Bob')).called(1);
        },
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should call repository with correct tripId and memberName',
        build: () {
          final mockCode = DeviceLinkCode(
            id: 'code-789',
            code: '9876-5432',
            tripId: 'trip-tokyo',
            memberName: 'Charlie',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: false,
            usedAt: null,
          );

          when(mockRepository.generateCode('trip-tokyo', 'Charlie'))
              .thenAnswer((_) async => mockCode);

          return cubit;
        },
        act: (cubit) => cubit.generateCode('trip-tokyo', 'Charlie'),
        verify: (_) {
          // Verify exact parameters passed to repository
          verify(mockRepository.generateCode('trip-tokyo', 'Charlie')).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should preserve all code properties in CodeGenerated state',
        build: () {
          final createdAt = DateTime(2025, 1, 20, 14, 30);
          final expiresAt = DateTime(2025, 1, 20, 14, 45);

          final mockCode = DeviceLinkCode(
            id: 'code-detail-test',
            code: '1111-2222',
            tripId: 'trip-detail',
            memberName: 'DetailUser',
            createdAt: createdAt,
            expiresAt: expiresAt,
            used: false,
            usedAt: null,
          );

          when(mockRepository.generateCode('trip-detail', 'DetailUser'))
              .thenAnswer((_) async => mockCode);

          return cubit;
        },
        act: (cubit) => cubit.generateCode('trip-detail', 'DetailUser'),
        expect: () => [
          const CodeGenerating(),
          isA<CodeGenerated>().having(
            (state) => state.code,
            'complete code object',
            isA<DeviceLinkCode>()
                .having((c) => c.id, 'id', 'code-detail-test')
                .having((c) => c.code, 'code', '1111-2222')
                .having((c) => c.tripId, 'tripId', 'trip-detail')
                .having((c) => c.memberName, 'memberName', 'DetailUser')
                .having((c) => c.used, 'used', false)
                .having((c) => c.usedAt, 'usedAt', null),
          ),
        ],
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should handle network timeout errors gracefully',
        build: () {
          when(mockRepository.generateCode(any, any))
              .thenThrow(Exception('Network timeout'));

          return cubit;
        },
        act: (cubit) => cubit.generateCode('trip-123', 'Alice'),
        expect: () => [
          const CodeGenerating(),
          isA<CodeGenerationError>().having(
            (state) => state.message,
            'error message',
            contains('Network timeout'),
          ),
        ],
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should handle permission denied errors',
        build: () {
          when(mockRepository.generateCode(any, any))
              .thenThrow(Exception('Permission denied'));

          return cubit;
        },
        act: (cubit) => cubit.generateCode('trip-123', 'Alice'),
        expect: () => [
          const CodeGenerating(),
          isA<CodeGenerationError>().having(
            (state) => state.message,
            'error message',
            contains('Permission denied'),
          ),
        ],
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should handle multiple consecutive generateCode calls independently',
        build: () {
          final code1 = DeviceLinkCode(
            id: 'code-1',
            code: '1234-5678',
            tripId: 'trip-1',
            memberName: 'Alice',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: false,
            usedAt: null,
          );

          final code2 = DeviceLinkCode(
            id: 'code-2',
            code: '8765-4321',
            tripId: 'trip-1',
            memberName: 'Bob',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: false,
            usedAt: null,
          );

          when(mockRepository.generateCode('trip-1', 'Alice'))
              .thenAnswer((_) async => code1);
          when(mockRepository.generateCode('trip-1', 'Bob'))
              .thenAnswer((_) async => code2);

          return cubit;
        },
        act: (cubit) async {
          await cubit.generateCode('trip-1', 'Alice');
          await cubit.generateCode('trip-1', 'Bob');
        },
        expect: () => [
          const CodeGenerating(),
          isA<CodeGenerated>().having((s) => s.code.id, 'first code id', 'code-1'),
          const CodeGenerating(),
          isA<CodeGenerated>().having((s) => s.code.id, 'second code id', 'code-2'),
        ],
        verify: (_) {
          verify(mockRepository.generateCode('trip-1', 'Alice')).called(1);
          verify(mockRepository.generateCode('trip-1', 'Bob')).called(1);
        },
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should handle member names with special characters',
        build: () {
          final mockCode = DeviceLinkCode(
            id: 'code-special',
            code: '5555-6666',
            tripId: 'trip-123',
            memberName: "O'Brien",
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: false,
            usedAt: null,
          );

          when(mockRepository.generateCode('trip-123', "O'Brien"))
              .thenAnswer((_) async => mockCode);

          return cubit;
        },
        act: (cubit) => cubit.generateCode('trip-123', "O'Brien"),
        expect: () => [
          const CodeGenerating(),
          isA<CodeGenerated>().having(
            (state) => state.code.memberName,
            'member name with apostrophe',
            "O'Brien",
          ),
        ],
        verify: (_) {
          verify(mockRepository.generateCode('trip-123', "O'Brien")).called(1);
        },
      );
    });
  });

  group('T038: DevicePairingCubit.validateCode() -', () {
    late DevicePairingCubit cubit;
    late MockDeviceLinkCodeRepository mockRepository;
    late MockLocalStorageService mockLocalStorageService;

    setUp(() {
      mockRepository = MockDeviceLinkCodeRepository();
      mockLocalStorageService = MockLocalStorageService();
      cubit = DevicePairingCubit(
        repository: mockRepository,
        localStorageService: mockLocalStorageService,
      );
    });

    tearDown(() {
      cubit.close();
    });

    group('validateCode() -', () {
      blocTest<DevicePairingCubit, DevicePairingState>(
        'should emit [CodeValidating, CodeValidated] when validation succeeds',
        build: () {
          // Arrange - Mock successful validation
          final mockCode = DeviceLinkCode(
            id: 'code-123',
            code: '1234-5678',
            tripId: 'trip-456',
            memberName: 'Alice',
            createdAt: DateTime(2025, 1, 15, 10, 0),
            expiresAt: DateTime(2025, 1, 15, 10, 15),
            used: true, // Now marked as used
            usedAt: DateTime(2025, 1, 15, 10, 5),
          );

          when(mockRepository.validateCode('trip-456', '1234-5678', 'Alice'))
              .thenAnswer((_) async => mockCode);

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-456', '1234-5678', 'Alice'),
        expect: () => [
          const CodeValidating(),
          isA<CodeValidated>().having(
            (state) => state.tripId,
            'trip id',
            'trip-456',
          ),
        ],
        verify: (_) {
          verify(mockRepository.validateCode('trip-456', '1234-5678', 'Alice'))
              .called(1);
        },
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should emit [CodeValidating, CodeValidationError] for invalid code',
        build: () {
          // Arrange - Mock validation failure (invalid code)
          when(mockRepository.validateCode(any, any, any))
              .thenThrow(Exception('Invalid code'));

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-456', '9999-9999', 'Bob'),
        expect: () => [
          const CodeValidating(),
          isA<CodeValidationError>().having(
            (state) => state.message,
            'error message',
            contains('Invalid code'),
          ),
        ],
        verify: (_) {
          verify(mockRepository.validateCode('trip-456', '9999-9999', 'Bob'))
              .called(1);
        },
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should emit error for expired code',
        build: () {
          when(mockRepository.validateCode(any, any, any))
              .thenThrow(Exception('Code has expired'));

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-123', '1234-5678', 'Alice'),
        expect: () => [
          const CodeValidating(),
          isA<CodeValidationError>().having(
            (state) => state.message,
            'error message',
            contains('expired'),
          ),
        ],
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should emit error for already used code',
        build: () {
          when(mockRepository.validateCode(any, any, any))
              .thenThrow(Exception('Code has already been used'));

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-123', '1234-5678', 'Alice'),
        expect: () => [
          const CodeValidating(),
          isA<CodeValidationError>().having(
            (state) => state.message,
            'error message',
            contains('already been used'),
          ),
        ],
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should emit error for member name mismatch',
        build: () {
          when(mockRepository.validateCode(any, any, any))
              .thenThrow(Exception('Member name does not match'));

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-123', '1234-5678', 'Bob'),
        expect: () => [
          const CodeValidating(),
          isA<CodeValidationError>().having(
            (state) => state.message,
            'error message',
            contains('does not match'),
          ),
        ],
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should call repository with correct parameters',
        build: () {
          final mockCode = DeviceLinkCode(
            id: 'code-789',
            code: '9876-5432',
            tripId: 'trip-tokyo',
            memberName: 'Charlie',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: true,
            usedAt: DateTime.now(),
          );

          when(mockRepository.validateCode('trip-tokyo', '9876-5432', 'Charlie'))
              .thenAnswer((_) async => mockCode);

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-tokyo', '9876-5432', 'Charlie'),
        verify: (_) {
          // Verify exact parameters passed to repository
          verify(mockRepository.validateCode('trip-tokyo', '9876-5432', 'Charlie'))
              .called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should handle network timeout errors gracefully',
        build: () {
          when(mockRepository.validateCode(any, any, any))
              .thenThrow(Exception('Network timeout'));

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-123', '1234-5678', 'Alice'),
        expect: () => [
          const CodeValidating(),
          isA<CodeValidationError>().having(
            (state) => state.message,
            'error message',
            contains('Network timeout'),
          ),
        ],
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should handle case-insensitive name matching',
        build: () {
          final mockCode = DeviceLinkCode(
            id: 'code-case',
            code: '1234-5678',
            tripId: 'trip-123',
            memberName: 'Alice',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: true,
            usedAt: DateTime.now(),
          );

          // Repository should handle case-insensitive matching
          when(mockRepository.validateCode('trip-123', '1234-5678', 'ALICE'))
              .thenAnswer((_) async => mockCode);

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-123', '1234-5678', 'ALICE'),
        expect: () => [
          const CodeValidating(),
          isA<CodeValidated>().having((s) => s.tripId, 'tripId', 'trip-123'),
        ],
        verify: (_) {
          verify(mockRepository.validateCode('trip-123', '1234-5678', 'ALICE'))
              .called(1);
        },
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should handle code with hyphen',
        build: () {
          final mockCode = DeviceLinkCode(
            id: 'code-123',
            code: '1234-5678',
            tripId: 'trip-123',
            memberName: 'Alice',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: true,
            usedAt: DateTime.now(),
          );

          when(mockRepository.validateCode('trip-123', '1234-5678', 'Alice'))
              .thenAnswer((_) async => mockCode);

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-123', '1234-5678', 'Alice'),
        expect: () => [
          const CodeValidating(),
          isA<CodeValidated>(),
        ],
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should handle code without hyphen',
        build: () {
          final mockCode = DeviceLinkCode(
            id: 'code-123',
            code: '1234-5678',
            tripId: 'trip-123',
            memberName: 'Alice',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: true,
            usedAt: DateTime.now(),
          );

          // Repository normalizes code internally
          when(mockRepository.validateCode('trip-123', '12345678', 'Alice'))
              .thenAnswer((_) async => mockCode);

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-123', '12345678', 'Alice'),
        expect: () => [
          const CodeValidating(),
          isA<CodeValidated>(),
        ],
        verify: (_) {
          verify(mockRepository.validateCode('trip-123', '12345678', 'Alice'))
              .called(1);
        },
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should handle member names with special characters',
        build: () {
          final mockCode = DeviceLinkCode(
            id: 'code-special',
            code: '5555-6666',
            tripId: 'trip-123',
            memberName: "O'Brien",
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: true,
            usedAt: DateTime.now(),
          );

          when(mockRepository.validateCode('trip-123', '5555-6666', "O'Brien"))
              .thenAnswer((_) async => mockCode);

          return cubit;
        },
        act: (cubit) => cubit.validateCode('trip-123', '5555-6666', "O'Brien"),
        expect: () => [
          const CodeValidating(),
          isA<CodeValidated>(),
        ],
        verify: (_) {
          verify(mockRepository.validateCode('trip-123', '5555-6666', "O'Brien"))
              .called(1);
        },
      );

      blocTest<DevicePairingCubit, DevicePairingState>(
        'should handle multiple consecutive validateCode calls',
        build: () {
          final code1 = DeviceLinkCode(
            id: 'code-1',
            code: '1234-5678',
            tripId: 'trip-1',
            memberName: 'Alice',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: true,
            usedAt: DateTime.now(),
          );

          final code2 = DeviceLinkCode(
            id: 'code-2',
            code: '8765-4321',
            tripId: 'trip-1',
            memberName: 'Bob',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
            used: true,
            usedAt: DateTime.now(),
          );

          when(mockRepository.validateCode('trip-1', '1234-5678', 'Alice'))
              .thenAnswer((_) async => code1);
          when(mockRepository.validateCode('trip-1', '8765-4321', 'Bob'))
              .thenAnswer((_) async => code2);

          return cubit;
        },
        act: (cubit) async {
          await cubit.validateCode('trip-1', '1234-5678', 'Alice');
          await cubit.validateCode('trip-1', '8765-4321', 'Bob');
        },
        expect: () => [
          const CodeValidating(),
          isA<CodeValidated>().having((s) => s.tripId, 'first validation', 'trip-1'),
          const CodeValidating(),
          isA<CodeValidated>().having((s) => s.tripId, 'second validation', 'trip-1'),
        ],
        verify: (_) {
          verify(mockRepository.validateCode('trip-1', '1234-5678', 'Alice'))
              .called(1);
          verify(mockRepository.validateCode('trip-1', '8765-4321', 'Bob'))
              .called(1);
        },
      );
    });
  });
}
