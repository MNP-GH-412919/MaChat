// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:machat/screens/auth/login_screen.dart';
// import 'package:machat/screens/chat/chat.dart';
// import 'package:machat/screens/profilepage.dart';

// class Homepage extends StatefulWidget {
//   const Homepage({super.key});

//   @override
//   State<Homepage> createState() => _HomepageState();
// }

// class _HomepageState extends State<Homepage> {
//   List<Map<String, dynamic>> chats = [];
//   List<Map<String, dynamic>> filteredChats = [];
//   TextEditingController searchController = TextEditingController();
//   bool isSearching = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchChats();
//   }

//   void _fetchChats() async {
//     User? currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       // Fetch all chats where the current user is a participant
//       QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
//           .collection('chat')
//           .where('participants', arrayContains: currentUser.uid)
//           .get();

//       List<Map<String, dynamic>> tempChats = [];

//       // Iterate over each chat
//       for (var doc in chatSnapshot.docs) {
//         List<String> participants = List<String>.from(doc['participants']);
//         participants.remove(currentUser.uid); // Remove the current user

//         if (participants.isNotEmpty) {
//           DocumentSnapshot userDoc = await FirebaseFirestore.instance
//               .collection('Users')
//               .doc(participants.first)
//               .get();

//           if (userDoc.exists) {
//             Map<String, dynamic> userData =
//                 userDoc.data() as Map<String, dynamic>;
//             String participantName = userData['empname'] ?? 'Unknown User';

//             // Calculate unread message count for this chat
//             int unreadCount = await _getUnreadCount(doc.id, currentUser.uid);

//             // Add the chat info to the list, including unreadCount
//             tempChats.add({
//               'chatID': doc.id,
//               'participantID': participants.first,
//               'participantName': participantName,
//               'unreadCount': unreadCount, // Store the unread count here
//             });
//           }
//         }
//       }

//       if (mounted) {
//         setState(() {
//           chats = tempChats; // Set the fetched chats to the state
//           filteredChats = tempChats; // Set the filtered chats as well
//         });
//       }
//     }
//   }

//   Future<int> _getUnreadCount(String chatID, String userID) async {
//     // Fetch all messages in the chat
//     QuerySnapshot messageSnapshot = await FirebaseFirestore.instance
//         .collection('chat')
//         .doc(chatID)
//         .collection('messages')
//         .get();

//     int unreadCount = 0;

//     // Check each message to see if the current user has seen it
//     for (var message in messageSnapshot.docs) {
//       // If the current user has not seen the message (their ID is not in the seenBy array)
//       if (!message['seenBy'].contains(userID)) {
//         unreadCount++;
//       }
//     }

//     return unreadCount;
//   }

//   void _filterChats(String query) {
//     List<Map<String, dynamic>> results = [];
//     if (query.isEmpty) {
//       results = chats;
//     } else {
//       results = chats
//           .where((chat) => chat['participantName']
//               .toLowerCase()
//               .contains(query.toLowerCase()))
//           .toList();
//     }

