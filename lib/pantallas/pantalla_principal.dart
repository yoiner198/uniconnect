import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uniconnect/pantallas/agregar_chat.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart'; // Asegúrate de usar la ruta correcta

class PantallaPrincipal extends StatefulWidget {
  @override
  _PantallaPrincipalState createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedIndex = 0;
  final String _usuarioActualId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _busquedaTexto = '';

  static const List<Widget> _widgetOptions = <Widget>[
    Text('Chats'),
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
        backgroundColor:
            const Color.fromARGB(255, 42, 143, 62), // Color verde del AppBar
      ),
      body: Center(
        child: _widgetOptions
            .elementAt(_selectedIndex), // Muestra la opción seleccionada
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarChat, // Llamada a la función modificada
        // ignore: sort_child_properties_last
        child: const Icon(Icons.chat),
        backgroundColor: Colors.blue, // Color azul para el FloatingActionButton
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .endFloat, // Asegura que se mantenga en la esquina inferior derecha
    );
  }

  // Cuadro de búsqueda de contactos por nombre
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

  // Función para agregar un nuevo chat
  void _agregarChat() {
    // Navegar a la pantalla de agregar chat
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgregarChatPage()),
    );
  }
}
