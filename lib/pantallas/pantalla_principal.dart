import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'agregar_chat.dart';
import '../widgets/bottom_nav_bar.dart';
import 'chat.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({Key? key}) : super(key: key);

  @override
  _PantallaPrincipalState createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _busquedaTexto = '';
  List<String> _contactosConMensajes = []; // Añadir esta línea
  List<Map<String, dynamic>> _notificaciones = []; // Añadir esta línea

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
    _obtenerNotificaciones(); // Llamar a la función para obtener notificaciones
  }

  // Método para obtener las notificaciones
  Future<void> _obtenerNotificaciones() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        QuerySnapshot notificacionesSnapshot = await _firestore
            .collection('notificaciones')
            .where('para', isEqualTo: user.uid)
            .get();

        setState(() {
          _notificaciones = notificacionesSnapshot.docs
              .map((doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id
                  }) // Agregar el ID
              .toList();
        });
      }
    } catch (e) {
      print('Error al obtener notificaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _cuadroBusqueda(),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _mostrarNotificaciones(); // Método para mostrar las notificaciones
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _mostrarNotificacionesWidget(), // Mostrar las notificaciones
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
        setState(() {
          _busquedaTexto = texto;
        });
      },
    );
  }

  Widget _listaContactos() {
    return ListView.builder(
      itemCount: _contactosConMensajes.length,
      itemBuilder: (context, index) {
        String contactUsername = _contactosConMensajes[index];
        return ListTile(
          title: Text(contactUsername),
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
      // Actualizar la lista de contactos cuando se regrese del chat
      _obtenerContactosConMensajes();
    });
  }

  void _agregarChat() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgregarChatPage()),
    );

    if (result == true) {
      _obtenerNotificaciones(); // Actualizar la lista de notificaciones
      setState(() {}); // Esto forzará una reconstrucción de la interfaz
    }
  }

  Future<void> _obtenerContactosConMensajes() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String uid = user.uid;
        DocumentSnapshot userDoc =
            await _firestore.collection('usuarios').doc(uid).get();
        String currentUsername = userDoc['username'];

        QuerySnapshot chatsSnapshot = await _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUsername)
            .get();

        Set<String> contactosTemp = {};

        for (var chatDoc in chatsSnapshot.docs) {
          List<String> participants =
              List<String>.from(chatDoc['participants']);
          String contactUsername = participants
              .firstWhere((username) => username != currentUsername);
          contactosTemp.add(contactUsername);
        }

        setState(() {
          _contactosConMensajes = contactosTemp.toList();
        });
      }
    } catch (e) {
      print('Error al obtener contactos con mensajes: $e');
    }
  }

  void _filtrarContactos(String texto) {
    setState(() {
      _busquedaTexto = texto;
      // Filtrar la lista de contactos con mensajes
      _contactosConMensajes = _contactosConMensajes
          .where((contacto) => contacto.contains(_busquedaTexto))
          .toList();
    });
  }

  // Método para mostrar las notificaciones
  void _mostrarNotificaciones() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Solicitudes de Amistad'),
          content: SizedBox(
            width: double.maxFinite,
            child: _mostrarNotificacionesWidget(), // Método para mostrar las notificaciones
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _mostrarNotificacionesWidget() {
    if (_notificaciones.isEmpty) {
      return const Text('No tienes notificaciones'); // Mensaje si no hay notificaciones
    }
    return Column(
      children: _notificaciones.map((notificacion) {
        return ListTile(
          title: Text('${notificacion['de']} te ha enviado una solicitud de amistad'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  await _aceptarSolicitud(notificacion);
                  Navigator.of(context).pop(); // Cerrar el diálogo
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await _eliminarSolicitud(notificacion);
                  Navigator.of(context).pop(); // Cerrar el diálogo
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _aceptarSolicitud(Map<String, dynamic> notificacion) async {
    // Lógica para agregar el contacto y eliminar la notificación
    // Aquí puedes usar la función agregarContacto que ya tienes
    // y luego eliminar la notificación de Firestore
  }

  Future<void> _eliminarSolicitud(Map<String, dynamic> notificacion) async {
    // Lógica para eliminar la notificación de Firestore
    await _firestore
        .collection('notificaciones')
        .doc(notificacion['id'])
        .delete();
    _obtenerNotificaciones(); // Actualizar la lista de notificaciones
  }
}
