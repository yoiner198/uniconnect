import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'agregar_chat.dart';
import '../widgets/bottom_nav_bar.dart';
import 'chat.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  _PantallaPrincipalState createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _busquedaTexto = '';
  List<String> _contactosFiltrados = [];
  Map<String, String> _contactosNombres = {};

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
  void initState() {
    super.initState();
    _obtenerContactosConMensajes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _cuadroBusqueda(),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _selectedIndex == 0
                  ? _listaContactos()
                  : _widgetOptions.elementAt(_selectedIndex),
            ),
          ),
        ],
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
        _filtrarContactos(texto);
      },
    );
  }

  Widget _listaContactos() {
    return ListView.builder(
      itemCount: _contactosFiltrados.length,
      itemBuilder: (context, index) {
        String contactUsername = _contactosFiltrados[index];
        String contactName =
            _contactosNombres[contactUsername] ?? contactUsername;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color.fromARGB(255, 113, 135, 117),
            child: Text(
              contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(contactName), // Muestra el nombre en la lista
          subtitle: Text(contactUsername), // Muestra el username como detalle
          onTap: () => abrirChat(contactUsername),
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
    ).then((_) {
      _obtenerContactosConMensajes();
    });
  }

  void _agregarChat() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgregarChatPage()),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _obtenerContactosConMensajes() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String uid = user.uid;

        // Obtén el documento del usuario actual
        DocumentSnapshot userDoc =
            await _firestore.collection('usuarios').doc(uid).get();
        String currentUsername = userDoc['username'];

        // Consulta todos los chats donde participa el usuario actual
        QuerySnapshot chatsSnapshot = await _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUsername)
            .get();

        // Extrae los usernames de los contactos
        Set<String> contactosUsernames = {};
        for (var chatDoc in chatsSnapshot.docs) {
          List<String> participants =
              List<String>.from(chatDoc['participants']);
          contactosUsernames.addAll(
              participants.where((username) => username != currentUsername));
        }

        if (contactosUsernames.isEmpty) return;

        // Consulta de forma masiva la colección "usuarios" para los contactos
        QuerySnapshot usuariosSnapshot = await _firestore
            .collection('usuarios')
            .where('username', whereIn: contactosUsernames.toList())
            .get();

        // Construye el mapa de usernames a nombres
        Map<String, String> contactosTemp = {};
        for (var userDoc in usuariosSnapshot.docs) {
          contactosTemp[userDoc['username']] = userDoc['nombres'];
        }

        setState(() {
          _contactosFiltrados = contactosTemp.keys.toList();
          _contactosNombres = contactosTemp;
        });
      }
    } catch (e) {
      print('Error al obtener contactos con mensajes: $e');
    }
  }

  void _filtrarContactos(String texto) {
    setState(() {
      _busquedaTexto = texto;
      _contactosFiltrados = _contactosNombres.entries
          .where((entry) =>
              entry.value.toLowerCase().contains(_busquedaTexto.toLowerCase()))
          .map((entry) => entry.key)
          .toList();
    });
  }
}
