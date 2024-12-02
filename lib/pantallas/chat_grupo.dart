import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'grupo_opciones.dart'; // Importamos el nuevo archivo de opciones

class ChatGrupoPage extends StatefulWidget {
  final String grupoId;

  const ChatGrupoPage({Key? key, required this.grupoId}) : super(key: key);

  @override
  _ChatGrupoPageState createState() => _ChatGrupoPageState();
}

class _ChatGrupoPageState extends State<ChatGrupoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _mensajeController = TextEditingController();
  String? _currentUserUsername;
  String? _currentUserFullName;
  String? _currentUserUid;
  late Stream<QuerySnapshot> _mensajesStream;
  Map<String, dynamic>? _grupoData;

  @override
  void initState() {
    super.initState();
    _getCurrentUserData();
    _setupMensajesStream();
    _obtenerGrupoData();
  }

  Future<void> _getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(user.uid).get();
      setState(() {
        _currentUserUsername = userDoc['username'];
        _currentUserFullName = '${userDoc['nombres']} ${userDoc['apellidos']}';
        _currentUserUid = user.uid;
      });
    }
  }

  Future<void> _obtenerGrupoData() async {
    try {
      DocumentSnapshot grupoDoc =
          await _firestore.collection('grupos').doc(widget.grupoId).get();
      setState(() {
        _grupoData = grupoDoc.data() as Map<String, dynamic>;
      });
    } catch (e) {
      print('Error al obtener datos del grupo: $e');
    }
  }

  void _setupMensajesStream() {
    _mensajesStream = _firestore
        .collection('grupos')
        .doc(widget.grupoId)
        .collection('mensajes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _enviarMensaje({
    String? texto,
    String? fileUrl,
    String? fileType,
  }) async {
    if ((texto?.trim().isNotEmpty ?? false) || fileUrl != null) {
      try {
        await _firestore
            .collection('grupos')
            .doc(widget.grupoId)
            .collection('mensajes')
            .add({
          'sender': _currentUserUsername,
          'senderFullName': _currentUserFullName,
          'text': texto,
          'fileUrl': fileUrl,
          'fileType': fileType,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _mensajeController.clear();
      } catch (e) {
        print('Error al enviar mensaje: $e');
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
        String filePath = result.files.single.path!;

        TaskSnapshot uploadTask =
            await _storage.ref('grupos/${widget.grupoId}/$fileName').putFile(
                  File(filePath),
                );

        String fileUrl = await uploadTask.ref.getDownloadURL();

        await _enviarMensaje(fileUrl: fileUrl, fileType: type);
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
        title: Text(_grupoData?['nombre'] ?? 'Grupo'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              GrupoOpciones.mostrarOpcionesGrupo(context, widget.grupoId,
                  _grupoData, _currentUserUid, _currentUserUsername);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _mensajesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay mensajes'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot mensajeDoc = snapshot.data!.docs[index];
                    Map<String, dynamic> mensajeData =
                        mensajeDoc.data() as Map<String, dynamic>;
                    bool isSender =
                        mensajeData['sender'] == _currentUserUsername;

                    return ListTile(
                      title: Row(
                        mainAxisAlignment: isSender
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: isSender
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                mensajeData['senderFullName'] ?? 'Desconocido',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (mensajeData['text'] != null)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSender
                                        ? Colors.green[100]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(mensajeData['text']),
                                ),
                              if (mensajeData['fileUrl'] != null &&
                                  mensajeData['fileType'] == 'photo')
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Image.network(mensajeData['fileUrl']),
                                ),
                              if (mensajeData['fileUrl'] != null &&
                                  mensajeData['fileType'] == 'audio')
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.audiotrack),
                                      Text(mensajeData['fileUrl']),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                mensajeData['timestamp'] != null
                                    ? DateFormat('hh:mm a').format(
                                        mensajeData['timestamp'].toDate())
                                    : '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                    controller: _mensajeController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _enviarMensaje(texto: _mensajeController.text.trim());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: () {
                    _pickFile('photo');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.audiotrack),
                  onPressed: () {
                    _pickFile('audio');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
