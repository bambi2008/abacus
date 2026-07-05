import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/owl_mood.dart';
import '../providers/gamification_provider.dart';

/// The emotional/visual layer on top of the numeric, loss-averse streak
/// card — never repeats the streak number, only reflects mood. V1 art is a
/// single owl emoji (no illustration/sprite pipeline exists in this app
/// yet, and Unicode has no owl mood variants); each mood gets a distinct
/// idle motion so it reads as "alive," not a static emoji. See
/// docs/technical-architecture.md and the gamification-depth plan.
class CompanionOwlCard extends StatelessWidget {
  const CompanionOwlCard({super.key});

  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>();
    final mood = gamification.currentMood;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.6),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showDetailSheet(context, gamification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: _AnimatedMoodEmoji(key: ValueKey(mood), mood: mood),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your owl is ${mood.label.toLowerCase()}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(mood.actionableLine, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, GamificationProvider gamification) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gamification.evolutionStageName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Care score: ${gamification.careScore}'),
            const SizedBox(height: 16),
            Text(gamification.currentMood.actionableLine),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMoodEmoji extends StatelessWidget {
  final OwlMood mood;
  const _AnimatedMoodEmoji({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    final text = Text(mood.emoji, style: const TextStyle(fontSize: 40));
    switch (mood) {
      case OwlMood.sleeping:
        // Very slow, subtle breathing — dormant, not distressed.
        return text
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 2400.ms, curve: Curves.easeInOut);
      case OwlMood.hungry:
        // A small shiver loop — needs attention.
        return text
            .animate(onPlay: (c) => c.repeat())
            .shake(duration: 600.ms, hz: 4, rotation: 0.03);
      case OwlMood.content:
        // A gentle bob.
        return text
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -4, duration: 900.ms, curve: Curves.easeInOut);
      case OwlMood.happy:
        // A bit more energetic bob with a slight rotation.
        return text
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -6, duration: 700.ms, curve: Curves.easeInOut)
            .rotate(begin: -0.02, end: 0.02, duration: 700.ms);
      case OwlMood.thriving:
        // Bright bounce + sparkle — everything's going great.
        return text
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 500.ms, curve: Curves.easeInOut)
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.8));
    }
  }
}
