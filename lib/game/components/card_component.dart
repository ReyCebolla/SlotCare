import 'package:flame/components.dart';
import '../blackjack_game.dart';

enum Pal { clubs, diamonds, hearts, spades }

class Carta {
  final Pal pal;
  final int valor; // utilitzo aquests valors: 1 (As), 2-10, 11 (J), 12 (Q), 13 (K)
  
  Carta({required this.pal, required this.valor});

  // genero aixi el image name per aconseguir els noms que tinc posats a les imatges de la baralla i despres sigui més facil obtenirles
  String get imageName {
    String rang;
    if (valor == 1) {
      rang = "ace";
    } else if (valor == 11) rang = "jack";
    else if (valor == 12) rang = "queen";
    else if (valor == 13) rang = "king";
    else rang = valor.toString(); //per si decas 

    String nomPal = pal.toString().split('.').last; //agafo el nom del pal de enum
    return "${rang}_of_$nomPal.png"; // i passo el resultat obtingut com la imagename
  }

  int get valorBlackjack { //per obtenir el valor real a blackjack de les cartes
    if (valor > 10) return 10; 
    if (valor == 1) return 11; //de moment fare que l'As valgui 11 per no complicar-me despres ja fare la logica de que pot valdre 1
    return valor;
  }
}


//això es per obtenir la imatge
class CartaComponent extends SpriteComponent with HasGameRef<BlackjackGame> {
  final Carta carta;
    bool estaOculta; // aquesta propietat perque una carta de la banca es mostra del reves al principi

  CartaComponent(this.carta, {this.estaOculta = false});
  
  @override
  Future<void> onLoad() async {
    String imatgeCarregar = estaOculta ? "reves.png" : carta.imageName;
    // Ara fem servir el 'getter' que hem creat a dalt
    sprite = await gameRef.loadSprite(imatgeCarregar); 
    size = Vector2(100, 140);
  }

  Future<void> revelar() async { // amb ixò giro la carta quan juga la banca
    estaOculta = false;
    sprite = await gameRef.loadSprite(carta.imageName);
  }
}