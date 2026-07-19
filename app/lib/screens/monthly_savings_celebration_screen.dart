import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/monthly_savings_result.dart';
import '../providers/gamification_provider.dart';
import '../services/analytics_service.dart';
import '../services/share_capture_service.dart';
import '../widgets/celebration_body.dart';

/// Full-screen selected-benchmark recap, shown once per calendar
/// month at the same month-boundary evaluation point as the category boss
/// battles. Reuses the same CelebrationBody/confetti/haptic machinery as
/// every other celebration in the app. See
/// GamificationProvider.computeMonthlySavings and
/// docs/technical-architecture.md for why this only compares categories
/// with a real, single, government-sourced benchmark (Dining Out + Snacks &
/// Drinks, Clothing & Shopping, Fun & Entertainment) rather than every
/// category.
class MonthlySavingsCelebrationScreen extends StatefulWidget {
  final MonthlySavingsResult result;

  const MonthlySavingsCelebrationScreen({super.key, required this.result});

  @override
  State<MonthlySavingsCelebrationScreen> createState() =>
      _MonthlySavingsCelebrationScreenState();
}

class _MonthlySavingsCelebrationScreenState
    extends State<MonthlySavingsCelebrationScreen> {
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
    AnalyticsService.instance.capture('monthly_savings_celebration_shown');
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    AnalyticsService.instance.capture('monthly_savings_shared');
    final ok = await ShareCaptureService.captureAndShare(
      key: _shareCardKey,
      filename: 'pocklume_monthly_savings_${widget.result.id}',
      text:
          'My tracked discretionary spending was '
          '\$${widget.result.totalSaved.toStringAsFixed(0)} below selected U.S. category benchmarks '
          'this month, on Pocklume.',
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
    context.read<GamificationProvider>().markMonthlySavingsCelebrationShown(
      widget.result.id,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.result.totalSaved;
    final headline = '\$${saved.toStringAsFixed(0)} below selected benchmarks';
    const message =
        'This comparison covers only the categories you chose to track. '
        'It is not a measure of total savings. Benchmarks use 2024 U.S. BLS averages '
        'for dining out, clothing, and entertainment.';

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          CelebrationBody(
            emoji: '💰',
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
