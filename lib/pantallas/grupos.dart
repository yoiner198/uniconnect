import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav_bar.dart';
import 'agregar_grupo.dart';
import 'chat_grupo.dart';

class GruposPage extends StatefulWidget {
  const GruposPage({Key? key}) : super(key: key);

  @override
  _GruposPageState createState() => _GruposPageState();
}

class _GruposPageState extends State<GruposPage> {
  int _selectedIndex = 1;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _grupos = [];
  String _busquedaTexto = '';

  @override
  void initState() {
    super.initState();
    _obtenerGrupos();
  }

  Future<void> _obtenerGrupos() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        QuerySnapshot snapshot = await _firestore
            .collection('grupos')
            .where('miembros', arrayContains: user.uid)
            .get();

        setState(() {
          _grupos = snapshot.docs
              .map((doc) =>
                  {'id': doc.id, ...doc.data() as Map<String, dynamic>})
              .toList();
        });
      }
    } catch (e) {
      print('Error al obtener grupos: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _cuadroBusqueda() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar grupos...',
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
          _busquedaTexto = texto.toLowerCase();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> gruposFiltrados = _grupos.where((grupo) {
      return grupo['nombre'].toLowerCase().contains(_busquedaTexto);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _cuadroBusqueda(),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: ListView.builder(
        itemCount: gruposFiltrados.length,
        itemBuilder: (context, index) {
          var grupo = gruposFiltrados[index];
          String grupoNombre = grupo['nombre'];
          return ListTile(
            leading: CircleAvatar(
              // ignore: sort_child_properties_last
              child: Text(
                grupoNombre.isNotEmpty ? grupoNombre[0].toUpperCase() : '',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color.fromARGB(
                  255, 84, 104, 97), // Cambia el color según tus preferencias
            ),
            title: Text(grupoNombre),
            subtitle: Text('Admin: ${grupo['admin']}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatGrupoPage(grupoId: grupo['id']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AgregarGrupoPage()),
          ).then((_) => _obtenerGrupos());
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
