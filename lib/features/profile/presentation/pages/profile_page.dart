import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/bloc/settings_cubit.dart';
import 'package:expense_tracker/core/widgets/glass_list_tile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _editingField;
  final _inlineEditController = TextEditingController();

  @override
  void dispose() {
    _inlineEditController.dispose();
    super.dispose();
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = context.watch<SettingsCubit>().state.currencyCode;
    final currencySymbol = context.watch<SettingsCubit>().state.currencySymbol;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          children: [
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                String email = 'Loading...';
                if (authState is AuthAuthenticated) {
                  email = authState.user.email;
                }
                return _buildSettingsSection(
                  title: 'Account',
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      title: 'Username',
                      subtitle: email != 'Loading...' ? email.split('@')[0] : email,
                      onTap: null,
                    ),
                    _buildSettingsTile(
                      icon: Icons.lock_reset,
                      title: 'Change Password',
                      onTap: () {
                        if (email != 'Loading...') {
                          context.push('/change-password', extra: email);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              title: 'Financial Preferences',
              children: [
                if (_editingField == 'payday')
                  _buildInlineEditForm(
                    icon: Icons.calendar_today,
                    initialValue: context.read<SettingsCubit>().state.paydayDate.toString(),
                    label: 'Day of month (1-31)',
                    keyboardType: TextInputType.number,
                    onSave: (val) {
                      final day = int.tryParse(val);
                      if (day != null && day >= 1 && day <= 31) {
                        final cubit = context.read<SettingsCubit>();
                        cubit.updateBarefootSettings(
                          paydayDate: day,
                          smileTargetAmount: cubit.state.smileTargetAmount,
                          smileGoalName: cubit.state.smileGoalName,
                          healRedirection: cubit.state.healRedirection,
                        );
                      }
                      setState(() => _editingField = null);
                    },
                    onCancel: () => setState(() => _editingField = null),
                  )
                else
                  _buildSettingsTile(
                    icon: Icons.calendar_today,
                    title: 'Payday Cycle',
                    subtitle: 'Every month on the ${context.watch<SettingsCubit>().state.paydayDate}${_getDaySuffix(context.watch<SettingsCubit>().state.paydayDate)}',
                    onTap: () => setState(() {
                      _editingField = 'payday';
                      _inlineEditController.text = context.read<SettingsCubit>().state.paydayDate.toString();
                    }),
                  ),
                _buildSettingsTile(
                  icon: Icons.attach_money,
                  title: 'Default Currency',
                  subtitle: '$currencyCode (${currencySymbol.trim()})',
                  onTap: () => context.push('/currency-selection'),
                ),

                if (_editingField == 'density')
                  _buildInlineEditForm(
                    icon: Icons.bubble_chart_rounded,
                    initialValue: context.read<SettingsCubit>().state.nodeDivisor.toInt().toString(),
                    label: 'Divisor Amount',
                    keyboardType: TextInputType.number,
                    onSave: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        context.read<SettingsCubit>().updateNodeDivisor(parsed);
                      }
                      setState(() => _editingField = null);
                    },
                    onCancel: () => setState(() => _editingField = null),
                  )
                else
                  _buildSettingsTile(
                    icon: Icons.bubble_chart_rounded,
                    title: 'Dashboard Art Density',
                    subtitle: '1 node per Rs ${context.watch<SettingsCubit>().state.nodeDivisor.toInt()}',
                    onTap: () => setState(() {
                      _editingField = 'density';
                      _inlineEditController.text = context.read<SettingsCubit>().state.nodeDivisor.toInt().toString();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              title: 'About',
              children: [
                _buildSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => context.push('/legal', extra: 'Privacy Policy'),
                ),
                _buildSettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => context.push('/legal', extra: 'Terms of Service'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'Version 1.0.0\n© 2026 OrbitView Innovations',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF1E1E2C),
            child: Icon(Icons.person, size: 50, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Barefoot Investor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'investor@barefoot.com',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInlineEditForm({
    required IconData icon,
    required String initialValue,
    required String label,
    required Function(String) onSave,
    required VoidCallback onCancel,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return GlassListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      leading: Icon(icon, color: const Color(0xFF38B2AC), size: 28),
      title: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inlineEditController,
              keyboardType: keyboardType,
              autofocus: true,
              cursorColor: const Color(0xFF38B2AC),
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                filled: false,
                hintText: label,
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF38B2AC)),
            onPressed: () => onSave(_inlineEditController.text),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF38B2AC)),
            onPressed: onCancel,
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
      {required String title, required List<Widget> children}) {
    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(const SizedBox(height: 12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...spacedChildren,
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GlassListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: subtitle != null ? 8 : 14),
      leading: Icon(icon, color: const Color(0xFF38B2AC), size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
      trailing: trailing,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<AuthCubit>().logout();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE11D48).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Log Out',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
