import 'package:flutter/material.dart';

/// StarRating Widget
/// - Supports half stars (e.g. 4.5)
/// - Safe clamping: rating is forced between 0..maxStars
/// - Optional count display
/// - Optional label text
/// - Accessibility friendly (Semantics)
class StarRating extends StatelessWidget {
  final double rating;
  final int count;

  /// Number of stars (default 5)
  final int maxStars;

  /// Star icon size
  final double size;

  /// Space between stars
  final double spacing;

  /// Active star color
  final Color color;

  /// Inactive star color
  final Color inactiveColor;

  /// Show numeric rating text (e.g. "4.3")
  final bool showValue;

  /// Show (count) beside stars
  final bool showCount;

  /// Count text style override
  final TextStyle? textStyle;

  /// Optional prefix label e.g. "التقييم"
  final String? label;

  /// Override how many decimals to show for rating value
  final int valueDecimals;

  const StarRating({
    super.key,
    required this.rating,
    required this.count,
    this.maxStars = 5,
    this.size = 20,
    this.spacing = 2,
    this.color = Colors.amber,
    this.inactiveColor = const Color(0xFFBDBDBD),
    this.showValue = false,
    this.showCount = true,
    this.textStyle,
    this.label,
    this.valueDecimals = 1,
  });

  @override
  Widget build(BuildContext context) {
    final double safeRating = _clampRating(rating, maxStars);
    final int safeCount = count < 0 ? 0 : count;

    final TextStyle effectiveStyle = textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ) ??
        const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600);

    return Semantics(
      label: _semanticLabel(safeRating, safeCount),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if ((label ?? '').trim().isNotEmpty) ...[
            Text(
              '${label!.trim()}: ',
              style: effectiveStyle,
            ),
          ],

          // Stars
          ..._buildStars(safeRating),

          if (showValue) ...[
            const SizedBox(width: 6),
            Text(
              safeRating.toStringAsFixed(valueDecimals),
              style: effectiveStyle,
            ),
          ],

          if (showCount) ...[
            const SizedBox(width: 6),
            Text(
              '($safeCount)',
              style: effectiveStyle,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStars(double safeRating) {
    final List<Widget> stars = [];

    // We render maxStars icons:
    // full star if rating >= i+1
    // half star if rating between i+0.25 and i+0.75 تقريباً
    // empty star otherwise
    for (int i = 0; i < maxStars; i++) {
      final double starIndex = i + 1.0;
      final Widget star;

      if (safeRating >= starIndex) {
        star = Icon(Icons.star, color: color, size: size);
      } else {
        final double diff = safeRating - i; // between 0..1
        if (diff >= 0.75) {
          star = Icon(Icons.star, color: color, size: size);
        } else if (diff >= 0.25) {
          star = Icon(Icons.star_half, color: color, size: size);
        } else {
          star = Icon(Icons.star_border, color: inactiveColor, size: size);
        }
      }

      stars.add(star);

      if (i != maxStars - 1 && spacing > 0) {
        stars.add(SizedBox(width: spacing));
      }
    }

    return stars;
  }

  double _clampRating(double value, int maxStars) {
    if (maxStars <= 0) return 0.0;
    if (value.isNaN || value.isInfinite) return 0.0;
    if (value < 0) return 0.0;
    if (value > maxStars.toDouble()) return maxStars.toDouble();
    return value;
  }

  String _semanticLabel(double r, int c) {
    // Simple Arabic label suitable for screen readers
    return 'التقييم $r من $maxStars، عدد التقييمات $c';
  }
}
