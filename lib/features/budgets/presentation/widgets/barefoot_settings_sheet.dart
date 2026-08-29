import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/settings_cubit.dart';
import '../../../../core/bloc/settings_state.dart';

class BarefootSettingsSheet extends StatefulWidget {
  const BarefootSettingsSheet({super.key});

  @override
  State<BarefootSettingsSheet> createState() => _BarefootSettingsSheetState();
}

class _BarefootSettingsSheetState extends State<BarefootSettingsSheet> {
  late int _paydayDate;
  late double _smileTargetAmount;
  late TextEditingController _smileGoalController;
  late HealRedirectionTarget _fireRedirection;

  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsCubit>().state;
    _paydayDate = state.paydayDate;
    _smileTargetAmount = state.smileTargetAmount;
    _smileGoalController = TextEditingController(text: state.smileGoalName);
    _fireRedirection = state.healRedirection;
  }

  @override
  void dispose() {
    _smileGoalController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    context.read<SettingsCubit>().updateBarefootSettings(
          paydayDate: _paydayDate,
          smileTargetAmount: _smileTargetAmount,
          smileGoalName: _smileGoalController.text,
          healRedirection: _fireRedirection,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Barefoot Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Payday Setting
            const Text('Monthly Payday (Auto-Sweep)', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _paydayDate.toDouble(),
                    min: 1,
                    max: 31,
                    divisions: 30,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (val) {
                      setState(() => _paydayDate = val.toInt());
                    },
                  ),
                ),
                Text(
                  'Day $_paydayDate',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Smile Goal Tracker
            const Text('Smile Goal (Holiday, New Phone, etc.)', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: _smileGoalController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Fiji Trip',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _smileTargetAmount > 0 ? _smileTargetAmount.toStringAsFixed(0) : '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Target Amount (e.g. 1000)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                _smileTargetAmount = double.tryParse(val) ?? 0.0;
              },
            ),
            
            const SizedBox(height: 24),

            // Heal Redirection
            const Text('Heal Allocation (20%)', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  RadioListTile<HealRedirectionTarget>(
                    title: const Text('Default (Heal Wallet)', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Keep building fire to pay off debts', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: HealRedirectionTarget.heal,
                    groupValue: _fireRedirection,
                    activeColor: const Color(0xFFEF4444),
                    onChanged: (val) => setState(() => _fireRedirection = val!),
                  ),
                  RadioListTile<HealRedirectionTarget>(
                    title: const Text('Redirect to Mojo', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Debt-free? Build your 3-month safety net', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: HealRedirectionTarget.mojo,
                    groupValue: _fireRedirection,
                    activeColor: const Color(0xFFF59E0B),
                    onChanged: (val) => setState(() => _fireRedirection = val!),
                  ),
                  RadioListTile<HealRedirectionTarget>(
                    title: const Text('Redirect to Grow', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Mojo full? Point the firehose at wealth', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: HealRedirectionTarget.grow,
                    groupValue: _fireRedirection,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _fireRedirection = val!),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _saveSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
