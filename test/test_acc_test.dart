import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/features/expenses/domain/entities/account.dart';
import 'dart:io';

void main() {
  test('print accounts', () async {
    Hive.init(Directory.current.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AccountEntityAdapter());
      Hive.registerAdapter(AccountTypeAdapter());
    }
    final box = await Hive.openBox<AccountEntity>('accounts_box');
    for (var acc in box.values) {
      print('ACCOUNT: ${acc.name} - ${acc.type} - ${acc.balance}');
    }
  });
}
