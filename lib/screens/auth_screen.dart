import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// PANTALLA PRINCIPAL DE AUTH

class AuthScreen extends StatefulWidget {
  final Function(bool, {String rol}) onLoginSuccess;
  const AuthScreen({required this.onLoginSuccess, super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  void toggleScreen() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Inici de Sessió' : 'Registre')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SlotCare',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 40),
              // Aquí decidimos si mostramos Login o Registro
              isLogin
                  ? LoginView(onLoginSuccess: widget.onLoginSuccess)
                  : RegisterView(onRegisterComplete: toggleScreen),

              const SizedBox(height: 20),
              TextButton(
                onPressed: toggleScreen,
                child: Text(
                  isLogin
                      ? 'No tens compte? Registra\'t'
                      : 'Ja tens compte? Inicia Sessió',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//VISTA DE LOGIN

class LoginView extends StatefulWidget {
  final Function(bool, {String rol}) onLoginSuccess;
  const LoginView({required this.onLoginSuccess, super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _errorMessage = '';

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final result = await _authService.login(
        username: _userController.text,
        password: _passController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        widget.onLoginSuccess(true, rol: result['rol']);
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _userController,
            decoration: const InputDecoration(
              labelText: 'Nom d\'Usuari',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Falta l\'usuari' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contrasenya',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Falta la contrasenya' : null,
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _submit,
                  child: const Text('INICIAR SESSIÓ'),
                ),
        ],
      ),
    );
  }
}

// VISTA DE REGISTRO

class RegisterView extends StatefulWidget {
  final VoidCallback onRegisterComplete;
  const RegisterView({required this.onRegisterComplete, super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  //Controllers
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _mailCtrl = TextEditingController();

  bool _isLoading = false;
  String _message = '';

  final String passwordRegex =
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\$;\.\-_*]).{8,}$';

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = '';
      });

      final result = await _authService.register(
        username: _userCtrl.text,
        password: _passCtrl.text,
        firstName: _nameCtrl.text,
        lastName: _lastCtrl.text,
        email: _mailCtrl.text,
      );

      setState(() {
        _isLoading = false;
        _message = result['message'];
      });

      if (result['success']) {
        await Future.delayed(const Duration(seconds: 2));
        widget.onRegisterComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _userCtrl,
            decoration: const InputDecoration(labelText: 'Usuari'),
            validator: (v) => v!.isEmpty ? 'Obligatori' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (v) => v!.isEmpty ? 'Obligatori' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _lastCtrl,
            decoration: const InputDecoration(labelText: 'Cognoms'),
            validator: (v) => v!.isEmpty ? 'Obligatori' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _mailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) => !v!.contains('@') ? 'Email malament' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contrasenya'),
            validator: (v) {
              if (v!.isEmpty) return 'Obligatoria';
              if (!RegExp(passwordRegex).hasMatch(v)) {
                return "Falten majúscules, números o símbols";
              }
              return null;
            },
          ),
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _message,
                style: TextStyle(
                  color: _message.contains('correcte')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _submit,
                  child: const Text('REGISTRAR'),
                ),
        ],
      ),
    );
  }
}