//     setState(() {
//       filteredChats = results;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.amber,
//         title: isSearching
//             ? TextField(
//                 controller: searchController,
//                 autofocus: true,
//                 cursorColor: Colors.white,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: const InputDecoration(
//                   hintText: "Search...",
//                   hintStyle: TextStyle(color: Colors.white70),
//                   border: InputBorder.none,
//                 ),
//                 onChanged: (query) => _filterChats(query),
//               )
//             : const Text("Chats"),
//         actions: [
//           IconButton(
//             icon: Icon(isSearching ? Icons.close : Icons.search),
//             onPressed: () {
//               setState(() {
//                 isSearching = !isSearching;
//                 if (!isSearching) {
//                   searchController.clear();
//                   filteredChats = chats;
//                 }
//               });
//             },
//           ),
//           PopupMenuButton<String>(
//             onSelected: (String result) async {
//               if (result == 'Profile') {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => Profilepage()),
//                 );
//               } else if (result == 'Sign Out') {
//                 await FirebaseAuth.instance.signOut();
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => LoginScreen()),
//                 );
//               }
//             },
//             itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//               const PopupMenuItem<String>(
//                 value: 'Profile',
//                 child: Text('Profile'),
//               ),
//               const PopupMenuItem<String>(
//                 value: 'Sign Out',
//                 child: Text('Sign Out'),
//               ),
//             ],
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16.0),
//             ),
//           )
//         ],
//       ),
//       body: ListView.builder(
//         itemCount: filteredChats.length,
//         itemBuilder: (context, index) {
//           var chat = filteredChats[index];
//           return Column(
//             children: [
//               ListTile(
//                 contentPadding: EdgeInsets.symmetric(horizontal: 25.0),
//                 title: Text(
//                   chat['participantName'],
//                   style: const TextStyle(
//                     fontSize: 25,
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//                 trailing: chat['unreadCount'] > 0
//                     ? CircleAvatar(
//                         backgroundColor: Colors.red,
//                         radius: 12,
//                         child: Text(
//                           chat['unreadCount'].toString(),
//                           style: const TextStyle(
//                               color: Colors.white, fontSize: 12),
//                         ),
//                       )
//                     : null,
//                 onTap: () {
//                   _markMessagesAsRead(chat['chatID']);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ChatPage(
//                         chatID: chat['chatID'],
//                         empName: chat['participantName'],
//                         empCode: 'Employee Code',
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               Divider(
//                 height: 1,
//                 thickness: 1,
//                 color: Colors.grey.withOpacity(0.5),
//                 indent: 16,
//                 endIndent: 16,
//               ),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           User? currentUser = FirebaseAuth.instance.currentUser;
//           if (currentUser == null) {
//             return;
//           }

//           showModalBottomSheet(
//             context: context,
//             isScrollControlled: true,
//             shape: const RoundedRectangleBorder(
//               borderRadius: BorderRadius.vertical(
//                 top: Radius.circular(25.0),
//               ),
//             ),
//             builder: (BuildContext context) {
//               return StreamBuilder<QuerySnapshot>(
//                 stream:
//                     FirebaseFirestore.instance.collection('Users').snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (snapshot.hasError) {
//                     return const Center(child: Text('Error fetching data'));
//                   }
//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(child: Text('No data available'));
//                   }

//                   var filteredDocs = snapshot.data!.docs.where((doc) {
//                     return doc.id != currentUser.uid;
//                   }).toList();

//                   filteredDocs.sort((a, b) {
//                     return a['empname']
//                         .toString()
//                         .compareTo(b['empname'].toString());
//                   });

//                   return ClipRRect(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(25.0),
//                     ),
//                     child: Container(
//                       height: MediaQuery.of(context).size.height * 0.75,
//                       color: const Color.fromARGB(255, 249, 246, 235),
//                       child: ListView.builder(
//                         itemCount: filteredDocs.length,
//                         itemBuilder: (context, index) {
//                           var user = filteredDocs[index];
//                           return Container(
//                             margin: const EdgeInsets.symmetric(
//                                 vertical: 8.0, horizontal: 16.0),
//                             padding: const EdgeInsets.all(16.0),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(12.0),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.grey.withOpacity(0.5),
//                                   spreadRadius: 2,
//                                   blurRadius: 5,
//                                   offset: const Offset(0, 3),
//                                 ),
//                               ],
//                             ),
//                             child: ListTile(
//                               title: Text(
//                                 user['empname'],
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w300,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                               subtitle: Text(user['empcode']),
//                               onTap: () async {
//                                 DocumentReference chatRef = await createNewChat(
//                                   currentUser.uid,
//                                   user.id,
//                                 );

//                                 bool chatExists = chats.any(
//                                     (chat) => chat['chatID'] == chatRef.id);

//                                 if (!chatExists) {
//                                   _fetchChats();
//                                 }

//                                 Navigator.pop(context);
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => ChatPage(
//                                       chatID: chatRef.id,
//                                       empName: user['empname'],
//                                       empCode: user['empcode'],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//         backgroundColor: Colors.amber,
//         child: const Icon(Icons.chat),
//       ),
//     );
//   }

//   Future<DocumentReference> createNewChat(
//       String userID, String otherUserID) async {
//     QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
//         .collection('chat')
//         .where('participants', arrayContains: userID)
//         .get();

//     final filteredChats = chatSnapshot.docs.where(
//       (doc) => (doc['participants'] as List).contains(otherUserID),
//     );

//     if (filteredChats.isNotEmpty) {
//       return filteredChats.first.reference;
//     } else {
//       DocumentReference newChatRef =
//           FirebaseFirestore.instance.collection('chat').doc();

//       await newChatRef.set({
//         'participants': [userID, otherUserID],
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       return newChatRef;
//     }
//   }

//   void _markMessagesAsRead(String chatID) async {
//     User? currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       // Fetch all messages in the chat
//       QuerySnapshot messageSnapshot = await FirebaseFirestore.instance
//           .collection('chat')
//           .doc(chatID)
//           .collection('messages')
//           .where('seenBy',
//               isNotEqualTo: currentUser.uid) // Only unread messages
//           .get();

//       WriteBatch batch = FirebaseFirestore.instance.batch();

//       // Iterate over each message to mark them as seen
//       for (var message in messageSnapshot.docs) {
//         batch.update(message.reference, {
//           'seenBy': FieldValue.arrayUnion(
//               [currentUser.uid]), // Mark the message as seen
//         });
//       }

//       // Commit the batch to update the messages
//       await batch.commit();

//       // Now, update the unreadCount field for the chat
//       int unreadCount = await _getUnreadCount(chatID, currentUser.uid);

//       // Update the unread count in the chat document
//       await FirebaseFirestore.instance.collection('chat').doc(chatID).update({
//         'unreadCount': unreadCount,
//       });
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:machat/screens/auth/login_screen.dart';
import 'package:machat/screens/chat/chat.dart';
import 'package:machat/screens/profilepage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Map<String, dynamic>> chats = []; // List to hold chat data
  List<Map<String, dynamic>> filteredChats = [];
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchChats(); // Fetch existing chats when the page initializes
  }

  void _fetchChats() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('chat')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      List<Map<String, dynamic>> tempChats = [];

      // Fetch user details for each chat participant
      for (var doc in chatSnapshot.docs) {
        List<String> participants = List<String>.from(doc['participants']);
        participants.remove(currentUser.uid); // Remove current user's ID
        if (participants.isNotEmpty) {
          // Fetch the user's name using their ID
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(participants.first)
              .get();

          if (userDoc.exists) {
            // Cast userDoc.data() to Map<String, dynamic> to access fields
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            String participantName = userData['empname'] ?? 'Unknown User';

            tempChats.add({
              'chatID': doc.id,
              'participantID': participants.first,
              'participantName':
                  participantName, // Assuming 'empname' holds the name
            });
          }
        }
      }

      // Update the state only if the widget is still mounted
      if (mounted) {
        setState(() {
          chats = tempChats; // Update the chats list with user names
          filteredChats = tempChats;
        });
      }
    }
  }

  void _filterChats(String query) {
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) {
      results = chats; // If the search query is empty, show all chats
    } else {
      results = chats
          .where((chat) => chat['participantName']
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList(); // Filter the chats list based on the query
    }

    setState(() {
      filteredChats = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (query) =>
                    _filterChats(query), // Update list as user types
              )
            : const Text("Chats"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  // Reset search when closing search bar
                  searchController.clear();
                  filteredChats = chats;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (String result) async {
              if (result == 'Profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Profilepage()),
                );
              } else if (result == 'Sign Out') {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem<String>(
                value: 'Sign Out',
                child: Text('Sign Out'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: filteredChats.length,
        itemBuilder: (context, index) {
          var chat = filteredChats[index];
          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 25.0),
                title: Text(
                  chat['participantName'],
                  style: const TextStyle(
                    fontSize: 25, // Increase font size here
                    fontWeight: FontWeight.w400, // Make the text bold
                  ),
                ), // Display only the participant's name
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatID: chat['chatID'],
                        empName: chat[
                            'participantName'], // Pass the participant's name
                        empCode:
                            'Employee Code', // You can pass the code if needed
                      ),
                    ),
                  );
                },
              ),
              Divider(
                height: 1, // Height of the divider
                thickness: 1, // Thickness of the divider
                color: Colors.grey.withOpacity(0.5), // Color of the divider
                indent: 16, // Indent on the left
                endIndent: 16, // Indent on the right
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            return; // Handle case where user is not signed in
          }

          // Show user list in a bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25.0),
              ),
            ),
            builder: (BuildContext context) {
              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('Users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error fetching data'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }

                  var filteredDocs = snapshot.data!.docs.where((doc) {
                    return doc.id !=
                        currentUser.uid; // Filter out the current user
                  }).toList();

                  // Sort the filteredDocs list alphabetically by empname
                  filteredDocs.sort((a, b) {
                    return a['empname']
                        .toString()
                        .compareTo(b['empname'].toString());
                  });

                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25.0),
                    ),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.75,
                      color: const Color.fromARGB(255, 249, 246, 235),
                      child: ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var user = filteredDocs[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                user['empname'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize:
                                      18, // Optional: Set size for user name
                                ),
                              ),
                              subtitle: Text(user['empcode']),
                              onTap: () async {
                                // Fetch or create a new chat when a user is selected
                                DocumentReference chatRef = await createNewChat(
                                  currentUser.uid,
                                  user.id,
                                );

                                // Check if the chat is already in the chats list before adding
                                bool chatExists = chats.any(
                                    (chat) => chat['participantID'] == user.id);

                                if (!chatExists) {
                                  // If chat doesn't exist, add it to the list
                                  setState(() {
                                    chats.add({
                                      'chatID': chatRef.id,
                                      'participantID': user.id,
                                      'participantName': user[
                                          'empname'], // Add the participant's name
                                    });
                                  });
                                }

                                // Navigate to the ChatPage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                      chatID: chatRef.id,
                                      empName: user['empname'],
                                      empCode: user['empcode'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.people_alt),
      ),
    );
  }

  // Function to create or fetch an existing chat
  Future<DocumentReference> createNewChat(
      String currentUserID, String selectedUserID) async {
    // Check if chat already exists between the two users
    QuerySnapshot existingChat = await FirebaseFirestore.instance
        .collection('chat')
        .where('participants', arrayContains: currentUserID)
        .get();

    DocumentSnapshot? chatDocument;

    // Iterate over chats to check if one exists between currentUser and selectedUser
    for (var doc in existingChat.docs) {
      List participants = doc['participants'];
      if (participants.contains(selectedUserID)) {
        chatDocument = doc;
        break;
      }
    }

    // If chat exists, return the existing chat reference
    if (chatDocument != null) {
      return FirebaseFirestore.instance.collection('chat').doc(chatDocument.id);
    } else {
      // If no chat exists, create a new one
      return await FirebaseFirestore.instance.collection('chat').add({
        'participants': [currentUserID, selectedUserID],
        'createdAt': Timestamp.now(),
        'lastMessage': '',
        'lastMessageAt': null,
      });
    }
  }
}
