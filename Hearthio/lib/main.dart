import 'dart:io';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import 'models/care_item.dart';
import 'models/maintenance_completion.dart';
import 'models/maintenance_calendar.dart';
import 'models/maintenance_lifecycle.dart';
import 'models/maintenance_notification.dart';
import 'models/maintenance_plan.dart';
import 'models/maintenance_record.dart';
import 'models/maintenance_status.dart';
import 'models/maintenance_task.dart';
import 'models/maintenance_template.dart';
import 'privacy_policy_page.dart';
import 'services/care_backup_codec.dart';
import 'services/care_repository.dart';
import 'services/maintenance_execution_controller.dart';
import 'services/maintenance_history_controller.dart';
import 'widgets/maintenance_plan_editor.dart';
import 'widgets/maintenance_execution_page.dart';
import 'widgets/maintenance_lifecycle_section.dart';
import 'widgets/maintenance_task_card.dart';
import 'widgets/maintenance_report_page.dart';

export 'models/care_item.dart';
export 'models/maintenance_completion.dart';
export 'models/maintenance_calendar.dart';
export 'models/maintenance_lifecycle.dart';
export 'models/maintenance_notification.dart';
export 'models/maintenance_plan.dart';
export 'models/maintenance_record.dart';
export 'models/maintenance_report.dart';
export 'models/maintenance_status.dart';
export 'models/maintenance_task.dart';
export 'models/maintenance_template.dart';
export 'services/care_backup_codec.dart';
export 'services/care_repository.dart';
export 'services/maintenance_execution_controller.dart';
export 'services/maintenance_history_controller.dart';
export 'widgets/maintenance_plan_editor.dart';
export 'widgets/maintenance_execution_page.dart';
export 'widgets/maintenance_lifecycle_section.dart';
export 'widgets/maintenance_record_editor.dart';
export 'widgets/maintenance_report_page.dart';
export 'widgets/maintenance_task_card.dart';

const _indigo = Color(0xFF31584B);
const _amber = Color(0xFFE59A72);
const _canvas = Color(0xFFF7F8F3);
const _paper = Color(0xFFFFFEFA);
const _mist = Color(0xFFEAF1E9);
const _ink = Color(0xFF263630);
const _muted = Color(0xFF72817A);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HearthioApp());
}

Future<void> _configureDeviceTimeZone() async {
  tz.initializeTimeZones();
  try {
    final deviceZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceZone.identifier));
  } catch (_) {
    // The framework defaults to UTC only if the device's zone is unavailable.
  }
}

Future<void>? _timeZoneReady;
Future<void> _ensureDeviceTimeZone() =>
    _timeZoneReady ??= _configureDeviceTimeZone();

Future<void> _refreshDeviceTimeZone() {
  final refresh = _configureDeviceTimeZone();
  _timeZoneReady = refresh;
  return refresh;
}

class HearthioApp extends StatelessWidget {
  const HearthioApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '家务志 · Hearthio',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _indigo,
        brightness: Brightness.light,
        surface: _paper,
      ),
      scaffoldBackgroundColor: _canvas,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: _canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: _ink),
      ),
      cardTheme: const CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: _muted),
        hintStyle: const TextStyle(color: Color(0xFF9AA6A0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE6EBE4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _indigo, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _indigo,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: const BorderSide(color: Color(0xFFDCE5DC)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    ),
    builder: (context, child) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child ?? const SizedBox.shrink(),
    ),
    home: const AppEntry(),
  );
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _onboardingSeen;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    } catch (_) {
      _onboardingSeen = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);
    } catch (_) {
      // The walkthrough can safely be shown again if local storage is absent.
    }
    if (mounted) setState(() => _onboardingSeen = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingSeen == null) {
      return const Scaffold(backgroundColor: _canvas);
    }
    return _onboardingSeen!
        ? const HomePage()
        : OnboardingPage(onFinished: _finishOnboarding);
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});
  final Future<void> Function() onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  static const _pages = [
    (
      image: 'assets/onboarding/archive.png',
      title: '先给家里的物品建档',
      body: '添加名称、位置和保养周期，随时找到每一件物品。',
    ),
    (
      image: 'assets/onboarding/proof.png',
      title: '拍下凭证，留住细节',
      body: '拍摄或选择说明书、保修卡和维修照片，都只保存在本机。',
    ),
    (
      image: 'assets/onboarding/calendar.png',
      title: '日历提醒，按时照料',
      body: '在保养日程中查看待办，到期前可收到本机提醒。',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == _pages.length - 1) {
      await widget.onFinished();
    } else {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _canvas,
    body: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onFinished,
              child: const Text('跳过', style: TextStyle(color: _muted)),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: RepaintBoundary(
                          child: Image.asset(
                            page.image,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.low,
                            cacheWidth: 1000,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 26,
                          letterSpacing: -.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        page.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _muted,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
            child: Row(
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: _page == index ? 23 : 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _page == index
                            ? _indigo
                            : const Color(0xFFC9D4CB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _next,
                  child: Text(_page == _pages.length - 1 ? '开始整理' : '下一步'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class BreezeSurface extends StatelessWidget {
  const BreezeSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? _paper,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE7ECE5)),
    ),
    child: child,
  );
}

class BreezeHeader extends StatelessWidget {
  const BreezeHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class AppBottomDock extends StatelessWidget {
  const AppBottomDock({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final int selected;
  final ValueChanged<int> onSelect;
  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, '首页'),
    (Icons.grid_view_rounded, Icons.inventory_2_rounded, '物品'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, '日程'),
    (Icons.auto_graph_rounded, Icons.auto_graph_rounded, '报告'),
    (Icons.tune_rounded, Icons.tune_rounded, '设置'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE2E9E1)),
      ),
      child: Row(
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final active = selected == index;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: () => onSelect(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: active ? _mist : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? item.$2 : item.$1,
                        size: 20,
                        color: active ? _indigo : _muted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: active ? _indigo : _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

class AddItemButton extends StatelessWidget {
  const AddItemButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _indigo,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white),
            SizedBox(width: 7),
            Text(
              '添加物品',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tone = _indigo,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final effectiveTone = enabled ? tone : _muted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: effectiveTone.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: effectiveTone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? _ink : _muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: enabled ? _muted : _muted.withValues(alpha: .45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhotoSourceRow extends StatelessWidget {
  const PhotoSourceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.source,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final ImageSource source;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pop(context, source),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _mist,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: _indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: _muted,
              size: 15,
            ),
          ],
        ),
      ),
    ),
  );
}

enum NotificationAccess { notDetermined, enabled, denied, unavailable }

typedef CareNotificationScheduler =
    Future<void> Function(CareItem item, CareItem? previous);
typedef CareBackupPicker = Future<String?> Function();
typedef CareDocumentsDirectoryProvider = Future<Directory> Function();

Future<String?> _pickCareBackup() async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['zip'],
  );
  return picked?.files.single.path;
}

int notificationIdForPlan(String itemId, String planId) {
  var hash = 0x811C9DC5;
  // Length-prefix both components so identities such as ("a:b", "c") and
  // ("a", "b:c") can never collapse into the same pre-hash input.
  final identity = '${itemId.length}:$itemId${planId.length}:$planId';
  for (final codeUnit in identity.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  final value = hash & 0x7FFFFFFF;
  return value == 0 ? 1 : value;
}

int _care002NotificationIdForPlan(String itemId, String planId) {
  var hash = 0x811C9DC5;
  for (final codeUnit in '$itemId:$planId'.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  final value = hash & 0x7FFFFFFF;
  return value == 0 ? 1 : value;
}

NotificationAccess notificationAccessFrom({
  required bool notificationsEnabled,
  required bool permissionPrompted,
}) {
  if (notificationsEnabled) return NotificationAccess.enabled;
  return permissionPrompted
      ? NotificationAccess.denied
      : NotificationAccess.notDetermined;
}

Future<bool> _showNotificationPrimer(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('开启保养提醒？'),
        content: const Text(
          '开启后，家务志会按每个计划设置的提前天数发送本地通知。\n\n不授权不会影响物品和保养计划保存，你也可以稍后在“设置”中开启。',
          style: TextStyle(height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('暂不开启'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('开启通知'),
          ),
        ],
      ),
    ) ??
    false;

String _date(DateTime? date) =>
    date == null ? '未设置' : '${date.year}年${date.month}月${date.day}日';

String? _nonNegativeNumber(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final number = double.tryParse(text);
  if (number == null || !number.isFinite || number < 0) {
    return '请输入大于或等于 0 的金额';
  }
  return null;
}

Future<void> _deferMaintenanceTask(
  BuildContext context,
  CareStore store,
  MaintenanceTask task,
) async {
  final today = maintenanceDateOnly(DateTime.now());
  final tomorrow = addMaintenanceDays(today, 1);
  final deferredUntil = await showModalBottomSheet<DateTime>(
    context: context,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '稍后提醒',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              '${task.item.name} · ${task.plan.title}\n原到期日 ${_date(task.dueDate)}，稍后提醒不会改变真实到期状态。',
              style: const TextStyle(color: _muted, height: 1.45),
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('defer-until-tomorrow'),
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('明天'),
              subtitle: Text(_date(tomorrow)),
              onTap: () => Navigator.pop(sheet, tomorrow),
            ),
            ListTile(
              key: const Key('defer-until-three-days'),
              leading: const Icon(Icons.calendar_view_day_outlined),
              title: const Text('3 天后'),
              subtitle: Text(_date(addMaintenanceDays(today, 3))),
              onTap: () => Navigator.pop(sheet, addMaintenanceDays(today, 3)),
            ),
            ListTile(
              key: const Key('defer-until-next-week'),
              leading: const Icon(Icons.date_range_outlined),
              title: const Text('下周'),
              subtitle: Text(_date(addMaintenanceDays(today, 7))),
              onTap: () => Navigator.pop(sheet, addMaintenanceDays(today, 7)),
            ),
            ListTile(
              key: const Key('defer-until-custom'),
              leading: const Icon(Icons.edit_calendar_outlined),
              title: const Text('自定义日期'),
              onTap: () async {
                final selected = await showDatePicker(
                  context: sheet,
                  initialDate: tomorrow,
                  firstDate: tomorrow,
                  lastDate: DateTime(2100, 12, 31),
                );
                if (selected != null && sheet.mounted) {
                  Navigator.pop(sheet, selected);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
  if (deferredUntil == null || !context.mounted) return;
  try {
    await store.deferPlan(task.item, task.plan.id, deferredUntil);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('稍后提醒设置失败，请重试。')));
    }
  }
}

Future<bool?> _startMaintenanceTask(
  BuildContext context,
  MaintenanceExecutionController controller,
  MaintenanceTask task, {
  bool openLifecycleAfterCompletion = true,
}) async {
  final completed = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          MaintenanceExecutionPage(controller: controller, task: task),
    ),
  );
  if (completed != true ||
      !openLifecycleAfterCompletion ||
      controller is! CareStore ||
      !context.mounted) {
    return completed;
  }
  CareItem? latestItem;
  for (final item in controller.items) {
    if (item.id == task.item.id) {
      latestItem = item;
      break;
    }
  }
  if (latestItem == null || !context.mounted) return completed;
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => DetailPage(store: controller, item: latestItem!),
    ),
  );
  return completed;
}

