import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart';

class GruposPage extends StatefulWidget {
  const GruposPage({Key? key}) : super(key: key);

  @override
  State<GruposPage> createState() => _GruposPageState();
}

class _GruposPageState extends State<GruposPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lista para almacenar los usuarios seleccionados
  List<Map<String, dynamic>> _usuariosSeleccionados = [];
  // Stream para obtener los grupos en tiempo real
  Stream<QuerySnapshot>? _gruposStream;

  @override
  void initState() {
    super.initState();
    _gruposStream = _firestore.collection('grupos').snapshots();
  }

  // Obtener la lista de contactos del usuario actual
  Future<List<Map<String, dynamic>>> _getContactos() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        throw Exception("Usuario no autenticado");
      }

      QuerySnapshot querySnapshot = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('contactos')
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'uid': doc.id,
          'nombres': doc['nombres'],
          'apellidos': doc['apellidos'],
          'username': doc['username'],
        };
      }).toList();
    } catch (e) {
      print("Error al obtener contactos: $e");
      return [];
    }
  }

  // Mostrar ventana para crear grupo
  void _mostrarVentanaCrearGrupo(BuildContext context) async {
    List<Map<String, dynamic>> contactos = await _getContactos();
    final TextEditingController nombreGrupoController = TextEditingController();

    if (contactos.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Contactos"),
          content: const Text("No tienes contactos agregados."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Crear Grupo"),
                backgroundColor: const Color.fromARGB(255, 42, 143, 62),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nombreGrupoController,
                      decoration: const InputDecoration(
                        labelText: "Nombre del Grupo",
                        hintText: "Ingresa un nombre para el grupo",
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Seleccionar contactos",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: contactos.length,
                        itemBuilder: (context, index) {
                          var contacto = contactos[index];
                          bool seleccionado = _usuariosSeleccionados.any(
                              (usuario) => usuario['uid'] == contacto['uid']);
                          return CheckboxListTile(
                            title: Text(
                                "${contacto['nombres']} ${contacto['apellidos']}"),
                            subtitle: Text(contacto['username']),
                            value: seleccionado,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _usuariosSeleccionados.add(contacto);
                                } else {
                                  _usuariosSeleccionados.removeWhere(
                                      (usuario) =>
                                          usuario['uid'] == contacto['uid']);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  String nombreGrupo = nombreGrupoController.text.trim();
                  if (nombreGrupo.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "El nombre del grupo no puede estar vacío.")),
                    );
                    return;
                  }
                  if (_usuariosSeleccionados.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Debes seleccionar al menos un contacto para crear el grupo.")),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _crearGrupo(nombreGrupo);
                },
                child: const Icon(Icons.check),
                backgroundColor: const Color.fromARGB(255, 42, 143, 62),
              ),
            );
          },
        );
      },
    );
  }

  // Crear grupo con los usuarios seleccionados
  Future<void> _crearGrupo(String nombreGrupo) async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        throw Exception("Usuario no autenticado");
      }

      List<String> uidsSeleccionados = _usuariosSeleccionados
          .map((usuario) => usuario['uid'] as String)
          .toList();

      // Guardar el grupo en Firestore
      await _firestore.collection('grupos').add({
        'nombre': nombreGrupo, // Usar el nombre proporcionado por el usuario
        'creador': user.uid,
        'usuarios': uidsSeleccionados,
        'creado': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Grupo creado con éxito.")),
      );

      _usuariosSeleccionados.clear();
    } catch (e) {
      print("Error al crear el grupo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al crear el grupo: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _gruposStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay grupos creados."));
          }

          var grupos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: grupos.length,
            itemBuilder: (context, index) {
              var grupo = grupos[index];
              return ListTile(
                title: Text(grupo['nombre']),
                subtitle: Text(
                    "Usuarios: ${(grupo['usuarios'] as List<dynamic>).length}"),
                onTap: () {
                  // Lógica para mostrar el chat del grupo
                  print("Abrir chat del grupo ${grupo['nombre']}");
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarVentanaCrearGrupo(context),
        child: const Icon(Icons.add),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1, // Índice para Grupos
        onItemTapped: (index) {},
      ),
    );
  }
}
