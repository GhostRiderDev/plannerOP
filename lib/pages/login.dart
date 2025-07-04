import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:lottie/lottie.dart';
import 'package:plannerop/hooks/auth/useLogin.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _passVisibility = true;

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);

    // Intentar auto-login al iniciar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryAutoLogin(mounted, setState, _isLoading, context);
    });
  }

  @override
  void dispose() {
    _usernameFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si está cargando (intentando auto-login), mostrar spinner
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 300,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
                child: Lottie.asset('assets/auth-animation.json'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 20),
                      Neumorphic(
                        style: NeumorphicStyle(
                          depth: -4,
                          intensity: 0.8,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                        ),
                        child: TextFormField(
                          key: Key('signin_username_field'),
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            errorStyle: TextStyle(
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su usuario';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Neumorphic(
                        style: NeumorphicStyle(
                          depth: -4,
                          intensity: 0.8,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                        ),
                        child: TextFormField(
                          key: Key('signin_password_field'),
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _passVisibility,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: _passVisibility
                                  ? Icon(Icons.visibility_off)
                                  : Icon(Icons.visibility),
                              onPressed: () {
                                _passVisibility = !_passVisibility;

                                setState(() {});
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su contraseña';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      NeumorphicButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await login(
                              _formKey,
                              context,
                              mounted,
                              _usernameController.text.trim(),
                              _passwordController.text.trim(),
                            );
                          }
                        },
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.flat,
                          depth: 8,
                          intensity: 1.0,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                          color: Colors.blue, // Cambia el color del botón
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 32.0), // Aumenta el tamaño del botón
                        child: const Center(
                          child: Text(
                            'Ingresar',
                            key: Key('signin_button'),
                            style: TextStyle(
                              fontSize: 20, // Aumenta el tamaño del texto
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Cambia el color del texto
                            ),
                          ),
                        ),
                      ),

                      // Footer con "Created by" y logo
                      const SizedBox(height: 90),
                      Column(
                        children: [
                          Text(
                            'Created by',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Image.asset(
                            'assets/cargoban.png',
                            height: 100, // Tamaño controlado de la imagen
                            fit: BoxFit.contain,
                          ),
                        ],
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
