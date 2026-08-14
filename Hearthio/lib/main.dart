import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:archive/archive.dart';
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
    (Icons.auto_graph_rounded, Icons.auto_graph_rounded, '资产'),
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
  final VoidCallback onTap;
  final Color tone;

  @override
  Widget build(BuildContext context) => Material(
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
                color: tone.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: tone),
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
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    ),
  );
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

class PhotoImportResult {
  const PhotoImportResult._({this.path, this.error = false});
  const PhotoImportResult.cancelled() : this._();
  const PhotoImportResult.failed() : this._(error: true);
  const PhotoImportResult.success(String path) : this._(path: path);

  final String? path;
  final bool error;
}

enum NotificationAccess { enabled, denied, unavailable }

class CareItem {
  CareItem({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.brand,
    required this.model,
    required this.notes,
    required this.photos,
    this.records = const [],
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.warrantyDate,
    this.lastCareDate,
    this.intervalDays,
  });

  final String id;
  final String name;
  final String category;
  final String location;
  final String brand;
  final String model;
  final String notes;
  final List<String> photos;
  final List<MaintenanceRecord> records;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final DateTime? warrantyDate;
  final DateTime? lastCareDate;
  final int? intervalDays;

  DateTime? get nextCareDate =>
      lastCareDate == null || intervalDays == null || intervalDays! <= 0
      ? null
      : lastCareDate!.add(Duration(days: intervalDays!));

  String get status {
    final date = nextCareDate;
    if (date == null) return '未设置';
    final today = DateUtils.dateOnly(DateTime.now());
    final due = DateUtils.dateOnly(date);
    if (due.isBefore(today)) return '已逾期';
    if (due.difference(today).inDays <= 30) return '30 天内';
    return '已计划';
  }

  bool get isOverdue => status == '已逾期';
  bool get isSoon => status == '30 天内';

  CareItem copyWith({
    String? name,
    String? category,
    String? location,
    String? brand,
    String? model,
    String? notes,
    List<String>? photos,
    List<MaintenanceRecord>? records,
    DateTime? purchaseDate,
    double? purchasePrice,
    double? currentValue,
    DateTime? warrantyDate,
    DateTime? lastCareDate,
    int? intervalDays,
    bool clearPurchaseDate = false,
    bool clearPurchasePrice = false,
    bool clearCurrentValue = false,
    bool clearWarrantyDate = false,
    bool clearLastCareDate = false,
    bool clearInterval = false,
  }) => CareItem(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    location: location ?? this.location,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    notes: notes ?? this.notes,
    photos: photos ?? this.photos,
    records: records ?? this.records,
    purchaseDate: clearPurchaseDate ? null : purchaseDate ?? this.purchaseDate,
    purchasePrice: clearPurchasePrice
        ? null
        : purchasePrice ?? this.purchasePrice,
    currentValue: clearCurrentValue ? null : currentValue ?? this.currentValue,
    warrantyDate: clearWarrantyDate ? null : warrantyDate ?? this.warrantyDate,
    lastCareDate: clearLastCareDate ? null : lastCareDate ?? this.lastCareDate,
    intervalDays: clearInterval ? null : intervalDays ?? this.intervalDays,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'location': location,
    'brand': brand,
    'model': model,
    'notes': notes,
    'photos': photos,
    'records': records.map((record) => record.toJson()).toList(),
    'purchaseDate': purchaseDate?.toIso8601String(),
    'purchasePrice': purchasePrice,
    'currentValue': currentValue,
    'warrantyDate': warrantyDate?.toIso8601String(),
    'lastCareDate': lastCareDate?.toIso8601String(),
    'intervalDays': intervalDays,
  };

