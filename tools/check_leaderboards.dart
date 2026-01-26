import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../lib/firebase_options.dart';

void main() async {
  print('═══════════════════════════════════════════════');
  print('LEADERBOARDS DIAGNOSTIC SCRIPT');
  print('═══════════════════════════════════════════════\n');

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final app = Firebase.app();
    print('Firebase initialized:');
    print('  projectId: ${app.options.projectId}');
    print('  appId: ${app.options.appId}');
    print('');

    final firestore = FirebaseFirestore.instance;
    final leagues = ['general', 'stars', 'pros'];

    for (final league in leagues) {
      print('─────────────────────────────────────────────');
      print('League: $league');
      print('Path: /leaderboards/$league/entries');
      print('─────────────────────────────────────────────');

      try {
        final entriesRef = firestore
            .collection('leaderboards')
            .doc(league)
            .collection('entries');

        // Count documents
        final countSnap = await entriesRef.count().get();
        final count = countSnap.count ?? 0;
        print('Total documents: $count');

        if (count == 0) {
          print('⚠️  Collection is EMPTY\n');
          continue;
        }

        // Get first 3 documents (raw)
        print('\nFirst 3 documents (raw):');
        final first3Snap = await entriesRef.limit(3).get();
        for (int i = 0; i < first3Snap.docs.length; i++) {
          final doc = first3Snap.docs[i];
          final data = doc.data();
          print('  Doc ${i + 1}:');
          print('    docId: ${doc.id}');
          print('    uid: ${data['uid'] ?? 'MISSING'}');
          print('    rank: ${data['rank'] ?? 'MISSING'} (type: ${data['rank'].runtimeType})');
          print('    points: ${data['points'] ?? 'MISSING'} (type: ${data['points'].runtimeType})');
          print('    name: ${data['name'] ?? 'MISSING'}');
          print('');
        }

        // Test the actual query used by the app (orderBy rank, limit 10)
        print('Testing repository query (orderBy rank, limit 10):');
        try {
          final querySnap = await entriesRef
              .orderBy('rank', descending: false)
              .limit(10)
              .get();

          print('  ✅ Query succeeded');
          print('  Results: ${querySnap.docs.length} documents');
          if (querySnap.docs.isNotEmpty) {
            print('  First result:');
            final first = querySnap.docs.first.data();
            print('    uid: ${first['uid']}');
            print('    rank: ${first['rank']}');
            print('    points: ${first['points']}');
          }
        } catch (e) {
          print('  ❌ Query FAILED');
          if (e is FirebaseException) {
            print('    code: ${e.code}');
            print('    message: ${e.message}');
            print('    plugin: ${e.plugin}');
          } else {
            print('    error: $e');
            print('    type: ${e.runtimeType}');
          }
        }
        print('');

      } catch (e) {
        print('❌ Error reading collection:');
        if (e is FirebaseException) {
          print('  code: ${e.code}');
          print('  message: ${e.message}');
          print('  plugin: ${e.plugin}');
        } else {
          print('  error: $e');
          print('  type: ${e.runtimeType}');
        }
        print('');
      }
    }

    print('═══════════════════════════════════════════════');
    print('DIAGNOSTIC COMPLETE');
    print('═══════════════════════════════════════════════');

  } catch (e) {
    print('❌ Fatal error: $e');
    exit(1);
  }

  exit(0);
}
