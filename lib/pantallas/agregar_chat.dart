import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat.dart'; // Asegúrate de crear este archivo con la clase ChatScreen

class AgregarChatPage extends StatefulWidget {
  const AgregarChatPage({super.key});

  @override
  _AgregarChatPageState createState() => _AgregarChatPageState();
}

class _AgregarChatPageState extends State<AgregarChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _buscarController = TextEditingController();
  List<Map<String, dynamic>> contactos = [];
  List<Map<String, dynamic>> resultadosBusqueda = [];
  String? _currentUserUsername;
  String? _currentUserUid;

  @override
  void initState() {
    super.initState();
    _getCurrentUserData();
  }

  Future<void> _getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(user.uid).get();
      setState(() {
        _currentUserUsername = userDoc['username'];
        _currentUserUid = user.uid; // Guardar el UID del usuario actual
        obtenerContactos();
      });
    }
  }

  // Obtener la lista de contactos del usuario actual
  Future<void> obtenerContactos() async {
    if (_currentUserUsername == null) return;
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('usuarios')
          .doc(_currentUserUid)
          .collection('contactos')
          .get();

      List<Map<String, dynamic>> contactosList = [];
      for (var doc in snapshot.docs) {
        var contacto = doc.data() as Map<String, dynamic>;
        bool chatIniciado = await verificarChatIniciado(
            _currentUserUsername!, contacto['username']);
        contacto['estado'] = chatIniciado ? 'inicializado' : 'no inicializado';
        contactosList.add(contacto);

        // Actualizar el estado en Firestore
        await _firestore
            .collection('usuarios')
            .doc(_currentUserUid)
            .collection('contactos')
            .doc(contacto['username'])
            .update({'estado': contacto['estado']});
      }

      setState(() {
        contactos = contactosList;
      });
    } catch (e) {
      print('Error al obtener contactos: $e');
    }
  }

  // Verificar si el chat ha sido iniciado
  Future<bool> verificarChatIniciado(
      String currentUser, String contactUser) async {
    try {
      String chatId1 = "${currentUser}_$contactUser";
      String chatId2 = "${contactUser}_$currentUser";

      DocumentSnapshot doc1 =
          await _firestore.collection('chats').doc(chatId1).get();
      DocumentSnapshot doc2 =
          await _firestore.collection('chats').doc(chatId2).get();

      return doc1.exists || doc2.exists;
    } catch (e) {
      print('Error al verificar chat: $e');
      return false;
    }
  }

  // Buscar usuarios por username en Firebase
  Future<void> buscarUsuario(String username) async {
    if (username.isEmpty) {
      setState(() {
        resultadosBusqueda = [];
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('usuarios')
          .where('username', isGreaterThanOrEqualTo: username)
          .where('username',
              isLessThan:
                  username + '\uf8ff') // Esto permite buscar coincidencias
          .get();

      setState(() {
        resultadosBusqueda = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error al buscar usuario: $e');
    }
  }

  // Función para enviar una notificación de solicitud de amistad
  Future<void> enviarNotificacion(Map<String, dynamic> usuario) async {
    try {
      await _firestore.collection('notificaciones').add({
        'de': _currentUserUsername,
        'para': usuario['username'],
        'mensaje': 'te ha enviado una solicitud de amistad',
        'estado': 'pendiente', // Estado de la notificación
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al enviar notificación: $e');
    }
  }

  // Agregar un nuevo contacto
  Future<void> agregarContacto(Map<String, dynamic> usuario) async {
    try {
      usuario['estado'] = 'no inicializado';
      await _firestore
          .collection('usuarios')
          .doc(_currentUserUid)
          .collection('contactos')
          .doc(usuario['username'])
          .set(usuario);

      // Enviar notificación al usuario agregado
      await enviarNotificacion(usuario);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacto agregado exitosamente')),
      );

      await obtenerContactos();
    } catch (e) {
      print('Error al agregar contacto: $e');
    }
  }

  // Función para abrir el chat con un contacto
  void abrirChat(String contactUsername) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(contactUsername: contactUsername),
      ),
    );

    // Actualizar la pantalla principal al volver
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Nuevo Chat'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Cuadro de búsqueda
            TextField(
              controller: _buscarController,
              decoration: InputDecoration(
                labelText: 'Buscar por username',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    buscarUsuario(_buscarController.text.trim());
                  },
                ),
              ),
              onChanged: (value) {
                buscarUsuario(
                    value.trim()); // Llamar a buscarUsuario en tiempo real
              },
            ),
            const SizedBox(height: 20),
            // Resultados de la búsqueda
            resultadosBusqueda.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: resultadosBusqueda.length,
                      itemBuilder: (context, index) {
                        var usuario = resultadosBusqueda[index];
                        return ListTile(
                          title: Text(
                              usuario['nombres'] + ' ' + usuario['apellidos']),
                          subtitle: Text(usuario['username']),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              agregarContacto(usuario);
                            },
                          ),
                        );
                      },
                    ),
                  )
                : const Text('No se encontraron usuarios.'),
            const SizedBox(height: 20),
            // Lista de contactos actuales
            const Text('Tus Contactos',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: contactos.length,
                itemBuilder: (context, index) {
                  var contacto = contactos[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(contacto['nombres'][0]),
                    ),
                    title:
                        Text(contacto['nombres'] + ' ' + contacto['apellidos']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contacto['username']),
                        Text(contacto['estado']),
                      ],
                    ),
                    onTap: () {
                      abrirChat(contacto['username']);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
