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

  @override
  void initState() {
    super.initState();
    obtenerContactos();
  }

  // Obtener la lista de contactos del usuario actual
  Future<void> obtenerContactos() async {
    try {
      String uid = _auth.currentUser!.uid;
      QuerySnapshot snapshot = await _firestore
          .collection('usuarios')
          .doc(uid)
          .collection('contactos')
          .get();

      setState(() {
        contactos = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error al obtener contactos: $e');
    }
  }

  // Buscar usuarios por username en Firebase
  Future<void> buscarUsuario(String username) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('usuarios')
          .where('username', isEqualTo: username)
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

  // Agregar un nuevo contacto
  Future<void> agregarContacto(Map<String, dynamic> usuario) async {
    try {
      String uid = _auth.currentUser!.uid;
      await _firestore
          .collection('usuarios')
          .doc(uid)
          .collection('contactos')
          .doc(usuario['username'])
          .set(usuario);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contacto agregado exitosamente')),
      );

      // Actualizar la lista de contactos
      obtenerContactos();
    } catch (e) {
      print('Error al agregar contacto: $e');
    }
  }

  // Función para abrir el chat con un contacto
  void abrirChat(String contactUsername) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(contactUsername: contactUsername),
      ),
    );
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
                    subtitle: Text(contacto['username']),
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
