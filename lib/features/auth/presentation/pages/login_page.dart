import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../widgets/quotes_carousel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isForgotPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    String username = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) return;

    if (!username.contains('@')) {
      username = '$username@expense.local';
    }

    context.read<AuthCubit>().login(username, password);
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }
    
    try {
      await context.read<AuthCubit>().repository.resetPassword(email);
      if (mounted) {
        setState(() => _isForgotPassword = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email address')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          QuotesCarousel(),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme, AuthState state, bool isWide) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: isWide ? BorderRadius.circular(40) : const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isWide ? BorderRadius.circular(40) : const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            top: !isWide,
            bottom: isWide,
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 32, 
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 400 : double.infinity),
                  child: _isForgotPassword ? _buildForgotPasswordForm(theme, state) : _buildLoginForm(theme, state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm(ThemeData theme, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _isForgotPassword = false),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
        Text(
          'Reset Password',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your email address and we will send you a password reset link.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.mail_outline,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: state is AuthLoading ? null : _resetPassword,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: state is AuthLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
        const Center(
          child: Text.rich(
            TextSpan(
              style: TextStyle(color: Colors.white60, fontSize: 12),
              children: [
                TextSpan(text: '© 2026 Barefoot.   |   Proudly made by '),
                TextSpan(
                  text: 'OrbitView Innovations',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Enter your username',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Enter your Password',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => _isForgotPassword = true),
            child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: state is AuthLoading ? null : _login,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: state is AuthLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\'t have an account?', style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text('Sign up', style: TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Center(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                            children: [
                              TextSpan(text: '© 2026 Barefoot.   |   Proudly made by '),
                              TextSpan(
                                text: 'OrbitView Innovations',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                          child: _buildHeader(theme),
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SafeArea(
                    bottom: false,
                    child: _buildHeader(theme),
                  ),
                  Expanded(
                    child: _buildForm(theme, state, isWide),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
