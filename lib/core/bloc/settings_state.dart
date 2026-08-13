import 'package:equatable/equatable.dart';

enum FireRedirectionTarget { fire, mojo, grow }

class SettingsState extends Equatable {
  final String currencySymbol;
  final String currencyCode;
  final int paydayDate;
  final double smileTargetAmount;
  final String smileGoalName;
  final FireRedirectionTarget fireRedirection;
  final double nodeDivisor;

  const SettingsState({
    required this.currencySymbol,
    required this.currencyCode,
    required this.paydayDate,
    required this.smileTargetAmount,
    required this.smileGoalName,
    required this.fireRedirection,
    required this.nodeDivisor,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      currencySymbol: 'Rs ',
      currencyCode: 'LKR',
      paydayDate: 1,
      smileTargetAmount: 0.0,
      smileGoalName: 'Smile Goal',
      fireRedirection: FireRedirectionTarget.fire,
      nodeDivisor: 5000.0,
    );
  }

  SettingsState copyWith({
    String? currencySymbol,
    String? currencyCode,
    int? paydayDate,
    double? smileTargetAmount,
    String? smileGoalName,
    FireRedirectionTarget? fireRedirection,
    double? nodeDivisor,
  }) {
    return SettingsState(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      paydayDate: paydayDate ?? this.paydayDate,
      smileTargetAmount: smileTargetAmount ?? this.smileTargetAmount,
      smileGoalName: smileGoalName ?? this.smileGoalName,
      fireRedirection: fireRedirection ?? this.fireRedirection,
      nodeDivisor: nodeDivisor ?? this.nodeDivisor,
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
        nodeDivisor,
      ];
}
