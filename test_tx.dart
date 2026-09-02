import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/features/expenses/domain/entities/transaction.dart';
import 'package:expense_tracker/core/enums/bucket_type.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionEntityAdapter());
  Hive.registerAdapter(BucketTypeAdapter());
  try {
    final box = await Hive.openBox<TransactionEntity>('transactions_box');
    for (var tx in box.values) {
      print('${tx.date} - ${tx.amount} - ${tx.isIncome ? "Income" : "Expense"} - Bucket: ${tx.bucketType}');
    }
  } catch (e) {
    print(e);
  }
}
