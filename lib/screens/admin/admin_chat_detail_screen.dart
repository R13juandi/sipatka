import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/models/profile_model.dart';
import 'package:sipatka/providers/auth_provider.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final Profile user;
  const AdminChatDetailScreen({super.key, required this.user});

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final _messageController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  late final String _adminId;

  @override
  void initState() {
    super.initState();
    _adminId = context.read<AuthProvider>().profile!.id;
    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', widget.user.id)
        .order('created_at', ascending: false);
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    await supabase.from('messages').insert({
      'user_id': widget.user.id,
      'sender_id': _adminId,
      'content': content,
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat dengan ${widget.user.parentName ?? 'Wali'}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Mulai percakapan dengan ${widget.user.parentName ?? 'wali'}."));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isAdminSender = message['sender_id'] == _adminId;
                    return _buildMessageBubble(text: message['content'], isFromAdmin: isAdminSender);
                  },
                );
              },
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }
  
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(8.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Ketik pesan...',
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({required String text, required bool isFromAdmin}) {
    return Align(
      alignment: isFromAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFromAdmin ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(color: isFromAdmin ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}