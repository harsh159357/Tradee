import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../features/portfolio_state.dart';
import '../features/market_state.dart';
import '../data/storage_service.dart';
import 'theme.dart';
import 'widgets/glass_card.dart';
import 'widgets/section_header.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volMode = ref.watch(volatilityModeProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SectionHeader(title: 'Account'),
            GlassCard(
              padding: const EdgeInsets.all(4),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh, color: Colors.orange, size: 20),
                ),
                title: const Text(
                  'Reset Demo Account',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Clear positions and reset to \$100,000',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                onTap: () => _confirmReset(context, ref),
              ),
            ),
            const SectionHeader(title: 'Volatility Model'),
            _VolToggleCard(
              title: 'Rolling Realized Vol',
              subtitle: 'Calculated from live 1h price window',
              icon: Icons.auto_graph,
              isSelected: volMode == 'rolling',
              onTap: () => _setVolMode(ref, 'rolling'),
            ),
            const SizedBox(height: 8),
            _VolToggleCard(
              title: 'Fixed 50% IV',
              subtitle: 'Constant implied volatility for all strikes',
              icon: Icons.linear_scale,
              isSelected: volMode == 'fixed',
              onTap: () => _setVolMode(ref, 'fixed'),
            ),
            const SectionHeader(title: 'About'),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _AboutRow(icon: Icons.show_chart, label: 'App', value: 'Tradee v1.0.0'),
                  const SizedBox(height: 14),
                  _AboutRow(icon: Icons.functions, label: 'Pricing', value: 'Black-Scholes (EU)'),
                  const SizedBox(height: 14),
                  _AboutRow(icon: Icons.schedule, label: 'Expiry', value: 'Daily 05:29:59 IST'),
                  const SizedBox(height: 14),
                  _AboutRow(icon: Icons.savings_outlined, label: 'Starting Balance', value: '\$100,000'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Built with Flutter',
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setVolMode(WidgetRef ref, String mode) {
    final box = StorageService.getBox(StorageService.boxSettings);
    box.put('volatility_mode', mode);
    ref.read(volatilityModeProvider.notifier).state = mode;
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder),
            left: BorderSide(color: AppColors.surfaceBorder),
            right: BorderSide(color: AppColors.surfaceBorder),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.lossDim,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.loss, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reset Account?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will delete all positions, trade history, and reset your balance to \$100,000.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final posBox = StorageService.getBox(StorageService.boxPositions);
                      final histBox = StorageService.getBox(StorageService.boxHistory);
                      await posBox.clear();
                      await histBox.clear();
                      await ref.read(balanceProvider.notifier).updateBalance(AppConstants.initialBalance);
                      ref.read(portfolioProvider.notifier).loadPositions();
                      ref.read(tradeHistoryProvider.notifier).refresh();

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Account reset successfully'),
                            backgroundColor: AppColors.profit,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.loss,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('RESET', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _VolToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VolToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDim : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary.withAlpha(100) : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textTertiary,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: AppColors.background)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
      ],
    );
  }
}
