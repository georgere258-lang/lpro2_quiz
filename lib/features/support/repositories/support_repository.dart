// PATH: lib/features/support/repositories/support_repository.dart
//
// FIX: Align SupportRepository writes with Firestore Rules (Support hardened)
// ✅ No serverTimestamp() for fields validated as timestamp in rules
// ✅ messages payload keys EXACTLY: senderId, isAdminMessage, text, sentAt
// ✅ ticket owner update keys EXACTLY: lastMessage, updatedAt
// ✅ ticket admin/mod update: full fields allowed (status/assignedTo/messageCount...)
// ✅ Keeps existing public API as much as possible

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/support_message.dart';
import '../models/support_ticket.dart';

/// Repository for support ticket and message operations.
class SupportRepository {
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _ticketsRef;

  static const String _messagesSubcollection = 'messages';

  SupportRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _ticketsRef = _firestore.collection(FirestorePaths.supportTickets);
  }

  // ─────────────────────────────────────────────────────────────────
  // Ticket Methods
  // ─────────────────────────────────────────────────────────────────

  Stream<List<SupportTicket>> watchUserTickets(String userId) {
    return _ticketsRef
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SupportTicket.fromFirestore(d.data(), d.id))
            .toList());
  }

  Stream<List<SupportTicket>> watchAllTickets() {
    return _ticketsRef
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SupportTicket.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<String> createTicket(
    String userId,
    String userName,
    String subject,
  ) async {
    if (subject.trim().isEmpty) throw ArgumentError('Subject cannot be empty');

    final ticket = SupportTicket(
      id: '',
      userId: userId,
      userName: userName,
      subject: subject.trim(),
      status: TicketStatus.open,
      messageCount: 0,
    );
    ticket.validate();

    final now = Timestamp.now();

    final data = ticket.toFirestore();
    // ✅ Use concrete timestamps (Rules that validate timestamp will pass)
    data['createdAt'] = now;
    data['updatedAt'] = now;

    final docRef = await _ticketsRef.add(data);
    return docRef.id;
  }

  Future<void> updateStatus(String ticketId, String status) async {
    if (!TicketStatus.isValid(status)) {
      throw ArgumentError('Invalid status: $status');
    }

    await _ticketsRef.doc(ticketId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> assignTicket(String ticketId, String adminUid) async {
    if (adminUid.trim().isEmpty) {
      throw ArgumentError('adminUid cannot be empty');
    }

    await _ticketsRef.doc(ticketId).update({
      'assignedTo': adminUid.trim(),
      'status': TicketStatus.inProgress,
      'updatedAt': Timestamp.now(),
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Message Methods
  // ─────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _messagesRef(String ticketId) {
    return _ticketsRef.doc(ticketId).collection(_messagesSubcollection);
  }

  Stream<List<SupportMessage>> watchMessages(String ticketId) {
    return _messagesRef(ticketId)
        .orderBy('sentAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SupportMessage.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<String> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String text,
    required bool isAdmin,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) throw ArgumentError('Message text cannot be empty');

    // Keep model validation (even though we will not store all fields in Firestore message doc)
    final message = SupportMessage(
      id: '',
      ticketId: ticketId,
      senderId: senderId,
      senderName: senderName,
      text: cleanText,
      isAdminMessage: isAdmin,
    );
    message.validate();

    final ticketDoc = _ticketsRef.doc(ticketId);
    final messagesCol = _messagesRef(ticketId);

    final now = Timestamp.now();

    return _firestore.runTransaction((tx) async {
      final ticketSnap = await tx.get(ticketDoc);
      if (!ticketSnap.exists) {
        throw ArgumentError('Ticket not found: $ticketId');
      }

      // ✅ Rules require EXACT message keys:
      // senderId, isAdminMessage, text, sentAt
      final messageData = <String, dynamic>{
        'senderId': senderId,
        'isAdminMessage': isAdmin,
        'text': cleanText,
        'sentAt': now,
      };

      final newMessageRef = messagesCol.doc();
      tx.set(newMessageRef, messageData);

      // ✅ Ticket update must match rules:
      // - Moderator: full update allowed
      // - Owner: ONLY lastMessage + updatedAt allowed
      if (isAdmin) {
        final currentCount = (ticketSnap.data()?['messageCount'] as int?) ?? 0;

        tx.update(ticketDoc, {
          'messageCount': currentCount + 1,
          'lastMessage': cleanText,
          // keep if your model/UI uses it (mods can write anything)
          'lastMessageAt': now,
          'updatedAt': now,
        });
      } else {
        // Owner-safe update (matches hardened rules exactly)
        tx.update(ticketDoc, {
          'lastMessage': cleanText,
          'updatedAt': now,
        });
      }

      return newMessageRef.id;
    });
  }
}
