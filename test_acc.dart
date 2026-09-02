import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/features/expenses/domain/entities/account.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(AccountEntityAdapter());
  Hive.registerAdapter(AccountTypeAdapter());
  try {
    final box = await Hive.openBox<AccountEntity>('accounts_box');
    for (var acc in box.values) {
      print('${acc.name} - ${acc.type} - ${acc.balance}');
    }
  } catch (e) {
    print(e);
  }
}
