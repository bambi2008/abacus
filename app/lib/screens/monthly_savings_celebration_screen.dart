import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/monthly_savings_result.dart';
import '../providers/gamification_provider.dart';
import '../services/analytics_service.dart';
import '../services/share_capture_service.dart';
import '../widgets/celebration_body.dart';

/// Full-screen "you spent less than average" recap, shown once per calendar
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
  State<MonthlySavingsCelebrationScreen> createState() => _MonthlySavingsCelebrationScreenState();
}

class _MonthlySavingsCelebrationScreenState extends State<MonthlySavingsCelebrationScreen> {
  final _shareCardKey = GlobalKey();
  late final ConfettiController _confettiController;

  // The standard "starter emergency fund" figure widely cited by consumer
  // financial educators (e.g. CFPB) — a stable, round heuristic rather than
  // a live market price, so it doesn't need upkeep the way a specific
  // product price would.
  static const _starterEmergencyFund = 500;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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
    await ShareCaptureService.captureAndShare(
      key: _shareCardKey,
      filename: 'abacus_monthly_savings_${widget.result.id}',
      text: 'I spent \$${widget.result.totalSaved.toStringAsFixed(0)} less than the average American '
          'on discretionary spending this month, on Abacus 💰',
    );
  }

  void _continue(BuildContext context) {
    context.read<GamificationProvider>().markMonthlySavingsCelebrationShown(widget.result.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.result.totalSaved;
    final headline = 'You spent \$${saved.toStringAsFixed(0)} less than average this month!';
    final pctOfFund = saved / _starterEmergencyFund * 100;
    final message = pctOfFund >= 100
        ? 'That alone could cover a \$$_starterEmergencyFund starter emergency fund, with some left over.'
        : 'That\'s ${pctOfFund.round()}% of the way to a \$$_starterEmergencyFund starter emergency fund — '
            'vs. real 2024 U.S. averages for dining out, shopping, and entertainment (BLS).';

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