  factory CareItem.fromJson(Map<String, dynamic> json) => CareItem(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String? ?? '其他',
    location: json['location'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    model: json['model'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    photos: List<String>.from(json['photos'] as List? ?? const []),
    records: (json['records'] as List? ?? const [])
        .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    purchaseDate: _parseDate(json['purchaseDate']),
    purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
    currentValue: (json['currentValue'] as num?)?.toDouble(),
    warrantyDate: _parseDate(json['warrantyDate']),
    lastCareDate: _parseDate(json['lastCareDate']),
    intervalDays: json['intervalDays'] as int?,
  );
}

class MaintenanceRecord {
  const MaintenanceRecord({
    required this.date,
    required this.kind,
    required this.cost,
    required this.note,
  });
  final DateTime date;
  final String kind;
  final double cost;
  final String note;
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'kind': kind,
    'cost': cost,
    'note': note,
  };
  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      MaintenanceRecord(
        date: DateTime.parse(json['date'] as String),
        kind: json['kind'] as String? ?? '保养',
        cost: (json['cost'] as num? ?? 0).toDouble(),
        note: json['note'] as String? ?? '',
      );
}

DateTime? _parseDate(dynamic value) =>
    value == null ? null : DateTime.tryParse(value as String);
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

String? _positiveWholeNumber(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final number = int.tryParse(text);
  if (number == null || number <= 0) return '请输入大于 0 的整数天数';
  return null;
}

class CareStore extends ChangeNotifier {
  final _notifications = FlutterLocalNotificationsPlugin();
  Future<void>? _notificationsReady;
  Future<void> _persistenceTail = Future.value();
  List<CareItem> items = [];
  bool loaded = false;

