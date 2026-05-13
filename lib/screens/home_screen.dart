import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/game.dart';

import 'package:frontend/screens/pacient_view.dart';
import 'package:frontend/screens/terapeuta_view.dart';
import 'news_view.dart';
import '../services/time_service.dart';
import '../services/auth_service.dart';
import '../game/blackjack_game.dart';

// Paleta de colores ajustada para alto contraste y profesionalidad
const Color scDarkBg = Color(0xFF1E2329);
const Color scCardBg = Color(0xFF2A313C);
const Color scCyan = Color(0xFF00D0C5);
const Color scOrange = Color(0xFFFF9933);
const Color scGreen = Color(0xFF4ADE80);

class HomeScreen extends StatefulWidget {
  final String userRol;
  final VoidCallback onLogout;

  const HomeScreen({required this.userRol, required this.onLogout, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TimeService _timeService = TimeService();

  // Variables para controlar el límite y el cierre
  double _limiteEscogido = 30.0; // Valor por defecto en minutos
  bool _cerrandoPorLimite = false;

  @override
  void initState() {
    super.initState();
    _timeService.empezarContador();

    // Escuchamos el cronómetro para actualizar el texto y comprobar el límite
    _timeService.addListener(() {
      if (mounted) {
        setState(() {});

        int currentSeconds = _timeService.obtenerSegundosActuales();
        int limiteSegundos = (_limiteEscogido * 60).toInt();

        // COMPROBACIÓN: Si llega al límite de tiempo elegido, cierra la sesión
        if (currentSeconds >= limiteSegundos && !_cerrandoPorLimite) {
          _cerrandoPorLimite = true;

          // Mostramos el mensaje de aviso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Límit de temps assolit. Tancant sessió per la teva seguretat...",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: scOrange, // Usa el color naranja de tu paleta
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Esperamos 3 segundos para que lea el mensaje y ejecutamos tu función _logout()
          Future.delayed(const Duration(seconds: 3), () {
            _logout();
          });
        }
      }
    });
  }

  Future<void> _logout() async {
    try {
      int segundosTotales = _timeService.obtenerSegundosActuales();
      double perdidaCalculada = segundosTotales * 0.05;

      final authService = AuthService();
      await authService.registrarSesion(segundosTotales, perdidaCalculada);

      _timeService.resetTimer();
    } catch (e) {
      debugPrint("Error crítico durante el registro de sesión: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_rol');

    widget.onLogout();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Widget para construir los botones de la cabecera (Top Nav)
  Widget _buildTopNavButton(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? scCyan.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? scCyan : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? scCyan : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userRol == 'Terapeuta') {
      return Scaffold(
        backgroundColor: scDarkBg,
        appBar: AppBar(
          title: const Text(
            "Panell de Terapeuta",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: scCardBg,
          foregroundColor: Colors.white,
          elevation: 1,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: const ListaChatsTerapeuta(),
      );
    }

    // Las 4 vistas principales
    final List<Widget> pages = [
      const DashboardView(),
      const NewsView(),
      const TherapistsView(),
      // Pasamos el límite y la función de cambio al perfil
      ProfileView(
        userRol: widget.userRol,
        limiteTiempo: _limiteEscogido,
        onLimiteChanged: (nouValor) {
          setState(() {
            _limiteEscogido = nouValor;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: scDarkBg,
      appBar: AppBar(
        backgroundColor: scCardBg,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.5),
        titleSpacing: 24,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 28,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.casino, size: 28, color: scCyan),
            ),
            const SizedBox(width: 12),
            const Text(
              'SlotCare',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 40),

            // Navegación movida a la cabecera
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTopNavButton(0, 'Inici', Icons.home_rounded),
                    _buildTopNavButton(1, 'Notícies', Icons.article_rounded),
                    _buildTopNavButton(
                      2,
                      'Terapèutes',
                      Icons.psychology_rounded,
                    ),
                    _buildTopNavButton(3, 'Perfil', Icons.person_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Cronómetro arriba a la derecha
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scDarkBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: scOrange),
                  const SizedBox(width: 6),
                  Text(
                    _timeService.obtenerTiempoFormateado(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
            tooltip: "Tancar Sessió",
            onPressed: _logout,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: pages[_selectedIndex],
    );
  }
}

// =========================================================================
// 1. DASHBOARD VIEW (El teu disseny original adaptat a la nova paleta)
// =========================================================================
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // CONTENEDOR DEL LOGO DE SLOTCARE
            Container(
              decoration: BoxDecoration(
                color: scCardBg, // <--- Nova paleta
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Image.asset(
                'assets/logo.png',
                height: 110,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Icon(
                      Icons.health_and_safety,
                      size: 80,
                      color: scCyan, // <--- Nova paleta
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Benvingut a SlotCare",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: scCyan, // <--- Nova paleta
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Tria una simulació per començar",
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ), // <--- Nova paleta
            ),
            const SizedBox(height: 40),

            // JUEGO 1: SLOT MACHINE
            Card(
              color: scCardBg, // <--- Nova paleta
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  debugPrint("Click en Slot Machine");
                },
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 25,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.casino,
                        size: 40,
                        color: scOrange,
                      ), // <--- Nova paleta
                      SizedBox(width: 20),
                      Text(
                        "Slot Machine",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // <--- Nova paleta
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: scCyan, // <--- Nova paleta
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // JUEGO 2: BLACKJACK
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  final game = BlackjackGame(
                    context,
                  ); // Creem la instància aquí per poder cridar mètodes

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        body: Stack(
                          children: [
                            GameWidget(game: game), // El joc de fons
                            // Botons a sobre
                            Positioned(
                              bottom: 50,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () =>
                                        game.repartirCartaJugador(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text("Demanar (Hit)"),
                                  ),
                                  const SizedBox(width: 20),
                                  ElevatedButton(
                                    onPressed: () => game.plantarse(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text("Plantar-se (Stand)"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 25,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.style, size: 40, color: Colors.deepPurple),
                      SizedBox(width: 20),
                      Text(
                        "Blackjack",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 2. THERAPISTS VIEW (Incluido en el mismo archivo)
// =========================================================================
/*class TherapistsView extends StatelessWidget {
  const TherapistsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Text(
          "El teu suport",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: scCyan,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Contacta amb professionals especialitzats en joc responsable. Estan aquí per ajudar-te.",
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        _buildTherapistCard(
          "Dra. Laura Gil",
          "Psicòloga clínica - Addiccions",
          Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTherapistCard(
          "Dr. Marc Pons",
          "Teràpia Cognitiu-Conductual",
          Icons.psychology_outlined,
        ),
        const SizedBox(height: 16),
        _buildTherapistCard(
          "Projecte Home",
          "Suport grupal i familiar",
          Icons.groups_outlined,
        ),
      ],
    );
  }

  Widget _buildTherapistCard(String name, String specialty, IconData iconData) {
    return Container(
      decoration: BoxDecoration(
        color: scCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            debugPrint("Iniciando chat con $name");
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(iconData, size: 28, color: scCyan),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: scOrange,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/
// --- VISTA 3: PERFIL ---
class ProfileView extends StatefulWidget {
  final String userRol;
  final double limiteTiempo;
  final ValueChanged<double> onLimiteChanged;

  const ProfileView({
    required this.userRol,
    required this.limiteTiempo,
    required this.onLimiteChanged,
    super.key,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthService _authService = AuthService();
  late Future<List<dynamic>> _historialFuture;

  @override
  void initState() {
    super.initState();
    _historialFuture = _authService.obtenerHistorialSesiones();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: scCardBg,
          child: Icon(Icons.person, size: 60, color: scCyan),
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            "Usuari Connectat",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Chip(
            label: Text(
              widget.userRol.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: scOrange,
          ),
        ),
        const SizedBox(height: 30),

        // --- CONFIGURACIÓ DE LÍMITS (SOLO TIEMPO) ---
        const Text(
          "Configuració de Límits",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: scCyan,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scCardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Temps Diari",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    "${widget.limiteTiempo.toInt()} min",
                    style: const TextStyle(
                      color: scCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Slider(
                value: widget.limiteTiempo,
                min:
                    1, // Mínimo 1 minuto para que puedas probar el cierre de sesión
                max: 120,
                divisions: 119,
                activeColor: scCyan,
                inactiveColor: Colors.black26,
                onChanged:
                    widget.onLimiteChanged, // Envía el cambio al HomeScreen
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
        const Divider(height: 1, thickness: 1, color: Colors.white24),
        const SizedBox(height: 30),

        // --- HISTORIAL DE SESSIONS ---
        const Text(
          "Historial de Sessions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: scCyan,
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<dynamic>>(
          future: _historialFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: scCyan),
              );
            }
            if (snapshot.hasError ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return Card(
                color: scCardBg,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Encara no hi ha sessions registrades.",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              );
            }
            return Card(
              color: scCardBg,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(
                      label: Text('Data', style: TextStyle(color: scCyan)),
                    ),
                    DataColumn(
                      label: Text('Temps (s)', style: TextStyle(color: scCyan)),
                    ),
                    DataColumn(
                      label: Text(
                        'Pèrdua (€)',
                        style: TextStyle(color: scOrange),
                      ),
                    ),
                  ],
                  rows: snapshot.data!.map((sesion) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            sesion['fecha_inicio']?.toString().substring(
                                  0,
                                  10,
                                ) ??
                                'Avui',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${sesion['duracion_segundos']}s",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${sesion['perdida_estimada']}€",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
