import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uniconnect/pantallas/agregar_chat.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart';
import 'chat.dart';

class PantallaPrincipal extends StatefulWidget {
  @override
  _PantallaPrincipalState createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _busquedaTexto = '';
  List<String> _contactosConMensajes = [];

  @override
  void initState() {
    super.initState();
    _obtenerContactosConMensajes(); // Obtener contactos con los que has intercambiado mensajes
  }

  // Función para obtener los chats con mensajes
  Future<void> _obtenerContactosConMensajes() async {
    try {
      String usernameActual = await _obtenerUsernameActual();

      QuerySnapshot chatsSnapshot = await _firestore.collection('chats').get();
      List<String> contactosTemp = [];

      // Recorrer cada chat para verificar si tiene mensajes
      for (var chatDoc in chatsSnapshot.docs) {
        String chatId = chatDoc.id;

        // Verificamos si el chat incluye al usuario actual
        if (chatId.contains(usernameActual)) {
          QuerySnapshot mensajesSnapshot = await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .get();

          if (mensajesSnapshot.docs.isNotEmpty) {
            // Extraemos el nombre del contacto
            String contactUsername =
                chatId.replaceAll(usernameActual, '').replaceAll('_', '');
            contactosTemp.add(contactUsername);
          }
        }
      }

      setState(() {
        _contactosConMensajes = contactosTemp;
      });
    } catch (e) {
      print('Error al obtener chats con mensajes: $e');
    }
  }

  // Función para obtener el username actual desde Firebase Auth
  Future<String> _obtenerUsernameActual() async {
    String uid = _auth.currentUser!.uid;
    DocumentSnapshot usuarioSnapshot =
        await _firestore.collection('usuarios').doc(uid).get();
    return usuarioSnapshot['username'];
  }

  static const List<Widget> _widgetOptions = <Widget>[
    Text('Grupos'),
    Text('Actividades'),
    Text('Novedades'),
    Text('Ajustes'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _cuadroBusqueda(),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: Center(
        child: _selectedIndex == 0
            ? _listaContactos()
            : _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarChat,
        child: const Icon(Icons.chat),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _cuadroBusqueda() {
    return TextField(
      controller: _controladorBusqueda,
      decoration: InputDecoration(
        hintText: 'Buscar personas...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (texto) {
        setState(() {
          _busquedaTexto = texto;
        });
      },
    );
  }

  Widget _listaContactos() {
    List<String> contactosFiltrados = _contactosConMensajes.where((contacto) {
      return contacto.toLowerCase().contains(_busquedaTexto.toLowerCase());
    }).toList();

    if (contactosFiltrados.isEmpty) {
      return const Text(
          'No se encontraron contactos con los que hayas intercambiado mensajes.');
    }

    return ListView.builder(
      itemCount: contactosFiltrados.length,
      itemBuilder: (context, index) {
        String contactUsername = contactosFiltrados[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(contactUsername[0].toUpperCase()),
          ),
          title: Text(contactUsername),
          onTap: () {
            abrirChat(contactUsername);
          },
        );
      },
    );
  }

  void abrirChat(String contactUsername) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(contactUsername: contactUsername),
      ),
    );
  }

  void _agregarChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgregarChatPage()),
    );
  }
}
