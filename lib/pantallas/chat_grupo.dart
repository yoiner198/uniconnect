import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart'; // Para formatear la hora

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
        _currentUserUid = user.uid; // Guardar el UID del usuario actual
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
        String filePath = result.files.single.path!; // Verifica que no sea nulo

        // Subir el archivo a Firebase Storage
        TaskSnapshot uploadTask =
            await _storage.ref('grupos/${widget.grupoId}/$fileName').putFile(
                  File(filePath),
                );

        // Obtener la URL del archivo
        String fileUrl = await uploadTask.ref.getDownloadURL();

        // Enviar el mensaje con el archivo
        await _enviarMensaje(fileUrl: fileUrl, fileType: type);
      } else {
        print('No se seleccionó ningún archivo');
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
    }
  }

  void _mostrarOpcionesGrupo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Salir del grupo'),
              onTap: () {
                _salirDelGrupo();
                Navigator.of(context).pop();
              },
            ),
            if (_grupoData?['adminUid'] == _currentUserUid)
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Cambiar nombre del grupo'),
                onTap: () {
                  Navigator.of(context)
                      .pop(); // Cerrar el BottomSheet antes de abrir el diálogo
                  _cambiarNombreGrupo();
                },
              ),
            if (_grupoData?['adminUid'] == _currentUserUid)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar grupo'),
                onTap: () {
                  _eliminarGrupo();
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _salirDelGrupo() async {
    if (_currentUserUid == null) return;

    try {
      DocumentReference grupoRef =
          _firestore.collection('grupos').doc(widget.grupoId);

      // Eliminar al usuario de la lista de miembros
      await grupoRef.update({
        'miembros': FieldValue.arrayRemove([_currentUserUid]),
        'miembrosNombres': FieldValue.arrayRemove([_currentUserUsername]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has salido del grupo')),
      );

      // Navegar de vuelta a la pantalla principal
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al salir del grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al salir del grupo')),
      );
    }
  }

  Future<void> _cambiarNombreGrupo() async {
    if (_grupoData?['adminUid'] != _currentUserUid) return;

    TextEditingController _nuevoNombreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambiar nombre del grupo'),
          content: TextField(
            controller: _nuevoNombreController,
            decoration: const InputDecoration(
              hintText: 'Nuevo nombre del grupo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Cerrar el diálogo antes de actualizar el nombre
                _actualizarNombreGrupo(_nuevoNombreController.text.trim());
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _actualizarNombreGrupo(String nuevoNombre) async {
    if (nuevoNombre.isEmpty || _grupoData?['adminUid'] != _currentUserUid)
      return;

    try {
      await _firestore.collection('grupos').doc(widget.grupoId).update({
        'nombre': nuevoNombre,
      });

      setState(() {
        _grupoData?['nombre'] = nuevoNombre;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre del grupo actualizado')),
      );
    } catch (e) {
      print('Error al actualizar el nombre del grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error al actualizar el nombre del grupo')),
      );
    }
  }

  Future<void> _eliminarGrupo() async {
    if (_grupoData?['adminUid'] != _currentUserUid) return;

    try {
      await _firestore.collection('grupos').doc(widget.grupoId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo eliminado')),
      );

      // Navegar de vuelta a la pantalla principal
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al eliminar el grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el grupo')),
      );
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
              _mostrarOpcionesGrupo(context);
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
