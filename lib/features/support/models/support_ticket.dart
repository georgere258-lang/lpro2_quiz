// PATH: lib/features/support/models/support_ticket.dart

import '../../../core/models/admin_control_models.dart';

/// Valid ticket statuses.
class TicketStatus {
  static const String open = 'open';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String closed = 'closed';

  static const List<String> values = [open, inProgress, resolved, closed];

  static bool isValid(String value) => values.contains(value);
}

/// Support ticket model.
class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String subject;
  final String status;
  final String? assignedTo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;
  final int messageCount;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.subject,
    this.status = TicketStatus.open,
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
    this.messageCount = 0,
  });

  void validate() {
    if (userId.trim().isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    if (userName.trim().isEmpty) {
      throw ArgumentError('userName cannot be empty');
    }
    if (subject.trim().isEmpty) {
      throw ArgumentError('subject cannot be empty');
    }
    if (subject.trim().length > 100) {
      throw ArgumentError('subject cannot exceed 100 characters');
    }
    if (!TicketStatus.isValid(status)) {
      throw ArgumentError('status must be one of: ${TicketStatus.values}');
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId.trim(),
      'userName': userName.trim(),
      'subject': subject.trim(),
      'status': status,
      if (assignedTo != null) 'assignedTo': assignedTo,
      'messageCount': messageCount,
    };
  }

  factory SupportTicket.fromFirestore(Map<String, dynamic> data, String id) {
    return SupportTicket(
      id: id,
      userId: (data['userId'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? '',
      subject: (data['subject'] as String?) ?? '',
      status: (data['status'] as String?) ?? TicketStatus.open,
      assignedTo: data['assignedTo'] as String?,
      createdAt: UtcNormalizer.fromTimestamp(data['createdAt']),
      updatedAt: UtcNormalizer.fromTimestamp(data['updatedAt']),
      lastMessageAt: UtcNormalizer.fromTimestamp(data['lastMessageAt']),
      messageCount: (data['messageCount'] as int?) ?? 0,
    );
  }
}
