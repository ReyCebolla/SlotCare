import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

final String API_BASE_URL = kIsWeb
    ? 'http://localhost:8000/api/users' // Si lo abres en Chrome (Web)
    : 'http://10.0.2.2:8000/api/users';

class AuthService {
  //REGISTRO
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final url = Uri.parse('$API_BASE_URL/register/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registre completat. Ja pots iniciar sessió.',
        };
      } else {
        //Gestionar errores de Django
        final errorData = json.decode(utf8.decode(response.bodyBytes));

        String errorMessage = 'Error al registrar.';
        if (errorData.containsKey('password')) {
          errorMessage = 'Error de Contrasenya: ${errorData['password'][0]}';
        } else if (errorData.containsKey('username')) {
          errorMessage = 'L\'usuari ja existeix.';
        } else if (errorData.containsKey('email')) {
          errorMessage = "Correu electrònic invàlid o en ús.";
        }

        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de connexió amb el servidor: $e',
      };
    }
  }

  //LOGIN
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$API_BASE_URL/login/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'sistema': 'Flutter App',
        }),
      );

      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // Imprimimos la respuesta real para ver qué nos manda Django
        print("DEBUG SERVER RESPONSE: $responseData");

        final prefs = await SharedPreferences.getInstance();

        // 1. Guardamos el token (buscamos 'token' o 'access', lo que sea que mande)
        final String tokenSeguro =
            responseData['token'] ?? responseData['access'] ?? '';
        await prefs.setString('auth_token', tokenSeguro);

        // 2. Guardamos el rol (si es nulo porque es el superusuario, le ponemos 'Admin')
        final String rolSeguro = responseData['rol'] ?? 'Admin';
        await prefs.setString('user_rol', rolSeguro);

        // 3. Guardamos el ID (si falla, ponemos 0)
        final int idSeguro = responseData['user_id'] ?? 0;
        await prefs.setInt('userId', idSeguro);

        return {
          'success': true,
          'rol': rolSeguro,
          'message': 'Inici de sessió correcte.',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Credencials incorrectes.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de connexió: $e'};
    }
  }

  Future<bool> registrarSesion(int segundos, double perdida) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    if (token == null) return false;
    print("DEBUG: Intentando conectar a /guardar-sesion/");
    try {
      print("Enviando Header: Authorization: Token $token");
      final response = await http.post(
        Uri.parse('$API_BASE_URL/guardar-sesion/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'duracion_segundos': segundos,
          'perdida_estimada': perdida,
        }),
      );
      print("RESPUESTA SERVIDOR: ${response.body}");
      return response.statusCode == 201;
    } catch (e) {
      print("Error conectando con el servidor: $e");
      return false;
    }
  }

  Future<List<dynamic>> obtenerHistorialSesiones() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    if (token == null) return [];

    final response = await http.get(
      Uri.parse(
        '$API_BASE_URL/guardar-sesion/',
      ), // O la URL que definas para listar
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      return [];
    }
  }

  Future<List<dynamic>> obtenerNoticias() async {
    final response = await http.get(Uri.parse('$API_BASE_URL/noticies/'));
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  // amb aquest metode obting tots els missatges del usuari
  Future<List<dynamic>> getMissatges() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final response = await http.get(
      Uri.parse('$API_BASE_URL/missatges/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al carregar missatges');
    }
  }

  //amb aquest metode envio missatges
  Future<bool> enviarMissatge(int receptorId, String contingut) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final response = await http.post(
      Uri.parse('$API_BASE_URL/missatges/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({'receptor': receptorId, 'contenido': contingut}),
    );

    return response.statusCode == 201;
  }

  //amb aquest retorno la llista de terapeutes perque el pacient pugui escollir
  Future<List<dynamic>> getTerapeutes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('$API_BASE_URL/terapeutes-llista/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    print("DEBUG Terapeutes: ${response.body}"); // Mira què respon el servidor

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }
}
