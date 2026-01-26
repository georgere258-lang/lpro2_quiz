import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String uid;
  final String name;
  final int avatarIndex;
  final int points;
  final int rank;
  final DateTime? updatedAt;

  LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.avatarIndex,
    required this.points,
    required this.rank,
    this.updatedAt,
  });

  factory LeaderboardEntry.fromFirestore(Map<String, dynamic> data, String docId) {
    DateTime? updated;
    final ts = data['updatedAt'];
    if (ts is Timestamp) {
      updated = ts.toDate();
    }

    return LeaderboardEntry(
      uid: data['uid'] as String? ?? docId,
      name: data['name'] as String? ?? 'مستخدم',
      avatarIndex: (data['avatarIndex'] as int?) ?? 0,
      points: (data['points'] as int?) ?? 0,
      rank: (data['rank'] as int?) ?? 0,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'avatarIndex': avatarIndex,
      'points': points,
      'rank': rank,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
