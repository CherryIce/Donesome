import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../l10n/maintenance_l10n.dart';
import '../models/maintenance_calendar.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_record.dart';
import '../models/maintenance_template.dart';
import '../theme/app_theme.dart';
import 'app_alert.dart';
import 'app_back_button.dart';
import 'app_date_picker.dart';
import 'app_safe_area.dart';

class MaintenancePlansEditorSection extends StatelessWidget {
  const MaintenancePlansEditorSection({
    super.key,
    required this.plans,
    required this.records,
    required this.onChanged,
  });

  final List<MaintenancePlan> plans;
  final List<MaintenanceRecord> records;
  final ValueChanged<List<MaintenancePlan>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = plans.where((plan) => !plan.archived).toList();
    final archived = plans.where((plan) => plan.archived).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.maintenancePlansTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            TextButton.icon(
              key: const Key('add-maintenance-plan'),
              onPressed: () => _addPlan(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addPlan),
            ),
          ],
        ),
        Text(
          l10n.planTemplateDisclaimer,
          style: TextStyle(color: context.palette.muted, height: 1.45),
        ),
        const SizedBox(height: 10),
        if (active.isEmpty)
          const _EmptyPlansCard()
        else
          ...active.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlanCard(
                key: ValueKey('maintenance-plan-${plan.id}'),
                plan: plan,
                onEdit: () => _editPlan(context, plan),
                onRemove: () => _removePlan(context, plan),
              ),
            ),
          ),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 4),
          ExpansionTile(
            key: const PageStorageKey<String>('archived-maintenance-plans'),
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.archivedPlansCount(archived.length)),
            subtitle: Text(l10n.archivedPlansSubtitle),
            children: archived
                .map(
                  (plan) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(l10n.maintenancePlanTitleLabel(plan.title)),
                    subtitle: Text(l10n.intervalEveryDays(plan.intervalDays)),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  Future<void> _addPlan(BuildContext context) async {
    final template = await showModalBottomSheet<MaintenanceTemplate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _MaintenanceTemplatePicker(),
    );
    if (template == null || !context.mounted) return;
    final planId = 'plan-${DateTime.now().microsecondsSinceEpoch}';
    final initial = context.l10n
        .localizedTemplate(template)
        .createPlan(planId: planId);
    final result = await Navigator.push<MaintenancePlan>(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenancePlanEditorPage(
          initialPlan: initial,
          isNewFromTemplate: true,
        ),
      ),
    );
    if (result != null) onChanged([...plans, result]);
  }

  Future<void> _editPlan(BuildContext context, MaintenancePlan plan) async {
    final result = await Navigator.push<MaintenancePlan>(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenancePlanEditorPage(initialPlan: plan),
      ),
    );
    if (result == null) return;
    onChanged([
      for (final current in plans)
        if (current.id == result.id) result else current,
    ]);
  }

  Future<void> _removePlan(BuildContext context, MaintenancePlan plan) async {
    final hasHistory = records.any((record) => record.planId == plan.id);
    final confirmed = await showAppAlert<bool>(
      context,
      title: hasHistory
          ? context.l10n.archivePlanTitle
          : context.l10n.deletePlanTitle,
      message: hasHistory
          ? context.l10n.archivePlanMessage(
              context.l10n.maintenancePlanTitleLabel(plan.title),
            )
          : context.l10n.deletePlanMessage(
              context.l10n.maintenancePlanTitleLabel(plan.title),
            ),
      actions: [
        AppAlertAction(label: context.l10n.commonCancel, result: false),
        AppAlertAction(
          label: hasHistory
              ? context.l10n.confirmArchive
              : context.l10n.confirmDelete,
          result: true,
          tone: hasHistory
              ? AppAlertActionTone.standard
              : AppAlertActionTone.destructive,
          isDefaultAction: hasHistory,
        ),
      ],
    );
    if (confirmed != true) return;
    onChanged([
      for (final current in plans)
        if (current.id != plan.id)
          current
        else if (hasHistory)
          current.copyWith(
            enabled: false,
            archived: true,
            clearDeferredUntil: true,
          ),
    ]);
  }
}

