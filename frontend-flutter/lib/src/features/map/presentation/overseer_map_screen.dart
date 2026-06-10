import 'package:flutter/material.dart';

class OverseerMapScreen extends StatelessWidget {
  const OverseerMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overseer Map')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                const Positioned.fill(child: _MapCanvas()),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _MapSummary(isCompact: constraints.maxWidth < 560),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPlaceholderPainter(),
      child: Stack(
        children: const [
          _MapMarker(
            alignment: Alignment(-0.55, -0.42),
            color: Color(0xFFE11D48),
            label: '12',
          ),
          _MapMarker(
            alignment: Alignment(0.22, -0.18),
            color: Color(0xFFF59E0B),
            label: '7',
          ),
          _MapMarker(
            alignment: Alignment(0.48, 0.34),
            color: Color(0xFF0F766E),
            label: '4',
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFEAF0ED);
    canvas.drawRect(Offset.zero & size, background);

    final parkPaint = Paint()..color = const Color(0xFFCDE7D8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.26, size.height * 0.34),
        width: size.width * 0.34,
        height: size.height * 0.24,
      ),
      parkPaint,
    );

    final riverPaint = Paint()
      ..color = const Color(0xFFB6D8EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;
    final river = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.54,
        size.width * 0.62,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.80,
        size.width * 0.98,
        size.height * 0.58,
      );
    canvas.drawPath(river, riverPaint);

    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    for (final y in [0.18, 0.44, 0.62]) {
      canvas.drawLine(
        Offset(size.width * 0.04, size.height * y),
        Offset(size.width * 0.96, size.height * (y + 0.06)),
        roadPaint,
      );
    }

    for (final x in [0.18, 0.42, 0.72]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * 0.06),
        Offset(size.width * (x + 0.08), size.height * 0.92),
        roadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.alignment,
    required this.color,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(blurRadius: 10, color: Color(0x33000000)),
          ],
        ),
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapSummary extends StatelessWidget {
  const _MapSummary({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _MapMetric(label: 'Open', value: '23'),
      const _MapMetric(label: 'Assigned', value: '11'),
      const _MapMetric(label: 'Resolved', value: '8'),
    ];

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              )
            : Row(
                children: items
                    .map((item) => Expanded(child: item))
                    .toList(growable: false),
              ),
      ),
    );
  }
}

class _MapMetric extends StatelessWidget {
  const _MapMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
