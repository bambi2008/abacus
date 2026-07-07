import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/owl_mood.dart';
import '../providers/gamification_provider.dart';

/// The emotional/visual layer on top of the numeric, loss-averse streak
/// card — never repeats the streak number, only reflects mood. V1 art is a
/// single owl emoji (no illustration/sprite pipeline exists in this app
/// yet, and Unicode has no owl mood variants); each mood gets a distinct
/// idle motion so it reads as "alive," not a static emoji. Evolution stage
/// is layered on top visually (size + aura + crown at the top stage) so
/// "leveling up" is something you can actually see, not just a text label
/// swap — see docs/technical-architecture.md and the gamification-depth
/// plan.
class CompanionOwlCard extends StatelessWidget {
  const CompanionOwlCard({super.key});

  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>();
    final mood = gamification.currentMood;
    final stage = gamification.evolutionStage;

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
                child: _StagedOwl(key: ValueKey('$mood-$stage'), mood: mood, stage: stage),
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
    final stage = gamification.evolutionStage;
    final careScore = gamification.careScore;
    final isMaxStage = stage >= EvolutionStages.names.length - 1;
    final currentThreshold = EvolutionStages.thresholds[stage];
    final nextThreshold = isMaxStage ? null : EvolutionStages.thresholds[stage + 1];
    final progress =
        isMaxStage ? 1.0 : ((careScore - currentThreshold) / (nextThreshold! - currentThreshold)).clamp(0.0, 1.0);

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gamification.evolutionStageName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 4),
            Text(
              isMaxStage
                  ? 'Care score: $careScore — max stage reached'
                  : 'Care score: $careScore ($nextThreshold to ${EvolutionStages.names[stage + 1]})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(gamification.currentMood.actionableLine),
          ],
        ),
      ),
    );
  }
}

/// Composes the mood emoji with stage-driven visual growth: a bigger owl
/// and a brighter aura at higher stages, plus a crown at the top stage —
/// all built from existing widgets/emoji, no new art assets needed.
class _StagedOwl extends StatelessWidget {
  final OwlMood mood;
  final int stage;
  const _StagedOwl({super.key, required this.mood, required this.stage});

  @override
  Widget build(BuildContext context) {
    final size = 32.0 + stage * 6;
    final auraAlpha = 0.05 + stage * 0.05;
    return SizedBox(
      width: size + 20,
      height: size + 20,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size + 14,
            height: size + 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: auraAlpha),
            ),
          ),
          _AnimatedMoodEmoji(mood: mood, size: size),
          if (stage >= EvolutionStages.names.length - 1)
            const Positioned(top: -6, right: -6, child: Text('👑', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }
}

class _AnimatedMoodEmoji extends StatelessWidget {
  final OwlMood mood;
  final double size;
  const _AnimatedMoodEmoji({required this.mood, required this.size});

  @override
  Widget build(BuildContext context) {
    final text = Text(mood.emoji, style: TextStyle(fontSize: size));
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
