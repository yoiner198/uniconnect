import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        backgroundColor: const Color.fromARGB(255, 42, 143, 62), // Color verde del AppBar
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex), // Muestra la opción seleccionada
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Actividades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: 'Novedades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 42, 143, 62), // Color verde para la selección
        unselectedItemColor: Colors.grey, // Color gris para los no seleccionados
        backgroundColor: Colors.white, // Fondo blanco del menú inferior
        onTap: _onItemTapped,
        elevation: 5, // Sombra para el menú
        type: BottomNavigationBarType.fixed, // Para mantener el texto debajo de los íconos
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarChat,
        child: const Icon(Icons.chat),
        backgroundColor: Colors.blue, // Color azul para el FloatingActionButton
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Asegura que se mantenga en la esquina inferior derecha
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
    // Lógica para agregar un nuevo chat
  }
}
