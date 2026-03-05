import 'package:flutter/material.dart';
import '../game_state.dart';

class StatsScreen extends StatelessWidget {
  final GameState gameState;
  const StatsScreen({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  '← ZURÜCK',
                  style: TextStyle(
                    fontFamily: 'DMMono',
                    fontSize: 10,
                    color: Color(0xFF555555),
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'DEINE STATS',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 40,
                  letterSpacing: 4,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 28),

              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatsCard(
                    value: gameState.bestDeviation != null
                        ? GameState.formatUs(gameState.bestUs)
                        : '—',
                    label: 'BESTER HEUTE',
                  ),
                  _StatsCard(
                    value: gameState.tries.toString(),
                    label: 'VERSUCHE HEUTE',
                  ),
                  const _StatsCard(value: '#4.821', label: 'WELTRANG'),
                  const _StatsCard(value: '7', label: 'TAGE STREAK 🔥'),
                ],
              ),
              const SizedBox(height: 28),

              // Chart placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ABWEICHUNG – LETZTE VERSUCHE (MS)',
                      style: TextStyle(
                        fontFamily: 'DMMono',
                        fontSize: 9,
                        color: Color(0xFF555555),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    gameState.tries > 0
                        ? const Text(
                            'Chart nach mehr Versuchen verfügbar',
                            style: TextStyle(
                              fontFamily: 'DMMono',
                              fontSize: 10,
                              color: Color(0xFF444444),
                            ),
                          )
                        : const _MockChart(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatsCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 24,
              color: Color(0xFFC8F55A),
              letterSpacing: 1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMMono',
              fontSize: 8,
              color: Color(0xFF555555),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockChart extends StatelessWidget {
  const _MockChart();

  @override
  Widget build(BuildContext context) {
    final data = [113.0, 57.0, 43.0, 28.0, 15.0, 7.0, 3.0, 2.0];
    final maxVal = data.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((val) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: (val / maxVal) * 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8F55A).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
