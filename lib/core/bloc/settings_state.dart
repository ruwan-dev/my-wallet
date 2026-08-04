import 'package:equatable/equatable.dart';

enum FireRedirectionTarget { fire, mojo, grow }

class SettingsState extends Equatable {
  final String currencySymbol;
  final String currencyCode;
  final int paydayDate;
  final double smileTargetAmount;
  final String smileGoalName;
  final FireRedirectionTarget fireRedirection;

  const SettingsState({
    required this.currencySymbol,
    required this.currencyCode,
    required this.paydayDate,
    required this.smileTargetAmount,
    required this.smileGoalName,
    required this.fireRedirection,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      currencySymbol: 'Rs ',
      currencyCode: 'LKR',
      paydayDate: 1,
      smileTargetAmount: 0.0,
      smileGoalName: 'Smile Goal',
      fireRedirection: FireRedirectionTarget.fire,
    );
  }

  SettingsState copyWith({
    String? currencySymbol,
    String? currencyCode,
    int? paydayDate,
    double? smileTargetAmount,
    String? smileGoalName,
    FireRedirectionTarget? fireRedirection,
  }) {
    return SettingsState(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      paydayDate: paydayDate ?? this.paydayDate,
      smileTargetAmount: smileTargetAmount ?? this.smileTargetAmount,
      smileGoalName: smileGoalName ?? this.smileGoalName,
      fireRedirection: fireRedirection ?? this.fireRedirection,
    );
  }

  @override
  List<Object?> get props => [
        currencySymbol,
        currencyCode,
        paydayDate,
        smileTargetAmount,
        smileGoalName,
        fireRedirection,
      ];
}
