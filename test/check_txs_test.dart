import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/features/expenses/domain/entities/transaction.dart';
import 'dart:io';

void main() {
  test('print txs', () async {
    Hive.init(Directory.current.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionEntityAdapter());
      Hive.registerAdapter(BucketTypeAdapter());
    }
    final box = await Hive.openBox<TransactionEntity>('transactions_box');
    print('Total transactions: ${box.length}');
    for (var tx in box.values) {
      print('TX: ${tx.title} - ${tx.amount} - ${tx.isIncome ? "Income" : "Expense"}');
    }
  });
}
