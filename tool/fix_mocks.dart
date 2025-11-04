/// Post-build script to fix mockito-generated mock files
///
/// This script fixes the CurrencyCode type resolution issue in generated mocks.
/// Mockito cannot resolve types from generated files during its code generation,
/// so it falls back to `dynamic` for CurrencyCode (which is in currency_code_generated.dart).
///
/// This script runs after build_runner and automatically:
/// 1. Adds CurrencyCode import to all .mocks.dart files
/// 2. Replaces List<dynamic> with List<CurrencyCode> in getAllowedCurrencies
/// 3. Replaces String? with String (non-nullable) in method parameters
///
/// Usage:
///   dart tool/fix_mocks.dart
///
/// Or as part of build process:
///   dart run build_runner build && dart tool/fix_mocks.dart

import 'dart:io';

void main() async {
  print('🔧 Fixing mockito-generated files for CurrencyCode...');

  final mockFiles = await _findMockFiles();

  if (mockFiles.isEmpty) {
    print('⚠️  No .mocks.dart files found');
    return;
  }

  print('Found ${mockFiles.length} mock files');

  int fixedCount = 0;
  for (final file in mockFiles) {
    if (await _fixMockFile(file)) {
      fixedCount++;
    }
  }

  print('\n✅ Fixed $fixedCount mock file(s)');
}

/// Find all .mocks.dart files in the project
Future<List<File>> _findMockFiles() async {
  final testDir = Directory('test');
  if (!await testDir.exists()) {
    return [];
  }

  final mockFiles = <File>[];
  await for (final entity in testDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.mocks.dart')) {
      mockFiles.add(entity);
    }
  }

  return mockFiles;
}

/// Fix a single mock file
Future<bool> _fixMockFile(File file) async {
  final content = await file.readAsString();

  // Check if file needs fixing
  if (!content.contains('getAllowedCurrencies')) {
    return false;
  }

  // Check if already fixed
  if (content.contains("import 'package:expense_tracker/core/models/currency_code")) {
    print('  ⏭️  ${file.path} - already fixed');
    return false;
  }

  print('  🔧 ${file.path}');

  String fixed = content;

  // Step 1: Add CurrencyCode import after dart:async
  final asyncImportPattern = RegExp(r"import 'dart:async' as _i\d+;");
  final match = asyncImportPattern.firstMatch(fixed);

  if (match != null) {
    final insertPosition = match.end;
    final beforeInsert = fixed.substring(0, insertPosition);
    final afterInsert = fixed.substring(insertPosition);

    fixed = beforeInsert +
            "\n\nimport 'package:expense_tracker/core/models/currency_code.dart' as _iCC;" +
            afterInsert;
  }

  // Step 2: Fix getAllowedCurrencies return type and parameter
  fixed = fixed.replaceAllMapped(
    RegExp(r'Future<List<dynamic>> getAllowedCurrencies\(String\? tripId\)'),
    (match) => 'Future<List<_iCC.CurrencyCode>> getAllowedCurrencies(String tripId)',
  );

  // Step 3: Fix getAllowedCurrencies returnValue
  fixed = fixed.replaceAllMapped(
    RegExp(r'Future<List<dynamic>>\.value\(<dynamic>\[\]\)'),
    (match) => 'Future<List<_iCC.CurrencyCode>>.value(<_iCC.CurrencyCode>[])',
  );

  // Step 4: Fix getAllowedCurrencies returnValueForMissingStub
  fixed = fixed.replaceAllMapped(
    RegExp(r'(getAllowedCurrencies.*?returnValueForMissingStub.*?)<dynamic>(\[\])', dotAll: true),
    (match) => '${match.group(1)}<_iCC.CurrencyCode>${match.group(2)}',
  );

  // Step 5: Fix getAllowedCurrencies cast
  fixed = fixed.replaceAllMapped(
    RegExp(r'as _i\d+\.Future<List<dynamic>>\);[\s\n]+@override[\s\n]+_i\d+\.Future<void> updateAllowedCurrencies'),
    (match) {
      final prefix = match.group(0)!.split('Future<List<dynamic>>')[0];
      final suffix = match.group(0)!.split('Future<List<dynamic>>')[1];
      return '${prefix}Future<List<_iCC.CurrencyCode>>$suffix';
    },
  );

  // Step 6: Fix updateAllowedCurrencies parameters
  fixed = fixed.replaceAllMapped(
    RegExp(r'updateAllowedCurrencies\(\s*String\? tripId,\s*List<dynamic>\? currencies,'),
    (match) => 'updateAllowedCurrencies(\n    String tripId,\n    List<_iCC.CurrencyCode> currencies,',
  );

  // Write fixed content back
  await file.writeAsString(fixed);

  return true;
}
