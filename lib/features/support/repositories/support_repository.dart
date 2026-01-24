// PATH: lib/features/support/repositories/support_repository.dart

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

  /// Watches tickets for a specific user.
  Stream<List<SupportTicket>> watchUserTickets(String userId) {
    return _ticketsRef
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SupportTicket.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Watches all tickets (admin only).
  Stream<List<SupportTicket>> watchAllTickets() {
    return _ticketsRef
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SupportTicket.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Creates a new support ticket.
  Future<String> createTicket(
    String userId,
    String userName,
    String subject,
  ) async {
    final ticket = SupportTicket(
      id: '',
      userId: userId,
      userName: userName,
      subject: subject,
      status: TicketStatus.open,
      messageCount: 0,
    );
    ticket.validate();

    final data = ticket.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    final docRef = await _ticketsRef.add(data);
    return docRef.id;
  }

  /// Updates the status of a ticket.
  Future<void> updateStatus(String ticketId, String status) async {
    if (!TicketStatus.isValid(status)) {
      throw ArgumentError('Invalid status: $status');
    }

    await _ticketsRef.doc(ticketId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Assigns a ticket to an admin.
  Future<void> assignTicket(String ticketId, String adminUid) async {
    if (adminUid.trim().isEmpty) {
      throw ArgumentError('adminUid cannot be empty');
    }

    await _ticketsRef.doc(ticketId).update({
      'assignedTo': adminUid.trim(),
      'status': TicketStatus.inProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Message Methods
  // ─────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _messagesRef(String ticketId) {
    return _ticketsRef.doc(ticketId).collection(_messagesSubcollection);
  }

  /// Watches messages for a ticket (ordered by sentAt asc).
  Stream<List<SupportMessage>> watchMessages(String ticketId) {
    return _messagesRef(ticketId)
        .orderBy('sentAt', descending: false)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SupportMessage.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Sends a message to a ticket (uses transaction to increment messageCount).
  Future<String> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String text,
    required bool isAdmin,
  }) async {
    final message = SupportMessage(
      id: '',
      ticketId: ticketId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      isAdminMessage: isAdmin,
    );
    message.validate();

    final ticketDoc = _ticketsRef.doc(ticketId);
    final messagesCol = _messagesRef(ticketId);

    return _firestore.runTransaction((tx) async {
      final ticketSnap = await tx.get(ticketDoc);
      if (!ticketSnap.exists) {
        throw ArgumentError('Ticket not found: $ticketId');
      }

      final currentCount = (ticketSnap.data()?['messageCount'] as int?) ?? 0;

      final messageData = message.toFirestore();
      messageData['sentAt'] = FieldValue.serverTimestamp();

      final newMessageRef = messagesCol.doc();
      tx.set(newMessageRef, messageData);

      tx.update(ticketDoc, {
        'messageCount': currentCount + 1,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return newMessageRef.id;
    });
  }
}
