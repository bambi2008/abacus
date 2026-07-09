import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/receipt_scan_result.dart';
import '../models/voice_expense_result.dart';
import '../providers/buddy_provider.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/analytics_service.dart';
import '../services/receipt_ocr_service.dart';
import '../services/voice_input_service.dart';
import '../widgets/buddy_streak_card.dart';
import '../widgets/companion_owl_card.dart';
import 'category_challenge_win_screen.dart';
import 'milestone_celebration_screen.dart';
import 'monthly_savings_celebration_screen.dart';
import 'owl_evolution_celebration_screen.dart';
import 'paywall_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  @override
  void initState() {
    super.initState();
    // Check for any celebration earned while the app was closed (or just
    // now, via the log sheet) that hasn't been shown yet — done here rather
    // than at the moment of earning so a cold-boot catch-up (see main.dart)
    // doesn't celebrate before the user has even opened a normal screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPendingCelebrationsIfAny());
  }

  void _showPendingCelebrationsIfAny() {
    if (!mounted) return;
    final gamification = context.read<GamificationProvider>();
    final pendingBadge = gamification.pendingCelebration;
    if (pendingBadge != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MilestoneCelebrationScreen(badge: pendingBadge)));
      return;
    }
    final pendingResult = gamification.pendingCategoryCelebration;
    if (pendingResult != null) {
      final category = context.read<CategoryProvider>().byId(pendingResult.categoryId);
      if (category != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryChallengeWinScreen(result: pendingResult, category: category),
          ),
        );
        return;
      }
    }
    if (gamification.pendingOwlEvolutionCelebration) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OwlEvolutionCelebrationScreen(newStage: gamification.evolutionStage)),
      );
      return;
    }
    final pendingSavings = gamification.pendingMonthlySavingsCelebration;
    if (pendingSavings != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MonthlySavingsCelebrationScreen(result: pendingSavings)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final categories = context.watch<CategoryProvider>();
    final gamification = context.watch<GamificationProvider>();
    final streak = expenses.currentStreak;
    final loggedToday = expenses.loggedToday;
    final isEvening = DateTime.now().hour >= 18;
    final atRisk = !loggedToday && isEvening && streak > 0;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          // Pro users are unlimited and never decrement the free-tier
          // counter (see ExpenseProvider.checkAndApplyStreakFreeze), so
          // this can't just gate on the counter being > 0 — a Pro user who
          // used their one free freeze before upgrading would otherwise
          // never see this icon again despite now having real unlimited
          // freezes.
          if (expenses.freeStreakFreezesAvailable > 0 || context.watch<SubscriptionProvider>().isPro)
            IconButton(
              tooltip: context.watch<SubscriptionProvider>().isPro
                  ? 'Unlimited streak freezes (Pro)'
                  : '${expenses.freeStreakFreezesAvailable} streak freeze available',
              icon: const Icon(Icons.shield_outlined),
              onPressed: () => _showStreakFreezeInfo(context),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StreakCard(streak: streak, atRisk: atRisk),
            const SizedBox(height: 12),
            const CompanionOwlCard(),
            const SizedBox(height: 12),
            const BuddyStreakCard(),
            if (!loggedToday) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: gamification.isNoSpendDay(now)
                      ? null
                      : () => context.read<GamificationProvider>().markNoSpendDay(now),
                  icon: const Icon(Icons.savings_outlined, size: 18),
                  label: Text(gamification.isNoSpendDay(now) ? 'Marked as no-spend today' : 'Mark today as no-spend'),
                ),
              ),
            ] else ...[
              // Optional bonus layer, not a requirement — the streak itself
              // only ever needs one log/day. This just lets a more engaged
              // user flag "that's everything I spent today" for extra owl
              // care score, without a fixed log-count quota that would be
              // arbitrary on days with genuinely few transactions.
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: gamification.isCompleteLogDay(now)
                      ? null
                      : () => context.read<GamificationProvider>().markCompleteLogDay(now),
                  icon: const Icon(Icons.playlist_add_check, size: 18),
                  label: Text(
                    gamification.isCompleteLogDay(now)
                        ? 'Marked as fully logged today'
                        : 'That\'s everything I spent today',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Today\'s spending', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('\$${expenses.todaySpend.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ...categories.all.map((c) => _CategoryBar(
                  category: c,
                  spentThisMonth: expenses.spendForCategoryInMonth(c.id, now),
                )),
            const SizedBox(height: 96),
          ],
        ),
      ),
      // The single most important button in the app — logging an expense is
      // the entire core loop, so it gets full-saturation primary color and
      // bold/larger text rather than Material 3's default muted
      // primaryContainer FAB styling, which read as too quiet for something
      // this important. No idle animation on it though: unlike a one-time
      // celebration, this is tapped many times a day, and a constantly
      // moving element that frequently would get tiring rather than
      // eye-catching — prominence comes from color/size, not motion.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogExpenseSheet(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 6,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Log an expense',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showLogExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _LogExpenseSheet(),
    ).then((_) => _showPendingCelebrationsIfAny());
  }

  // The shield icon used to be an inert Tooltip — it looked like every
  // other tappable AppBar icon in the app but a tap (as opposed to a
  // long-press, which is how Tooltip actually surfaces its message) did
  // nothing. Now it opens the same info a tap on any other icon here would.
  void _showStreakFreezeInfo(BuildContext context) {
    final freezes = context.read<ExpenseProvider>().freeStreakFreezesAvailable;
    final isPro = context.read<SubscriptionProvider>().isPro;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 28),
                const SizedBox(width: 12),
                Text('Streak freeze', style: Theme.of(sheetContext).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isPro
                  ? 'Unlimited — Pro never runs out of streak freezes.'
                  : 'You have $freezes free streak freeze${freezes == 1 ? '' : 's'} available.',
            ),
            const SizedBox(height: 8),
            const Text(
              'If you miss a day with an active streak, a freeze is applied automatically the '
              'next time you open the app — your streak stays alive instead of resetting to zero.',
            ),
            if (!isPro) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
                },
                child: const Text('Get unlimited freezes with Pro'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  final bool atRisk;
  const _StreakCard({required this.streak, required this.atRisk});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: atRisk ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // AnimatedSwitcher plays an elastic "pop" whenever the streak
            // value changes (increment or the 🔥/🔒 swap at zero); the
            // wrapped flutter_animate chain gives it a continuous idle
            // "breathing" pulse the rest of the time, so the card feels
            // alive even between logs, not just at the moment of change.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                child: child,
              ),
              child: Text(
                streak > 0 ? '🔥' : '🔒',
                key: ValueKey(streak),
                style: const TextStyle(fontSize: 40),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.08, 1.08),
                    duration: 1800.ms,
                    curve: Curves.easeInOut,
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak-day streak',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  // Loss-aversion framing when a streak is actually at risk —
                  // never generic "don't forget" copy. See
                  // docs/technical-architecture.md.
                  Text(
                    atRisk
                        ? 'You\'re about to lose your $streak-day streak — log something now.'
                        : streak == 0
                            ? 'Log an expense to start a streak.'
                            : 'Keep it going — log at least one expense today.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final ExpenseCategory category;
  final double spentThisMonth;
  const _CategoryBar({required this.category, required this.spentThisMonth});

  @override
  Widget build(BuildContext context) {
    final hasBossBattle = category.monthlyLimit > 0;
    // This is YOUR shield against this month's boss for the category —
    // every dollar spent is the boss's attack chipping it away. An empty
    // shield (spend >= limit) means the boss broke through: you lose.
    // Surviving to month-end with any shield left means you defeated the
    // boss (see GamificationProvider.evaluateMonthBoundaryIfNeeded /
    // CategoryChallengeWinScreen). "Defeated" now only ever means "you
    // won" — an earlier version used it for both outcomes depending on
    // when you read it, which was genuinely backwards from how every
    // combat game uses the word.
    final shieldHealth = hasBossBattle ? (1 - (spentThisMonth / category.monthlyLimit)).clamp(0.0, 1.0) : 0.0;
    final shieldBroken = hasBossBattle && spentThisMonth > category.monthlyLimit;
    final shieldColor = shieldHealth > 0.5
        ? Colors.green
        : shieldHealth > 0.2
            ? Colors.orange
            : Colors.red;
    final bossEmoji = shieldHealth > 0.5
        ? '😈'
        : shieldHealth > 0.2
            ? '👹'
            : '🔥';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${category.emoji} ${category.name}'),
              const Spacer(),
              // Monthly, not daily — a "$6.67/day" pace never matched how
              // discretionary spending actually happens (in occasional
              // lumps, not a smooth daily drip), and it was silently
              // derived from the same $200 flat default every category
              // starts with, making the number look arbitrary. The boss
              // battle bar below already gives the monthly picture, so
              // this is just the raw total, not a second progress metric.
              Text('\$${spentThisMonth.toStringAsFixed(0)} this month'),
            ],
          ),
          if (hasBossBattle) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(shieldBroken ? '💥' : bossEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    // The dollar limit is spelled out here, not just the
                    // percentage — a real-device tester couldn't tell what
                    // number the bar's 100% actually represented.
                    shieldBroken
                        ? 'The ${category.name} boss broke your \$${category.monthlyLimit.toStringAsFixed(0)} shield — you\'re over budget this month'
                        : '🛡️ ${(shieldHealth * 100).round()}% shield left (\$${(category.monthlyLimit - spentThisMonth).clamp(0, category.monthlyLimit).toStringAsFixed(0)} of \$${category.monthlyLimit.toStringAsFixed(0)}) vs. this month\'s ${category.name} boss',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: shieldHealth,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                color: shieldColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogExpenseSheet extends StatefulWidget {
  const _LogExpenseSheet();

  @override
  State<_LogExpenseSheet> createState() => _LogExpenseSheetState();
}

class _LogExpenseSheetState extends State<_LogExpenseSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;
  bool _confirmed = false;
  bool _scanning = false;
  bool _listening = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    // useRootNavigator: true so this chooser presents at the root level
    // instead of nested inside the log-expense sheet's own modal route —
    // on a real iPhone, presenting the native camera/photo-library UI
    // immediately after dismissing a *nested* Flutter modal route can
    // leave UIKit's presentation chain confused enough that "Use Photo"
    // never calls back and the picker just hangs with no error. A real
    // device tester hit exactly that: tapping "Use Photo" did nothing.
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    // Let this sheet's own dismiss animation finish before presenting
    // another modal (the native camera/library UI) on top of it — part of
    // the same fix as useRootNavigator above.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final picker = ImagePicker();
    XFile? photo;
    try {
      photo = await picker.pickImage(source: source, imageQuality: 85).timeout(const Duration(seconds: 60));
    } catch (e) {
      debugPrint('_scanReceipt: pickImage failed or timed out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the camera — enter the expense manually.')),
        );
      }
      return;
    }
    if (photo == null || !mounted) return;
    setState(() => _scanning = true);
    ReceiptScanResult? result;
    try {
      result = await ReceiptOcrService.scan(photo.path).timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('_scanReceipt: OCR failed or timed out: $e');
    }
    if (!mounted) return;
    setState(() => _scanning = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that receipt — enter it manually.')),
      );
      return;
    }
    AnalyticsService.instance.capture('receipt_scanned');
    setState(() {
      if (result!.amount != null) _amountController.text = result.amount!.toStringAsFixed(2);
      if (result.vendor != null && _noteController.text.isEmpty) _noteController.text = result.vendor!;
    });
  }

  Future<void> _startVoiceInput() async {
    setState(() => _listening = true);
    String? transcript;
    try {
      // A real-device tester hit the mic button spinning forever — the
      // underlying speech_to_text plugin's initialize() can fail to ever
      // resolve (e.g. a stuck permission dialog) with no error callback,
      // which had nothing bounding this await. This timeout is the
      // recovery path for that, on top of VoiceInputService's own
      // internal timeout on initialize() itself.
      transcript = await VoiceInputService.listenOnce().timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('_startVoiceInput: listenOnce failed or timed out: $e');
      transcript = null;
    }
    if (!mounted) return;
    setState(() => _listening = false);
    if (transcript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Didn\'t catch that — try again or enter it manually.')),
      );
      return;
    }
    final categories = context.read<CategoryProvider>().all;
    final result = parseVoiceExpense(transcript, categories);
    AnalyticsService.instance.capture('voice_expense_logged');
    setState(() {
      if (result.amount != null) _amountController.text = result.amount!.toStringAsFixed(2);
      if (result.categoryId != null) _selectedCategoryId = result.categoryId;
      if (_noteController.text.isEmpty) _noteController.text = result.note;
    });
  }

  Future<void> _confirm(BuildContext context) async {
    if (_confirmed) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _selectedCategoryId == null) return;
    // Light haptic on every routine log — deliberately the *light* variant,
    // reserving stronger haptics/confetti for milestones only. See
    // docs/technical-architecture.md's "game feel" calibration.
    HapticFeedback.lightImpact();
    setState(() => _confirmed = true);
    final expenseProvider = context.read<ExpenseProvider>();
    final gamificationProvider = context.read<GamificationProvider>();
    final buddyProvider = context.read<BuddyProvider>();
    final navigator = Navigator.of(context);
    await expenseProvider.addExpense(
      amount: amount,
      categoryId: _selectedCategoryId!,
      note: _noteController.text,
    );
    final badge = await gamificationProvider.onExpenseLogged(expenseProvider.currentStreak);
    // Push today's "logged" signal to the buddy backend (no-op when
    // unconfigured or unlinked) so the shared streak stays in sync.
    await buddyProvider.markTodayLogged(true);
    // Brief pause so the inline checkmark is actually seen before the sheet
    // closes — this replaces the previous silent, instant dismiss.
    await Future.delayed(const Duration(milliseconds: 300));
    navigator.pop();
    if (badge != null) {
      navigator.push(MaterialPageRoute(builder: (_) => MilestoneCelebrationScreen(badge: badge)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().all;
    _selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log an expense', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$'),
          ),
          // Placed directly under the field they fill, not up in the header
          // — this is the zone a thumb can already reach one-handed
          // (holding the phone with the same hand you're using to tap),
          // instead of making you stretch up to the top of the sheet.
          if (VoiceInputService.isSupportedPlatform || ReceiptOcrService.isAvailable) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Or fill in automatically:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 4),
                if (VoiceInputService.isSupportedPlatform)
                  IconButton.filledTonal(
                    tooltip: 'Speak an expense',
                    iconSize: 24,
                    onPressed: _listening ? null : _startVoiceInput,
                    icon: _listening
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.mic_none_outlined),
                  ),
                if (ReceiptOcrService.isAvailable)
                  IconButton.filledTonal(
                    tooltip: 'Scan a receipt',
                    iconSize: 24,
                    onPressed: _scanning ? null : _scanReceipt,
                    icon: _scanning
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.photo_camera_outlined),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: categories.map((c) {
              return ChoiceChip(
                label: Text('${c.emoji} ${c.name}'),
                selected: _selectedCategoryId == c.id,
                onSelected: (_) => setState(() => _selectedCategoryId = c.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _confirmed ? null : () => _confirm(context),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: _confirmed
                    ? const Icon(Icons.check, key: ValueKey('check'))
                    : const Text('Confirm', key: ValueKey('label')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
