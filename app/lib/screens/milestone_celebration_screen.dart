import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/badge_record.dart';
import '../providers/gamification_provider.dart';
import '../services/analytics_service.dart';
import '../services/share_capture_service.dart';
import '../widgets/celebration_body.dart';

/// Full-screen milestone celebration — generalizes the onboarding Day-1
/// celebration (see onboarding_screen.dart's _FirstExpensePage) into a
/// reusable widget parameterized by milestone day, so Day 7/30/100/365 each
/// get real motion/confetti/haptic, not just a bigger static asset. See
/// docs/technical-architecture.md and the gamification-depth plan.
class MilestoneCelebrationScreen extends StatefulWidget {
  final BadgeRecord badge;

  const MilestoneCelebrationScreen({super.key, required this.badge});

  @override
  State<MilestoneCelebrationScreen> createState() =>
      _MilestoneCelebrationScreenState();
}

class _MilestoneCelebrationScreenState
    extends State<MilestoneCelebrationScreen> {
  final _shareCardKey = GlobalKey();
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    // Stronger haptic than the routine per-log tap — reserved for
    // milestones only, matching the "subtle for frequent, strong for
    // significant" calibration.
    HapticFeedback.heavyImpact();
    _confettiController.play();
    AnalyticsService.instance.capture(
      'milestone_celebration_shown',
      properties: {'milestone_day': widget.badge.milestoneDay},
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    AnalyticsService.instance.capture(
      'milestone_shared',
      properties: {'milestone_day': widget.badge.milestoneDay},
    );
    final ok = await ShareCaptureService.captureAndShare(
      key: _shareCardKey,
      filename: 'pocklume_milestone_${widget.badge.milestoneDay}',
      text: 'I hit a ${widget.badge.milestoneDay}-day streak on Pocklume 🔥',
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
    context.read<GamificationProvider>().markCelebrationShown(widget.badge.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final (emoji, headline, message) =
        MilestoneCatalog.data[widget.badge.milestoneDay]!;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          CelebrationBody(
            emoji: emoji,
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
