import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final Box _box;

  static const String _currencySymbolKey = 'default_currency_symbol';
  static const String _currencyCodeKey = 'default_currency_code';

  static const String _paydayDateKey = 'payday_date';
  static const String _smileTargetAmountKey = 'smile_target_amount';
  static const String _smileGoalNameKey = 'smile_goal_name';
  static const String _fireRedirectionKey = 'fire_redirection';
  static const String _nodeDivisorKey = 'node_divisor';

  SettingsCubit(this._box) : super(SettingsState.initial()) {
    _loadSettings();
  }

  void _loadSettings() {
    final symbol = _box.get(_currencySymbolKey, defaultValue: 'Rs ');
    final code = _box.get(_currencyCodeKey, defaultValue: 'LKR');
    final paydayDate = _box.get(_paydayDateKey, defaultValue: 1) as int;
    final smileTargetAmount = (_box.get(_smileTargetAmountKey, defaultValue: 0.0) as num).toDouble();
    final smileGoalName = _box.get(_smileGoalNameKey, defaultValue: 'Smile Goal');
    
    final fireRedirectionStr = _box.get(_fireRedirectionKey, defaultValue: 'fire');
    FireRedirectionTarget fireRedirection = FireRedirectionTarget.values.firstWhere(
      (e) => e.name == fireRedirectionStr,
      orElse: () => FireRedirectionTarget.fire,
    );
    
    final nodeDivisor = (_box.get(_nodeDivisorKey, defaultValue: 5000.0) as num).toDouble();
    
    emit(state.copyWith(
      currencySymbol: symbol,
      currencyCode: code,
      paydayDate: paydayDate,
      smileTargetAmount: smileTargetAmount,
      smileGoalName: smileGoalName,
      fireRedirection: fireRedirection,
      nodeDivisor: nodeDivisor,
    ));
  }

  Future<void> updateCurrency(String symbol, String code) async {
    await _box.put(_currencySymbolKey, symbol);
    await _box.put(_currencyCodeKey, code);
    
    emit(state.copyWith(
      currencySymbol: symbol,
      currencyCode: code,
    ));
  }

  Future<void> updateBarefootSettings({
    required int paydayDate,
    required double smileTargetAmount,
    required String smileGoalName,
    required FireRedirectionTarget fireRedirection,
  }) async {
    await _box.put(_paydayDateKey, paydayDate);
    await _box.put(_smileTargetAmountKey, smileTargetAmount);
    await _box.put(_smileGoalNameKey, smileGoalName);
    await _box.put(_fireRedirectionKey, fireRedirection.name);

    emit(state.copyWith(
      paydayDate: paydayDate,
      smileTargetAmount: smileTargetAmount,
      smileGoalName: smileGoalName,
      fireRedirection: fireRedirection,
    ));
  }

  Future<void> updateNodeDivisor(double nodeDivisor) async {
    await _box.put(_nodeDivisorKey, nodeDivisor);
    emit(state.copyWith(nodeDivisor: nodeDivisor));
  }
}
