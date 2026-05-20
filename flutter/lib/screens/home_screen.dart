import 'package:flutter/material.dart';
import '../game_state.dart';
import '../storage_service.dart';
import '../utils/fade_page_route.dart';
import 'game_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GameState gameState = GameState();
  final _storage = StorageService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.2, end: 0.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadFromStorage();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadFromStorage() async {
    await _storage.load(gameState);
    if (mounted) setState(() {});
  }

  void _goToGame() async {
    final result = await Navigator.push<int>(
      context,
      FadePageRoute(page: GameScreen(gameState: gameState)),
    );
    if (result != null) setState(() {});
  }

  void _goToStats() {
    Navigator.push(
      context,
      FadePageRoute(page: StatsScreen(gameState: gameState)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                const Column(
                  children: [
                    Text(
                      'IMPOSSITAP',
                      style: TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 52,
                        letterSpacing: 6,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'YOU CAN\'T. BUT TRY ANYWAY.',
                      style: TextStyle(
                        fontFamily: 'DMMono',
                        fontSize: 10,
                        color: Color(0xFF383838),
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Target display
                Column(
                  children: [
                    const Text(
                      'HEUTIGES ZIEL',
                      style: TextStyle(
                        fontFamily: 'DMMono',
                        fontSize: 10,
                        color: Color(0xFF383838),
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      GameState.formatUs(GameState.targetUs),
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 46,
                        color: Color(0xFFC8F55A),
                        letterSpacing: 1,
                        height: 1,
                        shadows: [
                          Shadow(color: Color(0x47C8F55A), blurRadius: 20),
                          Shadow(color: Color(0x1AC8F55A), blurRadius: 50),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'MIKROSEKUNDEN',
                      style: TextStyle(
                        fontFamily: 'DMMono',
                        fontSize: 11,
                        color: Color(0xFF383838),
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatBox(label: 'BESTER (NS)', value: gameState.formattedBest),
                    const SizedBox(width: 16),
                    _StatBox(label: 'VERSUCHE', value: gameState.tries.toString()),
                  ],
                ),
                const SizedBox(height: 48),

                // Play button
                GestureDetector(
                  onTap: _goToGame,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TIPPE',
                          style: TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 28,
                            color: Color(0xFF0A0A0A),
                            letterSpacing: 4,
                          ),
                        ),
                        Text(
                          'ZWEIMAL',
                          style: TextStyle(
                            fontFamily: 'DMMono',
                            fontSize: 9,
                            color: Color(0x80000000),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    builder: (context, child) {
                      return SizedBox(
                        width: 180,
                        height: 180,
                        child: OverflowBox(
                          maxWidth: 340,
                          maxHeight: 340,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Äußere diffuse Aura
                              const Container(
                                width: 340,
                                height: 340,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [Color(0x0AC8F55A), Colors.transparent],
                                  ),
                                ),
                              ),
                              // Innere engere Aura
                              const Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [Color(0x06C8F55A), Colors.transparent],
                                  ),
                                ),
                              ),
                              // Play-Button
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFC8F55A),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFC8F55A).withOpacity(0.12),
                                      blurRadius: 0,
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFC8F55A)
                                          .withOpacity(_pulseAnim.value * 0.55),
                                      blurRadius: 25,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFC8F55A)
                                          .withOpacity(_pulseAnim.value * 0.25),
                                      blurRadius: 60,
                                    ),
                                  ],
                                ),
                                child: child,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Nav tabs
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavTab(label: 'SPIEL', active: true, onTap: () {}),
                  const SizedBox(width: 32),
                  _NavTab(label: 'STATS', active: false, onTap: _goToStats),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x04C8F55A),
        border: Border.all(color: const Color(0x0FC8F55A)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DMMono',
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Color(0x2EC8F55A), blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 4),
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

class _NavTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFFC8F55A) : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DMMono',
            fontSize: 10,
            letterSpacing: 2,
            color: active ? const Color(0xFFC8F55A) : const Color(0xFF555555),
            shadows: active
                ? [const Shadow(color: Color(0x33C8F55A), blurRadius: 6)]
                : null,
          ),
        ),
      ),
    );
  }
}