  Future<void> _ensureNotificationsReady() =>
      _notificationsReady ??= _initializeNotifications().catchError((_) {});

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('care_items');
      if (raw != null) {
        items = (jsonDecode(raw) as List)
            .map((e) => CareItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        items = _examples;
        await _persist();
      }
    } catch (_) {
      // A damaged local cache must never prevent the app from opening.
      items = [];
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> save(CareItem item) async {
    final index = items.indexWhere((e) => e.id == item.id);
    if (index == -1) {
      items.add(item);
    } else {
      final removedPhotos = items[index].photos.where(
        (path) => !item.photos.contains(path),
      );
      items[index] = item;
      for (final path in removedPhotos) {
        unawaited(_deletePhoto(path));
      }
    }
    // Update UI optimistically. A local file write must not hold the editor
    // open or make the inventory look stale.
    notifyListeners();
    _queuePersist();
    // A notification failure must never block saving an item or navigating
    // away from the editor.
    unawaited(_scheduleSafely(item));
  }

  void _queuePersist() {
    // Capture this version and serialize writes, so an older asynchronous
    // write can never overwrite a newer edit on disk.
    final snapshot = jsonEncode(items.map((e) => e.toJson()).toList());
    _persistenceTail = _persistenceTail.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('care_items', snapshot);
      } catch (_) {
        /* the following edit retries persistence */
      }
    });
  }

  Future<void> _deletePhoto(String path) async {
    try {
      await File(path).delete();
    } catch (_) {
      /* no-op */
    }
  }

  Future<void> remove(CareItem item) async {
    items.removeWhere((e) => e.id == item.id);
    notifyListeners();
    _queuePersist();
    for (final path in item.photos) {
      unawaited(_deletePhoto(path));
    }
    unawaited(_cancelNotificationSafely(item.id));
  }

  Future<void> addRecord(CareItem item, MaintenanceRecord record) {
    final records = [...item.records, record]
      ..sort((a, b) => b.date.compareTo(a.date));
    return save(item.copyWith(records: records, lastCareDate: record.date));
  }

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
    final archive = Archive();
    archive.addFile(
      ArchiveFile.string(
        'data.json',
        jsonEncode(items.map((e) => e.toJson()).toList()),
      ),
    );
    for (final item in items) {
      for (final path in item.photos) {
        final file = File(path);
        if (await file.exists()) {
          archive.addFile(
            ArchiveFile(
              'photos/${file.uri.pathSegments.last}',
              await file.length(),
              await file.readAsBytes(),
            ),
          );
        }
      }
    }
    final bytes = ZipEncoder().encode(archive);
    final file = File(
      '${(await getTemporaryDirectory()).path}/Hearthio-backup.zip',
    );
    await file.writeAsBytes(bytes, flush: true);
    if (context.mounted) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], title: 'Hearthio backup'),
      );
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

  Future<bool> restoreBackup() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final source = picked?.files.single.path;
    if (source == null) return false;
    try {
      final archive = ZipDecoder().decodeBytes(
        await File(source).readAsBytes(),
      );
      final dataFile = archive.findFile('data.json');
      if (dataFile == null) return false;
      // Validate the archive before writing anything into the app directory.
      final sourceItems =
          (jsonDecode(utf8.decode(dataFile.readBytes()!)) as List)
              .map((e) => CareItem.fromJson(e as Map<String, dynamic>))
              .toList();
      final root = await getApplicationDocumentsDirectory();
      final images = Directory('${root.path}/item-photos');
      await images.create(recursive: true);
      final backupPhotos = {
        for (final file in archive.files.where(
          (file) => file.name.startsWith('photos/') && file.isFile,
        ))
          file.name.split('/').last: file.readBytes()!,
      };
      for (final entry in backupPhotos.entries) {
        await File(
          '${images.path}/${entry.key}',
        ).writeAsBytes(entry.value, flush: true);
      }
      final restored = sourceItems
          .map(
            (item) => item.copyWith(
              photos: item.photos
                  .map((path) => File(path).uri.pathSegments.last)
                  .where(backupPhotos.containsKey)
                  .map((name) => '${images.path}/$name')
                  .toList(),
            ),
          )
          .toList();
      for (final oldItem in items) {
        unawaited(_cancelNotificationSafely(oldItem.id));
      }
      items = restored;
      // Keep restoration responsive even for a backup containing many photos.
      // The in-memory list is already complete at this point, so the UI can
      // safely render it while persistence and reminder setup continue.
      notifyListeners();
      _queuePersist();
      for (final item in items) {
        unawaited(_scheduleSafely(item));
      }
      return true;
    } catch (_) {
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
      return permissions?.isAlertEnabled == true
          ? NotificationAccess.enabled
          : NotificationAccess.denied;
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
      await _ensureNotificationsReady();
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios == null) return NotificationAccess.unavailable;
      await ios.requestPermissions(alert: true, badge: false, sound: true);
      final after = await notificationAccess();
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

  Future<bool> sendTestNotification() async {
    try {
      if (await notificationAccess() != NotificationAccess.enabled) {
        return false;
      }
      await _ensureDeviceTimeZone();
      await _notifications.zonedSchedule(
        id: 900001,
        title: '家务志提醒已开启',
        body: '这是一条测试提醒。保养到期前 3 天，你会在这里收到提醒。',
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

  Future<void> requestNotificationsOnFirstHomeOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('notification_permission_prompted') ?? false) return;
      final result = await requestNotifications();
      if (result != NotificationAccess.unavailable) {
        await prefs.setBool('notification_permission_prompted', true);
      }
    } catch (_) {
      // A failed launch prompt must never block the home screen.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'care_items',
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _initializeNotifications() => _notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  Future<void> _schedule(CareItem item) async {
    await _ensureNotificationsReady();
    await _ensureDeviceTimeZone();
    await _notifications.cancel(id: item.id.hashCode);
    final due = item.nextCareDate;
    if (due == null) return;
    final now = tz.TZDateTime.now(tz.local);
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.dateOnly(due).isBefore(today)) return;

    final reminderDate = due.subtract(const Duration(days: 3));
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
      id: item.id.hashCode,
      title: '保养提醒',
      body: '${item.name} 将于 ${_date(due)} 到期，记得安排处理。',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _scheduleSafely(CareItem item) async {
    try {
      await _schedule(item);
    } catch (_) {
      /* saving remains available offline */
    }
  }

  Future<void> _cancelNotificationSafely(String itemId) async {
    try {
      await _ensureNotificationsReady();
      await _notifications.cancel(id: itemId.hashCode);
    } catch (_) {
      /* notification state never blocks item changes */
    }
  }

  static final _examples = [
    CareItem(
      id: 'sample-filter',
      name: '厨房净水器',
      category: '滤芯与耗材',
      location: '厨房',
      brand: '',
      model: '',
      notes: '示例：更换滤芯后记录日期和型号。',
      photos: [],
      lastCareDate: DateTime.now().subtract(const Duration(days: 150)),
      intervalDays: 180,
    ),
    CareItem(
      id: 'sample-ac',
      name: '客厅空调',
      category: '家电',
      location: '客厅',
      brand: '',
      model: '',
      notes: '示例：每年换季前清洗滤网。',
      photos: [],
      lastCareDate: DateTime.now().subtract(const Duration(days: 300)),
      intervalDays: 365,
    ),
  ];
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final store = CareStore();
  int tab = 0;
  @override
  void initState() {
    super.initState();
    store.load();
    // The native alert appears only after the first frame, keeping the home
    // screen responsive while still asking on the user's first app entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(store.requestNotificationsOnFirstHomeOpen());
    });
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final pages = [
        Dashboard(store: store),
        InventoryPage(store: store),
        SchedulePage(store: store),
        AssetLedgerPage(store: store),
        SettingsPage(store: store),
      ];
      return Scaffold(
        body: SafeArea(child: pages[tab]),
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
    final upcoming = [...store.items]
      ..sort(
        (a, b) => (a.nextCareDate ?? DateTime(9999)).compareTo(
          b.nextCareDate ?? DateTime(9999),
        ),
      );
    final scheduledItems = upcoming
        .where((item) => item.nextCareDate != null)
        .toList(growable: false);
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
                      _stat(
                        '待处理',
                        '${store.items.where((x) => x.isOverdue || x.isSoon).length}',
                        _amber,
                      ),
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
                    '近期保养 · Upcoming care',
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
        if (scheduledItems.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.event_available, text: '还没有设置保养计划'),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = scheduledItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: ItemCard(
                    item: item,
                    onTap: () => _open(context, item),
                  ),
                );
              },
              childCount: scheduledItems.length,
              // ItemCard already owns a repaint boundary. Avoid adding a
              // second layer for every child while the list is scrolling.
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
  void _open(BuildContext c, CareItem item) => Navigator.push(
    c,
    MaterialPageRoute(
      builder: (_) => DetailPage(store: store, item: item),
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
                      confirmDismiss: (_) => _confirmDelete(context, item),
                      onDismissed: (_) => widget.store.remove(item),
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
    final list =
        widget.store.items.where((e) => e.nextCareDate != null).toList()
          ..sort((a, b) => a.nextCareDate!.compareTo(b.nextCareDate!));
    if (list.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreezeHeader(title: '保养日程', subtitle: '把需要照料的事情留给合适的时间'),
          Expanded(
            child: EmptyState(
              icon: Icons.calendar_today_outlined,
              text: '添加物品后设置维护周期',
            ),
          ),
        ],
      );
    }

    final byDay = <DateTime, List<CareItem>>{};
    for (final item in list) {
      final day = DateUtils.dateOnly(item.nextCareDate!);
      (byDay[day] ??= []).add(item);
    }
    final selectedItems = byDay[_selectedDay] ?? const <CareItem>[];
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        const SliverToBoxAdapter(
          child: BreezeHeader(title: '保养日程', subtitle: '点选日期，查看当天需要照料的物品'),
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
                  selectedItems.isEmpty ? '暂无安排' : '${selectedItems.length} 项',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (selectedItems.isEmpty)
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
            itemCount: selectedItems.length,
            itemBuilder: (context, index) {
              final item = selectedItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
  final Map<DateTime, List<CareItem>> scheduledDays;
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
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('暂时无法读取通知状态，请稍后重试')));
  }

  Future<void> _showReminderTools() async {
    final scheduledItems = store.items
        .where((item) => item.nextCareDate != null)
        .length;
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
                scheduledItems == 0
                    ? '还没有设置保养周期的物品。添加周期后，系统会在到期前 3 天提醒你。'
                    : '已为 $scheduledItems 个保养计划安排本机提醒，到期前 3 天的上午 9:00 通知你。',
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
                subtitle: '选择此前导出的 Hearthio-backup.zip',
                onTap: () => _restoreFromBackup(context),
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
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: BreezeSurface(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, color: _indigo),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '本应用不需要注册，也不上传物品、照片或维护记录。照片仅在你主动选择后复制到本机应用目录。',
                  style: TextStyle(color: _muted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<void> _restoreFromBackup(BuildContext context) async {
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
            ok ? '备份已恢复：物品、记录和照片已更新' : '没有选择有效的 Hearthio-backup.zip，当前档案未发生变化',
          ),
        ),
      );
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

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.store, required this.item});
  final CareStore store;
  final CareItem item;
  @override
  Widget build(BuildContext context) => Scaffold(
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
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditorPage(store: store, item: item),
                ),
              );
              if (saved == true && context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailPage(
                      store: store,
                      item: store.items.firstWhere(
                        (entry) => entry.id == item.id,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    ),
    body: ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(20),
      children: [
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
        const SizedBox(height: 18),
        _section('保养状态', [
          ('状态', item.status),
          ('下次保养', _date(item.nextCareDate)),
          ('上次保养', _date(item.lastCareDate)),
          (
            '保养周期',
            item.intervalDays == null ? '未设置' : '每 ${item.intervalDays} 天',
          ),
        ]),
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
        _records(context),
        FilledButton.icon(
          icon: const Icon(Icons.add_task_outlined),
          label: const Text('记录一次保养 / Add maintenance record'),
          onPressed: () => _addRecord(context),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          icon: const Icon(Icons.delete_outline),
          label: const Text('删除此物品'),
          onPressed: () async {
            await store.remove(item);
            if (context.mounted) Navigator.pop(context);
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
  Widget _records(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18, top: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '维护记录 · History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 8),
        if (item.records.isEmpty)
          const BreezeSurface(
            child: Text(
              '暂无记录 / No records yet',
              style: TextStyle(color: _muted),
            ),
          )
        else
          BreezeSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: List.generate(item.records.take(8).length, (index) {
                final record = item.records[index];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: _mist,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.build_circle_outlined,
                              size: 18,
                              color: _indigo,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.kind,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_date(record.date)}${record.note.isEmpty ? '' : ' · ${record.note}'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (record.cost != 0)
                            Text(
                              '¥${record.cost.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: _indigo,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (index < item.records.take(8).length - 1)
                      const Divider(height: 1, color: Color(0xFFE8EDE7)),
                  ],
                );
              }),
            ),
          ),
      ],
    ),
  );
  Future<void> _addRecord(BuildContext context) async {
    final kind = TextEditingController(text: '保养');
    final cost = TextEditingController();
    final note = TextEditingController();
    final form = GlobalKey<FormState>();
    final result = await showModalBottomSheet<MaintenanceRecord>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(sheet).bottom + 20,
        ),
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '维护记录 · Maintenance',
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kind,
                decoration: const InputDecoration(
                  labelText: '类型 / Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: cost,
                keyboardType: TextInputType.number,
                validator: _nonNegativeNumber,
                decoration: const InputDecoration(
                  labelText: '花费 / Cost',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  labelText: '备注 / Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (!(form.currentState?.validate() ?? false)) return;
                  Navigator.pop(
                    sheet,
                    MaintenanceRecord(
                      date: DateTime.now(),
                      kind: kind.text.trim().isEmpty ? '保养' : kind.text.trim(),
                      cost: double.tryParse(cost.text) ?? 0,
                      note: note.text.trim(),
                    ),
                  );
                },
                child: const Text('保存 / Save'),
              ),
            ],
          ),
        ),
      ),
    );
    kind.dispose();
    cost.dispose();
    note.dispose();
    if (result != null) {
      await store.addRecord(item, result);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPage(
              store: store,
              item: store.items.firstWhere((e) => e.id == item.id),
            ),
          ),
        );
      }
    }
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
      interval,
      purchasePrice,
      currentValue;
  late String category;
  DateTime? purchase, warranty, last;
  late List<String> photos;
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
    interval = TextEditingController(text: x?.intervalDays?.toString());
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
    last = x?.lastCareDate;
    photos = [...?x?.photos];
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
      interval,
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
            '时间与保养',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          _dateTile('购买日期', purchase, (d) => setState(() => purchase = d)),
          _dateTile('保修截止', warranty, (d) => setState(() => warranty = d)),
          _dateTile('上次保养', last, (d) => setState(() => last = d)),
          _field(
            interval,
            '保养周期（天）',
            type: TextInputType.number,
            validator: _positiveWholeNumber,
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
    final days = int.tryParse(interval.text.trim());
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
              purchaseDate: purchase,
              warrantyDate: warranty,
              lastCareDate: last,
              intervalDays: days,
              purchasePrice: double.tryParse(purchasePrice.text.trim()),
              currentValue: double.tryParse(currentValue.text.trim()),
              clearPurchasePrice: purchasePrice.text.trim().isEmpty,
              clearCurrentValue: currentValue.text.trim().isEmpty,
              clearPurchaseDate: purchase == null,
              clearWarrantyDate: warranty == null,
              clearLastCareDate: last == null,
              clearInterval: days == null,
            );
    try {
      await widget.store.save(item);
      _saved = true;
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请稍后重试。')));
      }
    }
  }
}
