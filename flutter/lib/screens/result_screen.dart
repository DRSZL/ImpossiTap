import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game_state.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final int elapsedUs;
  final int devUs;
  final GameState gameState;

  const ResultScreen({
    super.key,
    required this.elapsedUs,
    required this.devUs,
    required this.gameState,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _barAnim = CurvedAnimation(
      parent: _barController,
      curve: const ElasticOut(period: 0.5),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      _barController.forward();
    });
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  Color _gradeColor() {
    final absMs = widget.devUs.abs() / 1000;
    if (absMs <= 20) return const Color(0xFFC8F55A);
    if (absMs <= 80) return const Color(0xFF5AF5C8);
    if (absMs <= 200) return const Color(0xFFF5C85A);
    return const Color(0xFFF55A5A);
  }

  double _indicatorPosition() {
    final pct = 0.5 + widget.devUs / (GameState.targetUs * 0.4);
    return pct.clamp(0.04, 0.96);
  }

  @override
  Widget build(BuildContext context) {
    final grade = widget.gameState.gradeLabel(widget.devUs);
    final emoji = widget.gameState.gradeEmoji(widget.devUs);
    final rankPct = widget.gameState.rankPercent(widget.devUs);
    final devMs = (widget.devUs / 1000).round();
    final sign = devMs >= 0 ? '+' : '';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              const Text(
                'ERGEBNIS',
                style: TextStyle(
                  fontFamily: 'DMMono',
                  fontSize: 10,
                  color: Color(0xFF555555),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),

              // Grade
              Text(
                grade,
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 60,
                  color: _gradeColor(),
                  letterSpacing: 4,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 24),

              // Comparison boxes
              Row(
                children: [
                  Expanded(
                    child: _CompareBox(
                      label: 'DEINE ZEIT',
                      value: GameState.formatUs(widget.elapsedUs),
                      unit: 'μs',
                      highlight: true,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'vs',
                      style: TextStyle(
                        fontFamily: 'DMMono',
                        fontSize: 11,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _CompareBox(
                      label: 'ZIEL',
                      value: GameState.formatUs(GameState.targetUs),
                      unit: 'μs',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Deviation bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ZU FRÜH',
                          style: TextStyle(
                              fontFamily: 'DMMono',
                              fontSize: 8,
                              color: Color(0xFF555555))),
                      Text(
                        '$sign${_formatDevNs(widget.devUs)} NS',
                        style: const TextStyle(
                            fontFamily: 'DMMono',
                            fontSize: 8,
                            color: Color(0xFF555555)),
                      ),
                      const Text('ZU SPÄT',
                          style: TextStyle(
                              fontFamily: 'DMMono',
                              fontSize: 8,
                              color: Color(0xFF555555))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 4,
                    child: Stack(
                      children: [
                        Container(color: const Color(0xFF222222)),
                        // Center mark
                        Positioned(
                          left: MediaQuery.of(context).size.width / 2 - 24 - 1,
                          child: Container(
                            width: 2,
                            height: 4,
                            color: const Color(0xFF555555),
                          ),
                        ),
                        // Indicator
                        AnimatedBuilder(
                          animation: _barAnim,
                          builder: (_, __) {
                            final pos = _indicatorPosition();
                            return Positioned(
                              left: (MediaQuery.of(context).size.width - 48) *
                                      pos -
                                  10,
                              top: -8,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFC8F55A),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Rank
              Text(
                'Besser als $rankPct% der Welt heute',
                style: const TextStyle(
                  fontFamily: 'DMMono',
                  fontSize: 11,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GameScreen(gameState: widget.gameState),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        color: const Color(0xFFC8F55A),
                        alignment: Alignment.center,
                        child: const Text(
                          'NOCHMAL',
                          style: TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 20,
                            color: Colors.black,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF222222)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'HOME',
                          style: TextStyle(
                            fontFamily: 'DMMono',
                            fontSize: 10,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDevNs(int ns) {
    final str = ns.abs().toString();
    final buffer = StringBuffer();
    final offset = str.length % 3;
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (i - offset) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _CompareBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool highlight;

  const _CompareBox({
    required this.label,
    required this.value,
    required this.unit,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMMono',
              fontSize: 8,
              color: Color(0xFF555555),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 18,
              color: highlight ? const Color(0xFFC8F55A) : Colors.white,
              letterSpacing: 1,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontFamily: 'DMMono',
              fontSize: 8,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}
