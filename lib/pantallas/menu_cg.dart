import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuOpcionesGrupo extends StatefulWidget {
  final String grupoId;
  final String currentUserUid;
  final String currentUserUsername;

  const MenuOpcionesGrupo({
    super.key,
    required this.grupoId,
    required this.currentUserUid,
    required this.currentUserUsername,
    Map<String, dynamic>? grupoData,
  });

  @override
  State<MenuOpcionesGrupo> createState() => _MenuOpcionesGrupoState();
}

class _MenuOpcionesGrupoState extends State<MenuOpcionesGrupo> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _grupoData;

  @override
  void initState() {
    super.initState();
    _cargarDatosGrupo();
  }

  Future<void> _cargarDatosGrupo() async {
    DocumentSnapshot grupoSnapshot =
        await _firestore.collection('grupos').doc(widget.grupoId).get();
    setState(() {
      _grupoData = grupoSnapshot.data() as Map<String, dynamic>;
    });
  }

  void _mostrarOpcionesGrupo() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Salir del grupo'),
              onTap: () {
                _salirDelGrupo();
                Navigator.of(context).pop();
              },
            ),
            if (_grupoData?['adminUid'] == widget.currentUserUid)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Agregar miembros'),
                onTap: () {
                  Navigator.of(context).pop();
                  _mostrarAgregarMiembros();
                },
              ),
            if (_grupoData?['miembrosNombres'] != null)
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Ver miembros'),
                onTap: () {
                  Navigator.of(context).pop();
                  _mostrarMiembros();
                },
              ),
            if (_grupoData?['adminUid'] == widget.currentUserUid)
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Cambiar nombre del grupo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _cambiarNombreGrupo();
                },
              ),
            if (_grupoData?['adminUid'] == widget.currentUserUid)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar grupo'),
                onTap: () {
                  _eliminarGrupo();
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarMiembros() async {
    if (_grupoData?['miembrosNombres'] == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Miembros del Grupo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (String miembro in _grupoData!['miembrosNombres'])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(miembro),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarAgregarMiembros() async {
    List<String> usuariosSeleccionados = [];
    TextEditingController busquedaController = TextEditingController();
    String filtro = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Miembros'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: busquedaController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por username',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filtro = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('usuarios').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          List<DocumentSnapshot> usuariosFiltrados =
                              snapshot.data!.docs.where((doc) {
                            Map<String, dynamic> userData =
                                doc.data() as Map<String, dynamic>;
                            String username = userData['username'] ?? '';
                            String userId = doc.id;

                            bool noEstaEnGrupo =
                                !(_grupoData?['miembros'] ?? [])
                                    .contains(userId);
                            bool coincideBusqueda = filtro.isEmpty ||
                                username.toLowerCase().contains(filtro);

                            return noEstaEnGrupo && coincideBusqueda;
                          }).toList();

                          return ListView.builder(
                            itemCount: usuariosFiltrados.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot usuario =
                                  usuariosFiltrados[index];
                              Map<String, dynamic> userData =
                                  usuario.data() as Map<String, dynamic>;
                              String username = userData['username'] ?? '';
                              String nombreCompleto =
                                  '${userData['nombres']} ${userData['apellidos']}';
                              String userId = usuario.id;

                              return CheckboxListTile(
                                title: Text(username),
                                subtitle: Text(nombreCompleto),
                                value: usuariosSeleccionados.contains(userId),
                                onChanged: (bool? selected) {
                                  setState(() {
                                    if (selected == true) {
                                      usuariosSeleccionados.add(userId);
                                    } else {
                                      usuariosSeleccionados.remove(userId);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: usuariosSeleccionados.isNotEmpty
                      ? () => _agregarMiembrosAlGrupo(usuariosSeleccionados)
                      : null,
                  child: Text('Agregar (${usuariosSeleccionados.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _agregarMiembrosAlGrupo(List<String> usuariosIds) async {
    try {
      List<DocumentSnapshot> usuarios = await Future.wait(usuariosIds
          .map((id) => _firestore.collection('usuarios').doc(id).get()));

      List usernames = usuarios.map((usuario) {
        Map<String, dynamic> userData = usuario.data() as Map<String, dynamic>;
        return userData['username'];
      }).toList();

      await _firestore.collection('grupos').doc(widget.grupoId).update({
        'miembros': FieldValue.arrayUnion(usuariosIds),
        'miembrosNombres': FieldValue.arrayUnion(usernames),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${usuariosIds.length} miembros agregados')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Error al agregar miembros: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agregar miembros')),
      );
    }
  }

  Future<void> _salirDelGrupo() async {
    try {
      await _firestore.collection('grupos').doc(widget.grupoId).update({
        'miembros': FieldValue.arrayRemove([widget.currentUserUid]),
        'miembrosNombres': FieldValue.arrayRemove([widget.currentUserUsername]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has salido del grupo')),
      );

      Navigator.of(context).pop('salir'); // Devuelve el resultado al padre
    } catch (e) {
      print('Error al salir del grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al salir del grupo')),
      );
    }
  }

  Future<void> _cambiarNombreGrupo() async {
    TextEditingController _nuevoNombreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambiar nombre del grupo'),
          content: TextField(
            controller: _nuevoNombreController,
            decoration: const InputDecoration(
              hintText: 'Nuevo nombre del grupo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _actualizarNombreGrupo(_nuevoNombreController.text.trim());
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _actualizarNombreGrupo(String nuevoNombre) async {
    try {
      await _firestore.collection('grupos').doc(widget.grupoId).update({
        'nombre': nuevoNombre,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre del grupo actualizado')),
      );

      Navigator.of(context)
          .pop(nuevoNombre); // Devuelve el nuevo nombre al padre
    } catch (e) {
      print('Error al cambiar el nombre del grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar el nombre')),
      );
    }
  }

  Future<void> _eliminarGrupo() async {
    try {
      await _firestore.collection('grupos').doc(widget.grupoId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo eliminado')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Error al eliminar el grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el grupo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opciones del grupo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _mostrarOpcionesGrupo,
          ),
        ],
      ),
      body: _grupoData == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _grupoData?['nombre'] ?? 'Grupo',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _mostrarOpcionesGrupo,
                    child: const Text('Abrir menú de opciones'),
                  ),
                ],
              ),
            ),
    );
  }
}
