import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hearthio/l10n/app_localizations.dart';
import 'package:hearthio/main.dart';
import 'package:hearthio/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _GuideCaptureSequence());
}

class _GuideCaptureSequence extends StatefulWidget {
  const _GuideCaptureSequence();

  @override
  State<_GuideCaptureSequence> createState() => _GuideCaptureSequenceState();
}

class _GuideCaptureSequenceState extends State<_GuideCaptureSequence> {
  static const _requestedScreen = String.fromEnvironment(
    'GUIDE_CAPTURE_SCREEN',
  );
  static const _requestedLanguage = String.fromEnvironment(
    'GUIDE_CAPTURE_LANGUAGE',
  );
  static const _allEntries = [
    (screen: 'item-profile', language: 'zh'),
    (screen: 'item-profile-details', language: 'zh'),
    (screen: 'care-plan-entry', language: 'zh'),
    (screen: 'care-plan', language: 'zh'),
    (screen: 'complete-care', language: 'zh'),
    (screen: 'lifecycle-record', language: 'zh'),
    (screen: 'history-report', language: 'zh'),
    (screen: 'item-profile', language: 'en'),
    (screen: 'item-profile-details', language: 'en'),
    (screen: 'care-plan-entry', language: 'en'),
    (screen: 'care-plan', language: 'en'),
    (screen: 'complete-care', language: 'en'),
    (screen: 'lifecycle-record', language: 'en'),
    (screen: 'history-report', language: 'en'),
  ];
  static final entries = _allEntries
      .where(
        (entry) =>
            (_requestedScreen.isEmpty || entry.screen == _requestedScreen) &&
            (_requestedLanguage.isEmpty ||
                entry.language == _requestedLanguage),
      )
      .toList(growable: false);

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _index == entries.length - 1) {
        _timer?.cancel();
        return;
      }
      setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = entries[_index];
    final locale = Locale(entry.language);
    return MaterialApp(
      key: ValueKey('${entry.screen}-${entry.language}'),
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: HearthioTheme.light,
      home: _captureScreen(entry.screen, entry.language),
    );
  }
}

Widget _captureScreen(String screen, String language) {
  final plan = _samplePlan();
  final item = _sampleItem(plan, language);
  final lifecycleItem = _lifecycleItem(item, plan, language);
  final unplannedItem = item.copyWith(plans: const [], records: const []);
  return switch (screen) {
    'item-profile' => EditorPage(store: CareStore()),
    'item-profile-details' => const _ItemSupplementCapture(),
    'care-plan-entry' => DetailPage(
      store: _storeFor(unplannedItem),
      item: unplannedItem,
    ),
    'care-plan' => MaintenancePlanEditorPage(initialPlan: plan),
    'complete-care' => MaintenanceExecutionPage(
      controller: const _CaptureExecutionController(),
      task: MaintenanceTask(
        item: item,
        plan: plan,
        status: MaintenancePlanStatus.evaluate(
          plan,
          now: DateTime(2026, 8, 25),
        ),
      ),
    ),
    'lifecycle-record' => _LifecycleCapture(
      store: _storeFor(lifecycleItem),
      item: lifecycleItem,
    ),
    'history-report' => Scaffold(
      body: SafeArea(
        bottom: false,
        child: MaintenanceReportPage(items: [item], now: DateTime(2026, 8, 25)),
      ),
      bottomNavigationBar: AppBottomDock(selected: 3, onSelect: (_) {}),
    ),
    _ => throw ArgumentError.value(screen, 'screen'),
  };
}

CareStore _storeFor(CareItem item) => CareStore()
  ..loaded = true
  ..items = [item];

CareItem _lifecycleItem(CareItem item, MaintenancePlan plan, String language) =>
    item.copyWith(
      records: [
        ...item.records,
        MaintenanceRecord(
          id: 'sample-completion-older',
          planId: plan.id,
          completedAt: DateTime(2026, 3, 18),
          plannedDueDate: DateTime(2026, 3, 18),
          kind: language == 'zh' ? '更换滤芯' : 'Replace filter',
          cost: 89,
          materialName: 'Carbon A1',
          note: language == 'zh'
              ? '完成例行更换，并检查接口没有漏水。'
              : 'Routine replacement completed; connections checked for leaks.',
          completedStepIds: plan.checklist.map((step) => step.id).toList(),
        ),
      ],
    );

