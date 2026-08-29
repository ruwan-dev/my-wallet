import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_state.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final Box _box;
  final AuthRepository _authRepository;
  final FirebaseFirestore _firestore;

  static const String _currencySymbolKey = 'default_currency_symbol';
  static const String _currencyCodeKey = 'default_currency_code';

  static const String _paydayDateKey = 'payday_date';
  static const String _smileTargetAmountKey = 'smile_target_amount';
  static const String _smileGoalNameKey = 'smile_goal_name';
  static const String _fireRedirectionKey = 'fire_redirection';
  static const String _nodeDivisorKey = 'node_divisor';
  static const String _bucketAccountLinksKey = 'bucket_account_links';

  SettingsCubit(this._box, this._authRepository, this._firestore) : super(SettingsState.initial()) {
    _loadSettings();
  }

  void _loadSettings() {
    final symbol = _box.get(_currencySymbolKey, defaultValue: 'Rs ');
    final code = _box.get(_currencyCodeKey, defaultValue: 'LKR');
    final paydayDate = _box.get(_paydayDateKey, defaultValue: 1) as int;
    final smileTargetAmount = (_box.get(_smileTargetAmountKey, defaultValue: 0.0) as num).toDouble();
    final smileGoalName = _box.get(_smileGoalNameKey, defaultValue: 'Smile Goal');
    
    final fireRedirectionStr = _box.get(_fireRedirectionKey, defaultValue: 'heal');
    HealRedirectionTarget healRedirection = HealRedirectionTarget.values.firstWhere(
      (e) => e.name == fireRedirectionStr,
      orElse: () => HealRedirectionTarget.heal,
    );
    
    final nodeDivisor = (_box.get(_nodeDivisorKey, defaultValue: 5000.0) as num).toDouble();

    // Load bucket<->account links (stored as Map<String, String>)
    final rawLinks = _box.get(_bucketAccountLinksKey);
    final Map<String, String> bucketLinks = {};
    if (rawLinks is Map) {
      rawLinks.forEach((k, v) {
        if (k is String && v is String) bucketLinks[k] = v;
      });
    }

    emit(state.copyWith(
      currencySymbol: symbol,
      currencyCode: code,
      paydayDate: paydayDate,
      smileTargetAmount: smileTargetAmount,
      smileGoalName: smileGoalName,
      healRedirection: healRedirection,
      nodeDivisor: nodeDivisor,
      bucketAccountLinks: bucketLinks,
    ));
  }

  Future<void> syncFromCloud() async {
    final user = await _authRepository.getCurrentUser();
    if (user == null || !user.isPremium) return;

    try {
      final doc = await _firestore.collection('users').doc(user.id).collection('settings').doc('app_settings').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        if (data.containsKey(_currencySymbolKey)) await _box.put(_currencySymbolKey, data[_currencySymbolKey]);
        if (data.containsKey(_currencyCodeKey)) await _box.put(_currencyCodeKey, data[_currencyCodeKey]);
        if (data.containsKey(_paydayDateKey)) await _box.put(_paydayDateKey, data[_paydayDateKey]);
        if (data.containsKey(_smileTargetAmountKey)) await _box.put(_smileTargetAmountKey, (data[_smileTargetAmountKey] as num).toDouble());
        if (data.containsKey(_smileGoalNameKey)) await _box.put(_smileGoalNameKey, data[_smileGoalNameKey]);
        if (data.containsKey(_fireRedirectionKey)) await _box.put(_fireRedirectionKey, data[_fireRedirectionKey]);
        if (data.containsKey(_nodeDivisorKey)) await _box.put(_nodeDivisorKey, (data[_nodeDivisorKey] as num).toDouble());
        if (data.containsKey(_bucketAccountLinksKey)) {
          final rawLinks = data[_bucketAccountLinksKey] as Map<String, dynamic>;
          final Map<String, String> links = rawLinks.map((k, v) => MapEntry(k, v.toString()));
          await _box.put(_bucketAccountLinksKey, links);
        }

        // Reload locally to emit new state
        _loadSettings();
      }
    } catch (e) {
      print('Failed to sync settings from cloud: ' + e.toString());
    }
  }

  Future<void> syncToCloud() async {
    final user = await _authRepository.getCurrentUser();
    if (user == null || !user.isPremium) return;

    try {
      final data = {
        _currencySymbolKey: state.currencySymbol,
        _currencyCodeKey: state.currencyCode,
        _paydayDateKey: state.paydayDate,
        _smileTargetAmountKey: state.smileTargetAmount,
        _smileGoalNameKey: state.smileGoalName,
        _fireRedirectionKey: state.healRedirection.name,
        _nodeDivisorKey: state.nodeDivisor,
        _bucketAccountLinksKey: state.bucketAccountLinks,
      };

      await _firestore.collection('users').doc(user.id).collection('settings').doc('app_settings').set(data);
    } catch (e) {
      print('Failed to sync settings to cloud: ' + e.toString());
    }
  }

  Future<void> updateCurrency(String symbol, String code) async {
    await _box.put(_currencySymbolKey, symbol);
    await _box.put(_currencyCodeKey, code);
    
    emit(state.copyWith(
      currencySymbol: symbol,
      currencyCode: code,
    ));
    await syncToCloud();
  }

  Future<void> updateBarefootSettings({
    required int paydayDate,
    required double smileTargetAmount,
    required String smileGoalName,
    required HealRedirectionTarget healRedirection,
  }) async {
    await _box.put(_paydayDateKey, paydayDate);
    await _box.put(_smileTargetAmountKey, smileTargetAmount);
    await _box.put(_smileGoalNameKey, smileGoalName);
    await _box.put(_fireRedirectionKey, healRedirection.name);

    emit(state.copyWith(
      paydayDate: paydayDate,
      smileTargetAmount: smileTargetAmount,
      smileGoalName: smileGoalName,
      healRedirection: healRedirection,
    ));
    await syncToCloud();
  }

  Future<void> updateNodeDivisor(double nodeDivisor) async {
    await _box.put(_nodeDivisorKey, nodeDivisor);
    emit(state.copyWith(nodeDivisor: nodeDivisor));
    await syncToCloud();
  }

  Future<void> linkAccountToBucket(
      String bucketTypeName, String accountId) async {
    final updated = Map<String, String>.from(state.bucketAccountLinks);
    updated.removeWhere((_, v) => v == accountId);
    updated[bucketTypeName] = accountId;
    await _box.put(_bucketAccountLinksKey, updated);
    emit(state.copyWith(bucketAccountLinks: updated));
    await syncToCloud();
  }

  Future<void> unlinkAccountFromBucket(String bucketTypeName) async {
    final updated = Map<String, String>.from(state.bucketAccountLinks);
    updated.remove(bucketTypeName);
    await _box.put(_bucketAccountLinksKey, updated);
    emit(state.copyWith(bucketAccountLinks: updated));
    await syncToCloud();
  }
}
