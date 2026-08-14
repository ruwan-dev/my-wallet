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

  Widget _buildHeader(ThemeData theme, BuildContext context) {
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
                    child: _isForgotPassword ? _buildForgotPasswordForm(theme, state, isSmallScreen) : _buildLoginForm(theme, state, context, isSmallScreen),
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm(ThemeData theme, AuthState state, bool isSmallScreen) {
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
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          'Enter your email address and we will send you a password reset link.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isSmallScreen ? 20 : 32),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.mail_outline,
        ),
        SizedBox(height: isSmallScreen ? 20 : 32),
        FilledButton(
          onPressed: state is AuthLoading ? null : _resetPassword,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF50C8C8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: state is AuthLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Send Reset Link', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: isSmallScreen ? 16 : 32),
        const Center(
          child: Text.rich(
            TextSpan(
              style: TextStyle(color: Colors.black54, fontSize: 12),
              children: [
                TextSpan(text: '© 2026 Barefoot.   |   Proudly made by '),
                TextSpan(
                  text: 'OrbitView Innovations',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme, AuthState state, BuildContext context, bool isSmallScreen) {
    return Column(
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
        SizedBox(height: isSmallScreen ? 8 : 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => _isForgotPassword = true),
            child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF50C8C8), fontWeight: FontWeight.bold)),
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 32),
        FilledButton(
          onPressed: state is AuthLoading ? null : _login,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF50C8C8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: state is AuthLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('LOGIN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.black26)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Divider(color: Colors.black26)),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        OutlinedButton(
          onPressed: state is AuthLoading
              ? null
              : () => context.read<AuthCubit>().loginWithGoogle(),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF50C8C8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Don\'t have an account?', style: TextStyle(color: Colors.black54, fontSize: 13)),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Sign up', style: TextStyle(color: Color(0xFF50C8C8), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ],
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
                          child: _buildHeader(theme, context),
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
                  Expanded(
                    flex: 4,
                    child: SafeArea(
                      bottom: false,
                      child: _buildHeader(theme, context),
                    ),
                  ),
                  Expanded(
                    flex: 6,
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
