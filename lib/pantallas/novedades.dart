// novedades.dart
import 'package:flutter/material.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart';

class NovedadesPage extends StatelessWidget {
  const NovedadesPage({Key? key}) : super(key: key);

  // Lista estática con contenido interesante de noticias
  final List<Map<String, String>> noticias = const [
    {
      'titulo': 'Tecnología en 2024: Innovaciones Futuras',
      'descripcion':
          'Las tecnologías emergentes como IA, blockchain, y 5G están cambiando el panorama digital rápidamente.',
      'fecha': '20 de Octubre, 2024',
      'imagen': 'lib/assets/img/imagen1.png'
    },
    {
      'titulo': 'La Evolución del Trabajo Remoto',
      'descripcion':
          'El teletrabajo sigue siendo una tendencia en crecimiento, con nuevos desafíos y beneficios.',
      'fecha': '18 de Octubre, 2024',
      'imagen': 'lib/assets/img/imagen2.png'
    },
    {
      'titulo': 'Transformación Digital en la Educación',
      'descripcion':
          'Las plataformas digitales están revolucionando la forma en que los estudiantes acceden a la educación.',
      'fecha': '15 de Octubre, 2024',
      'imagen': 'lib/assets/img/imagen3.png'
    },
    {
      'titulo': 'Sostenibilidad en el Desarrollo Tecnológico',
      'descripcion':
          'Los desarrolladores están adoptando nuevas prácticas para garantizar la sostenibilidad en la tecnología.',
      'fecha': '12 de Octubre, 2024',
      'imagen': 'lib/assets/img/imagen4.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novedades'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: noticias.length,
          itemBuilder: (context, index) {
            final noticia = noticias[index];
            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen de la noticia con manejo de error
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        noticia['imagen']!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/default_image.png', // Imagen por defecto
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Título de la noticia
                    Text(
                      noticia['titulo']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Descripción de la noticia
                    Text(
                      noticia['descripcion']!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Fecha de la noticia
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        noticia['fecha']!,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 3, // Índice para Novedades
        onItemTapped: (index) {},
      ),
    );
  }
}
