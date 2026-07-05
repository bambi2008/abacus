import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/category_challenge_result.dart';
import '../providers/gamification_provider.dart';
import '../services/analytics_service.dart';
import '../services/share_capture_service.dart';
import '../widgets/celebration_body.dart';

/// "Boss defeated" celebration for a category that finished the month under
/// budget — reuses the exact same CelebrationBody/confetti/haptic machinery
/// as MilestoneCelebrationScreen, just with category-specific content. See
/// docs/technical-architecture.md's "boss battle" framing.
class CategoryChallengeWinScreen extends StatefulWidget {
  final CategoryChallengeResult result;
  final ExpenseCategory category;

  const CategoryChallengeWinScreen({super.key, required this.result, required this.category});

  @override
  State<CategoryChallengeWinScreen> createState() => _CategoryChallengeWinScreenState();
}

class _CategoryChallengeWinScreenState extends State<CategoryChallengeWinScreen> {
  final _shareCardKey = GlobalKey();
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    HapticFeedback.heavyImpact();
    _confettiController.play();
    AnalyticsService.instance
        .capture('category_challenge_celebration_shown', properties: {'category_id': widget.category.id});
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    AnalyticsService.instance.capture('category_challenge_shared', properties: {'category_id': widget.category.id});
    await ShareCaptureService.captureAndShare(
      key: _shareCardKey,
      filename: 'abacus_boss_${widget.result.id}',
      text: 'I stayed under budget in ${widget.category.name} on Abacus 🛡️',
    );
  }

  void _continue(BuildContext context) {
    context.read<GamificationProvider>().markCategoryCelebrationShown(widget.result.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _monthName(widget.result.month);
    final headline = '🛡️ Boss Defeated: ${widget.category.name}!';
    final message = 'You stayed under budget in ${widget.category.name} for $monthName.';

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          CelebrationBody(
            emoji: '🛡️',
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

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}
