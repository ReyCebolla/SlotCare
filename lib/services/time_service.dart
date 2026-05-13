import 'dart:async';
import 'package:flutter/foundation.dart';

//Esta clase es la encargada de contar el tiempo
class TimeService extends ChangeNotifier {
  //Esto es para que la clase sea única (Singleton)
  //Significa que aunque cambies de pantalla, el reloj es el mismo
  static final TimeService _instance = TimeService._internal();
  factory TimeService() {
    return _instance;
  }
  TimeService._internal();

  //Variables
  Timer? _timer; //El objeto del reloj
  int segundosJugados = 0; //La cuenta de segundos

  //Funcion 1 Empezar a contar
  void empezarContador() {
    //Si el reloj ya existe, no hacemos nada para no tener dos a la vez
    if (_timer != null) {
      return;
    }

    //Configurar el reloj para que se repita cada 1 segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      //Sumamos 1 segundo
      segundosJugados = segundosJugados + 1;

      //Avisamos a la pantalla para que se actualice
      notifyListeners();

      //Imprimir en la consola para ver que funciona
      print("Segundos: $segundosJugados");
    });
  }

  //Funcion 2 Convertir los segundos a texto bonito "00:00"
  String obtenerTiempoFormateado() {
    // Calcular minutos y segundos
    int minutos = (segundosJugados / 60).floor();
    int segundos = segundosJugados % 60;

    //Convertir a texto y ponerle un cero delante si es menor de 10
    String minutosTexto = minutos.toString().padLeft(2, '0');
    String segundosTexto = segundos.toString().padLeft(2, '0');

    return "$minutosTexto:$segundosTexto";
  }
  int obtenerSegundosActuales() {
    return segundosJugados;
  }
  void resetTimer() {
    _timer?.cancel(); // Apaga el motor
    _timer = null;    // Importante para que el 'if' de empezar funcione la próxima vez
    segundosJugados = 0;
    notifyListeners();
  }
  void detenerYResetear() {
   
    print("Reloj detenido y reseteado.");
  }
}
