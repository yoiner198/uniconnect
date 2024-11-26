import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgregarGrupoPage extends StatefulWidget {
  const AgregarGrupoPage({super.key});

  @override
  _AgregarGrupoPageState createState() => _AgregarGrupoPageState();
}

class _AgregarGrupoPageState extends State<AgregarGrupoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _buscarGrupoController = TextEditingController();
  final TextEditingController _nombreGrupoController = TextEditingController();
  String? _currentUserUid;
  String? _currentUserUsername;
  List<Map<String, dynamic>> resultadosBusqueda = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUserData();
  }

  Future<void> _getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(user.uid).get();
      setState(() {
        _currentUserUsername = userDoc['username'];
        _currentUserUid = user.uid;
      });
    }
  }

  Future<void> _crearGrupo(String nombreGrupo) async {
    if (nombreGrupo.trim().isEmpty || _currentUserUid == null) return;

    try {
      String grupoId = _firestore.collection('grupos').doc().id;

      await _firestore.collection('grupos').doc(grupoId).set({
        'nombre': nombreGrupo,
        'admin': _currentUserUsername,
        'adminUid': _currentUserUid,
        'miembros': [_currentUserUid],
        'miembrosNombres': [_currentUserUsername],
        'timestamp': FieldValue.serverTimestamp(),
      });

      _nombreGrupoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo creado exitosamente')),
      );
    } catch (e) {
      print('Error al crear grupo: $e');
    }
  }

  Future<void> buscarGrupo(String nombre) async {
    if (nombre.isEmpty) {
      setState(() {
        resultadosBusqueda = [];
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('grupos')
          .where('nombre', isGreaterThanOrEqualTo: nombre)
          .where('nombre', isLessThan: nombre + '\uf8ff')
          .get();

      setState(() {
        resultadosBusqueda = snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                })
            .toList();
      });
    } catch (e) {
      print('Error al buscar grupo: $e');
    }
  }

  Future<void> _unirseAGrupo(String grupoId) async {
    if (_currentUserUid == null || _currentUserUsername == null) return;

    try {
      DocumentReference grupoRef = _firestore.collection('grupos').doc(grupoId);

      await grupoRef.update({
        'miembros': FieldValue.arrayUnion([_currentUserUid]),
        'miembrosNombres': FieldValue.arrayUnion([_currentUserUsername]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te has unido al grupo')),
      );
    } catch (e) {
      print('Error al unirse al grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al unirse al grupo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Grupo'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nombreGrupoController,
              decoration: const InputDecoration(labelText: 'Nombre del Grupo'),
            ),
            ElevatedButton(
              onPressed: () {
                _crearGrupo(_nombreGrupoController.text.trim());
              },
              child: const Text('Crear Grupo'),
            ),
            const Divider(),
            TextField(
              controller: _buscarGrupoController,
              decoration: InputDecoration(
                labelText: 'Buscar Grupo',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    buscarGrupo(_buscarGrupoController.text.trim());
                  },
                ),
              ),
              onChanged: (value) {
                buscarGrupo(value.trim());
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: resultadosBusqueda.isNotEmpty
                  ? ListView.builder(
                      itemCount: resultadosBusqueda.length,
                      itemBuilder: (context, index) {
                        var grupo = resultadosBusqueda[index];
                        return ListTile(
                          title: Text(grupo['nombre']),
                          subtitle: Text('Admin: ${grupo['admin']}'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              _unirseAGrupo(grupo['id']);
                            },
                            child: const Text('Unirse'),
                          ),
                        );
                      },
                    )
                  : const Text('No se encontraron grupos.'),
            ),
          ],
        ),
      ),
    );
  }
}
