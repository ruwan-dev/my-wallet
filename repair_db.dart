import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/features/expenses/domain/entities/account.dart';
import 'package:expense_tracker/features/expenses/domain/entities/transaction.dart';
import 'package:expense_tracker/core/enums/bucket_type.dart';

void main() async {
  await Hive.initFlutter(Directory.current.path);
  Hive.registerAdapter(AccountEntityAdapter());
  Hive.registerAdapter(AccountTypeAdapter());
  Hive.registerAdapter(TransactionEntityAdapter());
  Hive.registerAdapter(BucketTypeAdapter());
  
  try {
    final accountsBox = await Hive.openBox<AccountEntity>('accounts_box');
    final txBox = await Hive.openBox<TransactionEntity>('transactions_box');
    
    for (var i = 0; i < accountsBox.length; i++) {
      final account = accountsBox.getAt(i)!;
      double newBalance = 0.0;
      
      // We don't have an initial balance field currently.
      // Assuming initial balance is 0 for all accounts and it's derived from txs.
      for (var tx in txBox.values) {
        if (tx.accountId == account.id) {
          if (account.type == AccountType.liability) {
             newBalance += tx.isIncome ? -tx.amount : tx.amount;
          } else {
             newBalance += tx.isIncome ? tx.amount : -tx.amount;
          }
        }
        if (tx.transferAccountId == account.id) {
          if (account.type == AccountType.liability) {
             newBalance -= tx.amount; // Received a payment to liability
          } else {
             newBalance += tx.amount; // Received a transfer to asset
          }
        }
      }
      
      if (account.balance != newBalance) {
        print('Repairing ${account.name}: ${account.balance} -> $newBalance');
        await accountsBox.putAt(i, account.copyWith(balance: newBalance));
      }
    }
    
    print('Repair complete.');
  } catch (e) {
    print('Error: $e');
  }
}