class _EmptyPlansCard extends StatelessWidget {
  const _EmptyPlansCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.palette.border),
    ),
    child: Column(
      children: [
        Icon(Icons.event_repeat_outlined, color: context.palette.primary),
        const SizedBox(height: 8),
        Text(
          context.l10n.noMaintenancePlans,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          context.l10n.noMaintenancePlansSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.muted),
        ),
      ],
    ),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onRemove,
  });

  final MaintenancePlan plan;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.palette.mist,
              shape: BoxShape.circle,
            ),
            child: Icon(
              plan.enabled ? Icons.event_available_outlined : Icons.event_busy,
              color: context.palette.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.maintenancePlanTitleLabel(plan.title),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.planScheduleSummary(
                    plan.enabled ? l10n.planEnabled : l10n.planDisabled,
                    plan.intervalDays,
                    plan.reminderLeadDays,
                  ),
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.planNextSummary(
                    _date(l10n, plan.dueDate),
                    plan.checklist.length,
                  ),
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('edit-plan-${plan.id}'),
            tooltip: l10n.editPlanTooltip(
              l10n.maintenancePlanTitleLabel(plan.title),
            ),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            key: ValueKey('remove-plan-${plan.id}'),
            tooltip: l10n.removePlanTooltip(
              l10n.maintenancePlanTitleLabel(plan.title),
            ),
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline, color: context.palette.danger),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceTemplatePicker extends StatelessWidget {
  const _MaintenanceTemplatePicker();

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.76,
    minChildSize: 0.45,
    maxChildSize: 0.92,
    builder: (context, scrollController) => ListView(
      controller: scrollController,
      padding: appSafeScrollPadding(
        context,
        const EdgeInsets.fromLTRB(20, 12, 20, 28),
      ),
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: context.palette.handle,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.selectMaintenanceTemplate,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.templatePickerDisclaimer,
          style: TextStyle(color: context.palette.muted, height: 1.45),
        ),
        const SizedBox(height: 14),
        ...maintenanceTemplates.map((template) {
          final localized = context.l10n.localizedTemplate(template);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              key: ValueKey('template-${template.id}'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.palette.border),
              ),
              leading: CircleAvatar(
                backgroundColor: context.palette.mist,
                foregroundColor: context.palette.primary,
                child: Icon(
                  template.id == 'custom'
                      ? Icons.edit_note_outlined
                      : Icons.home_repair_service_outlined,
                ),
              ),
              title: Text('${localized.scene} · ${localized.title}'),
              subtitle: Text(
                template.id == 'custom'
                    ? context.l10n.customTemplateDescription
                    : context.l10n.templateDefaultSummary(
                        template.intervalDays,
                        localized.steps.join(
                          Localizations.localeOf(context).languageCode == 'zh'
                              ? '、'
                              : ', ',
                        ),
                      ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
              onTap: () => Navigator.pop(context, template),
            ),
          );
        }),
      ],
    ),
  );
}

class MaintenancePlanEditorPage extends StatefulWidget {
  const MaintenancePlanEditorPage({
    super.key,
    required this.initialPlan,
    this.isNewFromTemplate = false,
  });

  final MaintenancePlan initialPlan;
  final bool isNewFromTemplate;

  @override
  State<MaintenancePlanEditorPage> createState() =>
      _MaintenancePlanEditorPageState();
}

