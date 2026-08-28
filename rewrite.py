import re

with open('lib/features/expenses/presentation/pages/financial_forecast_page.dart', 'r') as f:
    content = f.read()

# 1. Update variables inside BlocBuilder
old_vars = '''                  double fireBalance = 0;
                  double mojoBalance = 0;
                  for (final tx in txState.transactions) {
                    final bucket = _getBucketForTx(tx, catState.categories);
                    if (bucket == BucketType.fire) {
                      fireBalance += tx.isIncome ? tx.amount : -tx.amount;
                    } else if (bucket == BucketType.mojo) {
                      mojoBalance += tx.isIncome ? tx.amount : -tx.amount;
                    }
                  }'''

new_vars = '''                  double fireBalance = 0;
                  double mojoBalance = 0;
                  double smileBalance = 0;
                  double splurgeBalance = 0;
                  for (final tx in txState.transactions) {
                    final bucket = _getBucketForTx(tx, catState.categories);
                    if (bucket == BucketType.fire) {
                      fireBalance += tx.isIncome ? tx.amount : -tx.amount;
                    } else if (bucket == BucketType.mojo) {
                      mojoBalance += tx.isIncome ? tx.amount : -tx.amount;
                    } else if (bucket == BucketType.smile) {
                      smileBalance += tx.isIncome ? tx.amount : -tx.amount;
                    } else if (bucket == BucketType.splurge) {
                      splurgeBalance += tx.isIncome ? tx.amount : -tx.amount;
                    }
                  }'''
content = content.replace(old_vars, new_vars)

# 2. Add smileBudget and splurgeBudget
old_budgets = '''                  double actualBlowAllocation = monthlyIncome * 0.60;
                  double customBlowBudget = actualBlowAllocation;
                  double fireBudget = monthlyIncome * 0.20;'''

new_budgets = '''                  double actualBlowAllocation = monthlyIncome * 0.60;
                  double customBlowBudget = actualBlowAllocation;
                  double fireBudget = monthlyIncome * 0.20;
                  double smileBudget = monthlyIncome * 0.10;
                  double splurgeBudget = monthlyIncome * 0.10;'''
content = content.replace(old_budgets, new_budgets)

# 3. Update the _buildGitGraph call
old_call = '''                        _buildGitGraph(context, fireBalance, mojoBalance, month1Sweep, month1Deficit, fireBudget, actualBlowAllocation, customBlowBudget),'''
new_call = '''                        _buildGitGraph(context, fireBalance, mojoBalance, smileBalance, splurgeBalance, month1Sweep, month1Deficit, fireBudget, smileBudget, splurgeBudget, actualBlowAllocation, customBlowBudget),'''
content = content.replace(old_call, new_call)

# 4. Replace the entire _buildGitGraph method
# We need to find the start of the method and replace it until the end.
old_method_start = '  Widget _buildGitGraph(BuildContext context, double startingFire, double startingMojo, double month1Sweep, double month1Deficit, double monthlyFireAllocation, double actualBlowAllocation, double customBlowBudget) {'
old_method_pattern = re.compile(r'  Widget _buildGitGraph\(BuildContext context.*?\n  }\n}\n', re.DOTALL)

