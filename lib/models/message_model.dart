class Message {
  final BigInt id;
  final String content;
  final String senderId;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: BigInt.parse(map['id'].toString()),
      content: map['content'],
      senderId: map['sender_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}