class _MaintenancePlanEditorPageState extends State<MaintenancePlanEditorPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _interval;
  late final TextEditingController _reminderLead;
  late List<_StepDraft> _steps;
  late bool _enabled;
  DateTime? _lastCompletedAt;
  DateTime? _dueDate;
  bool _dueFollowsLast = false;
  bool _dueFollowsReference = false;
  bool _showDateError = false;
  bool _localizedInitialCopy = false;

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;
    _title = TextEditingController(text: plan.title);
    _interval = TextEditingController(text: '${plan.intervalDays}');
    _reminderLead = TextEditingController(text: '${plan.reminderLeadDays}');
    _enabled = plan.enabled;
    _lastCompletedAt = plan.lastCompletedAt;
    _dueDate = plan.dueDate;
    _dueFollowsLast =
        plan.lastCompletedAt != null &&
        plan.dueDate ==
            addMaintenanceDays(plan.lastCompletedAt!, plan.intervalDays);
    _dueFollowsReference = widget.isNewFromTemplate;
    final checklist = [...plan.checklist]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _steps = checklist
        .map(
          (step) => _StepDraft(
            step.id,
            TextEditingController(text: step.title),
            step.description,
          ),
        )
        .toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedInitialCopy) return;
    final l10n = context.l10n;
    _title.text = l10n.maintenancePlanTitleLabel(_title.text);
    for (final step in _steps) {
      step.controller.text = l10n.maintenanceStepTitleLabel(
        step.controller.text,
      );
      step.description = l10n.maintenanceStepDescriptionLabel(step.description);
    }
    _localizedInitialCopy = true;
  }

  @override
  void dispose() {
    _title.dispose();
    _interval.dispose();
    _reminderLead.dispose();
    for (final step in _steps) {
      step.controller.dispose();
    }
    super.dispose();
  }

  DateTime? get _previewDate => MaintenancePlanValidator.previewDueDate(
    lastCompletedAt: _lastCompletedAt,
    dueDate: _dueDate,
    intervalDays: int.tryParse(_interval.text.trim()),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(l10n.editMaintenancePlan),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              key: const Key('save-maintenance-plan'),
              onPressed: _save,
              child: Text(l10n.savePlan),
            ),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          key: const PageStorageKey('maintenance-plan-editor-scroll'),
          padding: appSafeScrollPadding(
            context,
            const EdgeInsets.fromLTRB(20, 16, 20, 40),
          ),
          children: [
            TextFormField(
              key: const Key('maintenance-plan-title'),
              controller: _title,
              validator: (value) => _validateTitle(l10n, value),
              decoration: InputDecoration(labelText: l10n.planNameLabel),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              key: const Key('maintenance-plan-enabled'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(l10n.enablePlan),
              subtitle: Text(l10n.disablePlanSubtitle),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('maintenance-plan-interval'),
                    controller: _interval,
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateInterval(l10n, value),
                    onChanged: (_) => _refreshDerivedDueDate(),
                    decoration: InputDecoration(
                      labelText: l10n.intervalDaysLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const Key('maintenance-plan-reminder-lead'),
                    controller: _reminderLead,
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateReminderLead(
                      l10n,
                      value,
                      intervalDays: int.tryParse(_interval.text.trim()),
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.reminderLeadDaysLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PlanDateTile(
              label: l10n.lastCompletedOptional,
              date: _lastCompletedAt,
              onChanged: (date) {
                setState(() {
                  _lastCompletedAt = date;
                  _showDateError = false;
                  if (date != null) {
                    _dueFollowsReference = false;
                    final interval = int.tryParse(_interval.text.trim());
                    if (interval != null && interval > 0) {
                      _dueDate = addMaintenanceDays(date, interval);
                      _dueFollowsLast = true;
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            _PlanDateTile(
              label: l10n.firstOrNextDueDate,
              date: _dueDate,
              onChanged: (date) => setState(() {
                _dueDate = date;
                _dueFollowsLast = date == null;
                _dueFollowsReference = false;
                _showDateError = false;
              }),
            ),
            if (_showDateError) ...[
              const SizedBox(height: 6),
              Text(
                _validateDates(l10n, _lastCompletedAt, _dueDate)!,
                key: const Key('maintenance-plan-date-error'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              key: const Key('maintenance-plan-preview'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.palette.mist,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    color: context.palette.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.nextDatePreview,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _previewDate == null
                              ? l10n.completeScheduleForPreview
                              : l10n.nextDateReminderPreview(
                                  _date(l10n, _previewDate),
                                  _reminderLead.text.trim().isEmpty
                                      ? '—'
                                      : _reminderLead.text.trim(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.executionSteps,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const Key('add-maintenance-step'),
                  onPressed: _addStep,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addStep),
                ),
              ],
            ),
            if (_steps.isEmpty)
              Text(
                l10n.optionalStepsHint,
                style: TextStyle(color: context.palette.muted),
              )
            else
              ...List.generate(_steps.length, (index) {
                final step = _steps[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, right: 10),
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: context.palette.mist,
                          foregroundColor: context.palette.primary,
                          child: Text('${index + 1}'),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('maintenance-step-$index'),
                          controller: step.controller,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? l10n.stepRequired
                              : null,
                          decoration: InputDecoration(
                            labelText: l10n.stepContentLabel,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.deleteStepTooltip(index + 1),
                        onPressed: () => _removeStep(index),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _refreshDerivedDueDate() {
    final interval = int.tryParse(_interval.text.trim());
    setState(() {
      if (_dueFollowsLast && _lastCompletedAt != null && interval != null) {
        _dueDate = addMaintenanceDays(_lastCompletedAt!, interval);
      } else if (_dueFollowsReference && interval != null && interval > 0) {
        final now = DateTime.now();
        _dueDate = addMaintenanceDays(now, interval);
      }
    });
  }

  void _addStep() {
    setState(() {
      _steps.add(
        _StepDraft(
          '${widget.initialPlan.id}-step-${DateTime.now().microsecondsSinceEpoch}',
          TextEditingController(),
          '',
        ),
      );
    });
  }

  void _removeStep(int index) {
    final removed = _steps.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.controller.dispose();
    });
  }

  void _save() {
    final formValid = _form.currentState?.validate() ?? false;
    final dateError = _validateDates(context.l10n, _lastCompletedAt, _dueDate);
    setState(() => _showDateError = dateError != null);
    if (!formValid || dateError != null) return;
    final interval = int.parse(_interval.text.trim());
    final reminderLeadDays = int.parse(_reminderLead.text.trim());
    final dueDate = MaintenancePlanValidator.previewDueDate(
      lastCompletedAt: _lastCompletedAt,
      dueDate: _dueDate,
      intervalDays: interval,
    );
    Navigator.pop(
      context,
      MaintenancePlan(
        id: widget.initialPlan.id,
        title: _title.text.trim(),
        intervalDays: interval,
        reminderLeadDays: reminderLeadDays,
        checklist: List.generate(
          _steps.length,
          (index) => MaintenanceStep(
            id: _steps[index].id,
            title: _steps[index].controller.text.trim(),
            sortOrder: index,
            description: _steps[index].description,
          ),
          growable: false,
        ),
        enabled: _enabled,
        lastCompletedAt: _lastCompletedAt,
        dueDate: dueDate,
        deferredUntil: widget.initialPlan.deferredUntilAfterScheduleEdit(
          intervalDays: interval,
          reminderLeadDays: reminderLeadDays,
          enabled: _enabled,
          lastCompletedAt: _lastCompletedAt,
          dueDate: dueDate,
        ),
        archived: widget.initialPlan.archived,
      ),
    );
  }
}

class _PlanDateTile extends StatelessWidget {
  const _PlanDateTile({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 9, 7, 9),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.palette.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                _date(context.l10n, date),
                style: TextStyle(color: context.palette.muted),
              ),
            ],
          ),
        ),
        if (date != null)
          IconButton(
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.clear_rounded),
          ),
        IconButton(
          onPressed: () async {
            final selected = await showAppDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: MaintenancePlanValidator.minDate,
              lastDate: MaintenancePlanValidator.maxDate,
            );
            if (selected != null) onChanged(selected);
          },
          icon: const Icon(Icons.calendar_today_outlined),
        ),
      ],
    ),
  );
}

class _StepDraft {
  _StepDraft(this.id, this.controller, this.description);

  final String id;
  final TextEditingController controller;
  String description;
}

String _date(AppLocalizations l10n, DateTime? value) => value == null
    ? l10n.notSet
    : l10n.dateYmd(value.year, value.month, value.day);

String? _validateTitle(AppLocalizations l10n, String? value) {
  if (value == null || value.trim().isEmpty) {
    return l10n.validationPlanNameRequired;
  }
  if (value.trim().length > 40) return l10n.validationPlanNameTooLong;
  return null;
}

String? _validateInterval(AppLocalizations l10n, String? value) {
  final days = int.tryParse(value?.trim() ?? '');
  if (days == null) return l10n.validationIntervalInteger;
  if (days < MaintenancePlanValidator.minIntervalDays ||
      days > MaintenancePlanValidator.maxIntervalDays) {
    return l10n.validationIntervalRange(
      MaintenancePlanValidator.minIntervalDays,
      MaintenancePlanValidator.maxIntervalDays,
    );
  }
  return null;
}

String? _validateReminderLead(
  AppLocalizations l10n,
  String? value, {
  required int? intervalDays,
}) {
  final days = int.tryParse(value?.trim() ?? '');
  if (days == null) return l10n.validationDaysInteger;
  if (days < 0 || days > MaintenancePlanValidator.maxReminderLeadDays) {
    return l10n.validationReminderRange(
      MaintenancePlanValidator.maxReminderLeadDays,
    );
  }
  if (intervalDays != null && days > intervalDays) {
    return l10n.validationReminderAfterInterval;
  }
  return null;
}

String? _validateDates(
  AppLocalizations l10n,
  DateTime? lastCompletedAt,
  DateTime? dueDate,
) {
  if (lastCompletedAt == null && dueDate == null) {
    return l10n.validationPlanDateRequired;
  }
  for (final date in [lastCompletedAt, dueDate]) {
    if (date != null &&
        (date.isBefore(MaintenancePlanValidator.minDate) ||
            date.isAfter(MaintenancePlanValidator.maxDate))) {
      return l10n.validationPlanDateRange;
    }
  }
  if (lastCompletedAt != null &&
      dueDate != null &&
      dueDate.isBefore(lastCompletedAt)) {
    return l10n.validationDueBeforeCompletion;
  }
  return null;
}
