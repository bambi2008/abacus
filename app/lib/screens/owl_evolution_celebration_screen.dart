import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../providers/gamification_provider.dart';
import '../services/analytics_service.dart';
import '../services/share_capture_service.dart';
import '../widgets/celebration_body.dart';

/// Full-screen "your owl evolved" celebration — reuses the exact same
/// CelebrationBody/confetti/haptic machinery as the streak-milestone and
/// category-win screens. Added 2026-07-06: evolution stage transitions were
/// already detected (for the `owl_evolved` analytics event) but had zero
/// user-facing payoff, just a silent text-label swap — this is the
/// deliberate "moment" that was missing.
class OwlEvolutionCelebrationScreen extends StatefulWidget {
  final int newStage;

  const OwlEvolutionCelebrationScreen({super.key, required this.newStage});

  @override
  State<OwlEvolutionCelebrationScreen> createState() =>
      _OwlEvolutionCelebrationScreenState();
}

class _OwlEvolutionCelebrationScreenState
    extends State<OwlEvolutionCelebrationScreen> {
  final _shareCardKey = GlobalKey();
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    HapticFeedback.heavyImpact();
    _confettiController.play();
    AnalyticsService.instance.capture(
      'owl_evolution_celebration_shown',
      properties: {'new_stage': widget.newStage},
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    AnalyticsService.instance.capture(
      'owl_evolution_shared',
      properties: {'new_stage': widget.newStage},
    );
    final ok = await ShareCaptureService.captureAndShare(
      key: _shareCardKey,
      filename: 'pocklume_owl_evolution_${widget.newStage}',
      text:
          'My Pocklume owl evolved into a ${EvolutionStages.names[widget.newStage]}! 🦉',
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the share sheet — try again.'),
        ),
      );
    }
  }

  void _continue(BuildContext context) {
    context.read<GamificationProvider>().markOwlEvolutionCelebrationShown();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final stageName = EvolutionStages.names[widget.newStage];
    final headline = 'Your owl evolved into a $stageName!';
    final message =
        EvolutionCelebrationCatalog.messages[widget.newStage] ?? 'Keep it up.';

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          CelebrationBody(
            emoji: '🦉',
            headline: headline,
            message: message,
            shareCardKey: _shareCardKey,
            onShare: _share,
            onContinue: () => _continue(context),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
          ),
        ],
      ),
    );
  }
}
