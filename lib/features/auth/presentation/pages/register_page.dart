// dart:ui removed - no BackdropFilter used in light theme
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../widgets/quotes_carousel.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    String username = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) return;

    if (!username.contains('@')) {
      username = '$username@expense.local';
    }

    context.read<AuthCubit>().register(username, password);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.black54),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF50C8C8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF50C8C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF50C8C8), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, BuildContext context, bool isWide) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: isSmallScreen ? 12 : 24),
      child: const QuotesCarousel(),
    );
  }

  Widget _buildForm(ThemeData theme, AuthState state, bool isWide) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: !isWide,
        bottom: isWide,
        child: Builder(
          builder: (context) {
            final isSmallScreen = MediaQuery.of(context).size.height < 700;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 24,
                vertical: isSmallScreen ? 12 : 32,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 400 : 340),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          label: 'Enter your username',
                          icon: Icons.person_outline,
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Enter your Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm your Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 32),
                        FilledButton(
                          onPressed: state is AuthLoading ? null : _register,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF50C8C8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('SIGN UP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?', style: TextStyle(color: Colors.black54)),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Sign in', style: TextStyle(color: Color(0xFF50C8C8), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 32),
                        Column(
                          children: [
                            const Text(
                              '© 2026 Barefoot.',
                              style: TextStyle(color: Colors.black54, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              const TextSpan(
                                style: TextStyle(color: Colors.black54, fontSize: 12),
                                children: [
                                  TextSpan(text: 'Proudly made by '),
                                  TextSpan(
                                    text: 'OrbitView Innovations',
                                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF5F5),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              
              if (isWide) {
                // Desktop side-by-side layout
                return Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 500,
                          child: _buildHeader(theme, context, isWide),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: _buildForm(theme, state, isWide),
                      ),
                    ),
                  ],
                );
              }

              // Mobile top-bottom layout
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SafeArea(
                          bottom: false,
                          child: _buildHeader(theme, context, isWide),
                        ),
                        Expanded(
                          child: _buildForm(theme, state, isWide),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
