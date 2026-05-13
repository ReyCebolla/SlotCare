import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final int receptorId;
  final String receptorNombre;

  const ChatScreen({super.key, required this.receptorId, required this.receptorNombre});

  @override
  State<ChatScreen> createState() => _ChatScreenState();

  
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final AuthService _authService = AuthService();

  void _enviar() async {
    if (_controller.text.isEmpty) return;
    
    bool ok = await _authService.enviarMissatge(widget.receptorId, _controller.text);
    if (ok) {
      _controller.clear();
      setState(() {}); // refresco perque es vegi el nou missatge
    }
  }
  int? elMeuId;

  @override
  void initState() {
    super.initState();
    _carregarElMeuId();
  }

  void _carregarElMeuId() async {
    int? id = await _authService.getUserId();
    setState(() {
      elMeuId = id;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Xat amb ${widget.receptorNombre}")),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _authService.getMissatges(), 
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());//quan esta carregant
                
                final tots = snapshot.data as List;
                // filtro per tenir nomes els missatges entre aquests dos usuaris
                final xat = tots.where((m) {
                  bool joAAltre = (m['emisor'] == elMeuId && m['receptor'] == widget.receptorId);
                  bool altreAJo = (m['emisor'] == widget.receptorId && m['receptor'] == elMeuId);
                  return joAAltre || altreAJo;
                }).toList();

                return ListView.builder(
                  itemCount: xat.length,
                  itemBuilder: (context, index) {
                    final m = xat[index];
                    bool socJo = m['emisor_username'] != widget.receptorNombre;
                    
                    return Align(
                      alignment: socJo ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: socJo ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(m['contenido']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Escriu un missatge..."))),
                IconButton(icon: const Icon(Icons.send), onPressed: _enviar),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
}