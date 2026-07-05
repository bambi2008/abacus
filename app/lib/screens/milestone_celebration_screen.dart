import 'dart:io';
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/constants.dart';
import '../models/badge_record.dart';
import '../providers/gamification_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/shareable_achievement_card.dart';

/// Full-screen milestone celebration — generalizes the onboarding Day-1
/// celebration (see onboarding_screen.dart's _FirstExpensePage) into a
/// reusable widget parameterized by milestone day, so Day 7/30/100/365 each
/// get real motion/confetti/haptic, not just a bigger static asset. See
/// docs/technical-architecture.md and the gamification-depth plan.
class MilestoneCelebrationScreen extends StatefulWidget {
  final BadgeRecord badge;

  const MilestoneCelebrationScreen({super.key, required this.badge});

  @override
  State<MilestoneCelebrationScreen> createState() => _MilestoneCelebrationScreenState();
}

class _MilestoneCelebrationScreenState extends State<MilestoneCelebrationScreen> {
  final _shareCardKey = GlobalKey();
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    // Stronger haptic than the routine per-log tap — reserved for
    // milestones only, matching the "subtle for frequent, strong for
    // significant" calibration.
    HapticFeedback.heavyImpact();
    _confettiController.play();
    AnalyticsService.instance
        .capture('milestone_celebration_shown', properties: {'milestone_day': widget.badge.milestoneDay});
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _share(BuildContext context) async {
    AnalyticsService.instance.capture('milestone_shared', properties: {'milestone_day': widget.badge.milestoneDay});
    final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/abacus_milestone_${widget.badge.milestoneDay}.png');
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'I hit a ${widget.badge.milestoneDay}-day streak on Abacus 🔥',
    );
  }

  void _continue(BuildContext context) {
    context.read<GamificationProvider>().markCelebrationShown(widget.badge.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final (emoji, headline, message) = MilestoneCatalog.data[widget.badge.milestoneDay]!;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 96))
                      .animate()
                      .scale(begin: const Offset(0.4, 0.4), duration: 500.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 300.ms)
                      .then()
                      .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(height: 24),
                  Text(headline, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center)
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 400.ms),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 220,
                    child: RepaintBoundary(
                      key: _shareCardKey,
                      child: ShareableAchievementCard(
                        emoji: emoji,
                        title: headline,
                        subtitle: message,
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => _share(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => _continue(context), child: const Text('Continue')),
                ],
              ),
            ),
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
