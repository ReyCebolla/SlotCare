import 'package:flutter/material.dart';
import 'chat_screen.dart'; // Revisa que la ruta sigui correcta
import '../services/auth_service.dart';

class ListaChatsTerapeuta extends StatefulWidget {
  const ListaChatsTerapeuta({super.key});

  @override
  State<ListaChatsTerapeuta> createState() => _ListaChatsTerapeutaState();
}

class _ListaChatsTerapeutaState extends State<ListaChatsTerapeuta> {
  final AuthService _authService = AuthService();
  int? elMeuId;

  @override
  void initState() {
    super.initState();
    _carregarDades();
  }

  void _carregarDades() async {
    int? id = await _authService.getUserId();
    setState(() {
      elMeuId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (elMeuId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder(
      future: _authService.getMissatges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(child: Text("Encara no tens missatges de pacients."));
        }

        final totsElsMissatges = snapshot.data as List;

        // LÒGICA PER AGRUPAR XATS (Només un per usuari)
        Map<int, dynamic> xatsAgrupats = {};
        for (var m in totsElsMissatges) {
          // Determinem qui és l'altre usuari
          int altreId = (m['emisor'] == elMeuId) ? m['receptor'] : m['emisor'];
          // Guardem l'últim missatge d'aquest usuari
          xatsAgrupats[altreId] = m;
        }

        final llistaXats = xatsAgrupats.values.toList();

        return ListView.builder(
          itemCount: llistaXats.length,
          itemBuilder: (context, index) {
            final m = llistaXats[index];
            
            // Calcul d'ID i Nom de l'altre
            int altreUsuariId = (m['emisor'] == elMeuId) ? m['receptor'] : m['emisor'];
            String altreUsuariNom = (m['emisor'] == elMeuId) 
                ? m['receptor_username'] 
                : m['emisor_username'];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Text(altreUsuariNom[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
              ),
              title: Text(altreUsuariNom),
              subtitle: Text(
                m['contenido'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      receptorId: altreUsuariId,
                      receptorNombre: altreUsuariNom,
                    ),
                  ),
                ).then((_) => setState(() {})); // Refresca en tornar del xat
              },
            );
          },
        );
      },
    );
  }
}