import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/main.dart';
import 'package:hearthio/widgets/system_permission_alert.dart';
import 'package:image_picker/image_picker.dart';

class _FakePermissionGateway implements SystemPermissionGateway {
  _FakePermissionGateway({
    required this.checkedState,
    this.requestedState = SystemPermissionState.granted,
  });

  SystemPermissionState checkedState;
  SystemPermissionState requestedState;
  bool settingsOpened = true;
  int checkCalls = 0;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<SystemPermissionState> check(SystemPermissionKind permission) async {
    checkCalls++;
    return checkedState;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return settingsOpened;
  }

  @override
  Future<SystemPermissionState> request(SystemPermissionKind permission) async {
    requestCalls++;
    checkedState = requestedState;
    return requestedState;
  }
}

void main() {
  test('permission guard checks on every feature call', () async {
    final gateway = _FakePermissionGateway(
      checkedState: SystemPermissionState.granted,
    );
    final guard = SystemPermissionGuard(gateway);

    expect(
      await guard.ensure(SystemPermissionKind.camera),
      SystemPermissionState.granted,
    );
    expect(
      await guard.ensure(SystemPermissionKind.camera),
      SystemPermissionState.granted,
    );

    expect(gateway.checkCalls, 2);
    expect(gateway.requestCalls, 0);
  });

  test('permission guard requests only an undetermined permission', () async {
    final gateway = _FakePermissionGateway(
      checkedState: SystemPermissionState.notDetermined,
      requestedState: SystemPermissionState.limited,
    );

    final state = await SystemPermissionGuard(
      gateway,
    ).ensure(SystemPermissionKind.photoLibrary);

    expect(state, SystemPermissionState.limited);
    expect(gateway.checkCalls, 1);
    expect(gateway.requestCalls, 1);
  });

  test('denied photo import never opens the system picker', () async {
    final gateway = _FakePermissionGateway(
      checkedState: SystemPermissionState.denied,
    );
    var pickerCalls = 0;
    final store = CareStore(
      systemPermissions: SystemPermissionGuard(gateway),
      imagePicker: (source) async {
        pickerCalls++;
        return null;
      },
    );

    final result = await store.importPhoto(ImageSource.camera);

    expect(result.permission, SystemPermissionKind.camera);
    expect(result.permissionState, SystemPermissionState.denied);
    expect(pickerCalls, 0);
    expect(gateway.checkCalls, 1);
    expect(gateway.requestCalls, 0);
  });

  test(
    'first photo import requests permission before opening picker',
    () async {
      final gateway = _FakePermissionGateway(
        checkedState: SystemPermissionState.notDetermined,
        requestedState: SystemPermissionState.granted,
      );
      var pickerCalls = 0;
      final store = CareStore(
        systemPermissions: SystemPermissionGuard(gateway),
        imagePicker: (source) async {
          pickerCalls++;
          return null;
        },
      );

      final result = await store.importPhoto(ImageSource.gallery);

      expect(result.path, isNull);
      expect(result.error, isFalse);
      expect(result.permission, isNull);
      expect(gateway.checkCalls, 1);
      expect(gateway.requestCalls, 1);
      expect(pickerCalls, 1);
    },
  );

  testWidgets('unavailable permission shows guidance and opens settings', (
    tester,
  ) async {
    final gateway = _FakePermissionGateway(
      checkedState: SystemPermissionState.unavailable,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSystemPermissionAlert(
                context,
                permission: SystemPermissionKind.camera,
                state: SystemPermissionState.unavailable,
                gateway: gateway,
              ),
              child: const Text('检查相机'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('检查相机'));
    await tester.pumpAndSettle();

    expect(find.text('相机权限不可用'), findsOneWidget);
    expect(find.textContaining('前往系统设置检查'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-system-permission-settings')));
    await tester.pumpAndSettle();

    expect(gateway.openSettingsCalls, 1);
  });
}
