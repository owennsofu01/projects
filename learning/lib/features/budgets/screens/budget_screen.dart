import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/budget_controller.dart';
import '../models/budget_model.dart';
import '../widgets/category_field.dart';

/// This month's spending against each category's limit.
class BudgetScreen extends StatelessWidget {
  BudgetScreen({super.key});

  final BudgetController controller = Get.find<BudgetController>();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'budgets-fab',
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add budget'),
      ),
      body: Obx(() {
        final statuses = controller.statuses;
        if (statuses.isEmpty) {
          return const EmptyState(
            icon: Icons.savings_outlined,
            message:
                'No budgets yet.\nSet a monthly limit for an expense '
                'category to get a warning before you overspend.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: statuses.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                'Spending in ${AppFormatter.month(now)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }
            final status = statuses[index - 1];
            return _BudgetTile(
              status: status,
              onTap: () => _openEditor(context, existing: status.budget),
              onDelete: () => _delete(context, status.budget),
            );
          },
        );
      }),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    BudgetModel? existing,
  }) async {
    final suggestions = await controller.expenseCategories();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BudgetEditor(
        controller: controller,
        existing: existing,
        suggestions: suggestions,
      ),
    );
  }

  Future<void> _delete(BuildContext context, BudgetModel budget) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete budget?',
      message:
          'Remove the ${budget.category} limit? Your expenses are not '
          'affected.',
    );
    if (confirmed) await controller.deleteBudget(budget.category);
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.status,
    required this.onTap,
    required this.onDelete,
  });

  final BudgetStatus status;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static Color colorFor(BudgetLevel level) => switch (level) {
    BudgetLevel.ok => AppColors.income,
    BudgetLevel.near => AppColors.warning,
    BudgetLevel.over => AppColors.expense,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorFor(status.level);
    final remaining = status.remaining;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status.budget.category,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete budget',
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: status.usage.clamp(0, 1).toDouble(),
                        minHeight: 8,
                        color: color,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${AppFormatter.currency(status.spent)} of '
                              '${AppFormatter.currency(status.budget.monthlyLimit)}',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            remaining >= 0
                                ? '${AppFormatter.currency(remaining)} left'
                                : '${AppFormatter.currency(-remaining)} over',
                            style: textTheme.bodyMedium?.copyWith(
                              color: status.level == BudgetLevel.ok
                                  ? colorScheme.onSurfaceVariant
                                  : color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetEditor extends StatefulWidget {
  const _BudgetEditor({
    required this.controller,
    required this.existing,
    required this.suggestions,
  });

  final BudgetController controller;
  final BudgetModel? existing;
  final List<String> suggestions;

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _categoryCtrl = TextEditingController(
    text: widget.existing?.category ?? '',
  );
  late final _limitCtrl = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.monthlyLimit.toStringAsFixed(2),
  );

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final category = _categoryCtrl.text.trim();
    if (!_isEditing && widget.controller.budgetFor(category) != null) {
      // Saving would silently replace the other limit.
      showErrorSnackbar(
        '$category already has a budget. Tap it in the list to change it.',
      );
      return;
    }

    final saved = await widget.controller.saveBudget(
      BudgetModel(
        category: category,
        monthlyLimit: double.parse(_limitCtrl.text.trim()),
      ),
    );
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final existingKeys = widget.controller.budgets.map((b) => b.key).toSet();
    final suggestions = widget.suggestions
        .where((c) => !existingKeys.contains(BudgetModel.keyFor(c)))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit budget' : 'New budget',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CategoryField(
              controller: _categoryCtrl,
              suggestions: suggestions,
              label: 'Expense category',
              enabled: !_isEditing,
            ),
            AppTextField(
              controller: _limitCtrl,
              label: 'Monthly limit',
              icon: Icons.savings_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: FormValidators.positiveNumber,
            ),
            const SizedBox(height: 8),
            Obx(
              () => AppPrimaryButton(
                label: 'SAVE BUDGET',
                isLoading: widget.controller.isSaving.value,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
