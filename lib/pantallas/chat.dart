import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart'; // Para seleccionar archivos
import 'package:intl/intl.dart'; // Para formatear la hora

class ChatScreen extends StatefulWidget {
  final String contactUsername;

  const ChatScreen({Key? key, required this.contactUsername}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _messageController = TextEditingController();
  String? _currentUserUsername;
  String? _contactFullName;
  late Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    _getCurrentUserUsername();
    _getContactFullName();
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
      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(user.uid).get();

      if (userDoc.exists) {
        DocumentSnapshot contactDoc = await _firestore
            .collection('usuarios')
            .doc(user.uid)
            .collection('contactos')
            .doc(widget.contactUsername)
            .get();

        if (contactDoc.exists) {
          setState(() {
            _contactFullName =
                '${contactDoc['nombres']} ${contactDoc['apellidos']}';
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

  Future<void> _sendMessage({String? text, String? fileUrl, String? fileType}) async {
    if ((text?.trim().isNotEmpty ?? false) || fileUrl != null) {
      String chatId = _getChatId();
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [_currentUserUsername, widget.contactUsername],
        'lastMessage': text ?? 'Archivo enviado',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'sender': _currentUserUsername,
        'text': text,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (text != null) {
        _messageController.clear();
      }
    }
  }

  Future<void> _pickFile(String type) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: type == 'photo' ? FileType.image : FileType.custom,
        allowedExtensions: type == 'audio' ? ['mp3', 'wav', 'm4a'] : null,
      );

      if (result != null && result.files.single.path != null) {
        String fileName = result.files.single.name;
        String filePath = result.files.single.path!; // Verifica que no sea nulo
        String chatId = _getChatId();

        // Crear un objeto File
        File file = File(filePath);

        if (!file.existsSync()) {
          print('Error: El archivo no existe');
          return;
        }

        // Subir el archivo a Firebase Storage
        TaskSnapshot uploadTask = await _storage
            .ref('chats/$chatId/$fileName')
            .putFile(file);

        // Obtener la URL del archivo
        String fileUrl = await uploadTask.ref.getDownloadURL();

        // Enviar el mensaje con el archivo
        await _sendMessage(fileUrl: fileUrl, fileType: type);
      } else {
        print('No se seleccionó ningún archivo');
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_contactFullName ?? widget.contactUsername),
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

                          // Formatear la hora del mensaje
                          Timestamp? timestamp = message['timestamp'];
                          String formattedTime = timestamp != null
                              ? DateFormat('hh:mm a')
                                  .format(timestamp.toDate())
                              : '';

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (message['fileType'] == 'photo')
                                    Image.network(
                                      message['fileUrl'],
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                  else if (message['fileType'] == 'audio')
                                    TextButton.icon(
                                      onPressed: () {
                                        print("Reproducir audio");
                                      },
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text("Reproducir"),
                                    )
                                  else
                                    Text(
                                      message['text'] ?? '',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
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
                      IconButton(
                        icon: const Icon(Icons.photo),
                        onPressed: () => _pickFile('photo'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic),
                        onPressed: () => _pickFile('audio'),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje...'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _sendMessage(text: _messageController.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
