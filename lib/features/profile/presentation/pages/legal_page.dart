import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LegalPage extends StatelessWidget {
  final String title;
  
  const LegalPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'This is a placeholder for the $title.\n\n'
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
              'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
              'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
              'nisi ut aliquip ex ea commodo consequat.\n\n'
              'Duis aute irure dolor in reprehenderit in voluptate velit esse '
              'cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat '
              'cupidatat non proident, sunt in culpa qui officia deserunt mollit '
              'anim id est laborum.\n\n'
              'In real-world usage, this would contain the actual legal text '
              'or be loaded dynamically from a web server or local asset file. '
              'For now, this demonstrates the native, full-screen navigation '
              'that avoids using popups.',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
