import 'package:equatable/equatable.dart';

enum HealRedirectionTarget { heal, mojo, grow }

class SettingsState extends Equatable {
  final String currencySymbol;
  final String currencyCode;
  final int paydayDate;
  final double smileTargetAmount;
  final String smileGoalName;
  final HealRedirectionTarget healRedirection;
  final double nodeDivisor;
  /// Maps BucketType.name → accountId for synced buckets.
  final Map<String, String> bucketAccountLinks;

  const SettingsState({
    required this.currencySymbol,
    required this.currencyCode,
    required this.paydayDate,
    required this.smileTargetAmount,
    required this.smileGoalName,
    required this.healRedirection,
    required this.nodeDivisor,
    this.bucketAccountLinks = const {},
  });

  factory SettingsState.initial() {
    return const SettingsState(
      currencySymbol: 'Rs ',
      currencyCode: 'LKR',
      paydayDate: 1,
      smileTargetAmount: 0.0,
      smileGoalName: 'Smile Goal',
      healRedirection: HealRedirectionTarget.heal,
      nodeDivisor: 5000.0,
      bucketAccountLinks: const {},
    );
  }

  SettingsState copyWith({
    String? currencySymbol,
    String? currencyCode,
    int? paydayDate,
    double? smileTargetAmount,
    String? smileGoalName,
    HealRedirectionTarget? healRedirection,
    double? nodeDivisor,
    Map<String, String>? bucketAccountLinks,
  }) {
    return SettingsState(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      paydayDate: paydayDate ?? this.paydayDate,
      smileTargetAmount: smileTargetAmount ?? this.smileTargetAmount,
      smileGoalName: smileGoalName ?? this.smileGoalName,
      healRedirection: healRedirection ?? this.healRedirection,
      nodeDivisor: nodeDivisor ?? this.nodeDivisor,
      bucketAccountLinks: bucketAccountLinks ?? this.bucketAccountLinks,
    );
  }

  @override
  List<Object?> get props => [
        currencySymbol,
        currencyCode,
        paydayDate,
        smileTargetAmount,
        smileGoalName,
        healRedirection,
        nodeDivisor,
        bucketAccountLinks,
      ];
}
