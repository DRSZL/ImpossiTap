import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game_state.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;
  const GameScreen({super.key, required this.gameState});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  bool _waiting = true; // waiting for first tap
  bool _running = false;
  int _elapsedUs = 0;
  DateTime? _startTime;
  late AnimationController _timerController;
  final List<_RippleEffect> _ripples = [];

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _onTap(TapDownDetails details) {
    HapticFeedback.lightImpact();

    // Add ripple
    setState(() {
      _ripples.add(_RippleEffect(position: details.localPosition));
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _ripples.removeAt(0));
    });

    if (_waiting) {
      // First tap – start timer
      _startTime = DateTime.now();
      _running = true;
      _waiting = false;
      _tick();
      setState(() {});
    } else if (_running) {
      // Second tap – stop
      final now = DateTime.now();
      final ns = now.difference(_startTime!).inMicroseconds;
      _running = false;
      final dev = ns - GameState.targetUs;
      widget.gameState.recordAttempt(dev);

      setState(() => _elapsedUs = ns);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                elapsedUs: ns,
                devUs: dev,
                gameState: widget.gameState,
              ),
            ),
          );
        }
      });
    }
  }

  void _tick() {
    if (!_running || !mounted) return;
    setState(() {
      _elapsedUs =
          DateTime.now().difference(_startTime!).inMicroseconds;
    });
    Future.delayed(const Duration(milliseconds: 16), _tick);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTap,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Stack(
            children: [
              // Ripples
              ..._ripples.map((r) => _RippleWidget(effect: r)),

              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _waiting ? 'TIPPE ZUM STARTEN' : 'JETZT NOCHMAL!',
                      style: const TextStyle(
                        fontFamily: 'DMMono',
                        fontSize: 11,
                        color: Color(0xFF555555),
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      GameState.formatUs(_elapsedUs),
                      style: TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 52,
                        color: _running
                            ? const Color(0xFFC8F55A)
                            : Colors.white,
                        letterSpacing: 1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'MIKROSEKUNDEN',
                      style: TextStyle(
                        fontFamily: 'DMMono',
                        fontSize: 10,
                        color: Color(0xFF555555),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'ZIEL: 1.337.000 μs μS',
                      style: TextStyle(
                        fontFamily: 'DMMono',
                        fontSize: 10,
                        color: Color(0xFF444444),
                        letterSpacing: 2,
                      ),
                    ),
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

class _RippleEffect {
  final Offset position;
  _RippleEffect({required this.position});
}

class _RippleWidget extends StatefulWidget {
  final _RippleEffect effect;
  const _RippleWidget({required this.effect});

  @override
  State<_RippleWidget> createState() => _RippleWidgetState();
}

class _RippleWidgetState extends State<_RippleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _scale = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.effect.position.dx - 40,
      top: widget.effect.position.dy - 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC8F55A),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
