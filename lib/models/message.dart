import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio, video, document }

class Message {
  final String id;
  final String senderId;
  final String text;
  final MessageType type;
  final String? mediaUrl;
  final DateTime timestamp;
  final String status; // 'sending', 'sent', 'delivered', 'read'
  final Map<String, String>? reactions;
  final bool isDeleted;
  final String? replyToId;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    required this.timestamp,
    required this.status,
    this.reactions,
    this.isDeleted = false,
    this.replyToId,
  });

  factory Message.fromMap(Map<String, dynamic> data, String documentId) {
    return Message(
      id: documentId,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'text'), 
        orElse: () => MessageType.text
      ),
      mediaUrl: data['mediaUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'sending',
      reactions: data['reactions'] != null 
          ? Map<String, String>.from(data['reactions']) 
          : null,
      isDeleted: data['isDeleted'] ?? false,
      replyToId: data['replyToId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'type': type.name,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      if (reactions != null) 'reactions': reactions,
      'isDeleted': isDeleted,
      if (replyToId != null) 'replyToId': replyToId,
    };
  }
}
