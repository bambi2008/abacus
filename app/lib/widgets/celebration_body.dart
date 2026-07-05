import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'shareable_achievement_card.dart';

/// Shared visual layout for every full-screen celebration (streak
/// milestones, category "boss battle" wins) — extracted so both screens
/// get identical motion/animation without duplicating it. Each caller owns
/// its own ConfettiController/GlobalKey/share logic (those need per-
/// instance state), this widget only renders the content column.
class CelebrationBody extends StatelessWidget {
  final String emoji;
  final String headline;
  final String message;
  final GlobalKey shareCardKey;
  final VoidCallback onShare;
  final VoidCallback onContinue;

  const CelebrationBody({
    super.key,
    required this.emoji,
    required this.headline,
    required this.message,
    required this.shareCardKey,
    required this.onShare,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            Text(message, textAlign: TextAlign.center).animate().fadeIn(delay: 350.ms, duration: 400.ms),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              child: RepaintBoundary(
                key: shareCardKey,
                child: ShareableAchievementCard(emoji: emoji, title: headline, subtitle: message),
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            const SizedBox(height: 32),
            FilledButton.icon(onPressed: onShare, icon: const Icon(Icons.share), label: const Text('Share')),
            const SizedBox(height: 12),
            TextButton(onPressed: onContinue, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}
