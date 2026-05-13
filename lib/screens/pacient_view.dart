import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class TherapistsView extends StatelessWidget {
  const TherapistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text("Els nostres Terapeutes")),
      body: FutureBuilder(
        future: authService.getTerapeutes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) { //per quan esta carregnat
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || (snapshot.data as List).isEmpty) { //quan no hi ha terapeutes disponibles
            return const Center(child: Text("No hi ha terapeutes disponibles actualment."));
          }

          final terapeutes = snapshot.data as List;

          return ListView.builder( //llisto el terapeutes amb els que pots obrir xat
            itemCount: terapeutes.length,
            itemBuilder: (context, index) {
              final t = terapeutes[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.medical_services, color: Colors.white),
                ),
                title: Text(t['username']),
                subtitle: const Text("Prem per iniciar una consulta"),
                trailing: const Icon(Icons.chat),
                onTap: () {
                  // obro el xat directament
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receptorId: t['id'],
                        receptorNombre: t['username'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}