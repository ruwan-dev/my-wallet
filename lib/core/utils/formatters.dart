import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

/// Currency and date formatting utilities.
class AppFormatters {
  AppFormatters._();

  /// Format [amount] as currency using the global [SettingsCubit] symbol.
  static String formatCurrency(
    BuildContext context,
    double amount,
  ) {
    final state = context.watch<SettingsCubit>().state;
    return formatCurrencyWithSettings(amount, state);
  }

  /// Format [amount] as currency using an explicit [SettingsState].
  static String formatCurrencyWithSettings(double amount, SettingsState state) {
    final symbol = state.currencySymbol;

    if (amount.abs() >= 1000000) {
      final formatter = NumberFormat.compactCurrency(
        name: state.currencyCode,
        symbol: symbol,
        decimalDigits: 2,
      );
      return formatter.format(amount);
    }

    final formatter = NumberFormat.currency(
      name: state.currencyCode,
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format [amount] compactly, e.g. 1,200 → "1.2K".
  static String formatCompact(double amount) {
    final formatter = NumberFormat.compact();
    return formatter.format(amount);
  }

  /// Format a [DateTime] as "MMM d, yyyy" (e.g. "Jul 25, 2026").
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format a [DateTime] as "MMM d" (e.g. "Jul 25").
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  /// Format a [DateTime] as "MMMM yyyy" (e.g. "July 2026").
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Format a [DateTime] as "h:mm a" (e.g. "3:45 PM").
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Returns a relative label: "Today", "Yesterday", or the formatted date.
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final input = DateTime(date.year, date.month, date.day);
    final diff = today.difference(input).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return formatDate(date);
  }

  /// Convert a percentage [value] (0–100) to a display string.
  static String formatPercent(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}
