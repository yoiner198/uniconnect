import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String contactUsername;

  const ChatScreen({Key? key, required this.contactUsername}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  String? _currentUserUsername;
  String? _contactFullName;
  late Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    _getCurrentUserUsername();
    _getContactFullName(); // Llamamos para obtener el nombre completo del contacto
  }

  Future<void> _getCurrentUserUsername() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(user.uid).get();
      setState(() {
        _currentUserUsername = userDoc['username'];
        _setupMessagesStream();
      });
    }
  }

  Future<void> _getContactFullName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Obtenemos el documento del usuario actual
      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(user.uid).get();

      // Verificamos si el documento existe y si tiene la subcolección 'contactos'
      if (userDoc.exists) {
        // Accedemos a la subcolección 'contactos' y buscamos por el username del contacto
        DocumentSnapshot contactDoc = await _firestore
            .collection('usuarios')
            .doc(user.uid)
            .collection('contactos')
            .doc(widget.contactUsername)
            .get();

        if (contactDoc.exists) {
          // Si encontramos el documento del contacto, obtenemos los nombres y apellidos
          setState(() {
            _contactFullName =
                '${contactDoc['nombres']} ${contactDoc['apellidos']}'; // Concatenamos nombres y apellidos
          });
        } else {
          print(
              "No se encontró el contacto con username: ${widget.contactUsername}");
        }
      } else {
        print("No se encontró el usuario logueado.");
      }
    }
  }

  void _setupMessagesStream() {
    _messagesStream = _firestore
        .collection('chats')
        .doc(_getChatId())
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  String _getChatId() {
    List<String> ids = [_currentUserUsername ?? '', widget.contactUsername];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty &&
        _currentUserUsername != null) {
      await _firestore
          .collection('chats')
          .doc(_getChatId())
          .collection('messages')
          .add({
        'sender': _currentUserUsername,
        'text': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_contactFullName ??
            'Cargando...'), // Mostramos el nombre completo o un indicador de carga
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: _currentUserUsername == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      var messages = snapshot.data!.docs;
                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var message =
                              messages[index].data() as Map<String, dynamic>;
                          bool isMe = message['sender'] == _currentUserUsername;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    isMe ? Colors.blue[100] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(message['text'] ?? ''),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje...'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
