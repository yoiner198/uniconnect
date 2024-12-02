// pantallas/registro.dart
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  _RegistroPageState createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String nombres = '';
  String apellidos = '';
  String correoInstitucional = '';
  String contrasena = '';
  String carrera = '';
  String username = '';
  String facultad = '';

  // Listas de facultades y carreras
  final List<String> facultades = [
    'Facultad de Ingenierías y Tecnologías',
    'Facultad de Ciencias Administrativas y Contables',
    'Facultad de Derecho, Ciencias Políticas y Sociales',
    'Facultad de Ciencias de la Salud',
    'Facultad de Bellas Artes',
    'Facultad de Ciencias Básicas',
    'Facultad de Educación',
  ];

  final Map<String, List<String>> carrerasPorFacultad = {
    'Facultad de Ingenierías y Tecnologías': [
      'Ingeniería de Sistemas',
      'Ingeniería Electrónica',
      'Ingeniería Ambiental',
      'Ingeniería Agroindustrial',
    ],
    'Facultad de Ciencias Administrativas y Contables': [
      'Administración de Empresas',
      'Contaduría Pública',
      'Administración de Empresas Turísticas y Hoteleras',
      'Comercio Internacional',
    ],
    'Facultad de Derecho, Ciencias Políticas y Sociales': [
      'Derecho',
      'Psicología',
      'Sociología',
    ],
    'Facultad de Ciencias de la Salud': [
      'Instrumentación Quirúrgica',
      'Enfermería',
    ],
    'Facultad de Bellas Artes': [
      'Licenciatura en Artes',
      'Música',
    ],
    'Facultad de Ciencias Básicas': [
      'Microbiología',
    ],
    'Facultad de Educación': [
      'Licenciatura en Ciencias Naturales y Educación Ambiental',
      'Licenciatura en Literatura y Lengua Castellana',
      'Licenciatura en Matemáticas',
      'Licenciatura en Español e Inglés',
    ],
  };

  String? seleccionarFacultad;
  String? seleccionarCarrera;

  Future<void> _solicitarPermisoUbicacion() async {
    // Mostrar un diálogo personalizado para solicitar permiso
    bool? permitir = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Uniconnect quiere conocer tu ubicación'),
          content:
              const Text('¿Permites que la aplicación acceda a tu ubicación?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Denegar
              child: const Text('Denegar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Permitir
              child: const Text('Permitir'),
            ),
          ],
        );
      },
    );

    if (permitir == true) {
      // Si el usuario permite, solicita el permiso
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
          return;
        }
      }

      // Obtener la ubicación actual
      Position posicion = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print(
          'Ubicación actual: Latitud: ${posicion.latitude}, Longitud: ${posicion.longitude}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación concedido')),
      );
    } else {
      // Si el usuario deniega, muestra un mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación denegado')),
      );
    }
  }

  Future<void> registrarUsuario() async {
    // Solicitar permiso de ubicación al registrarse
    await _solicitarPermisoUbicacion();

    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: correoInstitucional,
          password: contrasena,
        );

        // Generate username from email
        username = correoInstitucional.split('@')[0];

        await _firestore
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
          'nombres': nombres,
          'apellidos': apellidos,
          'correo': correoInstitucional,
          'carrera': seleccionarCarrera,
          'username': username,
          'facultad': seleccionarFacultad,
        });

        // Show a dialog with the username
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Registro Exitoso'),
              content: Text('Tu usuario es: $username'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );

        // Optional: You can also keep the success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'UniConnect',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 42, 143, 62)),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Nombres'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tus nombres';
                        }
                        return null;
                      },
                      onChanged: (value) => nombres = value,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Apellidos'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tus apellidos';
                        }
                        return null;
                      },
                      onChanged: (value) => apellidos = value,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Correo Institucional'),
                      validator: (value) {
                        if (value == null ||
                            !value.endsWith('@unicesar.edu.co')) {
                          return 'El correo debe ser institucional (@unicesar.edu.co)';
                        }
                        return null;
                      },
                      onChanged: (value) => correoInstitucional = value,
                    ),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                      onChanged: (value) => contrasena = value,
                    ),
                    // ComboBox para seleccionar la facultad
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Facultad'),
                      value: seleccionarFacultad,
                      items: facultades.map((String facultad) {
                        return DropdownMenuItem<String>(
                          value: facultad,
                          child: Text(facultad),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          seleccionarFacultad = value;
                          seleccionarCarrera =
                              null; // Reiniciar carrera al cambiar facultad
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona una facultad';
                        }
                        return null;
                      },
                    ),
                    // ComboBox para seleccionar la carrera
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Carrera'),
                      value: seleccionarCarrera,
                      items: seleccionarFacultad != null
                          ? carrerasPorFacultad[seleccionarFacultad]!
                              .map((String carrera) {
                              return DropdownMenuItem<String>(
                                value: carrera,
                                child: Text(carrera),
                              );
                            }).toList()
                          : [],
                      onChanged: (value) {
                        setState(() {
                          seleccionarCarrera = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona una carrera';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: registrarUsuario,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Registrar'),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 42, 143, 62),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Volver al Inicio de Sesión'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
