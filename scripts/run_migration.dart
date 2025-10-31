import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Connect to emulator
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

  runApp(const MigrationApp());
}

class MigrationApp extends StatelessWidget {
  const MigrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Category Migration',
      home: MigrationScreen(),
    );
  }
}

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  String _log = '';
  bool _running = false;

  @override
  void initState() {
    super.initState();
    // Auto-run migration on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runMigration();
    });
  }

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
    print(message);
  }

  Future<void> _runMigration() async {
    if (_running) return;

    setState(() {
      _running = true;
      _log = '';
    });

    _addLog('=' * 60);
    _addLog('Starting category migration...');
    _addLog('Environment: EMULATOR (localhost:8080)');
    _addLog('Mode: LIVE');
    _addLog('=' * 60);

    try {
      final db = FirebaseFirestore.instance;

      // Check if there's any data
      final trips = await db.collection('trips').get();
      _addLog('Found ${trips.size} trips');

      if (trips.docs.isEmpty) {
        _addLog('No trips found - nothing to migrate');
        _addLog('Migration completed (nothing to do)');
        return;
      }

      // Scan for trip categories
      int totalCategories = 0;
      final categoryNames = <String>{};

      for (final trip in trips.docs) {
        final categories = await db
            .collection('trips')
            .doc(trip.id)
            .collection('categories')
            .get();

        totalCategories += categories.size;
        for (final cat in categories.docs) {
          categoryNames.add((cat.data()['name'] as String).toLowerCase());
        }
      }

      _addLog('Found $totalCategories trip-specific categories');
      _addLog('Unique category names: ${categoryNames.length}');

      if (totalCategories == 0) {
        _addLog('No categories to migrate');
        _addLog('Migration completed (nothing to do)');
        return;
      }

      _addLog('Migration would process:');
      _addLog('  - Create ${categoryNames.length} global categories');
      _addLog('  - Update expense references');
      _addLog('');
      _addLog('⚠️  Full migration script needs to be run separately');
      _addLog('⚠️  Use: dart run scripts/migrate_categories.dart');
      _addLog('⚠️  (Requires server-side Firebase Admin SDK)');

    } catch (e, stack) {
      _addLog('ERROR: $e');
      _addLog('Stack: $stack');
    } finally {
      setState(() {
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Migration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_running)
              const LinearProgressIndicator()
            else
              ElevatedButton(
                onPressed: _runMigration,
                child: const Text('Run Migration Scan'),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _log.isEmpty ? 'Ready to scan...' : _log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