MaintenancePlan _samplePlan() {
  final template = maintenanceTemplates.firstWhere(
    (candidate) => candidate.id == 'water-purifier-filter',
  );
  return enrichMaintenanceTemplateStepDescriptions(
    template.createPlan(
      planId: 'sample-filter-plan',
      referenceDate: DateTime(2026, 2, 26),
    ),
  );
}

CareItem _sampleItem(MaintenancePlan plan, String language) => CareItem(
  id: 'sample-filter',
  name: language == 'zh' ? '示例 · 厨房净水器' : 'Sample purifier',
  category: language == 'zh' ? '滤芯与耗材' : 'Filters & consumables',
  location: language == 'zh' ? '厨房' : 'Kitchen',
  brand: language == 'zh' ? '家用净水器' : 'Home water purifier',
  model: 'WP-180',
  notes: language == 'zh'
      ? '这是示例数据：完成更换滤芯后，可以记录日期、型号和实际费用。'
      : 'This is sample data. After replacing the filter, record the date, model, and actual cost.',
  photos: const [],
  plans: [plan],
  records: [
    MaintenanceRecord(
      id: 'sample-completion',
      planId: plan.id,
      completedAt: DateTime(2026, 8, 20),
      plannedDueDate: DateTime(2026, 8, 20),
      kind: language == 'zh' ? '更换滤芯' : 'Replace filter',
      cost: 129,
      materialName: 'PP A1',
      note: language == 'zh'
          ? '出水正常，已记录新滤芯型号。'
          : 'Water flow is normal and the new filter model is recorded.',
      completedStepIds: plan.checklist.map((step) => step.id).toList(),
    ),
  ],
  purchaseDate: DateTime(2025, 8, 25),
  isSample: true,
);

class _ItemSupplementCapture extends StatefulWidget {
  const _ItemSupplementCapture();

  @override
  State<_ItemSupplementCapture> createState() => _ItemSupplementCaptureState();
}

class _ItemSupplementCaptureState extends State<_ItemSupplementCapture> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 500), _selectWaterPurifier);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectWaterPurifier() {
    if (!mounted) return;
    final target = _findElementByKey(
      context as Element,
      const ValueKey('common-item-净水器'),
    );
    final targetWidget = target?.widget;
    if (targetWidget is InkWell) targetWidget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) => EditorPage(store: CareStore());
}

class _LifecycleCapture extends StatefulWidget {
  const _LifecycleCapture({required this.store, required this.item});

  final CareStore store;
  final CareItem item;

  @override
  State<_LifecycleCapture> createState() => _LifecycleCaptureState();
}

class _LifecycleCaptureState extends State<_LifecycleCapture> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 700), _showTimeline);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showTimeline() {
    if (!mounted) return;
    final scrollable = _findElementByType<Scrollable>(context as Element);
    if (scrollable case final StatefulElement element) {
      final scrollState = element.state as ScrollableState;
      scrollState.position.jumpTo(scrollState.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final timeline = _findElementByKey(
          context as Element,
          const Key('maintenance-lifecycle-timeline'),
        );
        final renderObject = timeline?.renderObject;
        if (renderObject is! RenderBox) return;
        final desiredTop = MediaQuery.paddingOf(context).top + 80;
        final currentTop = renderObject.localToGlobal(Offset.zero).dy;
        final target = (scrollState.position.pixels + currentTop - desiredTop)
            .clamp(0.0, scrollState.position.maxScrollExtent)
            .toDouble();
        scrollState.position.jumpTo(target);
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      DetailPage(store: widget.store, item: widget.item);
}

Element? _findElementByKey(Element root, Key key) =>
    _findElement(root, (element) => element.widget.key == key);

Element? _findElementByType<T extends Widget>(Element root) =>
    _findElement(root, (element) => element.widget is T);

Element? _findElement(Element root, bool Function(Element) matches) {
  if (matches(root)) return root;
  Element? result;
  root.visitChildren((child) {
    result ??= _findElement(child, matches);
  });
  return result;
}

class _CaptureExecutionController implements MaintenanceExecutionController {
  const _CaptureExecutionController();

  @override
  Future<MaintenanceCompletionResult> completeMaintenance(
    MaintenanceCompletionDraft draft,
  ) => throw UnsupportedError('Capture-only controller');

  @override
  Future<void> discardImportedPhoto(String path) async {}

  @override
  Future<PhotoImportResult> importPhoto(ImageSource source) async =>
      const PhotoImportResult.cancelled();
}
