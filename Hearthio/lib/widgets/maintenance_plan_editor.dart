import 'package:flutter/material.dart';

import '../models/maintenance_calendar.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_record.dart';
import '../models/maintenance_template.dart';

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
    final active = plans.where((plan) => !plan.archived).toList();
    final archived = plans.where((plan) => plan.archived).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '保养计划',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
            TextButton.icon(
              key: const Key('add-maintenance-plan'),
              onPressed: () => _addPlan(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加计划'),
            ),
          ],
        ),
        const Text(
          '模板中的周期仅供参考，保存前可修改全部字段；请优先遵循设备厂商说明书。',
          style: TextStyle(color: Color(0xFF72817A), height: 1.45),
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
            title: Text('已归档计划（${archived.length}）'),
            subtitle: const Text('关联历史已保留，不再发送提醒'),
            children: archived
                .map(
                  (plan) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(plan.title),
                    subtitle: Text('每 ${plan.intervalDays} 天'),
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
    final initial = template.createPlan(planId: planId);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(hasHistory ? '归档这个计划？' : '删除这个计划？'),
        content: Text(
          hasHistory
              ? '“${plan.title}”已有维护记录。归档后会停止提醒，但历史记录仍会保留。'
              : '“${plan.title}”尚无维护记录，删除后无法恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(hasHistory ? '确认归档' : '确认删除'),
          ),
        ],
      ),
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
      border: Border.all(color: const Color(0xFFE6EBE4)),
    ),
    child: const Column(
      children: [
        Icon(Icons.event_repeat_outlined, color: Color(0xFF31584B)),
        SizedBox(height: 8),
        Text('还没有保养计划', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 3),
        Text(
          '可从模板开始，也可以创建完全自定义的任务。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF72817A)),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E9E2)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF1E9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            plan.enabled ? Icons.event_available_outlined : Icons.event_busy,
            color: const Color(0xFF31584B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${plan.enabled ? '已启用' : '已停用'} · 每 ${plan.intervalDays} 天 · 提前 ${plan.reminderLeadDays} 天',
                style: const TextStyle(color: Color(0xFF72817A), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '下次：${_date(plan.dueDate)} · ${plan.checklist.length} 个步骤',
                style: const TextStyle(color: Color(0xFF72817A), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          key: ValueKey('edit-plan-${plan.id}'),
          tooltip: '编辑 ${plan.title}',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          key: ValueKey('remove-plan-${plan.id}'),
          tooltip: '删除或归档 ${plan.title}',
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
      ],
    ),
  );
}

class _MaintenanceTemplatePicker extends StatelessWidget {
  const _MaintenanceTemplatePicker();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.76,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '选择保养模板',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '模板只是可编辑起点，并非强制安全周期；请以厂商说明书为准。',
            style: TextStyle(color: Color(0xFF72817A), height: 1.45),
          ),
          const SizedBox(height: 14),
          ...maintenanceTemplates.map(
            (template) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                key: ValueKey('template-${template.id}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E9E2)),
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEAF1E9),
                  foregroundColor: const Color(0xFF31584B),
                  child: Icon(
                    template.id == 'custom'
                        ? Icons.edit_note_outlined
                        : Icons.home_repair_service_outlined,
                  ),
                ),
                title: Text('${template.scene} · ${template.title}'),
                subtitle: Text(
                  template.id == 'custom'
                      ? '名称、周期和步骤均由你填写'
                      : '默认 ${template.intervalDays} 天 · ${template.steps.join('、')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                onTap: () => Navigator.pop(context, template),
              ),
            ),
          ),
        ],
      ),
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
          (step) =>
              _StepDraft(step.id, TextEditingController(text: step.title)),
        )
        .toList();
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('编辑保养计划'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton(
            key: const Key('save-maintenance-plan'),
            onPressed: _save,
            child: const Text('保存计划'),
          ),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Form(
        key: _form,
        child: ListView(
          key: const PageStorageKey('maintenance-plan-editor-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            TextFormField(
              key: const Key('maintenance-plan-title'),
              controller: _title,
              validator: MaintenancePlanValidator.title,
              decoration: const InputDecoration(labelText: '计划名称 *'),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              key: const Key('maintenance-plan-enabled'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text('启用计划'),
              subtitle: const Text('停用后保留计划和历史，但不再发送提醒'),
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
                    validator: MaintenancePlanValidator.interval,
                    onChanged: (_) => _refreshDerivedDueDate(),
                    decoration: const InputDecoration(labelText: '周期（天）*'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const Key('maintenance-plan-reminder-lead'),
                    controller: _reminderLead,
                    keyboardType: TextInputType.number,
                    validator: (value) => MaintenancePlanValidator.reminderLead(
                      value,
                      intervalDays: int.tryParse(_interval.text.trim()),
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: '提前提醒（天）*'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PlanDateTile(
              label: '上次完成日（可选）',
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
              label: '首次 / 下次到期日',
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
                MaintenancePlanValidator.dates(_lastCompletedAt, _dueDate)!,
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
                color: const Color(0xFFEAF1E9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    color: Color(0xFF31584B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '下一次日期预览',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _previewDate == null
                              ? '补全周期和日期后显示'
                              : '${_date(_previewDate)} · 提前 ${_reminderLead.text.trim().isEmpty ? '—' : _reminderLead.text.trim()} 天提醒',
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
                const Expanded(
                  child: Text(
                    '执行步骤',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  key: const Key('add-maintenance-step'),
                  onPressed: _addStep,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('添加步骤'),
                ),
              ],
            ),
            if (_steps.isEmpty)
              const Text(
                '步骤可选；需要时可逐条添加，并在保存前修改。',
                style: TextStyle(color: Color(0xFF72817A)),
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
                          backgroundColor: const Color(0xFFEAF1E9),
                          foregroundColor: const Color(0xFF31584B),
                          child: Text('${index + 1}'),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('maintenance-step-$index'),
                          controller: step.controller,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? '请填写步骤内容'
                              : null,
                          decoration: const InputDecoration(labelText: '步骤内容'),
                        ),
                      ),
                      IconButton(
                        tooltip: '删除步骤 ${index + 1}',
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
    ),
  );

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
    final dateError = MaintenancePlanValidator.dates(
      _lastCompletedAt,
      _dueDate,
    );
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
      border: Border.all(color: const Color(0xFFE2E9E2)),
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
                _date(date),
                style: const TextStyle(color: Color(0xFF72817A)),
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
            final selected = await showDatePicker(
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
  _StepDraft(this.id, this.controller);

  final String id;
  final TextEditingController controller;
}

String _date(DateTime? value) =>
    value == null ? '未设置' : '${value.year}年${value.month}月${value.day}日';