class CareStore extends ChangeNotifier
    implements MaintenanceExecutionController, MaintenanceHistoryController {
  static const _exampleItemId = 'sample-filter';
  static const _examplePlanId = 'sample-filter-plan';

  CareStore({
    CareRepository? repository,
    CareNotificationScheduler? notificationScheduler,
    CareBackupPicker? backupPicker,
    CareDocumentsDirectoryProvider? documentsDirectoryProvider,
  }) : _repository = repository,
       _notificationScheduler = notificationScheduler,
       _backupPicker = backupPicker ?? _pickCareBackup,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final _notifications = FlutterLocalNotificationsPlugin();
  Future<void>? _notificationsReady;
  Future<void> _notificationMutationTail = Future.value();
  Future<void> _persistenceTail = Future.value();
  CareRepository? _repository;
  final CareNotificationScheduler? _notificationScheduler;
  final CareBackupPicker _backupPicker;
  final CareDocumentsDirectoryProvider _documentsDirectoryProvider;
  final Map<String, Future<MaintenanceCompletionResult>> _completionOperations =
      {};
  Future<bool>? _restoreOperation;
  final List<String> _pendingNotificationPayloads = [];
  Future<void> _dataMutationTail = Future.value();
  bool _writesBlocked = false;
  List<CareItem> items = [];
  bool loaded = false;
  String? loadError;

  bool get isDataReadOnly => _writesBlocked;
  bool get isRestoringBackup => _restoreOperation != null;

  bool get hasPendingNotificationNavigation =>
      _pendingNotificationPayloads.isNotEmpty;

  void handleNotificationPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;
    _pendingNotificationPayloads.add(payload);
    notifyListeners();
  }

  MaintenanceNotificationResolution? takeNotificationNavigation() {
    if (!loaded || _pendingNotificationPayloads.isEmpty) return null;
    final payload = _pendingNotificationPayloads.removeAt(0);
    return resolveMaintenanceNotification(payload, items);
  }

  void dismissLoadError() {
    if (loadError == null) return;
    loadError = null;
    notifyListeners();
  }

  Future<CareRepository> _openRepository() async =>
      _repository ??= await CareRepository.open();

  Future<void> _ensureNotificationsReady() =>
      _notificationsReady ??= _initializeNotifications().catchError((_) {});

  Future<void> load() async {
    try {
      final repository = await _openRepository();
      final result = await repository.load(initialItems: [_newExampleItem()]);
      items = [...result.items];
      loadError = null;
      _writesBlocked = false;
      final replacedExamples = _replaceLegacyExamples();
      final normalizedFacts = _normalizeMaintenanceFactsIn(items);
      if (replacedExamples || normalizedFacts) await _persist();
    } catch (_) {
      // Keep the app usable while making it explicit that the unreadable
      // snapshot was preserved and must not be replaced by an empty list.
      items = [];
      loadError = '本地档案读取失败，原数据仍保留在设备上，当前编辑已暂停。请勿卸载应用，可重启或从有效备份恢复。';
      _writesBlocked = true;
    }
    loaded = true;
    notifyListeners();
    if (!_writesBlocked) {
      // Upgrades can replace one legacy reminder with several plan-specific
      // reminders. Refresh silently only when access already exists; loading
      // data must never trigger the system permission prompt.
      unawaited(_rescheduleRemindersIfAuthorized());
    }
  }

  Future<void> save(CareItem item) => _serializeDataMutation(() => _save(item));

  Future<void> _save(CareItem item) async {
    _ensureWritable();
    final nextItems = [...items];
    final index = nextItems.indexWhere((entry) => entry.id == item.id);
    CareItem? previous;
    final removedPhotos = <String>[];
    if (index == -1) {
      nextItems.add(item);
    } else {
      previous = nextItems[index];
      final nextPhotos = _photoPathsForItem(item).toSet();
      removedPhotos.addAll(
        _photoPathsForItem(
          previous,
        ).where((path) => !nextPhotos.contains(path)),
      );
      nextItems[index] = item;
    }
    await _writeItems(nextItems);
    items = nextItems;
    notifyListeners();
    _deleteUnreferencedPhotos(removedPhotos, retainedBy: nextItems);
    // A notification failure must never turn a persisted edit into failure.
    unawaited(_scheduleSafely(item, previous: previous));
  }

  void _ensureWritable() {
    if (_writesBlocked) {
      throw const FileSystemException(
        'Care data is read-only after load failure',
      );
    }
  }

  Future<void> _writeItems(List<CareItem> nextItems) {
    final snapshot = CareDataEnvelope(items: nextItems).encode();
    final write = _persistenceTail.then((_) async {
      final repository = await _openRepository();
      await repository.writeEncodedSnapshot(snapshot);
    });
    _persistenceTail = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return write;
  }

  Future<void> _deletePhoto(String path) async {
    try {
      await File(path).delete();
    } catch (_) {
      /* no-op */
    }
  }

  Future<void> remove(CareItem item) =>
      _serializeDataMutation(() => _remove(item.id));

  Future<void> _remove(String itemId) async {
    _ensureWritable();
    final index = items.indexWhere((entry) => entry.id == itemId);
    if (index == -1) return;
    final removed = items[index];
    final nextItems = [...items]..removeAt(index);
    await _writeItems(nextItems);
    items = nextItems;
    notifyListeners();
    _deleteUnreferencedPhotos(
      _photoPathsForItem(removed),
      retainedBy: nextItems,
    );
    unawaited(_cancelItemNotificationsSafely(removed));
  }

  bool get hasExampleData => items.any((item) => item.isSample);

  Future<bool> shouldOfferNotificationPrimer() async {
    if (await notificationAccess() != NotificationAccess.notDetermined) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('notification_primer_seen') ?? false);
  }

  Future<void> markNotificationPrimerSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_primer_seen', true);
  }

  Future<void> deleteExampleData() =>
      _serializeDataMutation(_deleteExampleData);

  Future<void> _deleteExampleData() async {
    _ensureWritable();
    final examples = items.where((item) => item.isSample).toList();
    if (examples.isEmpty) return;
    final nextItems = items.where((item) => !item.isSample).toList();
    await _writeItems(nextItems);
    items = nextItems;
    notifyListeners();
    for (final item in examples) {
      _deleteUnreferencedPhotos(
        _photoPathsForItem(item),
        retainedBy: nextItems,
      );
      unawaited(_cancelItemNotificationsSafely(item));
    }
  }

  Future<void> resetExampleData() => _serializeDataMutation(_resetExampleData);

  Future<void> _resetExampleData() async {
    _ensureWritable();
    final examples = items.where((item) => item.isSample).toList();
    final replacement = _newExampleItem();
    final nextItems = items.where((item) => !item.isSample).toList()
      ..insert(0, replacement);
    await _writeItems(nextItems);
    items = nextItems;
    notifyListeners();
    for (final item in examples) {
      _deleteUnreferencedPhotos(
        _photoPathsForItem(item),
        retainedBy: nextItems,
      );
      unawaited(_cancelItemNotificationsSafely(item));
    }
    await _scheduleSafely(replacement);
  }

  Future<void> addRecord(CareItem item, MaintenanceRecord record) {
    final records = [...item.records, record]
      ..sort((a, b) => b.date.compareTo(a.date));
    final planIndex = item.plans.indexWhere((plan) => plan.id == record.planId);
    if (planIndex == -1) {
      return save(item.copyWith(records: records));
    }
    final plans = [...item.plans];
    plans[planIndex] = plans[planIndex].completedAt(record.date);
    return save(item.copyWith(records: records, plans: plans));
  }

  @override
  Future<CareItem> updateMaintenanceRecord(
    String itemId,
    MaintenanceRecord record,
  ) => _serializeDataMutation(() => _updateMaintenanceRecord(itemId, record));

  Future<CareItem> _updateMaintenanceRecord(
    String itemId,
    MaintenanceRecord record,
  ) async {
    final itemIndex = items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      throw const MaintenanceHistoryException('找不到这件物品，记录未修改。');
    }
    final current = items[itemIndex];
    final recordIndex = current.records.indexWhere(
      (candidate) => candidate.id == record.id,
    );
    if (recordIndex == -1) {
      throw const MaintenanceHistoryException('这条维护记录已不存在。');
    }
    final previousRecord = current.records[recordIndex];
    if (record.planId != previousRecord.planId) {
      throw const MaintenanceHistoryException('维护记录不能改到其他保养计划。');
    }
    final normalized = record.copyWith(
      completedAt: maintenanceDateOnly(record.completedAt),
      materialName: record.materialName.trim(),
      note: record.note.trim(),
      kind: previousRecord.kind,
    );
    _validateHistoryRecord(normalized);
    final records = [...current.records]..[recordIndex] = normalized;
    _sortMaintenanceRecords(records);
    final changed = recalculateMaintenancePlanFromRecords(
      current.copyWith(records: records),
      previousRecord.planId,
    );
    final removedPhotos = previousRecord.photos
        .where((path) => !normalized.photos.contains(path))
        .toList(growable: false);
    return _persistMaintenanceHistoryChange(
      itemIndex: itemIndex,
      previous: current,
      changed: changed,
      affectedPlanId: previousRecord.planId,
      removedPhotos: removedPhotos,
    );
  }

  @override
  Future<CareItem> deleteMaintenanceRecord(String itemId, String recordId) =>
      _serializeDataMutation(() => _deleteMaintenanceRecord(itemId, recordId));

  Future<CareItem> _deleteMaintenanceRecord(
    String itemId,
    String recordId,
  ) async {
    final itemIndex = items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      throw const MaintenanceHistoryException('找不到这件物品，记录未删除。');
    }
    final current = items[itemIndex];
    final recordIndex = current.records.indexWhere(
      (record) => record.id == recordId,
    );
    if (recordIndex == -1) {
      throw const MaintenanceHistoryException('这条维护记录已不存在。');
    }
    final removed = current.records[recordIndex];
    final records = [...current.records]..removeAt(recordIndex);
    _sortMaintenanceRecords(records);
    final changed = recalculateMaintenancePlanFromRecords(
      current.copyWith(records: records),
      removed.planId,
      fallbackDueDate: removed.plannedDueDate,
    );
    return _persistMaintenanceHistoryChange(
      itemIndex: itemIndex,
      previous: current,
      changed: changed,
      affectedPlanId: removed.planId,
      removedPhotos: removed.photos,
    );
  }

  Future<CareItem> _persistMaintenanceHistoryChange({
    required int itemIndex,
    required CareItem previous,
    required CareItem changed,
    required String? affectedPlanId,
    required Iterable<String> removedPhotos,
  }) async {
    if (_writesBlocked) {
      throw const MaintenanceHistoryException('本地档案当前为只读状态，无法修改维护记录。');
    }
    final nextItems = [...items]..[itemIndex] = changed;
    try {
      await _writeItems(nextItems);
    } catch (_) {
      throw const MaintenanceHistoryException('维护记录保存失败，原数据未改变，请重试。');
    }

    items = nextItems;
    notifyListeners();
    _deleteUnreferencedPhotos(removedPhotos, retainedBy: nextItems);
    if (affectedPlanId != null) {
      await _tryScheduleCompletion(changed, previous: previous);
    }
    return changed;
  }

  void _validateHistoryRecord(MaintenanceRecord record) {
    if (record.id.trim().isEmpty || record.id.length > 180) {
      throw const MaintenanceHistoryException('维护记录标识无效。');
    }
    if (!record.cost.isFinite || record.cost < 0) {
      throw const MaintenanceHistoryException('维护费用必须为大于或等于 0 的有限数。');
    }
    final completedAt = maintenanceDateOnly(record.completedAt);
    final today = maintenanceDateOnly(DateTime.now());
    if (completedAt.isBefore(DateTime(2000)) || completedAt.isAfter(today)) {
      throw const MaintenanceHistoryException('完成日期需在 2000 年至今天之间。');
    }
  }

  void _sortMaintenanceRecords(List<MaintenanceRecord> records) {
    records.sort((a, b) {
      final dateOrder = b.completedAt.compareTo(a.completedAt);
      if (dateOrder != 0) return dateOrder;
      return a.id.compareTo(b.id);
    });
  }

  @override
  Future<MaintenanceCompletionResult> completeMaintenance(
    MaintenanceCompletionDraft draft,
  ) {
    final operationKey = '${draft.itemId}:${draft.planId}:${draft.operationId}';
    final running = _completionOperations[operationKey];
    if (running != null) return running;
    final future = _serializeDataMutation(() => _completeMaintenance(draft));
    _completionOperations[operationKey] = future;
    future.then<void>(
      (_) {
        if (identical(_completionOperations[operationKey], future)) {
          _completionOperations.remove(operationKey);
        }
      },
      onError: (Object _, StackTrace __) {
        if (identical(_completionOperations[operationKey], future)) {
          _completionOperations.remove(operationKey);
        }
      },
    );
    return future;
  }

  Future<T> _serializeDataMutation<T>(Future<T> Function() operation) {
    final result = _dataMutationTail.then((_) => operation());
    _dataMutationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<MaintenanceCompletionResult> _completeMaintenance(
    MaintenanceCompletionDraft draft,
  ) async {
    if (_writesBlocked) {
      throw const MaintenanceCompletionException('本地档案当前为只读状态，无法完成保养。');
    }
    final itemIndex = items.indexWhere((item) => item.id == draft.itemId);
    if (itemIndex == -1) {
      throw const MaintenanceCompletionException('找不到需要保养的物品。');
    }
    final current = items[itemIndex];
    final planIndex = current.plans.indexWhere(
      (plan) => plan.id == draft.planId,
    );
    if (planIndex == -1 ||
        current.plans[planIndex].archived ||
        !current.plans[planIndex].enabled) {
      throw const MaintenanceCompletionException('保养计划已不存在或已归档。');
    }
    final plan = current.plans[planIndex];
    final existingIndex = current.records.indexWhere(
      (record) => record.id == draft.recordId,
    );
    if (existingIndex != -1) {
      final notificationScheduled = await _tryScheduleCompletion(current);
      return MaintenanceCompletionResult(
        item: current,
        plan: plan,
        record: current.records[existingIndex],
        notificationScheduled: notificationScheduled,
        alreadyCompleted: true,
      );
    }

    validateMaintenanceCompletion(draft, plan);
    final completedPlan = plan.completedAt(draft.completedAt);
    final record = MaintenanceRecord(
      id: draft.recordId,
      planId: plan.id,
      completedAt: draft.completedAt,
      plannedDueDate: plan.dueDate,
      kind: plan.title,
      cost: draft.cost,
      materialName: draft.materialName.trim(),
      note: draft.note.trim(),
      completedStepIds: draft.completedStepIds,
      stepSnapshots: captureMaintenanceStepSnapshots(
        plan,
        draft.completedStepIds,
      ),
      beforePhotos: draft.beforePhotos,
      afterPhotos: draft.afterPhotos,
    );
    final plans = [...current.plans]..[planIndex] = completedPlan;
    final records = [...current.records, record]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final completedItem = current.copyWith(plans: plans, records: records);
    final nextItems = [...items]..[itemIndex] = completedItem;

    try {
      await _writeItems(nextItems);
    } catch (_) {
      throw const MaintenanceCompletionException('本次保养保存失败，数据未更新。请检查设备存储后重试。');
    }

    items = nextItems;
    notifyListeners();
    final notificationScheduled = await _tryScheduleCompletion(
      completedItem,
      previous: current,
    );
    return MaintenanceCompletionResult(
      item: completedItem,
      plan: completedPlan,
      record: record,
      notificationScheduled: notificationScheduled,
    );
  }

  Future<bool> _tryScheduleCompletion(
    CareItem item, {
    CareItem? previous,
  }) async {
    try {
      if (_notificationScheduler == null &&
          await notificationAccess() != NotificationAccess.enabled) {
        return false;
      }
      await _serializeNotificationMutation(
        () => _scheduleItem(item, previous: previous),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deferPlan(
    CareItem item,
    String planId,
    DateTime deferredUntil,
  ) => _serializeDataMutation(() => _deferPlan(item.id, planId, deferredUntil));

  Future<void> _deferPlan(
    String itemId,
    String planId,
    DateTime deferredUntil,
  ) {
    final targetDate = maintenanceDateOnly(deferredUntil);
    final today = maintenanceDateOnly(DateTime.now());
    if (!targetDate.isAfter(today)) {
      throw ArgumentError.value(
        deferredUntil,
        'deferredUntil',
        'Reminder deferral must be after today',
      );
    }
    final itemIndex = items.indexWhere((entry) => entry.id == itemId);
    if (itemIndex == -1) {
      throw StateError('Cannot defer a plan for an unknown item');
    }
    final current = items[itemIndex];
    final planIndex = current.plans.indexWhere((plan) => plan.id == planId);
    if (planIndex == -1) {
      throw StateError('Cannot defer an unknown maintenance plan');
    }
    final plans = [...current.plans];
    plans[planIndex] = plans[planIndex].deferredTo(targetDate);
    return _save(current.copyWith(plans: plans));
  }

  @override
  Future<PhotoImportResult> importPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );
      // A null result means the user dismissed the system picker. It is not a
      // permission failure and must not show an alarming error message.
      if (picked == null) return const PhotoImportResult.cancelled();
      final root = await getApplicationDocumentsDirectory();
      final folder = Directory('${root.path}/item-photos');
      await folder.create(recursive: true);
      final target = File(
        '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await File(picked.path).copy(target.path);
      return PhotoImportResult.success(target.path);
    } catch (_) {
      return const PhotoImportResult.failed();
    }
  }

  @override
  Future<void> discardImportedPhoto(String path) => _deletePhoto(path);

  Future<void> exportCSV(BuildContext context) async {
    String cell(String text) => '"${text.replaceAll('"', '""')}"';
    final rows = <String>[
      '名称,类别,位置,品牌,型号,购买日期,保修截止,下次保养,购买价,当前估值,维护记录数,累计维护费用,备注',
    ];
    for (final item in items) {
      rows.add(
        [
          item.name,
          item.category,
          item.location,
          item.brand,
          item.model,
          _date(item.purchaseDate),
          _date(item.warrantyDate),
          _date(item.nextCareDate),
          item.purchasePrice?.toStringAsFixed(2) ?? '',
          item.currentValue?.toStringAsFixed(2) ?? '',
          item.records.length.toString(),
          item.records
              .fold<double>(0, (sum, record) => sum + record.cost)
              .toStringAsFixed(2),
          item.notes,
        ].map(cell).join(','),
      );
    }
    // iOS's share sheet can fail to resolve non-ASCII cache URLs on some
    // devices. Keep the temporary export in Documents with a stable ASCII
    // name; the share-sheet title remains localized for the user.
    final root = await getApplicationDocumentsDirectory();
    final exports = Directory('${root.path}/exports');
    await exports.create(recursive: true);
    final file = File('${exports.path}/hearthio-export.csv');
    await file.writeAsString('\uFEFF${rows.join('\n')}');
    if (context.mounted) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], title: '家庭物品保养册数据导出'),
      );
    }
  }

  Future<void> exportBackup(BuildContext context) async {
    try {
      final photoBytes = <String, List<int>>{};
      for (final path in _allPhotoPaths()) {
        final file = File(path);
        if (await file.exists()) photoBytes[path] = await file.readAsBytes();
      }
      final bytes = CareBackupCodec.encode(
        items: items,
        photoBytesByPath: photoBytes,
      );
      final file = File(
        '${(await getTemporaryDirectory()).path}/Hearthio-backup.zip',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (context.mounted) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], title: 'Hearthio backup'),
        );
      }
    } on CareBackupException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('完整备份未导出：${error.message}')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('完整备份未导出，请检查设备存储后重试。')));
      }
    }
  }

  Future<bool> needsRestoreGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool('restore_backup_guide_seen') ?? false);
    } catch (_) {
      // Showing the guide again is always safer than skipping it.
      return true;
    }
  }

  Future<void> markRestoreGuideSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('restore_backup_guide_seen', true);
    } catch (_) {
      /* guide will be shown again next time */
    }
  }

  Future<bool> restoreBackup() {
    final running = _restoreOperation;
    if (running != null) return running;

    final completer = Completer<bool>();
    final future = completer.future;
    _restoreOperation = future;
    notifyListeners();
    Future<bool>.sync(_restoreBackup).then<void>(
      (value) {
        completer.complete(value);
        _finishRestoreOperation(future);
      },
      onError: (Object error, StackTrace stackTrace) {
        completer.completeError(error, stackTrace);
        _finishRestoreOperation(future);
      },
    );
    return future;
  }

  void _finishRestoreOperation(Future<bool> future) {
    if (!identical(_restoreOperation, future)) return;
    _restoreOperation = null;
    notifyListeners();
  }

  Future<bool> _restoreBackup() async {
    Directory? stagedImages;
    var restoreCommitted = false;
    try {
      final source = await _backupPicker();
      if (source == null) return false;
      final sourceFile = File(source);
      if (await sourceFile.length() > CareBackupCodec.maxArchiveBytes) {
        return false;
      }
      final decoded = CareBackupCodec.decode(await sourceFile.readAsBytes());
      final root = await _documentsDirectoryProvider();
      stagedImages = Directory(
        '${root.path}/item-photos/restore-${DateTime.now().microsecondsSinceEpoch}',
      );
      await stagedImages.create(recursive: true);
      final restoredPhotoPaths = <String, String>{};
      for (final entry in decoded.photos.entries) {
        final name = entry.key.substring('photos/'.length);
        final destination = File('${stagedImages.path}/$name');
        await destination.writeAsBytes(entry.value, flush: true);
        restoredPhotoPaths[entry.key] = destination.path;
      }
      final restored = decoded.items
          .map((item) => _withRestoredPhotoPaths(item, restoredPhotoPaths))
          .toList();
      _replaceLegacyExamplesIn(restored);
      _normalizeMaintenanceFactsIn(restored);
      await _deleteUnreferencedPhotosNow(
        restoredPhotoPaths.values,
        retainedBy: restored,
      );

      await _serializeDataMutation(() async {
        final previousItems = [...items];
        final previousPhotoPaths = <String>{
          for (final item in previousItems) ..._photoPathsForItem(item),
        };

        // Join the same ordered write path as every other data mutation. Only
        // publish the restored list after its complete snapshot is durable.
        await _writeItems(restored);
        items = restored;
        loadError = null;
        _writesBlocked = false;
        restoreCommitted = true;
        notifyListeners();

        await _deleteUnreferencedPhotosNow(
          previousPhotoPaths,
          retainedBy: restored,
        );
        for (final oldItem in previousItems) {
          unawaited(_cancelItemNotificationsSafely(oldItem));
        }
        for (final item in restored) {
          unawaited(_scheduleSafely(item));
        }
      });
      return true;
    } catch (_) {
      if (restoreCommitted) return true;
      if (stagedImages != null) {
        await _deleteDirectorySafely(stagedImages);
      }
      return false;
    }
  }

  Future<NotificationAccess> notificationAccess() async {
    try {
      await _ensureNotificationsReady();
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios == null) return NotificationAccess.unavailable;
      final permissions = await ios.checkPermissions();
      final prefs = await SharedPreferences.getInstance();
      return notificationAccessFrom(
        notificationsEnabled:
            permissions?.isAlertEnabled == true ||
            permissions?.isProvisionalEnabled == true,
        permissionPrompted:
            prefs.getBool('notification_permission_prompted') ?? false,
      );
    } catch (_) {
      return NotificationAccess.unavailable;
    }
  }

  Future<NotificationAccess> requestNotifications() async {
    try {
      final before = await notificationAccess();
      if (before == NotificationAccess.enabled) {
        _scheduleAllReminders();
        return before;
      }
      if (before == NotificationAccess.denied) return before;
      await _ensureNotificationsReady();
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios == null) return NotificationAccess.unavailable;
      final granted = await ios.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_permission_prompted', true);
      final after = granted == true
          ? NotificationAccess.enabled
          : NotificationAccess.denied;
      if (after == NotificationAccess.enabled) {
        _scheduleAllReminders();
      }
      return after;
    } catch (_) {
      return NotificationAccess.unavailable;
    }
  }

  void _scheduleAllReminders() {
    for (final item in items) {
      unawaited(_scheduleSafely(item));
    }
  }

  Future<void> _rescheduleRemindersIfAuthorized() async {
    if (await notificationAccess() == NotificationAccess.enabled) {
      _scheduleAllReminders();
    }
  }

  Future<void> refreshRemindersForAppResume() async {
    try {
      await _serializeDataMutation(() async {
        final nextItems = [...items];
        if (!_normalizeMaintenanceFactsIn(nextItems)) return;
        await _writeItems(nextItems);
        items = nextItems;
        notifyListeners();
      });
    } catch (_) {
      // Scheduling still ignores expired deferrals even when disk cleanup has
      // to wait for a later successful write.
    }
    await _refreshDeviceTimeZone();
    await _rescheduleRemindersIfAuthorized();
  }

  Future<bool> sendTestNotification() async {
    try {
      if (await notificationAccess() != NotificationAccess.enabled) {
        return false;
      }
      await _ensureDeviceTimeZone();
      await _notifications.zonedSchedule(
        id: 900001,
        title: '家务志提醒已开启',
        body: '这是一条测试提醒。之后会按每个计划设置的提前天数通知你。',
        scheduledDate: tz.TZDateTime.now(
          tz.local,
        ).add(const Duration(seconds: 5)),
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
          android: AndroidNotificationDetails(
            'care_reminders',
            '保养提醒',
            channelDescription: '家庭物品保养提醒',
            importance: Importance.defaultImportance,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persist() async {
    final repository = await _openRepository();
    await repository.save(items);
  }

  Future<void> _initializeNotifications() async {
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        handleNotificationPayload(response.payload);
      },
    );
    try {
      final launchDetails = await _notifications
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        handleNotificationPayload(launchDetails?.notificationResponse?.payload);
      }
    } catch (_) {
      // Live notification taps remain available even if launch details cannot
      // be read on an unsupported platform.
    }
  }

  Future<void> _schedule(CareItem item, {CareItem? previous}) async {
    await _ensureNotificationsReady();
    await _ensureDeviceTimeZone();
    // Remove the pre-CARE-002 item-level notification and every previous plan
    // id before installing the current independent plan reminders.
    await _notifications.cancel(id: item.id.hashCode);
    for (final plan in previous?.plans ?? const <MaintenancePlan>[]) {
      await _notifications.cancel(id: notificationIdForPlan(item.id, plan.id));
      await _notifications.cancel(
        id: _care002NotificationIdForPlan(item.id, plan.id),
      );
    }
    for (final plan in item.plans) {
      await _notifications.cancel(id: notificationIdForPlan(item.id, plan.id));
      await _notifications.cancel(
        id: _care002NotificationIdForPlan(item.id, plan.id),
      );
    }
    for (final plan in item.plans.where(
      (plan) => plan.enabled && !plan.archived,
    )) {
      await _schedulePlan(item, plan);
    }
  }

  Future<void> _schedulePlan(CareItem item, MaintenancePlan plan) async {
    final due = plan.dueDate;
    final reminderDate = maintenanceReminderDateForPlan(plan);
    if (due == null || reminderDate == null) return;
    final now = tz.TZDateTime.now(tz.local);
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.dateOnly(due).isBefore(today) &&
        !DateUtils.dateOnly(reminderDate).isAfter(today)) {
      return;
    }

    final planned = tz.TZDateTime.from(
      DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9),
      tz.local,
    );
    // Do not silently skip an item which is already in its three-day window.
    // Scheduling a few seconds later makes the reminder useful immediately.
    final scheduled = planned.isAfter(now)
        ? planned
        : now.add(const Duration(seconds: 5));
    await _notifications.zonedSchedule(
      id: notificationIdForPlan(item.id, plan.id),
      title: plan.title,
      body: '${item.name} · ${_date(due)} 到期，记得安排处理。',
      payload: MaintenanceNotificationPayload(
        itemId: item.id,
        planId: plan.id,
      ).encode(),
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _scheduleSafely(CareItem item, {CareItem? previous}) async {
    try {
      await _serializeNotificationMutation(
        () => _scheduleItem(item, previous: previous),
      );
    } catch (_) {
      /* saving remains available offline */
    }
  }

  Future<void> _serializeNotificationMutation(
    Future<void> Function() operation,
  ) {
    final result = _notificationMutationTail.then((_) => operation());
    _notificationMutationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<void> _scheduleItem(CareItem item, {CareItem? previous}) {
    final override = _notificationScheduler;
    return override == null
        ? _schedule(item, previous: previous)
        : override(item, previous);
  }

  Future<void> _cancelItemNotificationsSafely(CareItem item) async {
    try {
      await _serializeNotificationMutation(() async {
        await _ensureNotificationsReady();
        await _notifications.cancel(id: item.id.hashCode);
        for (final plan in item.plans) {
          await _notifications.cancel(
            id: notificationIdForPlan(item.id, plan.id),
          );
          await _notifications.cancel(
            id: _care002NotificationIdForPlan(item.id, plan.id),
          );
        }
      });
    } catch (_) {
      /* notification state never blocks item changes */
    }
  }

  Iterable<String> _allPhotoPaths() sync* {
    final seen = <String>{};
    for (final item in items) {
      for (final path in item.photos) {
        if (seen.add(path)) yield path;
      }
      for (final record in item.records) {
        for (final path in record.photos) {
          if (seen.add(path)) yield path;
        }
      }
    }
  }

  Iterable<String> _photoPathsForItem(CareItem item) sync* {
    yield* item.photos;
    for (final record in item.records) {
      yield* record.photos;
    }
  }

  void _deleteUnreferencedPhotos(
    Iterable<String> candidates, {
    required Iterable<CareItem> retainedBy,
  }) {
    final retainedPhotoPaths = <String>{
      for (final item in retainedBy) ..._photoPathsForItem(item),
    };
    for (final path in candidates.toSet()) {
      if (!retainedPhotoPaths.contains(path)) {
        unawaited(_deletePhoto(path));
      }
    }
  }

  Future<void> _deleteUnreferencedPhotosNow(
    Iterable<String> candidates, {
    required Iterable<CareItem> retainedBy,
  }) async {
    final retainedPhotoPaths = <String>{
      for (final item in retainedBy) ..._photoPathsForItem(item),
    };
    final emptyDirectoryCandidates = <String>{};
    for (final path in candidates.toSet()) {
      if (retainedPhotoPaths.contains(path)) continue;
      emptyDirectoryCandidates.add(File(path).parent.path);
      await _deletePhoto(path);
    }
    for (final path in emptyDirectoryCandidates) {
      final directory = Directory(path);
      final normalized = path.replaceAll('\\', '/');
      if (!normalized.split('/').last.startsWith('restore-')) continue;
      try {
        if (await directory.exists() &&
            await directory.list(followLinks: false).isEmpty) {
          await directory.delete();
        }
      } catch (_) {
        /* best-effort cleanup after a durable restore */
      }
    }
  }

  Future<void> _deleteDirectorySafely(Directory directory) async {
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (_) {
      /* a failed cleanup must not hide the restore result */
    }
  }

  CareItem _withRestoredPhotoPaths(
    CareItem item,
    Map<String, String> restoredPhotoPaths,
  ) => item.copyWith(
    photos: item.photos
        .where(restoredPhotoPaths.containsKey)
        .map((path) => restoredPhotoPaths[path]!)
        .toList(growable: false),
    records: item.records
        .map(
          (record) => record.copyWith(
            beforePhotos: record.beforePhotos
                .where(restoredPhotoPaths.containsKey)
                .map((path) => restoredPhotoPaths[path]!)
                .toList(growable: false),
            afterPhotos: record.afterPhotos
                .where(restoredPhotoPaths.containsKey)
                .map((path) => restoredPhotoPaths[path]!)
                .toList(growable: false),
          ),
        )
        .toList(growable: false),
  );

  bool _replaceLegacyExamples() => _replaceLegacyExamplesIn(items);

  bool _normalizeMaintenanceFactsIn(List<CareItem> target) {
    var changed = false;
    final today = maintenanceDateOnly(DateTime.now());
    for (var index = 0; index < target.length; index++) {
      var item = freezeMaintenanceHistorySnapshots(target[index]);
      final plans = item.plans
          .map((plan) => clearExpiredMaintenanceDeferral(plan, now: today))
          .toList(growable: false);
      final plansChanged = List.generate(
        plans.length,
        (planIndex) => !identical(plans[planIndex], item.plans[planIndex]),
      ).any((value) => value);
      if (plansChanged) item = item.copyWith(plans: plans);
      if (!identical(item, target[index])) {
        target[index] = item;
        changed = true;
      }
    }
    return changed;
  }

  bool _replaceLegacyExamplesIn(List<CareItem> target) {
    final firstLegacyIndex = target.indexWhere(_shouldReplaceLegacyExample);
    if (firstLegacyIndex == -1) return false;
    final hasPreservedExample = target.any(
      (item) =>
          item.id == _exampleItemId &&
          item.isSample &&
          !_shouldReplaceLegacyExample(item),
    );
    target.removeWhere(_shouldReplaceLegacyExample);
    final insertIndex = firstLegacyIndex > target.length
        ? target.length
        : firstLegacyIndex;
    if (!hasPreservedExample) {
      target.insert(insertIndex, _newExampleItem());
    }
    return true;
  }

  static bool _shouldReplaceLegacyExample(CareItem item) {
    if (item.id == 'sample-ac') return true;
    if (item.id != _exampleItemId) return false;
    if (!item.isSample) return true;
    if (item.records.isNotEmpty) return false;
    return !item.plans.any((plan) => plan.id == _examplePlanId);
  }

  static CareItem _newExampleItem() {
    final today = maintenanceDateOnly(DateTime.now());
    final template = maintenanceTemplates.firstWhere(
      (candidate) => candidate.id == 'water-purifier-filter',
    );
    return CareItem(
      id: _exampleItemId,
      name: '示例 · 厨房净水器',
      category: '滤芯与耗材',
      location: '厨房',
      brand: '',
      model: '',
      notes: '这是可删除的示例数据：完成更换滤芯后，可以记录日期、型号和实际费用。',
      photos: const [],
      plans: [
        template.createPlan(
          planId: _examplePlanId,
          referenceDate: addMaintenanceDays(today, -template.intervalDays),
        ),
      ],
      isSample: true,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.store});

  final CareStore? store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final CareStore store;
  late final bool _ownsStore;
  bool _notificationNavigationScheduled = false;
  bool _notificationNavigationInFlight = false;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    store = widget.store ?? CareStore();
    _ownsStore = widget.store == null;
    WidgetsBinding.instance.addObserver(this);
    if (!store.loaded) unawaited(store.load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(store.refreshRemindersForAppResume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsStore) store.dispose();
    super.dispose();
  }

  void _scheduleNotificationNavigation() {
    if (!store.loaded ||
        !store.hasPendingNotificationNavigation ||
        _notificationNavigationScheduled ||
        _notificationNavigationInFlight) {
      return;
    }
    _notificationNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationNavigationScheduled = false;
      unawaited(_openPendingNotification());
    });
  }

  Future<void> _openPendingNotification() async {
    if (!mounted || _notificationNavigationInFlight) return;
    final resolution = store.takeNotificationNavigation();
    if (resolution == null) return;
    _notificationNavigationInFlight = true;
    try {
      final task = resolution.task;
      if (resolution.type == MaintenanceNotificationResolutionType.ready &&
          task != null) {
        await _startMaintenanceTask(context, store, task);
        return;
      }
      setState(() => tab = 2);
      final message = switch (resolution.type) {
        MaintenanceNotificationResolutionType.itemUnavailable =>
          '提醒对应的物品已删除，已返回待保养列表。',
        MaintenanceNotificationResolutionType.planUnavailable =>
          '提醒对应的保养计划已删除或停用，已返回待保养列表。',
        MaintenanceNotificationResolutionType.malformed =>
          '这条保养提醒已失效，已返回待保养列表。',
        MaintenanceNotificationResolutionType.ready => '',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      _notificationNavigationInFlight = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      _scheduleNotificationNavigation();
      final pages = [
        Dashboard(store: store),
        InventoryPage(store: store),
        SchedulePage(store: store),
        MaintenanceReportPage(items: store.items),
        SettingsPage(store: store),
      ];
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (store.loadError case final message?)
                MaterialBanner(
                  content: Text(message),
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.deepOrange,
                  ),
                  actions: [
                    TextButton(
                      onPressed: store.dismissLoadError,
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              Expanded(child: pages[tab]),
            ],
          ),
        ),
        floatingActionButton: tab < 2
            ? AddItemButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditorPage(store: store)),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: AppBottomDock(
          selected: tab,
          onSelect: (v) => setState(() => tab = v),
        ),
      );
    },
  );
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.store});
  final CareStore store;
  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final annualCost = store.items
        .expand((item) => item.records)
        .where((record) => record.date.year == year)
        .fold<double>(0, (sum, record) => sum + record.cost);
    final assetValue = store.items.fold<double>(
      0,
      (sum, item) => sum + (item.currentValue ?? item.purchasePrice ?? 0),
    );
    final rooms = <String, int>{};
    for (final item in store.items) {
      if (item.location.isNotEmpty) {
        rooms[item.location] = (rooms[item.location] ?? 0) + 1;
      }
    }
    final tasks = maintenanceTasksForItems(store.items);
    final attentionCount = tasks
        .where(
          (task) =>
              task.status.dueState == MaintenanceTaskState.overdue ||
              task.status.dueState == MaintenanceTaskState.dueToday ||
              task.status.dueState == MaintenanceTaskState.dueSoon,
        )
        .length;
    return CustomScrollView(
      // The dashboard cards are intentionally lightweight; avoid speculative
      // off-screen work during the very first user drag.
      cacheExtent: 0,
      slivers: [
        const SliverToBoxAdapter(
          child: RepaintBoundary(
            child: BreezeHeader(
              title: '家务志',
              subtitle: 'Hearthio · 安静整理家的每一件物品',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _stat('物品总数', '${store.items.length}', _indigo),
                      const SizedBox(width: 10),
                      _stat('待处理', '$attentionCount', _amber),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _indigo,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.spa_outlined,
                              color: Color(0xFFDBECDD),
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text(
                              '家庭资产估值',
                              style: TextStyle(color: Color(0xFFDBECDD)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '¥${assetValue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _stat(
                        '$year 年维护',
                        '¥${annualCost.toStringAsFixed(0)}',
                        const Color(0xFF3A7D70),
                      ),
                      const SizedBox(width: 10),
                      _stat(
                        '家庭空间 / Rooms',
                        '${rooms.length}',
                        const Color(0xFF875E9C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '待保养 · Maintenance tasks',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (tasks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: MaintenanceTaskEmptyState(
              onCreate: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditorPage(store: store)),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = tasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: MaintenanceTaskCard(
                    task: task,
                    onStart: () => _startMaintenanceTask(context, store, task),
                    onDefer: () => _deferMaintenanceTask(context, store, task),
                  ),
                );
              },
              childCount: tasks.length,
              addRepaintBoundaries: false,
              addAutomaticKeepAlives: false,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _stat(String title, String value, Color color) => Expanded(
    child: BreezeSurface(
      color: color.withValues(alpha: .10),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class MaintenanceTaskEmptyState extends StatelessWidget {
  const MaintenanceTaskEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: BreezeSurface(
      color: _paper,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: _mist,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              size: 30,
              color: _indigo,
            ),
          ),
          const SizedBox(height: 15),
          const Text('还没有保养计划', style: TextStyle(color: _muted)),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('create-first-maintenance-plan'),
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('建立首个计划'),
          ),
        ],
      ),
    ),
  );
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, required this.store});
  final CareStore store;
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.store.items
        .where(
          (item) =>
              item.name.contains(query) ||
              item.location.contains(query) ||
              item.category.contains(query),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BreezeHeader(title: '物品档案', subtitle: '按空间、类别或名称快速找到它'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => query = v.trim()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: _indigo),
                    hintText: '搜索物品、位置或类别',
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  text: '没有找到物品',
                )
              : ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        if (!await _confirmDelete(context, item)) return false;
                        try {
                          await widget.store.remove(item);
                          return true;
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('物品删除失败，原数据未改变，请重试。'),
                              ),
                            );
                          }
                          return false;
                        }
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 22),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ItemCard(
                        item: item,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetailPage(store: widget.store, item: item),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context, CareItem item) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('删除物品？'),
          content: Text('将删除“${item.name}”以及已保存的凭证照片。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('删除'),
            ),
          ],
        ),
      ) ??
      false;
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.store});
  final CareStore store;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime _month;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _month = DateTime(today.year, today.month);
    _selectedDay = today;
  }

  void _moveMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _selectedDay = DateTime(_month.year, _month.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = maintenanceTasksForItems(widget.store.items);
    if (tasks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BreezeHeader(title: '保养日程', subtitle: '把需要照料的事情留给合适的时间'),
          Expanded(
            child: MaintenanceTaskEmptyState(
              onCreate: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditorPage(store: widget.store),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final byDay = <DateTime, List<MaintenanceTask>>{};
    for (final task in tasks) {
      final day = maintenanceDateOnly(task.dueDate);
      (byDay[day] ??= []).add(task);
    }
    final selectedTasks = byDay[_selectedDay] ?? const <MaintenanceTask>[];
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        const SliverToBoxAdapter(
          child: BreezeHeader(title: '保养日程', subtitle: '点选日期，查看当天具体的保养任务'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _MonthCalendar(
              month: _month,
              selectedDay: _selectedDay,
              scheduledDays: byDay,
              onPrevious: () => _moveMonth(-1),
              onNext: () => _moveMonth(1),
              onSelectDay: (day) => setState(() => _selectedDay = day),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedDay.month}月${_selectedDay.day}日的保养',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  selectedTasks.isEmpty ? '暂无安排' : '${selectedTasks.length} 项',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (selectedTasks.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 90),
              child: BreezeSurface(
                child: Row(
                  children: [
                    Icon(Icons.event_available_outlined, color: _indigo),
                    SizedBox(width: 10),
                    Text('这一天没有安排，慢慢享受生活吧。', style: TextStyle(color: _muted)),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: selectedTasks.length,
            itemBuilder: (context, index) {
              final task = selectedTasks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MaintenanceTaskCard(
                  task: task,
                  onStart: () =>
                      _startMaintenanceTask(context, widget.store, task),
                  onDefer: () =>
                      _deferMaintenanceTask(context, widget.store, task),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.selectedDay,
    required this.scheduledDays,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<DateTime, List<MaintenanceTask>> scheduledDays;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCells = firstDay.weekday - DateTime.monday;
    final cellCount = ((leadingEmptyCells + daysInMonth + 6) ~/ 7) * 7;
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final today = DateUtils.dateOnly(DateTime.now());
    return BreezeSurface(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              _monthButton(Icons.chevron_left_rounded, onPrevious),
              Expanded(
                child: Text(
                  '${month.year} 年 ${month.month} 月',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              _monthButton(Icons.chevron_right_rounded, onNext),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: weekdays
                .map(
                  (weekday) => Expanded(
                    child: Center(
                      child: Text(
                        weekday,
                        style: TextStyle(
                          color: weekday == '六' || weekday == '日'
                              ? _amber
                              : _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leadingEmptyCells + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = DateTime(month.year, month.month, dayNumber);
              final itemCount = scheduledDays[day]?.length ?? 0;
              final selected = DateUtils.isSameDay(day, selectedDay);
              final isToday = DateUtils.isSameDay(day, today);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey(
                    'calendar-day-${day.year}-${day.month}-${day.day}',
                  ),
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => onSelectDay(day),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected
                            ? _indigo
                            : (isToday ? _mist : Colors.transparent),
                        borderRadius: BorderRadius.circular(15),
                        border: isToday && !selected
                            ? Border.all(color: _indigo.withValues(alpha: .35))
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              color: selected ? Colors.white : _ink,
                              fontWeight: selected || isToday
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          SizedBox(
                            height: 4,
                            child: itemCount == 0
                                ? null
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      itemCount.clamp(1, 3).toInt(),
                                      (_) => Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? const Color(0xFFFFE6C9)
                                              : _amber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _monthButton(IconData icon, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: _mist, shape: BoxShape.circle),
        child: Icon(icon, color: _indigo),
      ),
    ),
  );
}

class AssetLedgerPage extends StatelessWidget {
  const AssetLedgerPage({super.key, required this.store});
  final CareStore store;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final entries = <(CareItem, MaintenanceRecord)>[];
    for (final item in store.items) {
      for (final record in item.records) {
        entries.add((item, record));
      }
    }
    entries.sort((a, b) => b.$2.date.compareTo(a.$2.date));
    final annualCost = entries
        .where((entry) => entry.$2.date.year == year)
        .fold<double>(0, (sum, entry) => sum + entry.$2.cost);
    final assetValue = store.items.fold<double>(
      0,
      (sum, item) => sum + (item.currentValue ?? item.purchasePrice ?? 0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BreezeHeader(title: '资产运营账本', subtitle: '只记录与家庭物品有关的支出'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _summary(
                          '$year 年持有成本',
                          '¥${annualCost.toStringAsFixed(0)}',
                          _amber,
                        ),
                        const SizedBox(width: 10),
                        _summary(
                          '资产估值',
                          '¥${assetValue.toStringAsFixed(0)}',
                          const Color(0xFF3A7D70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '成本流水 · Linked costs',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  text: '在物品详情中添加维修或耗材记录',
                )
              : ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return BreezeSurface(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _amber.withValues(alpha: .14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              color: _amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.$2.kind,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${entry.$1.name} · ${_date(entry.$2.date)}${entry.$2.note.isEmpty ? '' : ' · ${entry.$2.note}'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.$2.cost == 0
                                ? '—'
                                : '¥${entry.$2.cost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _indigo,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _summary(String title, String value, Color color) => Expanded(
    child: BreezeSurface(
      color: color.withValues(alpha: .10),
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});
  final CareStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _remindersEnabled = false;
  bool _restoreInProgress = false;

  CareStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshReminderStatus());
  }

  Future<void> _refreshReminderStatus() async {
    final access = await store.notificationAccess();
    if (mounted) {
      setState(() => _remindersEnabled = access == NotificationAccess.enabled);
    }
  }

  Future<void> _handleReminderTap() async {
    final current = await store.notificationAccess();
    if (!mounted) return;
    if (current == NotificationAccess.enabled) {
      await _showReminderTools();
      return;
    }
    if (current == NotificationAccess.denied) {
      await _showNotificationSettingsGuide();
      return;
    }
    if (current == NotificationAccess.unavailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂时无法读取通知状态，请稍后重试')));
      return;
    }
    final proceed = await _showNotificationPrimer(context);
    if (!proceed || !mounted) return;
    await store.markNotificationPrimerSeen();
    final access = await store.requestNotifications();
    if (!mounted) return;
    if (access == NotificationAccess.enabled) {
      setState(() => _remindersEnabled = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保养提醒已开启：到期前 3 天会在本机提醒你')));
      return;
    }
    if (access == NotificationAccess.denied) {
      await _showNotificationSettingsGuide();
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('暂时无法读取通知状态，请稍后重试')));
  }

  Future<void> _showNotificationSettingsGuide() async {
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('通知权限未开启'),
        content: const Text(
          '你之前没有允许“家务志”发送通知，因此系统不会再次弹出授权框。\n\n请前往 iPhone「设置 → 通知 → 家务志」，打开“允许通知”后再回到这里。',
          style: TextStyle(height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('稍后处理'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialog);
              final opened = await launchUrl(
                Uri.parse('app-settings:'),
                mode: LaunchMode.externalApplication,
              );
              if (!opened && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请手动前往“设置 → 通知 → 家务志”开启通知')),
                );
              }
            },
            child: const Text('前往系统设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _showReminderTools() async {
    final scheduledTasks = maintenanceTasksForItems(store.items).length;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '保养提醒已开启',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                scheduledTasks == 0
                    ? '还没有启用且设置到期日的保养计划。建立计划后，可按计划的提前天数提醒。'
                    : '已为 $scheduledTasks 个保养计划安排本机提醒，将按各计划的提前天数在上午 9:00 通知你。',
                style: const TextStyle(color: _muted, height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  final sent = await store.sendTestNotification();
                  if (sheet.mounted) Navigator.pop(sheet);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          sent
                              ? '测试提醒将在 5 秒后送达，可切到桌面或锁屏查看'
                              : '无法发送测试提醒，请检查系统通知设置',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('发送测试提醒'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final opened = await launchUrl(
                    Uri.parse('app-settings:'),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && sheet.mounted) {
                    ScaffoldMessenger.of(sheet).showSnackBar(
                      const SnackBar(content: Text('请手动前往“设置 → 通知 → 家务志”管理提醒')),
                    );
                  }
                },
                child: const Text('前往系统通知设置'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _manageExampleData() async {
    if (store.isDataReadOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('档案读取失败时不能修改示例数据，请先重启或恢复有效备份')),
      );
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '示例数据',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '重置只会恢复一条“示例 · 厨房净水器”，不会删除你自己创建的物品。',
                style: TextStyle(color: _muted, height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheet, 'reset'),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('重置示例净水器'),
              ),
              if (store.hasExampleData) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.pop(sheet, 'delete'),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除示例数据'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    try {
      if (action == 'reset') {
        await store.resetExampleData();
      } else if (action == 'delete') {
        await store.deleteExampleData();
      } else {
        return;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('示例数据保存失败，原数据未改变，请重试。')));
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(action == 'reset' ? '示例净水器已重置' : '示例数据已删除')),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
    children: [
      const BreezeHeader(title: '设置', subtitle: '提醒、备份与隐私都留在你的掌握中'),
      const SizedBox(height: 10),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          '数据与提醒',
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: BreezeSurface(
          child: Column(
            children: [
              SettingRow(
                icon: Icons.notifications_active_outlined,
                title: _remindersEnabled ? '提醒与测试' : '开启保养提醒',
                subtitle: _remindersEnabled
                    ? '已开启 · 查看规则或发送测试提醒'
                    : '到期前 3 天在本机提醒',
                onTap: _handleReminderTap,
              ),
              const Divider(height: 1, color: Color(0xFFE8EDE7)),
              SettingRow(
                icon: Icons.ios_share_outlined,
                title: '导出本地数据',
                subtitle: '生成 CSV，可保存到文件或发送',
                onTap: () => store.exportCSV(context),
              ),
              const Divider(height: 1, color: Color(0xFFE8EDE7)),
              SettingRow(
                icon: Icons.backup_outlined,
                title: '完整备份',
                subtitle: '导出全部档案、记录和凭证照片',
                onTap: () => store.exportBackup(context),
              ),
              const Divider(height: 1, color: Color(0xFFE8EDE7)),
              SettingRow(
                icon: Icons.restore_page_outlined,
                title: '恢复备份',
                subtitle: _restoreInProgress
                    ? '正在恢复，请勿关闭应用'
                    : '选择此前导出的 Hearthio-backup.zip',
                onTap: _restoreInProgress || store.isRestoringBackup
                    ? null
                    : () => _restoreFromBackup(context),
              ),
              const Divider(height: 1, color: Color(0xFFE8EDE7)),
              SettingRow(
                icon: Icons.science_outlined,
                title: '管理示例数据',
                subtitle: store.hasExampleData
                    ? '可删除或重置“示例 · 厨房净水器”'
                    : '恢复一条可删除的示例净水器',
                onTap: _manageExampleData,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          '隐私',
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: BreezeSurface(
          child: SettingRow(
            icon: Icons.privacy_tip_outlined,
            title: '隐私政策',
            subtitle: '查看数据保存、权限和导出说明',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            ),
          ),
        ),
      ),
    ],
  );

  Future<void> _restoreFromBackup(BuildContext context) async {
    if (_restoreInProgress || store.isRestoringBackup) return;
    setState(() => _restoreInProgress = true);
    try {
      final firstTime = await store.needsRestoreGuide();
      if (!context.mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(firstTime ? '如何恢复完整备份？' : '从文件恢复完整备份？'),
          content: Text(
            firstTime
                ? '接下来会打开“文件”选择器。\n\n1. 找到此前通过“完整备份”导出的 Hearthio-backup.zip。\n2. 选择该文件后，物品、维护记录和凭证照片会一起恢复。\n3. 当前设备上的档案将被替换；如需保留，请先导出一次当前完整备份。'
                : '接下来会打开“文件”选择器，请选择此前导出的 Hearthio-backup.zip。\n\n恢复会替换当前设备上的档案。',
            style: const TextStyle(height: 1.55),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('暂不恢复'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('选择备份文件'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
      if (firstTime) unawaited(store.markRestoreGuideSeen());
      final ok = await store.restoreBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? '备份已恢复：物品、记录和照片已更新'
                  : '没有选择有效的 Hearthio-backup.zip，当前档案未发生变化',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _restoreInProgress = false);
    }
  }
}

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, required this.onTap});
  final CareItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = item.isOverdue
        ? Colors.red
        : item.isSoon
        ? Colors.orange
        : _indigo;
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7ECE5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_iconFor(item.category), color: color),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          item.category,
                          item.location,
                        ].where((e) => e.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (item.nextCareDate == null)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: _muted,
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _date(item.nextCareDate),
                        style: const TextStyle(fontSize: 10, color: _muted),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(String category) {
  switch (category) {
    case '家电':
      return Icons.kitchen_outlined;
    case '滤芯与耗材':
      return Icons.water_drop_outlined;
    case '家具与家居':
      return Icons.chair_outlined;
    case '车辆与出行':
      return Icons.directions_car_outlined;
    case '宠物用品':
      return Icons.pets_outlined;
    default:
      return Icons.inventory_2_outlined;
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: BreezeSurface(
      color: _paper,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: _mist,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: _indigo),
          ),
          const SizedBox(height: 15),
          Text(text, style: const TextStyle(color: _muted)),
        ],
      ),
    ),
  );
}

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.store, required this.item});
  final CareStore store;
  final CareItem item;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  CareStore get store => widget.store;

  CareItem get item {
    for (final current in store.items) {
      if (current.id == widget.item.id) return current;
    }
    return widget.item;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => _buildPage(context),
  );

  Widget _buildPage(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 72,
      title: Text(item.name),
      leading: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: _mist,
            foregroundColor: _indigo,
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: _mist,
              foregroundColor: _indigo,
            ),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditorPage(store: store, item: item),
                ),
              );
            },
          ),
        ),
      ],
    ),
    body: ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(20),
      children: [
        MaintenanceLifecycleOverview(item: item),
        if (item.photos.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: item.photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(item.photos[i]),
                  width: 150,
                  height: 110,
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 150,
                    child: Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          ),
        if (item.photos.isNotEmpty) const SizedBox(height: 18),
        _plansSection(),
        _section('物品信息', [
          ('类别', item.category),
          ('位置', item.location),
          ('品牌', item.brand),
          ('型号', item.model),
          ('购买日期', _date(item.purchaseDate)),
          ('保修截止', _date(item.warrantyDate)),
          (
            '购买价',
            item.purchasePrice == null
                ? '未设置'
                : '¥${item.purchasePrice!.toStringAsFixed(0)}',
          ),
          (
            '当前估值',
            item.currentValue == null
                ? '未设置'
                : '¥${item.currentValue!.toStringAsFixed(0)}',
          ),
        ]),
        if (item.notes.isNotEmpty) _section('备注', [('说明', item.notes)]),
        MaintenanceLifecycleTimeline(item: item, controller: store),
        FilledButton.icon(
          key: const Key('start-maintenance-from-detail'),
          icon: const Icon(Icons.add_task_outlined),
          label: const Text('开始一次保养'),
          onPressed: () => _startMaintenance(context),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          icon: const Icon(Icons.delete_outline),
          label: const Text('删除此物品'),
          onPressed: () async {
            try {
              await store.remove(item);
              if (context.mounted) Navigator.pop(context);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('物品删除失败，原数据未改变，请重试。')),
                );
              }
            }
          },
        ),
      ],
    ),
  );

  Widget _section(String title, List<(String, String)> rows) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 8),
        BreezeSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: List.generate(rows.length, (index) {
              final row = rows[index];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Text(
                          row.$1,
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            row.$2,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < rows.length - 1)
                    const Divider(height: 1, color: Color(0xFFE8EDE7)),
                ],
              );
            }),
          ),
        ),
      ],
    ),
  );

  Widget _plansSection() {
    final visiblePlans = item.plans.where((plan) => !plan.archived).toList()
      ..sort((a, b) {
        final aDate = a.dueDate ?? DateTime(9999);
        final bDate = b.dueDate ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
    final archivedCount = item.plans.where((plan) => plan.archived).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        key: const Key('detail-maintenance-plans'),
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
              if (archivedCount > 0)
                Text(
                  '已归档 $archivedCount 项',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (visiblePlans.isEmpty)
            const BreezeSurface(
              child: Text('暂无启用或停用的保养计划', style: TextStyle(color: _muted)),
            )
          else
            BreezeSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: List.generate(visiblePlans.length, (index) {
                  final plan = visiblePlans[index];
                  final status = MaintenancePlanStatus.evaluate(plan);
                  return Column(
                    key: ValueKey('detail-plan-${plan.id}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              plan.enabled
                                  ? Icons.event_available_outlined
                                  : Icons.event_busy_outlined,
                              color: _indigo,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${status.label} · 每 ${plan.intervalDays} 天 · 提前 ${plan.reminderLeadDays} 天',
                                    key: ValueKey(
                                      'detail-plan-status-${plan.id}',
                                    ),
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '原到期日 ${_date(plan.dueDate)} · ${status.timingLabel} · ${plan.checklist.length} 个步骤',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (status.hasActiveDeferral) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '稍后提醒 ${_date(status.deferredUntil)} · 原状态 ${status.dueStateLabel}',
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < visiblePlans.length - 1)
                        const Divider(height: 1, color: Color(0xFFE8EDE7)),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _startMaintenance(BuildContext context) async {
    final availablePlans = item.plans
        .where((plan) => plan.enabled && !plan.archived && plan.dueDate != null)
        .toList();
    if (availablePlans.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先为物品建立并启用一个保养计划。')));
      return;
    }
    MaintenancePlan? selectedPlan;
    if (availablePlans.length == 1) {
      selectedPlan = availablePlans.single;
    } else {
      selectedPlan = await showModalBottomSheet<MaintenancePlan>(
        context: context,
        builder: (sheet) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              const Text(
                '选择保养任务',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final plan in availablePlans)
                ListTile(
                  key: ValueKey('start-detail-plan-${plan.id}'),
                  title: Text(plan.title),
                  subtitle: Text('原到期日 ${_date(plan.dueDate)}'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded),
                  onTap: () => Navigator.pop(sheet, plan),
                ),
            ],
          ),
        ),
      );
    }
    if (selectedPlan == null || !context.mounted) return;
    final task = MaintenanceTask(
      item: item,
      plan: selectedPlan,
      status: MaintenancePlanStatus.evaluate(selectedPlan),
    );
    await _startMaintenanceTask(
      context,
      store,
      task,
      openLifecycleAfterCompletion: false,
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.store, this.item});
  final CareStore store;
  final CareItem? item;
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name,
      location,
      brand,
      model,
      notes,
      purchasePrice,
      currentValue;
  late String category;
  DateTime? purchase, warranty;
  late List<String> photos;
  late List<MaintenancePlan> plans;
  final _newPhotoPaths = <String>{};
  bool _saved = false;
  final categories = ['家电', '滤芯与耗材', '家具与家居', '车辆与出行', '宠物用品', '其他'];
  @override
  void initState() {
    super.initState();
    final x = widget.item;
    name = TextEditingController(text: x?.name);
    location = TextEditingController(text: x?.location);
    brand = TextEditingController(text: x?.brand);
    model = TextEditingController(text: x?.model);
    notes = TextEditingController(text: x?.notes);
    purchasePrice = TextEditingController(
      text: x?.purchasePrice?.toStringAsFixed(0),
    );
    currentValue = TextEditingController(
      text: x?.currentValue?.toStringAsFixed(0),
    );
    category = x?.category ?? categories.first;
    if (!categories.contains(category)) categories.add(category);
    purchase = x?.purchaseDate;
    warranty = x?.warrantyDate;
    photos = [...?x?.photos];
    plans = [...?x?.plans];
  }

  @override
  void dispose() {
    if (!_saved) {
      for (final path in _newPhotoPaths) {
        unawaited(widget.store._deletePhoto(path));
      }
    }
    for (final c in [
      name,
      location,
      brand,
      model,
      notes,
      purchasePrice,
      currentValue,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 72,
      title: Text(widget.item == null ? '添加物品' : '编辑物品'),
      leading: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: _mist,
            foregroundColor: _indigo,
          ),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: FilledButton(
            key: const Key('save-care-item'),
            onPressed: _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('保存'),
          ),
        ),
      ],
    ),
    body: Form(
      key: form,
      child: ListView(
        key: const PageStorageKey('item-editor-scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          _field(name, '物品名称 *', required: true),
          _category(),
          _field(location, '存放位置'),
          _field(brand, '品牌'),
          _field(model, '型号'),
          const SizedBox(height: 4),
          const Text(
            '资产信息 · Asset',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 10),
          _field(
            purchasePrice,
            '购买价（元）',
            type: const TextInputType.numberWithOptions(decimal: true),
            validator: _nonNegativeNumber,
          ),
          _field(
            currentValue,
            '当前估值（元）',
            type: const TextInputType.numberWithOptions(decimal: true),
            validator: _nonNegativeNumber,
          ),
          const SizedBox(height: 16),
          const Text(
            '时间信息',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          _dateTile('购买日期', purchase, (d) => setState(() => purchase = d)),
          _dateTile('保修截止', warranty, (d) => setState(() => warranty = d)),
          const SizedBox(height: 10),
          MaintenancePlansEditorSection(
            plans: plans,
            records: widget.item?.records ?? const [],
            onChanged: (value) => setState(() => plans = value),
          ),
          const SizedBox(height: 16),
          const Text(
            '凭证照片',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          _photos(),
          const SizedBox(height: 16),
          _field(notes, '备注', maxLines: 4),
          const SizedBox(height: 80),
        ],
      ),
    ),
  );
  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? type,
    int maxLines = 1,
    FormFieldValidator<String>? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '请填写物品名称';
        }
        return validator?.call(value);
      },
    ),
  );
  Widget _category() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: category,
      decoration: const InputDecoration(
        labelText: '类别',
        border: OutlineInputBorder(),
      ),
      items: categories
          .map((x) => DropdownMenuItem(value: x, child: Text(x)))
          .toList(),
      onChanged: (v) => setState(() => category = v!),
    ),
  );
  Widget _photos() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ...photos.map(
        (p) => Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(p),
                width: 82,
                height: 82,
                fit: BoxFit.cover,
                cacheWidth: 164,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 82,
                  height: 82,
                  child: Icon(Icons.broken_image),
                ),
              ),
            ),
            Positioned(
              right: -8,
              top: -8,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.white),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () {
                  setState(() => photos.remove(p));
                  if (_newPhotoPaths.remove(p)) {
                    unawaited(widget.store._deletePhoto(p));
                  }
                },
                icon: const Icon(Icons.close, size: 16),
              ),
            ),
          ],
        ),
      ),
      InkWell(
        onTap: _addPhoto,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueGrey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_a_photo_outlined),
        ),
      ),
    ],
  );
  Widget _dateTile(String label, DateTime? date, ValueChanged<DateTime?> set) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: BreezeSurface(
          radius: 18,
          padding: const EdgeInsets.fromLTRB(15, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _date(date),
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (date != null)
                    IconButton(
                      onPressed: () => set(null),
                      icon: const Icon(Icons.clear),
                    ),
                  IconButton(
                    onPressed: () async {
                      final result = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDate: date ?? DateTime.now(),
                      );
                      if (result != null) set(result);
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 2, 8, 12),
                child: Text(
                  '添加凭证照片',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              BreezeSurface(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: const Column(
                  children: [
                    PhotoSourceRow(
                      icon: Icons.photo_camera_outlined,
                      title: '拍照',
                      subtitle: '直接拍摄物品、说明书或保修卡',
                      source: ImageSource.camera,
                    ),
                    Divider(height: 1, color: Color(0xFFE8EDE7)),
                    PhotoSourceRow(
                      icon: Icons.photo_library_outlined,
                      title: '从相册选择',
                      subtitle: '从已保存的照片中添加凭证',
                      source: ImageSource.gallery,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    final result = await widget.store.importPhoto(source);
    if (!mounted) return;
    if (result.path != null) {
      setState(() {
        photos.add(result.path!);
        _newPhotoPaths.add(result.path!);
      });
    } else if (result.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? '无法打开相机，请检查“相机”权限后重试。'
                : '无法读取照片，请检查“照片”权限后重试。',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!(form.currentState?.validate() ?? false)) return;
    final item =
        (widget.item ??
                CareItem(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: '',
                  category: category,
                  location: '',
                  brand: '',
                  model: '',
                  notes: '',
                  photos: [],
                ))
            .copyWith(
              name: name.text.trim(),
              category: category,
              location: location.text.trim(),
              brand: brand.text.trim(),
              model: model.text.trim(),
              notes: notes.text.trim(),
              photos: photos,
              plans: plans,
              purchaseDate: purchase,
              warrantyDate: warranty,
              purchasePrice: double.tryParse(purchasePrice.text.trim()),
              currentValue: double.tryParse(currentValue.text.trim()),
              clearPurchasePrice: purchasePrice.text.trim().isEmpty,
              clearCurrentValue: currentValue.text.trim().isEmpty,
              clearPurchaseDate: purchase == null,
              clearWarrantyDate: warranty == null,
            );
    try {
      await widget.store.save(item);
      _saved = true;
      await _offerNotificationFor(item);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请稍后重试。')));
      }
    }
  }

  Future<void> _offerNotificationFor(CareItem item) async {
    try {
      if (item.nextCareDate == null || !mounted) return;
      if (!await widget.store.shouldOfferNotificationPrimer() || !mounted) {
        return;
      }
      await widget.store.markNotificationPrimerSeen();
      if (!mounted) return;
      final proceed = await _showNotificationPrimer(context);
      if (!proceed || !mounted) return;
      final access = await widget.store.requestNotifications();
      if (!mounted) return;
      final message = switch (access) {
        NotificationAccess.enabled => '保养提醒已开启',
        NotificationAccess.denied => '通知权限未开启，可稍后在“设置”中处理',
        NotificationAccess.notDetermined => '暂未开启通知',
        NotificationAccess.unavailable => '暂时无法申请通知权限，请稍后重试',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      // Notification setup must never turn a successful item save into failure.
    }
  }
}
