import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/card_component.dart'; 

class BlackjackGame extends FlameGame {
  final BuildContext context; // afegeixo el context per poder fer el dialeg de flutter quan acaba la partida
  BlackjackGame(this.context);

  //inicialitzo textComponents perque es vagi veient el resultat durant la partida
  late TextComponent textPuntsJugador;
  late TextComponent textPuntsBanca;

  // aqui creo llistes de cartes per gestionar la logica
  List<Carta> baralla = [];
  List<Carta> maJugador = [];
  List<Carta> maBanca = [];
  bool partidaAcabada = false; // afegeixo aquesta perque no em deixi seguir demanant quan acabiel joc

  // simulo un tapet de casino verd
  @override
  Color backgroundColor() => const Color(0xFF0E5D2F);

  @override
  Future<void> onLoad() async {
    final estilText = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black26, 
      ),
    );

    // inicialitzo el text de la banca
    textPuntsBanca = TextComponent(
      text: 'Banca: 0',
      textRenderer: estilText,
      position: Vector2(50, 20), // a sobre de les cartes de la banca
    );

    // inicialitzo el text del jugador
    textPuntsJugador = TextComponent(
      text: 'Jugador: 0',
      textRenderer: estilText,
      position: Vector2(50, size.y - 230), // a sobre de les cartes del jugador
    );
    
    add(textPuntsBanca);
    add(textPuntsJugador);

    _generarBaralla();
    _barrejar();
    
    // reparteixo 2 cartes al jugador utilitzant await perque es carreguii tot be
    await repartirCartaBanca();
    await repartirCartaBanca(oculta : true);

    await repartirCartaJugador();
    await repartirCartaJugador();

    _actualitzarMarcadors();
    
    print("Joc de Blackjack iniciat amb ${baralla.length} cartes restants.");
  }

  // aqui omplo la llista amb les 52 cartes utilitzant valors de l'1 al 13 (per simular les j, q, k)
  void _generarBaralla() {
    baralla.clear();
    for (var pal in Pal.values) { //afegeixo totes les cartes de cada pal.
      for (var i = 1; i <= 13; i++) {
        baralla.add(Carta(pal: pal, valor: i));
      }
    }
  }

  // amb aixo barrejo la baralla de forma aleatoria
  void _barrejar() {
    baralla.shuffle();
  }

  // amb aquest metode trec una carta de la baralla i la poso a la pantalla
  Future<void> repartirCartaJugador() async {
    if (partidaAcabada) return;
    if (baralla.isNotEmpty) {
      // sempre trec la ultima carta de la baralla
      Carta novaCarta = baralla.removeLast();
      maJugador.add(novaCarta);

      // creo el component visual que he fet a card_component
      var cartaVisual = CartaComponent(novaCarta);
      


      // Calculem la posició a la pantalla:
      // x: desplaçament horitzontal segons quantes cartes ja té
      // y: alçada de la pantalla menys un marge per estar a baix
      double offsetX = 50.0 + (maJugador.length - 1) * 45.0;
      double offsetY = size.y - 200; 
      
      cartaVisual.position = Vector2(offsetX, offsetY);
      
      // Afegim el component al motor Flame per pintar-lo
      add(cartaVisual);
      _actualitzarMarcadors();
      int punts = calcularPunts(maJugador);
      if (punts > 21) {
        partidaAcabada = true;
        print("T'has passat de 21!");
        _determinarGuanyador(); // acabo el joc si s'ha passat
      }
    }
  }

  // amb això calculo els punts de la mà
  int calcularPunts(List<Carta> ma) {
    int total = 0;
    int asos = 0;// això ho utilitzo per la logica de que l'as pot valdre 1 i 11

    for (var carta in ma) {
      total += carta.valorBlackjack;
      if (carta.valor == 1) asos++;
    }

    // si el jugador es passa de 21 i te asos, els faig valdre 1 en comptes de11
    while (total > 21 && asos > 0) {
      total -= 10;
      asos--;
    }
    return total;
  }
  CartaComponent? cartaOcultaBanca;
  Future<void> repartirCartaBanca({bool oculta = false}) async {
    if (baralla.isNotEmpty) {
      Carta novaCarta = baralla.removeLast();
      maBanca.add(novaCarta);

      var cartaVisual = CartaComponent(novaCarta, estaOculta: oculta);
      if (oculta) cartaOcultaBanca = cartaVisual; // guardo la referencia de la carta per despres desocultarla
      
      // la posiciono a la part superior perque es el dealer
      double offsetX = 50.0 + (maBanca.length - 1) * 45.0;
      double offsetY = 50; // A dalt
      
      cartaVisual.position = Vector2(offsetX, offsetY);
      add(cartaVisual);
      _actualitzarMarcadors();
    }
  }

  void plantarse() async {
    if (partidaAcabada) return;
    partidaAcabada = true;
    print("Jugador es planta amb ${calcularPunts(maJugador)} punts");
    // amb això revelo la carta oculta de la banca
    if (cartaOcultaBanca != null) {
      await cartaOcultaBanca!.revelar();
    }
    _actualitzarMarcadors();
    // 2. Esperem una mica per efecte dramàtic
    await Future.delayed(const Duration(milliseconds: 600));
      jugarTornBanca();
    }

  Future<void> jugarTornBanca() async {
    //mostro la carta girada si encara no ho habia fet
    if (cartaOcultaBanca != null && cartaOcultaBanca!.estaOculta) {
      await cartaOcultaBanca!.revelar();
      await Future.delayed(const Duration(milliseconds: 800)); // faig una pausa per fer-ho realista
    }

    // aqui faig que quan el jugador es planta la banca demana cartes fins arribar a 17 o pasarse
    while (calcularPunts(maBanca) < 17) {
      await repartirCartaBanca();
      // afegeixo una mica de retard perque es pugui veure tot
      await Future.delayed(const Duration(milliseconds: 800));
    }
    _determinarGuanyador();
  }

  void _determinarGuanyador() {
    int pJ = calcularPunts(maJugador);
    int pB = calcularPunts(maBanca);
    String titol = "";
    String missatge = "Jugador: $pJ | Banca: $pB";

    if (pJ > 21) {
      titol = "T'has passat!";
    } else if (pB > 21 || pJ > pB) {
      titol = "Has guanyat!";
    } else if (pJ < pB) {
      titol = "Guanya la banca";
    } else {
      titol = "Empat!";
    }

    // mostro el dialeg de glutter
    showDialog(
      context: context,
      barrierDismissible: false, // es obligatori clickar el boto
      builder: (context) => AlertDialog(
        title: Text(titol),
        content: Text(missatge),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tanca el diàleg
              Navigator.of(context).pop(); // Surt del joc per tornar a la Home
            },
            child: const Text("Tornar al menú"),
          ),
        ],
      ),
    );
  }
  void _actualitzarMarcadors() {
    // Punts del jugador
    textPuntsJugador.text = 'Jugador: ${calcularPunts(maJugador)}';

    // Punts de la banca
    if (partidaAcabada) {
      textPuntsBanca.text = 'Banca: ${calcularPunts(maBanca)}';
    } else {
      // si la partida no ha acabat nomes mostro el valor de la carta visible
      textPuntsBanca.text = 'Banca: ${maBanca.isNotEmpty ? maBanca[0].valorBlackjack : 0} + ?';
    }
  }
  
}