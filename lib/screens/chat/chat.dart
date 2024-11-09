import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ChatPage extends StatefulWidget {
  final String chatID;
  final String empName;
  final String empCode;

  const ChatPage({
    Key? key,
    required this.chatID,
    required this.empName,
    required this.empCode,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  late bool isReceiver;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when the chat page is opened
    _markMessagesAsRead(widget.chatID);

    isReceiver = FirebaseAuth.instance.currentUser!.uid != widget.empCode;

    // If the current user is the receiver, mark messages as seen when they open the chat
    if (isReceiver) {
      markMessagesAsSeen(widget.chatID, FirebaseAuth.instance.currentUser!.uid);
    }

    // If the current user is the sender, listen to changes in the 'seenBy' field to update ticks in real-time
    if (!isReceiver) {
      listenForSeenStatus(widget.chatID);
    }
  }

  // Function to listen for changes in the seenBy array (for sender)
  void listenForSeenStatus(String chatId) {
    FirebaseFirestore.instance
        .collection('chat')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .listen((snapshot) {
      setState(
          () {}); // Trigger UI update to show the correct tick icon in real-time
    });
  }

  // Function to mark messages as seen by the receiver
  Future<void> markMessagesAsSeen(String chatId, String userId) async {
    final messages = await FirebaseFirestore.instance
        .collection('chat')
        .doc(chatId)
        .collection('messages')
        .where('seenBy', isNotEqualTo: userId)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var message in messages.docs) {
      List seenBy = message['seenBy'] ?? [];

      // Add the receiver to the seenBy array if it's not the sender
      if (message['senderID'] != userId && !seenBy.contains(userId)) {
        batch.update(message.reference, {
          'seenBy': FieldValue.arrayUnion([userId])
        });
      }
    }

    await batch.commit();
  }

  // Function to send message
  void _sendMessage({String? mediaUrl, String? mediaType}) async {
    if (_messageController.text.trim().isEmpty && mediaUrl == null) {
      return;
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Map<String, dynamic> messageData = {
        'text': _messageController.text.trim(),
        'senderID': currentUser.uid,
        'createdAt': Timestamp.now(),
        'seenBy': [], // Initially, seenBy is empty when sent
      };

      if (mediaUrl != null && mediaType != null) {
        messageData['mediaUrl'] = mediaUrl;
        messageData['mediaType'] = mediaType;
      }

      await _firestore
          .collection('chat')
          .doc(widget.chatID)
          .collection('messages')
          .add(messageData);

      _messageController.clear();
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      await _firestore.collection('chat').doc(widget.chatID).update({
        'lastMessage': mediaUrl != null
            ? 'Sent a $mediaType'
            : _messageController.text.trim(),
        'lastMessageAt': Timestamp.now(),
      });
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.empName),
        backgroundColor: Colors.amber,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat')
                  .doc(widget.chatID)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isCurrentUser = message['senderID'] ==
                        FirebaseAuth.instance.currentUser?.uid;
                    var messageData = message.data() as Map<String, dynamic>;
                    DateTime messageDate =
                        (message['createdAt'] as Timestamp).toDate();
                    bool showDate = index == messages.length - 1;

                    // Show date only if it's the first message of the day
                    if (index < messages.length - 1) {
                      DateTime previousMessageDate =
                          (messages[index + 1]['createdAt'] as Timestamp)
                              .toDate();
                      showDate = !isSameDay(messageDate, previousMessageDate);
                    }

                    // Check if the message has been seen by the receiver
                    bool isSeen = messageData['seenBy'] != null &&
                        messageData['seenBy'].isNotEmpty;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                DateFormat('dd MMMM yyyy').format(messageDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ListTile(
                          title: Align(
                            alignment: isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.amber[200]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['text'] ?? '',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  if (messageData['mediaUrl'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Image.network(
                                        messageData['mediaUrl'],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  // Show single or double green tick based on "seenBy"
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isSeen)
                                        Icon(Icons.check_circle,
                                            size: 20, color: Colors.green),
                                      if (!isSeen)
                                        Icon(Icons.check,
                                            size: 16, color: Colors.green),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          subtitle: Align(
                            alignment: isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Text(
                              _formatTimestamp(message['createdAt']),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.amber),
                  onPressed: () {
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead(String chatID) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Fetch all messages in the chat
      QuerySnapshot messageSnapshot = await FirebaseFirestore.instance
          .collection('chat')
          .doc(chatID)
          .collection('messages')
          .where('seenBy',
              isNotEqualTo: currentUser.uid) // Only unread messages
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Iterate over each message to mark them as seen
      for (var message in messageSnapshot.docs) {
        batch.update(message.reference, {
          'seenBy': FieldValue.arrayUnion(
              [currentUser.uid]), // Mark the message as seen
        });
      }

      // Commit the batch to update the messages
      await batch.commit();

      // Now, update the unreadCount field for the chat
      int unreadCount = await _getUnreadCount(chatID, currentUser.uid);

      // Update the unread count in the chat document
      await FirebaseFirestore.instance.collection('chat').doc(chatID).update({
        'unreadCount': unreadCount,
      });
    }
  }

  Future<int> _getUnreadCount(String chatID, String userID) async {
    // Fetch all messages in the chat
    QuerySnapshot messageSnapshot = await FirebaseFirestore.instance
        .collection('chat')
        .doc(chatID)
        .collection('messages')
        .get();

    int unreadCount = 0;

    // Count unread messages (messages that the user has not seen)
    for (var message in messageSnapshot.docs) {
      if (!message['seenBy'].contains(userID)) {
        unreadCount++;
      }
    }

    return unreadCount;
  }
}
