import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../../core/bloc/settings_cubit.dart';
import '../../../../core/utils/sweep_util.dart';
import '../../../../core/widgets/currency_selection_bottom_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 32),
            _buildSettingsSection(
              title: 'Financial Preferences',
              children: [
                _buildSettingsTile(
                  icon: Icons.calendar_today,
                  title: 'Payday Cycle',
                  subtitle:
                      'Every month on the ${context.watch<SettingsCubit>().state.paydayDate}${_getDaySuffix(context.watch<SettingsCubit>().state.paydayDate)}',
                  trailing: IconButton(
                    icon: const Icon(Icons.flash_on, color: Color(0xFFEAB308)),
                    tooltip: 'Test Sweep Now',
                    onPressed: () {
                      SweepUtil.checkAndTriggerAutoSweep(context, force: true);
                    },
                  ),
                  onTap: () {
                    final cubit = context.read<SettingsCubit>();
                    int selectedDay = cubit.state.paydayDate;

                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return Container(
                          height: 300,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E2C),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(32)),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel',
                                          style:
                                              TextStyle(color: Colors.white54)),
                                    ),
                                    const Text('Select Payday',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    TextButton(
                                      onPressed: () {
                                        cubit.updateBarefootSettings(
                                          paydayDate: selectedDay,
                                          smileTargetAmount:
                                              cubit.state.smileTargetAmount,
                                          smileGoalName:
                                              cubit.state.smileGoalName,
                                          fireRedirection:
                                              cubit.state.fireRedirection,
                                        );
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Save',
                                          style: TextStyle(
                                              color: Color(0xFF3B82F6),
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: StatefulBuilder(
                                  builder: (context, setState) {
                                    return ListWheelScrollView.useDelegate(
                                      itemExtent: 60,
                                      perspective: 0.005,
                                      diameterRatio: 1.2,
                                      physics: const FixedExtentScrollPhysics(),
                                      controller: FixedExtentScrollController(initialItem: selectedDay - 1),
                                      onSelectedItemChanged: (index) {
                                        setState(() {
                                          selectedDay = index + 1;
                                        });
                                      },
                                      childDelegate: ListWheelChildBuilderDelegate(
                                        childCount: 31,
                                        builder: (context, index) {
                                          final day = index + 1;
                                          final isSelected = day == selectedDay;
                                          return Center(
                                            child: AnimatedDefaultTextStyle(
                                              duration: const Duration(milliseconds: 200),
                                              style: TextStyle(
                                                color: isSelected ? const Color(0xFF3B82F6) : Colors.white54,
                                                fontSize: isSelected ? 32 : 20,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              ),
                                              child: Text('$day${_getDaySuffix(day)}'),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.attach_money,
                  title: 'Default Currency',
                  subtitle: '$currencyCode (${currencySymbol.trim()})',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) =>
                          const CurrencySelectionBottomSheet(),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.account_balance,
                  title: 'Linked Bank Accounts',
                  subtitle: '2 Connected',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              title: 'Security',
              children: [
                _buildSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'App Lock',
                  subtitle: 'PIN / Biometric',
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeColor: const Color(0xFF8B5CF6),
                  ),
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              title: 'Data & Export',
              children: [
                _buildSettingsTile(
                  icon: Icons.download_rounded,
                  title: 'Export to CSV/PDF',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Backup & Restore',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              title: 'App Settings',
              children: [
                _buildSettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark / Light Theme',
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeColor: const Color(0xFF8B5CF6),
                  ),
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
            const SizedBox(height: 80),
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

  Widget _buildSettingsSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: children,
              ),
            ),
          ),
        ),
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.white54)
              : null),
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
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
        ),
        child: const Center(
          child: Text(
            'Log Out',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
