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
import 'services/system_permission_service.dart';
import 'widgets/app_alert.dart';
import 'widgets/app_back_button.dart';
import 'widgets/app_date_picker.dart';
import 'widgets/app_safe_area.dart';
import 'widgets/app_toast.dart';
import 'widgets/maintenance_plan_editor.dart';
import 'widgets/maintenance_execution_page.dart';
import 'widgets/maintenance_lifecycle_section.dart';
import 'widgets/maintenance_task_card.dart';
import 'widgets/maintenance_report_page.dart';
import 'widgets/system_permission_alert.dart';

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
export 'services/system_permission_service.dart';
export 'widgets/app_alert.dart';
export 'widgets/app_back_button.dart';
export 'widgets/app_date_picker.dart';
export 'widgets/app_toast.dart';
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
                key: ValueKey('bottom-tab-$index'),
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
typedef CareImagePicker = Future<XFile?> Function(ImageSource source);

Future<XFile?> _pickCareImage(ImageSource source) =>
    ImagePicker().pickImage(source: source, imageQuality: 82, maxWidth: 1800);

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
    await showAppAlert<bool>(
      context,
      title: '开启保养提醒？',
      message:
          '开启后，家务志会按每个计划设置的提前天数发送本地通知。\n\n不授权不会影响物品和保养计划保存，你也可以稍后在“设置”中开启。',
      actions: const [
        AppAlertAction(label: '暂不开启', result: false),
        AppAlertAction(label: '开启通知', result: true, isDefaultAction: true),
      ],
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
    builder: (sheet) => SingleChildScrollView(
      padding: appSafeScrollPadding(
        sheet,
        const EdgeInsets.fromLTRB(20, 16, 20, 24),
      ),
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
              final selected = await showAppDatePicker(
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
  );
  if (deferredUntil == null || !context.mounted) return;
  try {
    await store.deferPlan(task.item, task.plan.id, deferredUntil);
  } catch (_) {
    if (context.mounted) {
      AppToast.show(context, '稍后提醒设置失败，请重试。', style: AppToastStyle.error);
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
    SystemPermissionGuard? systemPermissions,
    CareImagePicker? imagePicker,
  }) : _repository = repository,
       _notificationScheduler = notificationScheduler,
       _backupPicker = backupPicker ?? _pickCareBackup,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _systemPermissions =
           systemPermissions ??
           const SystemPermissionGuard(MethodChannelSystemPermissionGateway()),
       _imagePicker = imagePicker ?? _pickCareImage;

  final _notifications = FlutterLocalNotificationsPlugin();
  Future<void>? _notificationsReady;
  Future<void> _notificationMutationTail = Future.value();
  Future<void> _persistenceTail = Future.value();
  CareRepository? _repository;
  final CareNotificationScheduler? _notificationScheduler;
  final CareBackupPicker _backupPicker;
  final CareDocumentsDirectoryProvider _documentsDirectoryProvider;
  final SystemPermissionGuard _systemPermissions;
  final CareImagePicker _imagePicker;
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
      final permission = source == ImageSource.camera
          ? SystemPermissionKind.camera
          : SystemPermissionKind.photoLibrary;
      final permissionState = await _systemPermissions.ensure(permission);
      if (!permissionState.isGranted) {
        return PhotoImportResult.permissionBlocked(permission, permissionState);
      }
      final picked = await _imagePicker(source);
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
        AppToast.show(
          context,
          '完整备份未导出：${error.message}',
          style: AppToastStyle.error,
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.show(
          context,
          '完整备份未导出，请检查设备存储后重试。',
          style: AppToastStyle.error,
        );
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
      final prefs = await SharedPreferences.getInstance();
      final permissionPrompted =
          prefs.getBool('notification_permission_prompted') ?? false;
      if (Platform.isIOS) {
        final ios = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (ios == null) return NotificationAccess.unavailable;
        final permissions = await ios.checkPermissions();
        return notificationAccessFrom(
          notificationsEnabled:
              permissions?.isAlertEnabled == true ||
              permissions?.isProvisionalEnabled == true,
          permissionPrompted: permissionPrompted,
        );
      }
      if (Platform.isAndroid) {
        final android = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (android == null) return NotificationAccess.unavailable;
        return notificationAccessFrom(
          notificationsEnabled: await android.areNotificationsEnabled() == true,
          permissionPrompted: permissionPrompted,
        );
      }
      return NotificationAccess.unavailable;
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
      final bool? granted;
      if (Platform.isIOS) {
        final ios = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (ios == null) return NotificationAccess.unavailable;
        granted = await ios.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        final android = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (android == null) return NotificationAccess.unavailable;
        granted = await android.requestNotificationsPermission();
      } else {
        return NotificationAccess.unavailable;
      }
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
        android: AndroidNotificationDetails(
          'care_reminders',
          '保养提醒',
          channelDescription: '家庭物品保养提醒',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _scheduleSafely(CareItem item, {CareItem? previous}) async {
    try {
      if (_notificationScheduler == null &&
          await notificationAccess() != NotificationAccess.enabled) {
        return;
      }
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
          .map(
            (plan) => enrichMaintenanceTemplateStepDescriptions(
              clearExpiredMaintenanceDeferral(plan, now: today),
            ),
          )
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
      AppToast.show(context, message);
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
      void openItemEditor() {
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => EditorPage(store: store)),
        );
      }

      final pages = [
        Dashboard(
          store: store,
          onAdd: openItemEditor,
          onOpenSchedule: () => setState(() => tab = 2),
        ),
        InventoryPage(store: store),
        SchedulePage(store: store),
        MaintenanceReportPage(items: store.items),
        SettingsPage(store: store),
      ];
      return Scaffold(
        body: SafeArea(
          bottom: false,
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
        floatingActionButton: tab == 1
            ? AddItemButton(onTap: openItemEditor)
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
  const Dashboard({
    super.key,
    required this.store,
    this.onAdd,
    this.onOpenSchedule,
    this.now,
  });

  final CareStore store;
  final VoidCallback? onAdd;
  final VoidCallback? onOpenSchedule;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final today = maintenanceDateOnly(now ?? DateTime.now());
    final year = today.year;
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
    final tasks = maintenanceTasksForItems(store.items, now: today);
    final attentionCount = tasks
        .where(
          (task) =>
              task.status.dueState == MaintenanceTaskState.overdue ||
              task.status.dueState == MaintenanceTaskState.dueToday ||
              task.status.dueState == MaintenanceTaskState.dueSoon,
        )
        .length;
    final nextTask = tasks.isEmpty ? null : tasks.first;

    void openAddFlow() {
      if (onAdd != null) {
        onAdd!();
        return;
      }
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => EditorPage(store: store)),
      );
    }

    return CustomScrollView(
      key: const PageStorageKey('dashboard-scroll'),
      cacheExtent: 0,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          sliver: SliverToBoxAdapter(
            child: RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(today: today, onAdd: openAddFlow),
                  const SizedBox(height: 12),
                  _DashboardTodayHero(
                    attentionCount: attentionCount,
                    onOpenSchedule: onOpenSchedule,
                  ),
                  const SizedBox(height: 20),
                  const _DashboardSectionTitle(title: '下一项保养'),
                  const SizedBox(height: 4),
                  if (nextTask == null)
                    MaintenanceTaskEmptyState(onCreate: openAddFlow)
                  else
                    _DashboardNextTask(
                      task: nextTask,
                      onStart: () =>
                          _startMaintenanceTask(context, store, nextTask),
                      onDefer: () =>
                          _deferMaintenanceTask(context, store, nextTask),
                    ),
                  const SizedBox(height: 6),
                  const Text(
                    '家庭概览',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DashboardHouseholdOverview(
                    itemCount: store.items.length,
                    roomCount: rooms.length,
                    annualCost: annualCost,
                    assetValue: assetValue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.today, required this.onAdd});

  final DateTime today;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '家务志',
              style: TextStyle(
                color: _ink,
                fontSize: 30,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _dashboardDate(today),
              style: const TextStyle(
                color: _muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
      Semantics(
        button: true,
        label: '添加物品',
        child: Material(
          color: _mist,
          shape: const CircleBorder(),
          child: InkWell(
            key: const Key('dashboard-add-item'),
            onTap: onAdd,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.add_rounded, color: _indigo, size: 28),
            ),
          ),
        ),
      ),
    ],
  );
}

class _DashboardTodayHero extends StatelessWidget {
  const _DashboardTodayHero({
    required this.attentionCount,
    required this.onOpenSchedule,
  });

  final int attentionCount;
  final VoidCallback? onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final title = attentionCount == 0
        ? '没有到期任务'
        : attentionCount == 1
        ? '1 项任务需要关注'
        : '$attentionCount 项任务需要关注';
    final subtitle = attentionCount == 0 ? '家里一切按计划进行' : '先从最紧要的一项开始';
    return Container(
      key: const Key('dashboard-today-hero'),
      width: double.infinity,
      height: 172,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _indigo,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -16,
            width: 218,
            height: 164,
            child: ExcludeSemantics(
              child: Opacity(
                opacity: .22,
                child: Image.asset(
                  'assets/home/dashboard-room-line.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  color: const Color(0xFFD7E6DA),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFFECF3ED),
                        size: 17,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '今日',
                        style: TextStyle(
                          color: Color(0xFFECF3ED),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFD7E6DA),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    key: const Key('dashboard-open-schedule'),
                    onPressed: onOpenSchedule,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    label: const Text(
                      '查看日程',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSectionTitle extends StatelessWidget {
  const _DashboardSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -.2,
        ),
      ),
      const SizedBox(height: 10),
      const Divider(height: 1, color: Color(0xFFDCE4DD)),
    ],
  );
}

class _DashboardNextTask extends StatelessWidget {
  const _DashboardNextTask({
    required this.task,
    required this.onStart,
    required this.onDefer,
  });

  final MaintenanceTask task;
  final VoidCallback onStart;
  final VoidCallback onDefer;

  @override
  Widget build(BuildContext context) {
    final status = task.status;
    final tone = _dashboardTaskTone(status.dueState);
    return Container(
      key: ValueKey('maintenance-task-${task.item.id}-${task.plan.id}'),
      constraints: const BoxConstraints(minHeight: 206),
      child: Stack(
        children: [
          Positioned(
            left: 2,
            top: 5,
            bottom: 7,
            child: SizedBox(
              width: 10,
              child: Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tone,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Expanded(
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFD8E1D9),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC9D8C9),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 31),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dashboardTaskTiming(status),
                  style: TextStyle(
                    color: tone,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _mist,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: _dashboardTaskIcon(task),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            task.plan.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 14),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              const Icon(
                                Icons.event_outlined,
                                color: _indigo,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  status.hasActiveDeferral
                                      ? '原到期日 ${_date(task.dueDate)}'
                                      : _date(task.dueDate),
                                  key: ValueKey(
                                    'maintenance-task-due-${task.id}',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _indigo,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (status.hasActiveDeferral) ...[
                            const SizedBox(height: 4),
                            Text(
                              '稍后提醒 ${_date(status.deferredUntil)} · 原状态 ${status.dueStateLabel}',
                              key: ValueKey(
                                'maintenance-task-deferral-${task.id}',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _mist,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              status.label,
                              style: const TextStyle(
                                color: _indigo,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 70),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilledButton.icon(
                        key: ValueKey('start-maintenance-task-${task.id}'),
                        onPressed: onStart,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('开始保养'),
                      ),
                      const SizedBox(height: 1),
                      TextButton(
                        key: ValueKey('defer-maintenance-task-${task.id}'),
                        onPressed: onDefer,
                        style: TextButton.styleFrom(
                          foregroundColor: _indigo,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(status.hasActiveDeferral ? '修改提醒' : '稍后提醒'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHouseholdOverview extends StatelessWidget {
  const _DashboardHouseholdOverview({
    required this.itemCount,
    required this.roomCount,
    required this.annualCost,
    required this.assetValue,
  });

  final int itemCount;
  final int roomCount;
  final double annualCost;
  final double assetValue;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('dashboard-household-overview'),
    height: 96,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDCE4DD)),
    ),
    child: Row(
      children: [
        _DashboardFact(
          icon: Icons.inventory_2_outlined,
          label: '物品',
          value: '$itemCount',
        ),
        const _DashboardFactDivider(),
        _DashboardFact(
          icon: Icons.chair_outlined,
          label: '空间',
          value: '$roomCount',
        ),
        const _DashboardFactDivider(),
        _DashboardFact(
          icon: Icons.paid_outlined,
          label: '今年维护',
          value: '¥${annualCost.toStringAsFixed(0)}',
        ),
        const _DashboardFactDivider(),
        _DashboardFact(
          icon: Icons.home_outlined,
          label: '资产',
          value: '¥${assetValue.toStringAsFixed(0)}',
        ),
      ],
    ),
  );
}

class _DashboardFact extends StatelessWidget {
  const _DashboardFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _muted, size: 20),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DashboardFactDivider extends StatelessWidget {
  const _DashboardFactDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 58,
    child: VerticalDivider(width: 1, color: Color(0xFFE2E8E2)),
  );
}

String _dashboardDate(DateTime value) {
  const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return '${value.month}月${value.day}日 · ${weekdays[value.weekday - 1]}';
}

String _dashboardTaskTiming(MaintenancePlanStatus status) {
  final days = status.daysUntilDue;
  if (days == null) return '尚未设置日期';
  if (days < 0) return '已逾期 ${-days} 天';
  if (days == 0) return '今天到期';
  return '$days 天后';
}

Color _dashboardTaskTone(MaintenanceTaskState state) => switch (state) {
  MaintenanceTaskState.overdue => const Color(0xFFB64B43),
  MaintenanceTaskState.dueToday => const Color(0xFFC36F2D),
  MaintenanceTaskState.dueSoon => const Color(0xFFE18455),
  MaintenanceTaskState.deferred => const Color(0xFF725E91),
  MaintenanceTaskState.planned => const Color(0xFFE18455),
  MaintenanceTaskState.completed => const Color(0xFF3A7D70),
  MaintenanceTaskState.disabled => _muted,
};

Widget _dashboardTaskIcon(MaintenanceTask task) {
  final searchable = '${task.item.name}${task.item.category}${task.plan.title}';
  if (searchable.contains('净水') || searchable.contains('滤芯')) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        'assets/home/dashboard-purifier-icon.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
  return const Icon(
    Icons.home_repair_service_outlined,
    color: _indigo,
    size: 27,
  );
}

class MaintenanceTaskEmptyState extends StatelessWidget {
  const MaintenanceTaskEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('dashboard-empty-maintenance-state'),
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDCE4DD)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _mist,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      Icons.calendar_month_outlined,
                      size: 27,
                      color: _indigo,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 7,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: _amber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '从第一个计划开始',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.2,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '添加物品并设置保养周期，到期前会提醒你。',
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('create-first-maintenance-plan'),
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text(
              '创建保养计划',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
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
                            AppToast.show(
                              context,
                              '物品删除失败，原数据未改变，请重试。',
                              style: AppToastStyle.error,
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
      await showAppAlert<bool>(
        context,
        title: '删除物品？',
        message: '将删除“${item.name}”以及已保存的凭证照片。',
        actions: const [
          AppAlertAction(label: '取消', result: false),
          AppAlertAction(
            label: '删除',
            result: true,
            tone: AppAlertActionTone.destructive,
          ),
        ],
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
      await showSystemPermissionAlert(
        context,
        permission: SystemPermissionKind.notifications,
        state: SystemPermissionState.unavailable,
      );
      return;
    }
    final proceed = await _showNotificationPrimer(context);
    if (!proceed || !mounted) return;
    await store.markNotificationPrimerSeen();
    final access = await store.requestNotifications();
    if (!mounted) return;
    if (access == NotificationAccess.enabled) {
      setState(() => _remindersEnabled = true);
      AppToast.show(
        context,
        '保养提醒已开启：到期前 3 天会在本机提醒你',
        style: AppToastStyle.success,
      );
      return;
    }
    if (access == NotificationAccess.denied) {
      await _showNotificationSettingsGuide();
      return;
    }
    await showSystemPermissionAlert(
      context,
      permission: SystemPermissionKind.notifications,
      state: SystemPermissionState.unavailable,
    );
  }

  Future<void> _showNotificationSettingsGuide() async {
    await showSystemPermissionAlert(
      context,
      permission: SystemPermissionKind.notifications,
      state: SystemPermissionState.denied,
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
                  if (!mounted) return;
                  if (sent) {
                    AppToast.show(
                      context,
                      '测试提醒将在 5 秒后送达，可切到桌面或锁屏查看',
                      style: AppToastStyle.success,
                    );
                    return;
                  }
                  final access = await store.notificationAccess();
                  if (!mounted) return;
                  if (access == NotificationAccess.denied) {
                    await _showNotificationSettingsGuide();
                  } else if (access == NotificationAccess.unavailable) {
                    await showSystemPermissionAlert(
                      context,
                      permission: SystemPermissionKind.notifications,
                      state: SystemPermissionState.unavailable,
                    );
                  } else {
                    AppToast.show(
                      context,
                      '测试提醒暂时无法发送，请稍后重试',
                      style: AppToastStyle.error,
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
                    AppToast.show(
                      sheet,
                      '请手动前往“设置 → 通知 → 家务志”管理提醒',
                      style: AppToastStyle.error,
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
      AppToast.show(
        context,
        '档案读取失败时不能修改示例数据，请先重启或恢复有效备份',
        style: AppToastStyle.error,
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
        AppToast.show(
          context,
          '示例数据保存失败，原数据未改变，请重试。',
          style: AppToastStyle.error,
        );
      }
      return;
    }
    if (!mounted) return;
    AppToast.show(
      context,
      action == 'reset' ? '示例净水器已重置' : '示例数据已删除',
      style: AppToastStyle.success,
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
      final proceed = await showAppAlert<bool>(
        context,
        title: firstTime ? '如何恢复完整备份？' : '从文件恢复完整备份？',
        message: firstTime
            ? '接下来会打开“文件”选择器。\n\n1. 找到此前通过“完整备份”导出的 Hearthio-backup.zip。\n2. 选择该文件后，物品、维护记录和凭证照片会一起恢复。\n3. 当前设备上的档案将被替换；如需保留，请先导出一次当前完整备份。'
            : '接下来会打开“文件”选择器，请选择此前导出的 Hearthio-backup.zip。\n\n恢复会替换当前设备上的档案。',
        actions: const [
          AppAlertAction(label: '暂不恢复', result: false),
          AppAlertAction(label: '选择备份文件', result: true, isDefaultAction: true),
        ],
      );
      if (proceed != true) return;
      if (firstTime) unawaited(store.markRestoreGuideSeen());
      final ok = await store.restoreBackup();
      if (context.mounted) {
        AppToast.show(
          context,
          ok ? '备份已恢复：物品、记录和照片已更新' : '没有选择有效的 Hearthio-backup.zip，当前档案未发生变化',
          style: ok ? AppToastStyle.success : AppToastStyle.error,
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
    case '家用电器':
      return Icons.kitchen_outlined;
    case '滤芯与耗材':
      return Icons.water_drop_outlined;
    case '家具与家居':
    case '家具':
      return Icons.chair_outlined;
    case '厨房用品':
      return Icons.soup_kitchen_outlined;
    case '个人与卫浴':
      return Icons.bathtub_outlined;
    case '织物与床品':
      return Icons.bed_outlined;
    case '清洁与收纳':
      return Icons.cleaning_services_outlined;
    case '小物品与工具':
      return Icons.handyman_outlined;
    case '医疗保健':
      return Icons.medical_services_outlined;
    case '文件证件':
      return Icons.folder_outlined;
    case '装饰与兴趣':
      return Icons.palette_outlined;
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
      leading: AppBackButton(onPressed: () => Navigator.pop(context)),
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
      padding: appSafeScrollPadding(context, const EdgeInsets.all(20)),
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
                AppToast.show(
                  context,
                  '物品删除失败，原数据未改变，请重试。',
                  style: AppToastStyle.error,
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
      AppToast.show(context, '请先为物品建立并启用一个保养计划。');
      return;
    }
    MaintenancePlan? selectedPlan;
    if (availablePlans.length == 1) {
      selectedPlan = availablePlans.single;
    } else {
      selectedPlan = await showModalBottomSheet<MaintenancePlan>(
        context: context,
        builder: (sheet) => ListView(
          shrinkWrap: true,
          padding: appSafeScrollPadding(
            sheet,
            const EdgeInsets.fromLTRB(20, 14, 20, 24),
          ),
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

class _ItemPreset {
  const _ItemPreset(this.name, [this.icon]);

  final String name;
  final IconData? icon;
}

class _ItemCatalogCategory {
  const _ItemCatalogCategory(this.name, this.icon, this.items);

  final String name;
  final IconData icon;
  final List<_ItemPreset> items;
}

const _itemCatalog = <_ItemCatalogCategory>[
  _ItemCatalogCategory('家具', Icons.chair_outlined, [
    _ItemPreset('沙发'),
    _ItemPreset('床'),
    _ItemPreset('茶几'),
    _ItemPreset('电视柜'),
    _ItemPreset('餐桌'),
    _ItemPreset('餐椅'),
    _ItemPreset('衣柜'),
    _ItemPreset('书桌'),
    _ItemPreset('鞋柜'),
    _ItemPreset('其他家具', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('家用电器', Icons.kitchen_outlined, [
    _ItemPreset('冰箱', Icons.kitchen_outlined),
    _ItemPreset('洗衣机', Icons.local_laundry_service_outlined),
    _ItemPreset('空调', Icons.air_outlined),
    _ItemPreset('电视', Icons.tv_outlined),
    _ItemPreset('油烟机', Icons.wind_power_outlined),
    _ItemPreset('电饭煲', Icons.rice_bowl_outlined),
    _ItemPreset('吸尘器', Icons.cleaning_services_outlined),
    _ItemPreset('扫地机器人', Icons.smart_toy_outlined),
    _ItemPreset('净水器', Icons.water_drop_outlined),
    _ItemPreset('热水器', Icons.hot_tub_outlined),
    _ItemPreset('其他家电', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('厨房用品', Icons.soup_kitchen_outlined, [
    _ItemPreset('炒锅'),
    _ItemPreset('汤锅'),
    _ItemPreset('碗碟'),
    _ItemPreset('筷子'),
    _ItemPreset('刀具'),
    _ItemPreset('砧板'),
    _ItemPreset('保鲜盒'),
    _ItemPreset('调料罐'),
    _ItemPreset('其他厨房用品', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('个人与卫浴', Icons.bathtub_outlined, [
    _ItemPreset('牙刷'),
    _ItemPreset('毛巾'),
    _ItemPreset('沐浴用品'),
    _ItemPreset('洗发用品'),
    _ItemPreset('马桶'),
    _ItemPreset('洗手盆'),
    _ItemPreset('浴帘'),
    _ItemPreset('其他卫浴用品', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('织物与床品', Icons.bed_outlined, [
    _ItemPreset('床单'),
    _ItemPreset('被套'),
    _ItemPreset('被子'),
    _ItemPreset('枕头'),
    _ItemPreset('凉席'),
    _ItemPreset('蚊帐'),
    _ItemPreset('衣物'),
    _ItemPreset('鞋子'),
    _ItemPreset('包包'),
    _ItemPreset('配饰'),
    _ItemPreset('其他织物', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('清洁与收纳', Icons.cleaning_services_outlined, [
    _ItemPreset('扫帚'),
    _ItemPreset('拖把'),
    _ItemPreset('洗洁精'),
    _ItemPreset('洗衣液'),
    _ItemPreset('垃圾桶'),
    _ItemPreset('收纳箱'),
    _ItemPreset('衣架'),
    _ItemPreset('其他清洁用品', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('小物品与工具', Icons.handyman_outlined, [
    _ItemPreset('文具'),
    _ItemPreset('充电线'),
    _ItemPreset('充电宝'),
    _ItemPreset('螺丝刀'),
    _ItemPreset('扳手'),
    _ItemPreset('胶带'),
    _ItemPreset('电池'),
    _ItemPreset('其他工具', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('医疗保健', Icons.medical_services_outlined, [
    _ItemPreset('常用药品'),
    _ItemPreset('保健品'),
    _ItemPreset('体温计'),
    _ItemPreset('血压计'),
    _ItemPreset('创可贴'),
    _ItemPreset('其他医疗用品', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('文件证件', Icons.folder_outlined, [
    _ItemPreset('身份证'),
    _ItemPreset('户口本'),
    _ItemPreset('房产证'),
    _ItemPreset('合同'),
    _ItemPreset('票据'),
    _ItemPreset('证书'),
    _ItemPreset('其他文件', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('装饰与兴趣', Icons.palette_outlined, [
    _ItemPreset('挂画'),
    _ItemPreset('花瓶'),
    _ItemPreset('香薰'),
    _ItemPreset('绿植'),
    _ItemPreset('运动器材'),
    _ItemPreset('书法绘画工具'),
    _ItemPreset('其他兴趣用品', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('滤芯与耗材', Icons.filter_alt_outlined, [
    _ItemPreset('净水器滤芯'),
    _ItemPreset('空调滤网'),
    _ItemPreset('空气净化器滤芯'),
    _ItemPreset('吸尘器尘袋'),
    _ItemPreset('其他耗材', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('车辆与出行', Icons.directions_car_outlined, [
    _ItemPreset('汽车'),
    _ItemPreset('电动车'),
    _ItemPreset('自行车'),
    _ItemPreset('头盔'),
    _ItemPreset('行车记录仪'),
    _ItemPreset('其他出行物品', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('宠物用品', Icons.pets_outlined, [
    _ItemPreset('猫砂盆'),
    _ItemPreset('宠物饮水机'),
    _ItemPreset('宠物喂食器'),
    _ItemPreset('宠物笼'),
    _ItemPreset('其他宠物用品', Icons.more_horiz_rounded),
  ]),
  _ItemCatalogCategory('其他物品', Icons.more_horiz_rounded, [
    _ItemPreset('其他物品', Icons.inventory_2_outlined),
  ]),
];

const _commonItemNames = ['冰箱', '空调', '洗衣机', '净水器', '扫地机器人'];

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
      customName,
      search,
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
  final _expandedCategories = <String>{'家用电器'};
  bool _saved = false;
  bool _allowSupplementPop = false;
  bool _showSupplement = false;
  bool _advancedExpanded = false;
  bool _brandModelExpanded = false;
  String? _selectedPresetName;
  IconData _selectedPresetIcon = Icons.inventory_2_outlined;
  late final List<String> categories = _itemCatalog
      .map((entry) => entry.name)
      .followedBy(const ['家电', '家具与家居', '其他'])
      .toSet()
      .toList();

  @override
  void initState() {
    super.initState();
    final x = widget.item;
    name = TextEditingController(text: x?.name);
    customName = TextEditingController();
    search = TextEditingController();
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
      customName,
      search,
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
  Widget build(BuildContext context) {
    if (widget.item != null) return _buildLegacyEditor();
    return _showSupplement ? _buildSupplementPage() : _buildSelectionPage();
  }

  Widget _buildLegacyEditor() => Scaffold(
    appBar: AppBar(
      toolbarHeight: 72,
      title: const Text('编辑物品'),
      leading: AppBackButton(onPressed: () => Navigator.pop(context)),
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
        padding: appSafeScrollPadding(context, const EdgeInsets.all(20)),
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

  Widget _buildSelectionPage() => Scaffold(
    appBar: AppBar(
      toolbarHeight: 76,
      title: const Text('选择物品'),
      leading: AppBackButton(onPressed: () => Navigator.pop(context)),
    ),
    body: ListView(
      key: const PageStorageKey('item-selection-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: appSafeScrollPadding(
        context,
        const EdgeInsets.fromLTRB(20, 4, 20, 36),
      ),
      children: [
        TextField(
          key: const Key('item-search'),
          controller: search,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '搜索类别或物品',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        _stepIndicator(1),
        const SizedBox(height: 26),
        if (search.text.trim().isNotEmpty)
          _searchResults()
        else ...[
          const Text(
            '常用物品',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _commonItems(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Divider(height: 1, color: Color(0xFFE3E9E2)),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '全部分类',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('toggle-all-item-categories'),
                onPressed: _toggleAllCategories,
                iconAlignment: IconAlignment.end,
                icon: Icon(
                  _expandedCategories.length == _itemCatalog.length
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: Text(
                  _expandedCategories.length == _itemCatalog.length
                      ? '全部收起'
                      : '展开全部',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _categoryDirectory(),
        ],
      ],
    ),
  );

  Widget _buildSupplementPage() => PopScope(
    canPop: _allowSupplementPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _returnToSelection();
    },
    child: Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        centerTitle: true,
        title: const Text('补充信息'),
        leading: AppBackButton(onPressed: _returnToSelection),
      ),
      body: Form(
        key: form,
        child: ListView(
          key: const PageStorageKey('item-supplement-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _stepIndicator(2),
            const SizedBox(height: 24),
            _selectedItemSummary(),
            const SizedBox(height: 28),
            const Text(
              '选填信息',
              style: TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _optionalInfoGroup(),
            const SizedBox(height: 16),
            _advancedInfoGroup(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: appSafeScrollPadding(
          context,
          _advancedExpanded
              ? const EdgeInsets.fromLTRB(20, 6, 20, 8)
              : const EdgeInsets.fromLTRB(20, 10, 20, 12),
        ),
        child: _advancedExpanded
            ? Row(
                key: const Key('compact-item-actions'),
                children: [
                  TextButton(
                    key: const Key('save-care-item-later'),
                    onPressed: _save,
                    child: const Text('稍后完善'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        key: const Key('save-care-item'),
                        onPressed: _save,
                        child: const Text('完成添加'),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                key: const Key('full-item-actions'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('save-care-item'),
                      onPressed: _save,
                      child: const Text('完成添加'),
                    ),
                  ),
                  TextButton(
                    key: const Key('save-care-item-later'),
                    onPressed: _save,
                    child: const Text('稍后完善'),
                  ),
                ],
              ),
      ),
    ),
  );

  Widget _stepIndicator(int activeStep) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _stepDot(1, '选择物品', activeStep == 1),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('·', style: TextStyle(color: _muted, fontSize: 20)),
      ),
      _stepDot(2, '补充信息', activeStep == 2),
    ],
  );

  Widget _stepDot(int number, String label, bool active) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _indigo : _mist,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$number',
          style: TextStyle(
            color: active ? Colors.white : _muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          color: active ? _ink : _muted,
          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _commonItems() => SizedBox(
    height: 104,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _commonItemNames.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final match = _findPreset(_commonItemNames[index])!;
        return SizedBox(
          width: 64,
          child: InkWell(
            key: ValueKey('common-item-${match.item.name}'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => _selectPreset(match.category, match.item),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8E1)),
                  ),
                  child: Icon(
                    match.item.icon ?? match.category.icon,
                    color: _indigo,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  match.item.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _ink),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _categoryDirectory() => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BreezeSurface(
      radius: 18,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < _itemCatalog.length; index++) ...[
            if (index > 0) const Divider(height: 1, color: Color(0xFFE3E9E2)),
            _categorySection(_itemCatalog[index]),
          ],
        ],
      ),
    ),
  );

  Widget _categorySection(_ItemCatalogCategory itemCategory) {
    final expanded = _expandedCategories.contains(itemCategory.name);
    return Column(
      children: [
        InkWell(
          key: ValueKey('item-category-${itemCategory.name}'),
          onTap: () => setState(() {
            expanded
                ? _expandedCategories.remove(itemCategory.name)
                : _expandedCategories.add(itemCategory.name);
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(itemCategory.icon, color: _indigo, size: 25),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    itemCategory.name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: expanded ? 24 : 15,
                  color: _muted,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Container(
            width: double.infinity,
            color: _mist.withValues(alpha: .62),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 16) / 3;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in itemCategory.items)
                      SizedBox(
                        width: width,
                        height: 58,
                        child: OutlinedButton(
                          key: ValueKey(
                            'catalog-item-${itemCategory.name}-${item.name}',
                          ),
                          onPressed: () => _selectPreset(itemCategory, item),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _paper,
                            foregroundColor: _ink,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _searchResults() {
    final query = search.text.trim();
    final matches = <({_ItemCatalogCategory category, _ItemPreset item})>[];
    for (final itemCategory in _itemCatalog) {
      for (final item in itemCategory.items) {
        if (itemCategory.name.contains(query) || item.name.contains(query)) {
          matches.add((category: itemCategory, item: item));
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          matches.isEmpty ? '没有找到相关物品' : '搜索结果',
          style: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (matches.isEmpty)
          BreezeSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('可以把“$query”作为自定义名称添加。'),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('add-custom-search-item'),
                  onPressed: () {
                    final other = _itemCatalog.last;
                    _selectPreset(other, other.items.single, custom: query);
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('添加其他物品'),
                ),
              ],
            ),
          )
        else
          BreezeSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < matches.length; index++) ...[
                  if (index > 0)
                    const Divider(height: 1, color: Color(0xFFE3E9E2)),
                  ListTile(
                    key: ValueKey(
                      'search-item-${matches[index].category.name}-${matches[index].item.name}',
                    ),
                    leading: Icon(
                      matches[index].item.icon ?? matches[index].category.icon,
                      color: _indigo,
                    ),
                    title: Text(matches[index].item.name),
                    subtitle: Text(matches[index].category.name),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                    ),
                    onTap: () => _selectPreset(
                      matches[index].category,
                      matches[index].item,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _selectedItemSummary() => BreezeSurface(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _mist,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(_selectedPresetIcon, size: 31, color: _indigo),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedPresetName ?? '',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(category, style: const TextStyle(color: _muted)),
            ],
          ),
        ),
        TextButton(
          key: const Key('change-selected-item'),
          onPressed: _returnToSelection,
          child: const Text('更换'),
        ),
      ],
    ),
  );

  Widget _optionalInfoGroup() => BreezeSurface(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        _inlineField(
          customName,
          '备注或自定义名称',
          '例如：主卧空调',
          const Key('custom-item-name'),
        ),
        const Divider(height: 1, color: Color(0xFFE3E9E2)),
        _inlineField(location, '存放位置', '选择或输入位置', const Key('item-location')),
        const Divider(height: 1, color: Color(0xFFE3E9E2)),
        InkWell(
          key: const Key('toggle-brand-model'),
          onTap: () => setState(() {
            _brandModelExpanded = !_brandModelExpanded;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 17),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '品牌与型号',
                    style: TextStyle(color: _ink, fontSize: 16),
                  ),
                ),
                Text(
                  [
                        brand.text,
                        model.text,
                      ].where((x) => x.isNotEmpty).join(' · ').isEmpty
                      ? '以后也可以补充'
                      : [
                          brand.text,
                          model.text,
                        ].where((x) => x.isNotEmpty).join(' · '),
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(width: 6),
                Icon(
                  _brandModelExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: _muted,
                  size: _brandModelExpanded ? 22 : 14,
                ),
              ],
            ),
          ),
        ),
        if (_brandModelExpanded) ...[
          const Divider(height: 1, color: Color(0xFFE3E9E2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(brand, '品牌')),
              const SizedBox(width: 10),
              Expanded(child: _field(model, '型号')),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _inlineField(
    TextEditingController controller,
    String label,
    String hint,
    Key key,
  ) => TextFormField(
    key: key,
    controller: controller,
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    ),
  );

  Widget _advancedInfoGroup() => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BreezeSurface(
      padding: EdgeInsets.zero,
      radius: 18,
      child: Column(
        children: [
          InkWell(
            key: const Key('toggle-advanced-item-details'),
            onTap: () => setState(() {
              _advancedExpanded = !_advancedExpanded;
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '购买、保修与保养信息',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '需要时再填写',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _advancedExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _muted,
                  ),
                ],
              ),
            ),
          ),
          if (_advancedExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE3E9E2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _dateTile(
                    '购买日期',
                    purchase,
                    (d) => setState(() => purchase = d),
                  ),
                  _dateTile(
                    '保修截止',
                    warranty,
                    (d) => setState(() => warranty = d),
                  ),
                  const SizedBox(height: 6),
                  MaintenancePlansEditorSection(
                    plans: plans,
                    records: widget.item?.records ?? const [],
                    onChanged: (value) => setState(() => plans = value),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '凭证照片',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _photos(),
                  const SizedBox(height: 16),
                  _field(notes, '备注', maxLines: 4),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );

  ({_ItemCatalogCategory category, _ItemPreset item})? _findPreset(
    String name,
  ) {
    for (final itemCategory in _itemCatalog) {
      for (final item in itemCategory.items) {
        if (item.name == name) return (category: itemCategory, item: item);
      }
    }
    return null;
  }

  void _selectPreset(
    _ItemCatalogCategory itemCategory,
    _ItemPreset item, {
    String? custom,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      category = itemCategory.name;
      _selectedPresetName = item.name;
      _selectedPresetIcon = item.icon ?? itemCategory.icon;
      customName.text = custom ?? '';
      name.text = item.name;
      _showSupplement = true;
      _allowSupplementPop = false;
      _advancedExpanded = false;
      _brandModelExpanded = false;
    });
  }

  void _returnToSelection() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showSupplement = false);
  }

  void _toggleAllCategories() {
    setState(() {
      if (_expandedCategories.length == _itemCatalog.length) {
        _expandedCategories.clear();
      } else {
        _expandedCategories
          ..clear()
          ..addAll(_itemCatalog.map((entry) => entry.name));
      }
    });
  }

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
                      final result = await showAppDatePicker(
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
    } else if (result.permission case final permission?) {
      await showSystemPermissionAlert(
        context,
        permission: permission,
        state: result.permissionState!,
      );
    } else if (result.error) {
      AppToast.show(
        context,
        source == ImageSource.camera
            ? '无法打开相机，请检查“相机”权限后重试。'
            : '无法读取照片，请检查“照片”权限后重试。',
        style: AppToastStyle.error,
      );
    }
  }

  Future<void> _save() async {
    if (widget.item == null && _selectedPresetName == null) return;
    if (widget.item == null) {
      final hiddenAdvancedError =
          _nonNegativeNumber(purchasePrice.text) ??
          _nonNegativeNumber(currentValue.text);
      if (hiddenAdvancedError != null) {
        setState(() => _advancedExpanded = true);
        AppToast.show(context, hiddenAdvancedError, style: AppToastStyle.error);
        return;
      }
    }
    if (!(form.currentState?.validate() ?? false)) return;
    final resolvedName = widget.item == null
        ? (customName.text.trim().isEmpty
              ? _selectedPresetName!
              : customName.text.trim())
        : name.text.trim();
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
              name: resolvedName,
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
      if (mounted) {
        setState(() => _allowSupplementPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(context, '保存失败，请稍后重试。', style: AppToastStyle.error);
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
      if (access == NotificationAccess.denied) {
        await showSystemPermissionAlert(
          context,
          permission: SystemPermissionKind.notifications,
          state: SystemPermissionState.denied,
        );
      } else if (access == NotificationAccess.unavailable) {
        await showSystemPermissionAlert(
          context,
          permission: SystemPermissionKind.notifications,
          state: SystemPermissionState.unavailable,
        );
      } else {
        final message = access == NotificationAccess.enabled
            ? '保养提醒已开启'
            : '暂未开启通知';
        AppToast.show(
          context,
          message,
          style: access == NotificationAccess.enabled
              ? AppToastStyle.success
              : AppToastStyle.info,
        );
      }
    } catch (_) {
      // Notification setup must never turn a successful item save into failure.
    }
  }
}
