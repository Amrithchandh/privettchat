import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/message.dart';
import 'export_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> { 
  final _chatService = ChatService();
  final _authService = AuthService();
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  
  bool _showEmojiPicker = false;
  bool _isTyping = false;
  bool _isRecording = false;
  Message? _replyingTo;
  
  late final String _myUserId;

  @override
  void initState() {
    super.initState();
    _myUserId = _authService.currentUser?.uid ?? 'unknown';
    
    _textController.addListener(() {
      if (_textController.text.isNotEmpty && !_isTyping) {
        setState(() => _isTyping = true);
      } else if (_textController.text.isEmpty && _isTyping) {
        setState(() => _isTyping = false);
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(source: source);
    if (image != null) {
      await _chatService.sendMessage(
        senderId: _myUserId,
        text: "📷 Photo",
        type: MessageType.image,
        file: File(image.path),
        replyToId: _replyingTo?.id,
      );
      setState(() => _replyingTo = null);
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      await _chatService.sendMessage(
        senderId: _myUserId,
        text: "🎥 Video",
        type: MessageType.video,
        file: File(video.path),
        replyToId: _replyingTo?.id,
      );
      setState(() => _replyingTo = null);
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = p.basename(file.path);
      await _chatService.sendMessage(
        senderId: _myUserId,
        text: fileName,
        type: MessageType.document,
        file: file,
        replyToId: _replyingTo?.id,
      );
      setState(() => _replyingTo = null);
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = p.basename(file.path);
      await _chatService.sendMessage(
        senderId: _myUserId,
        text: fileName,
        type: MessageType.audio,
        file: file,
        replyToId: _replyingTo?.id,
      );
      setState(() => _replyingTo = null);
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;
    
    final text = _textController.text;
    _textController.clear();
    
    await _chatService.sendMessage(
      senderId: _myUserId,
      text: text,
      replyToId: _replyingTo?.id,
    );
    setState(() => _replyingTo = null);
  }

  Future<void> _toggleAudioRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
         await _chatService.sendMessage(
           senderId: _myUserId,
           text: "🎵 Voice Note",
           type: MessageType.audio,
           file: File(path),
           replyToId: _replyingTo?.id,
         );
         setState(() => _replyingTo = null);
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = p.join(dir.path, "audio_${DateTime.now().millisecondsSinceEpoch}.m4a");
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _attachmentItem(Icons.insert_drive_file, Colors.deepPurple, "Document", _pickDocument),
            _attachmentItem(Icons.camera_alt, Colors.pink, "Camera", () => _pickImage(ImageSource.camera)),
            _attachmentItem(Icons.photo, Colors.purple, "Gallery", () => _pickImage(ImageSource.gallery)),
            _attachmentItem(Icons.videocam, Colors.orange, "Video", _pickVideo),
            _attachmentItem(Icons.headset, Colors.orangeAccent, "Audio", _pickAudio),
            _attachmentItem(Icons.location_on, Colors.green, "Location", () {}),
            _attachmentItem(Icons.person, Colors.blue, "Contact", () {}),
          ],
        ),
      ),
    );
  }

  Widget _attachmentItem(IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _onReplySelected(Message message) {
    setState(() => _replyingTo = message);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: AppBar(
        titleSpacing: 0,
        leading: const BackButton(),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Partner", style: TextStyle(fontSize: 16)),
                  Text("Online", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: _pickVideo),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Export chat')),
              const PopupMenuItem(value: 'clear', child: Text('Clear chat')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _myUserId;
                    
                    return SwipeTo(
                      onRightSwipe: (details) => _onReplySelected(msg),
                      child: _buildMessageBubble(msg, isMe),
                    );
                  },
                );
              },
            ),
          ),
          if (_replyingTo != null) _buildReplyPreview(),
          _buildInputBar(),
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(width: 5, height: 40, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyingTo!.senderId == _myUserId ? "You" : "Partner",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                ),
                Text(_replyingTo!.text, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: _cancelReply),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    if (msg.isDeleted) {
       return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
          child: const Text("🚫 This message was deleted", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        )
       );
    }

    final time = DateFormat('HH:mm').format(msg.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.replyToId != null) 
              Container(
                padding: const EdgeInsets.all(5),
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(5)),
                child: const Text("Replying to a message...", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              ),
            if (msg.type == MessageType.image && msg.mediaUrl != null)
              GestureDetector(
                onTap: () {}, // Full screen view
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: msg.mediaUrl!,
                    placeholder: (context, url) => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              )
            else if (msg.type == MessageType.video && msg.mediaUrl != null)
              Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white70)),
              )
            else if (msg.type == MessageType.audio)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.green),
                  Container(height: 2, width: 100, color: Colors.grey.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 5)),
                  const Icon(Icons.mic, color: Colors.grey, size: 16),
                ]
              )
            else if (msg.type == MessageType.document)
              GestureDetector(
                onTap: () async {
                  if (msg.mediaUrl != null) await OpenFilex.open(msg.mediaUrl!);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(child: Text(msg.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
            if (msg.type == MessageType.text)
              Text(msg.text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(),
                Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.status == 'read' ? Icons.done_all : Icons.done,
                    size: 14,
                    color: msg.status == 'read' ? Colors.blue : Colors.grey[600],
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined),
                    color: Colors.grey[600],
                    onPressed: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: 6,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: "Message",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    color: Colors.grey[600],
                    onPressed: _showAttachmentMenu,
                  ),
                  if (!_isTyping) IconButton(
                    icon: const Icon(Icons.camera_alt),
                    color: Colors.grey[600],
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF075E54),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(_isTyping ? Icons.send : (_isRecording ? Icons.stop : Icons.mic), color: Colors.white),
              onPressed: _isTyping ? _sendMessage : _toggleAudioRecording,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (cat, emoji) {
          _textController.text = _textController.text + emoji.emoji;
        },
      ),
    );
  }
}
