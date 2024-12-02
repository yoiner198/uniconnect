import 'package:flutter/material.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart';

class ActividadesPage extends StatefulWidget {
  const ActividadesPage({Key? key}) : super(key: key);

  @override
  State<ActividadesPage> createState() => _ActividadesPageState();
}

class _ActividadesPageState extends State<ActividadesPage> {
  // Lista de actividades con estado
  final List<Map<String, dynamic>> _actividades = [
    {'titulo': 'Actividad 1: Resolver ecuaciones', 'completada': false},
    {'titulo': 'Actividad 2: Leer capítulo 3', 'completada': false},
    {'titulo': 'Actividad 3: Responder cuestionario', 'completada': false},
    {'titulo': 'Actividad 4: Proyecto grupal', 'completada': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lista de Actividades',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _actividades.length,
                itemBuilder: (context, index) {
                  final actividad = _actividades[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        actividad['completada']
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: actividad['completada']
                            ? Colors.green
                            : Colors.grey,
                      ),
                      title: Text(
                        actividad['titulo'],
                        style: TextStyle(
                          decoration: actividad['completada']
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _editarActividad(context, index);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _eliminarActividad(index);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          actividad['completada'] = !actividad['completada'];
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _agregarActividad(context);
        },
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2, // Índice para Actividades
        onItemTapped: (index) {
          // Implementar navegación si es necesario
        },
      ),
    );
  }

  // Función para agregar una nueva actividad
  void _agregarActividad(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nueva Actividad'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Título de la actividad'),
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
                setState(() {
                  _actividades.add({
                    'titulo': _controller.text,
                    'completada': false,
                  });
                });
                Navigator.of(context).pop();
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  // Función para editar una actividad
  void _editarActividad(BuildContext context, int index) {
    final TextEditingController _controller =
        TextEditingController(text: _actividades[index]['titulo']);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Actividad'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Nuevo título de la actividad'),
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
                setState(() {
                  _actividades[index]['titulo'] = _controller.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Función para eliminar una actividad
  void _eliminarActividad(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Actividad'),
          content: const Text('¿Estás seguro de que deseas eliminar esta actividad?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _actividades.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
