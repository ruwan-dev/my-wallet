import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/entities/account.dart';
import '../../../../core/utils/formatters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CreditCardTile
// A premium bank-card style widget for displaying an AccountEntity.
// ─────────────────────────────────────────────────────────────────────────────

class CreditCardTile extends StatelessWidget {
  final AccountEntity account;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  /// When non-null, shows a linked-bucket badge on the card.
  final String? linkedBucketName;

  const CreditCardTile({
    super.key,
    required this.account,
    this.onEdit,
    this.onTap,
    this.linkedBucketName,
  });

  // Derive a 2-stop gradient from the account's stored colour.
  List<Color> _gradientColors() {
    final base = Color(account.colorValue);
    final hsl = HSLColor.fromColor(base);
    final light = hsl
        .withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation - 0.05).clamp(0.0, 1.0))
        .toColor();
    final dark = hsl
        .withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.05).clamp(0.0, 1.0))
        .toColor();
    return [light, base, dark];
  }

  // Stable masked card number seeded by account id.
  String _maskedNumber() {
    final seed = account.id.codeUnits.fold(0, (a, b) => a + b);
    final rng = Random(seed);
    final last4 = (1000 + rng.nextInt(8999)).toString();
    return '••••  ••••  ••••  $last4';
  }

  @override
  Widget build(BuildContext context) {
    final gradients = _gradientColors();
    final isLiability = account.type == AccountType.liability;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: gradients,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(account.colorValue).withOpacity(0.45),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // ── Background shimmer pattern ──────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _CardPatternPainter(
                    color: Colors.white.withOpacity(0.07),
                    seed: account.id.hashCode,
                  ),
                ),
              ),
              // ── Glossy top sheen ────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Card content ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row: Account name + edit button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            account.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onEdit != null)
                          GestureDetector(
                            onTap: onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Account type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Text(
                        isLiability ? 'Credit / Liability' : 'Asset',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Chip + Network Logos ──────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // EMV Chip
                        _ChipWidget(),
                        const Spacer(),
                        // Network circles (Mastercard-style)
                        _NetworkCircles(color: Colors.white),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ── Masked card number ────────────────────────────────
                    Text(
                      _maskedNumber(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.0,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Balance row ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLiability ? 'AVAILABLE' : 'BALANCE',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLiability
                                  ? AppFormatters.formatCurrency(context,
                                      account.creditLimit - account.balance)
                                  : AppFormatters.formatCurrency(
                                      context, account.balance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isLiability)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'OUTSTANDING',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppFormatters.formatCurrency(
                                    context, account.balance),
                                style: TextStyle(
                                  color: Colors.red.shade200,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Linked-bucket badge ─────────────────────────────────────
              if (linkedBucketName != null)
                Positioned(
                  bottom: 12,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.15),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          color: Colors.white70,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          linkedBucketName!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMV Chip widget
// ─────────────────────────────────────────────────────────────────────────────

class _ChipWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8C96A), Color(0xFFD4A843)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(painter: _ChipLinePainter()),
    );
  }
}

class _ChipLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBF8E20).withOpacity(0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Horizontal lines
    for (final y in [size.height * 0.33, size.height * 0.67]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical center line
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    // Center contact rect
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.45,
      height: size.height * 0.45,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Network Circles (Mastercard-style overlapping rings)
// ─────────────────────────────────────────────────────────────────────────────

class _NetworkCircles extends StatelessWidget {
  final Color color;
  const _NetworkCircles({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 30,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.35),
                border:
                    Border.all(color: color.withOpacity(0.5), width: 1.2),
              ),
            ),
          ),
          Positioned(
            left: 18,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border:
                    Border.all(color: color.withOpacity(0.5), width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card background pattern painter
// ─────────────────────────────────────────────────────────────────────────────

class _CardPatternPainter extends CustomPainter {
  final Color color;
  final int seed;

  _CardPatternPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Two large decorative arcs in the bottom-right corner
    for (int i = 0; i < 4; i++) {
      final radius = 80.0 + i * 45.0;
      final rect = Rect.fromCircle(
        center: Offset(size.width + 10, size.height + 10),
        radius: radius,
      );
      canvas.drawArc(rect, pi, pi / 2, false, paint);
    }

    // Small dots scattered across the card
    final rng = Random(seed);
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        1.2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter old) =>
      old.seed != seed || old.color != color;
}
