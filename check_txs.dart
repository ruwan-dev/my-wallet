import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/features/expenses/domain/entities/transaction.dart';
import 'package:expense_tracker/core/enums/bucket_type.dart';

void main() async {
  await Hive.initFlutter(Directory.current.path);
  Hive.registerAdapter(TransactionEntityAdapter());
  Hive.registerAdapter(BucketTypeAdapter());
  try {
    final box = await Hive.openBox<TransactionEntity>('transactions_box');
    print('Total transactions: ${box.length}');
    for (var tx in box.values) {
      print('${tx.title} - ${tx.amount} - ${tx.isIncome ? "Income" : "Expense"}');
    }
  } catch (e) {
    print(e);
  }
}
