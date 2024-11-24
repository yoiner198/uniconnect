// pantallas/ajustes.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart';

class AjustesPage extends StatefulWidget {
  const AjustesPage({Key? key}) : super(key: key);

  @override
  _AjustesPageState createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  // Controladores para los campos de texto
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _correoUsuario;

  // Método para cargar los datos del usuario desde Firebase
  Future<void> _cargarDatosUsuario() async {
    try {
      User? usuario = _auth.currentUser;

      if (usuario != null) {
        String correo = usuario.email!;
        setState(() {
          _correoUsuario =
              correo; // Asignamos el correo del usuario a la variable
        });

        DocumentSnapshot usuarioSnapshot = await _firestore
            .collection('usuarios')
            .where('correo', isEqualTo: correo)
            .limit(1)
            .get()
            .then((querySnapshot) => querySnapshot.docs.first);

        if (usuarioSnapshot.exists) {
          Map<String, dynamic> datos =
              usuarioSnapshot.data() as Map<String, dynamic>;

          _nombresController.text = datos['nombres'] ?? '';
          _apellidosController.text = datos['apellidos'] ?? '';
          _telefonoController.text = datos['telefono'] ?? '';
          _carreraController.text = datos['carrera'] ?? '';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // Método para manejar la navegación inferior
  void _onItemTapped(int index) {
    setState(() {});

    // Redirigir a las diferentes páginas según el índice
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajustes de perfil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40, color: Colors.grey[700]),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Lógica para cambiar foto de perfil (opcional)
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombresController,
              decoration: const InputDecoration(labelText: 'Nombres'),
            ),
            TextFormField(
              controller: _apellidosController,
              decoration: const InputDecoration(labelText: 'Apellidos'),
            ),
            TextFormField(
              controller: _carreraController,
              decoration: const InputDecoration(labelText: 'Carrera'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.email),
                const SizedBox(width: 10),
                Text(
                  _correoUsuario ?? 'Cargando...',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.lock),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    // Lógica para cambiar contraseña
                  },
                  child: const Text(
                    'Cambiar contraseña',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            const Text(
              'Ajustes de privacidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Visibilidad del número de teléfono'),
              value: true,
              onChanged: (bool value) {
                // Lógica para cambiar visibilidad
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1, // Índice para Grupos
        onItemTapped: (index) {},
      ),
    );
  }
}
