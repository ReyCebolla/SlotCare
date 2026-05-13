import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class NewsView extends StatelessWidget {
  const NewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return FutureBuilder<List<dynamic>>(
      future: authService.obtenerNoticias(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("No hi ha notícies disponibles en aquest moment."),
          );
        }

        final noticies = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: noticies.length,
          itemBuilder: (context, index) {
            final noticia = noticies[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imatge (si en tens una a l'API)
                  if (noticia['imatge_url'] != null && noticia['imatge_url'] != "")
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        noticia['imatge_url'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          noticia['titol'] ?? 'Sense títol',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          noticia['contingut'] ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              noticia['font'] ?? "SlotCare",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: Colors.deepPurple
                              ),
                            ),
                            Text(
                              noticia['data_publicacio']?.toString().substring(0, 10) ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}