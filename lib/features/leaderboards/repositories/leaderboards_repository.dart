import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry.dart';

/// Repository for public leaderboard reads and admin refresh operations.
class LeaderboardsRepository {
  final FirebaseFirestore _firestore;

  LeaderboardsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for a specific league.
  CollectionReference<Map<String, dynamic>> _entriesRef(String league) {
    return _firestore.collection('leaderboards').doc(league).collection('entries');
  }

  /// Fetch top 10 entries for a league, ordered by rank ascending.
  Future<List<LeaderboardEntry>> getTop10(String league) async {
    final snap = await _entriesRef(league)
        .orderBy('rank', descending: false)
        .limit(10)
        .get();

    return snap.docs
        .map((d) => LeaderboardEntry.fromFirestore(d.data(), d.id))
        .toList();
  }

  /// Stream top 10 entries for a league (real-time).
  Stream<List<LeaderboardEntry>> streamTop10(String league) {
    return _entriesRef(league)
        .orderBy('rank', descending: false)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LeaderboardEntry.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Fetch current user's entry in a league (by uid).
  /// Returns null if user is not in the leaderboard.
  Future<LeaderboardEntry?> getUserEntry(String league, String uid) async {
    final doc = await _entriesRef(league).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return LeaderboardEntry.fromFirestore(doc.data()!, doc.id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN ONLY: Refresh leaderboard from /users collection.
  // Caller must be admin/moderator (enforced by Firestore rules on write).
  // ═══════════════════════════════════════════════════════════════════════════

  /// Refresh top 10 for all leagues.
  /// Reads /users (admin permission required), computes top 10, writes to /leaderboards.
  Future<void> refreshTop10AsAdmin() async {
    // Read all users with points > 0 (admin has read access to /users)
    final usersSnap = await _firestore
        .collection('users')
        .orderBy('points', descending: true)
        .limit(100) // Fetch more to sort for different leagues
        .get();

    final users = usersSnap.docs.map((d) {
      final data = d.data();
      return {
        'uid': d.id,
        'name': (data['name'] as String?) ?? 'مستخدم',
        'avatarIndex': (data['avatarIndex'] as int?) ?? 0,
        'points': (data['points'] as int?) ?? 0,
        'starsPoints': (data['starsPoints'] as int?) ?? 0,
        'proPoints': (data['proPoints'] as int?) ?? 0,
      };
    }).toList();

    // Refresh each league
    await _refreshLeague('general', users, 'points');
    await _refreshLeague('stars', users, 'starsPoints');
    await _refreshLeague('pros', users, 'proPoints');
  }

  /// Refresh a single league's top 10.
  Future<void> _refreshLeague(
    String league,
    List<Map<String, dynamic>> users,
    String pointsField,
  ) async {
    // Sort by the league's points field
    final sorted = List<Map<String, dynamic>>.from(users)
      ..sort((a, b) => (b[pointsField] as int).compareTo(a[pointsField] as int));

    // Take top 10
    final top10 = sorted.take(10).toList();

    final batch = _firestore.batch();
    final entriesRef = _entriesRef(league);

    // Delete existing entries first (clean slate)
    final existing = await entriesRef.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Write new top 10
    for (int i = 0; i < top10.length; i++) {
      final user = top10[i];
      final uid = user['uid'] as String;
      final entry = LeaderboardEntry(
        uid: uid,
        name: user['name'] as String,
        avatarIndex: user['avatarIndex'] as int,
        points: user[pointsField] as int,
        rank: i + 1,
      );
      batch.set(entriesRef.doc(uid), entry.toFirestore());
    }

    await batch.commit();
  }
}
