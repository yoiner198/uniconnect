// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GrupoOpciones {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static void mostrarOpcionesGrupo(
      BuildContext context,
      String grupoId,
      Map<String, dynamic>? grupoData,
      String? currentUserUid,
      String? currentUserUsername) {
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
                _salirDelGrupo(
                    context, grupoId, currentUserUid, currentUserUsername);
                Navigator.of(context).pop();
              },
            ),
            if (grupoData?['adminUid'] == currentUserUid)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Agregar miembros'),
                onTap: () {
                  Navigator.of(context).pop();
                  _mostrarAgregarMiembros(context, grupoId, grupoData);
                },
              ),
            if (grupoData?['miembrosNombres'] != null)
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Ver miembros'),
                onTap: () {
                  Navigator.of(context).pop();
                  _mostrarMiembros(context, grupoData);
                },
              ),
            if (grupoData?['adminUid'] == currentUserUid)
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Cambiar nombre del grupo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _cambiarNombreGrupo(
                      context, grupoId, grupoData, currentUserUid);
                },
              ),
            if (grupoData?['adminUid'] == currentUserUid)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar grupo'),
                onTap: () {
                  _eliminarGrupo(context, grupoId);
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  static Future<void> _mostrarMiembros(
      BuildContext context, Map<String, dynamic>? grupoData) async {
    if (grupoData?['miembrosNombres'] == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Miembros del Grupo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (String miembro in grupoData!['miembrosNombres'])
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

  static Future<void> _mostrarAgregarMiembros(BuildContext context,
      String grupoId, Map<String, dynamic>? grupoData) async {
    List<String> usuariosSeleccionados = [];
    TextEditingController busquedaController = TextEditingController();
    String filtro = '';

    showDialog(
      context: context,
      builder: (context) {
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
                                !((grupoData?['miembros'] ?? [])
                                    .contains(userId));
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
                      ? () => _agregarMiembrosAlGrupo(
                          context, grupoId, usuariosSeleccionados)
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

  static Future<void> _agregarMiembrosAlGrupo(
      BuildContext context, String grupoId, List<String> usuariosIds) async {
    try {
      // Obtener referencias a los documentos de los usuarios
      List<DocumentSnapshot> usuarios = await Future.wait(usuariosIds
          .map((id) => _firestore.collection('usuarios').doc(id).get()));

      // Extraer usernames
      List usernames = usuarios.map((usuario) {
        Map<String, dynamic> userData = usuario.data() as Map<String, dynamic>;
        return userData['username'];
      }).toList();

      // Actualizar el grupo en Firestore
      await _firestore.collection('grupos').doc(grupoId).update({
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

  static Future<void> _salirDelGrupo(BuildContext context, String grupoId,
      String? currentUserUid, String? currentUserUsername) async {
    if (currentUserUid == null) return;

    try {
      DocumentReference grupoRef = _firestore.collection('grupos').doc(grupoId);

      // Eliminar al usuario de la lista de miembros
      await grupoRef.update({
        'miembros': FieldValue.arrayRemove([currentUserUid]),
        'miembrosNombres': FieldValue.arrayRemove([currentUserUsername]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has salido del grupo')),
      );

      // Navegar de vuelta a la pantalla principal
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al salir del grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al salir del grupo')),
      );
    }
  }

  static Future<void> _cambiarNombreGrupo(BuildContext context, String grupoId,
      Map<String, dynamic>? grupoData, String? currentUserUid) {
    final TextEditingController nuevoNombreController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambiar nombre del grupo'),
          content: TextField(
            controller: nuevoNombreController,
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
                _actualizarNombreGrupo(
                    context,
                    grupoId,
                    nuevoNombreController.text.trim(),
                    grupoData,
                    currentUserUid);
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _actualizarNombreGrupo(
      BuildContext context,
      String grupoId,
      String nuevoNombre,
      Map<String, dynamic>? grupoData,
      String? currentUserUid) async {
    if (nuevoNombre.isEmpty || grupoData?['adminUid'] != currentUserUid) return;

    try {
      await _firestore.collection('grupos').doc(grupoId).update({
        'nombre': nuevoNombre,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre del grupo actualizado')),
      );
    } catch (e) {
      print('Error al actualizar el nombre del grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error al actualizar el nombre del grupo')),
      );
    }
  }

  static Future<void> _eliminarGrupo(
      BuildContext context, String grupoId) async {
    try {
      await _firestore.collection('grupos').doc(grupoId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo eliminado')),
      );

      // Navegar de vuelta a la pantalla principal
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al eliminar el grupo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el grupo')),
      );
    }
  }
}