new_method = '''  Widget _buildGitGraph(
    BuildContext context, 
    double startingFire, 
    double startingMojo, 
    double startingSmile,
    double startingSplurge,
    double month1Sweep, 
    double month1Deficit, 
    double monthlyFireAllocation, 
    double monthlySmileAllocation,
    double monthlySplurgeAllocation,
    double actualBlowAllocation, 
    double customBlowBudget
  ) {
    List<ForecastNode> graphNodes = [];
    double projectedFire = startingFire;
    double projectedMojo = startingMojo;
    double projectedSmile = startingSmile;
    double projectedSplurge = startingSplurge;
    double projectedDebt = 0;
    final now = DateTime.now();

    for (int i = 0; i < 6; i++) {
      final targetDate = DateTime(now.year, now.month + i, 1);
      
      double sweepAmount = 0;
      double allocationAmount = 0;
      double smileAllocAmount = 0;
      double splurgeAllocAmount = 0;
      double deficitAmount = 0;
      
      if (i == 0) {
        sweepAmount = month1Sweep;
        allocationAmount = 0; 
        smileAllocAmount = 0;
        splurgeAllocAmount = 0;
        deficitAmount = month1Deficit;
      } else {
        double futureSweep = actualBlowAllocation - customBlowBudget;
        if (futureSweep < 0) {
          deficitAmount = futureSweep.abs();
          sweepAmount = 0;
        } else {
          sweepAmount = futureSweep;
          deficitAmount = 0;
        }
        allocationAmount = monthlyFireAllocation;
        smileAllocAmount = monthlySmileAllocation;
        splurgeAllocAmount = monthlySplurgeAllocation;
      }
      
      List<ForecastTransfer> transfers = [];

      if (sweepAmount > 0) {
        transfers.add(ForecastTransfer(TrackType.blow, TrackType.fire, sweepAmount, '+${AppFormatters.formatCurrency(context, sweepAmount)}', TrackColors.blow));
      }
      
      if (deficitAmount > 0) {
        transfers.add(ForecastTransfer(TrackType.fire, TrackType.blow, deficitAmount, '-${AppFormatters.formatCurrency(context, deficitAmount)}', TrackColors.fire));
      }

      projectedFire += sweepAmount + allocationAmount - deficitAmount;
      projectedSmile += smileAllocAmount;
      projectedSplurge += splurgeAllocAmount;
      
      if (projectedFire < 0) {
        double missing = projectedFire.abs();
        
        if (projectedSmile > 0) {
          double pull = projectedSmile >= missing ? missing : projectedSmile;
          transfers.add(ForecastTransfer(TrackType.smile, TrackType.fire, pull, 'Rescue: ${AppFormatters.formatCurrency(context, pull)}', TrackColors.smile));
          projectedSmile -= pull;
          missing -= pull;
        }
        
        if (missing > 0 && projectedSplurge > 0) {
          double pull = projectedSplurge >= missing ? missing : projectedSplurge;
          transfers.add(ForecastTransfer(TrackType.splurge, TrackType.fire, pull, 'Rescue: ${AppFormatters.formatCurrency(context, pull)}', TrackColors.splurge));
          projectedSplurge -= pull;
          missing -= pull;
        }

        if (missing > 0) {
          transfers.add(ForecastTransfer(TrackType.mojo, TrackType.fire, missing, 'Cover: ${AppFormatters.formatCurrency(context, missing)}', TrackColors.mojo));
          projectedMojo -= missing;
          missing = 0;
        }
        projectedFire = 0;
      }
      
      if (projectedMojo < 0) {
        double mojoDrain = projectedMojo.abs();
        transfers.add(ForecastTransfer(TrackType.debt, TrackType.mojo, mojoDrain, 'Borrow: ${AppFormatters.formatCurrency(context, mojoDrain)}', TrackColors.debt));
        projectedDebt += mojoDrain;
        projectedMojo = 0;
      }

      graphNodes.add(ForecastNode(
        monthLabel: i == 0 ? 'End of ${DateFormat('MMM yyyy').format(targetDate)}' : DateFormat('MMMM yyyy').format(targetDate),
        smileBalance: projectedSmile,
        smileBalanceStr: AppFormatters.formatCurrency(context, projectedSmile),
        splurgeBalance: projectedSplurge,
        splurgeBalanceStr: AppFormatters.formatCurrency(context, projectedSplurge),
        fireBalance: projectedFire,
        fireBalanceStr: AppFormatters.formatCurrency(context, projectedFire),
        mojoBalance: projectedMojo,
        mojoBalanceStr: AppFormatters.formatCurrency(context, projectedMojo),
        debtBalance: projectedDebt,
        debtBalanceStr: AppFormatters.formatCurrency(context, projectedDebt),
        allocationAmount: allocationAmount,
        allocationAmountStr: '+${AppFormatters.formatCurrency(context, allocationAmount)}',
        transfers: transfers,
      ));
    }
    return ForecastGitGraph(nodes: graphNodes);
  }
}
'''
content = old_method_pattern.sub(new_method, content)

with open('lib/features/expenses/presentation/pages/financial_forecast_page.dart', 'w') as f:
    f.write(content)

print("Done")
