import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Dummy controllers to match the layout
  final _birthdayController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSignUp(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios')),
      );
      return;
    }

    final success = await authProvider.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _passwordController.text, // Same as password since UI lacks it
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Erro ao registrar')),
      );
    }
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _commonInputDecoration([String? hintText, Widget? suffixIcon]) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFF9A826), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9A826), // Orange top
              Color(0xFFFDCB6E), // Light orange middle
              Color(0xFFFFF7E6), // very light bottom
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back arrow
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Registro',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Already have account
                    Row(
                      children: [
                        Text(
                          'Já possui uma conta? ',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: const Text(
                            'Entrar',
                            style: TextStyle(
                              color: Color(0xFFF9A826),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Nome Completo
                    _buildFieldLabel('Nome Completo'),
                    TextField(
                      controller: _nameController,
                      decoration: _commonInputDecoration('Usuário da Silva'),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _buildFieldLabel('Email'),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _commonInputDecoration('usuario@gmail.com'),
                    ),
                    const SizedBox(height: 20),

                    // Aniversário
                    _buildFieldLabel('Aniversário'),
                    TextField(
                      controller: _birthdayController,
                      decoration: _commonInputDecoration(
                        '01/01/2000',
                        const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Number
                    _buildFieldLabel('Phone Number'),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Country Code
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                // Brazilian Flag emoji
                                const Text('+55', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                              ],
                            ),
                          ),
                          Container(
                            width: 1.5,
                            color: Colors.grey.shade200,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          // Phone Input
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: '(11) 9 1234-5678',
                                hintStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Senha
                    _buildFieldLabel('Senha'),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _commonInputDecoration(
                        '*******',
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Registrar-se Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return ElevatedButton(
                          onPressed: authProvider.isLoading ? null : () => _handleSignUp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDA516), // Orange matching the button
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Registrar-se',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
