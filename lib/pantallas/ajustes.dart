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
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _correoUsuario;

  Future<void> _cargarDatosUsuario() async {
    try {
      User? usuario = _auth.currentUser;

      if (usuario != null) {
        String correo = usuario.email!;
        setState(() {
          _correoUsuario = correo;
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

  Future<void> _cambiarContrasena() async {
    final TextEditingController nuevaContrasenaController =
        TextEditingController();
    final TextEditingController confirmarContrasenaController =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nuevaContrasenaController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Nueva contraseña'),
              ),
              TextField(
                controller: confirmarContrasenaController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirmar contraseña'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                String nuevaContrasena = nuevaContrasenaController.text.trim();
                String confirmarContrasena =
                    confirmarContrasenaController.text.trim();

                if (nuevaContrasena.isEmpty || confirmarContrasena.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, completa ambos campos.')),
                  );
                  return;
                }

                if (nuevaContrasena != confirmarContrasena) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Las contraseñas no coinciden.')),
                  );
                  return;
                }

                try {
                  User? usuario = _auth.currentUser;

                  if (usuario != null) {
                    await usuario.updatePassword(nuevaContrasena);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Contraseña actualizada con éxito.')),
                    );
                    Navigator.of(context).pop(); // Cerrar el diálogo
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error al cambiar la contraseña: $e')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
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
                  onTap: _cambiarContrasena,
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
