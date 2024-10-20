import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart';

class AjustesPage extends StatefulWidget {
  @override
  _AjustesPageState createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController carreraController = TextEditingController();
  final String correoInstitucional = 'usuario@unicesar.edu.co'; // Ejemplo
  bool mostrarTelefono = true;
  String visibilidadPerfil = 'todos'; // Opciones: 'todos', 'contactos', 'nadie'
  bool notificacionesMensajes = true;
  bool notificacionesGrupos = true;
  bool vibracion = true;
  String idioma = 'Español'; // Opciones: 'Español', 'Inglés'
  bool temaOscuro = false;

  Future<void> cambiarFotoPerfil() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil cambiada')),
      );
    }
  }

  void cambiarContrasena() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función para cambiar contraseña')),
    );
  }

  void cerrarSesion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada')),
    );
  }

  void borrarCuenta() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuenta eliminada')),
    );
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
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Foto de perfil'),
              leading: const Icon(Icons.account_circle),
              trailing: const Icon(Icons.edit),
              onTap: cambiarFotoPerfil,
            ),
            ListTile(
              title: TextFormField(
                controller: nombresController,
                decoration: const InputDecoration(labelText: 'Nombres'),
              ),
            ),
            ListTile(
              title: TextFormField(
                controller: apellidosController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
              ),
            ),
            ListTile(
              title: TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Número de teléfono'),
              ),
            ),
            ListTile(
              title: TextFormField(
                controller: carreraController,
                decoration: const InputDecoration(labelText: 'Carrera'),
              ),
            ),
            ListTile(
              title: Text('Correo institucional: $correoInstitucional'),
              leading: const Icon(Icons.email),
            ),
            ListTile(
              title: const Text('Cambiar contraseña'),
              leading: const Icon(Icons.lock),
              trailing: const Icon(Icons.arrow_forward),
              onTap: cambiarContrasena,
            ),
            const SizedBox(height: 20),
            const Text(
              'Ajustes de privacidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Visibilidad del número de teléfono'),
              value: mostrarTelefono,
              onChanged: (bool value) {
                setState(() {
                  mostrarTelefono = value;
                });
              },
            ),
            ListTile(
              title: const Text('Quién puede ver tu perfil'),
              trailing: DropdownButton<String>(
                value: visibilidadPerfil,
                onChanged: (String? newValue) {
                  setState(() {
                    visibilidadPerfil = newValue!;
                  });
                },
                items: <String>['todos', 'contactos', 'nadie']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ajustes de notificaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Notificaciones de mensajes nuevos'),
              value: notificacionesMensajes,
              onChanged: (bool value) {
                setState(() {
                  notificacionesMensajes = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Notificaciones de actividades de grupo'),
              value: notificacionesGrupos,
              onChanged: (bool value) {
                setState(() {
                  notificacionesGrupos = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Vibraciones'),
              value: vibracion,
              onChanged: (bool value) {
                setState(() {
                  vibracion = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Ajustes generales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Idioma'),
              trailing: DropdownButton<String>(
                value: idioma,
                onChanged: (String? newValue) {
                  setState(() {
                    idioma = newValue!;
                  });
                },
                items: <String>['Español', 'Inglés']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            SwitchListTile(
              title: const Text('Tema oscuro'),
              value: temaOscuro,
              onChanged: (bool value) {
                setState(() {
                  temaOscuro = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: cerrarSesion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cerrar sesión'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: borrarCuenta,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Borrar cuenta'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4, // Índice para Ajustes
        onItemTapped: (index) {
          // Lógica de navegación al cambiar entre elementos del menú
        },
      ),
    );
  }
}
