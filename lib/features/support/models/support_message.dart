// PATH: lib/features/support/models/support_message.dart

import '../../../core/models/admin_control_models.dart';

/// Support message model.
class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? sentAt;
  final bool isAdminMessage;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.sentAt,
    this.isAdminMessage = false,
  });

  void validate() {
    if (ticketId.trim().isEmpty) {
      throw ArgumentError('ticketId cannot be empty');
    }
    if (senderId.trim().isEmpty) {
      throw ArgumentError('senderId cannot be empty');
    }
    if (senderName.trim().isEmpty) {
      throw ArgumentError('senderName cannot be empty');
    }
    if (text.trim().isEmpty) {
      throw ArgumentError('text cannot be empty');
    }
    if (text.trim().length > 1000) {
      throw ArgumentError('text cannot exceed 1000 characters');
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ticketId': ticketId.trim(),
      'senderId': senderId.trim(),
      'senderName': senderName.trim(),
      'text': text.trim(),
      'isAdminMessage': isAdminMessage,
    };
  }

  factory SupportMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return SupportMessage(
      id: id,
      ticketId: (data['ticketId'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      sentAt: UtcNormalizer.fromTimestamp(data['sentAt']),
      isAdminMessage: data['isAdminMessage'] == true,
    );
  }
}
