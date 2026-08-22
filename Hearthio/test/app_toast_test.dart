import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/widgets/app_toast.dart';

void main() {
  testWidgets('uses the root overlay below the navigation bar', (tester) async {
    const toastKey = Key('root-overlay-toast');
    const layoutKey = Key('page-layout');
    final nestedEntry = OverlayEntry(
      builder: (context) => Align(
        alignment: Alignment.topLeft,
        child: TextButton(
          key: const Key('show-toast'),
          onPressed: () => AppToast.show(context, '公共提示', key: toastKey),
          child: const Text('显示'),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('页面标题')),
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              key: layoutKey,
              width: 120,
              height: 100,
              child: Overlay(initialEntries: <OverlayEntry>[nestedEntry]),
            ),
          ),
        ),
      ),
    );
    final sizeBefore = tester.getSize(find.byKey(layoutKey));

    await tester.tap(find.byKey(const Key('show-toast')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(toastKey), findsOneWidget);
    expect(tester.getSize(find.byKey(layoutKey)), sizeBefore);
    expect(
      tester.getCenter(find.byKey(toastKey)).dx,
      moreOrLessEquals(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(toastKey)).dy,
      greaterThanOrEqualTo(kToolbarHeight + 8),
    );

    AppToast.dismiss();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('replaces the current toast and applies its style', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(key: Key('page'))),
      ),
    );
    final context = tester.element(find.byKey(const Key('page')));

    AppToast.show(context, '第一条', key: const Key('first-toast'));
    await tester.pump();
    AppToast.show(
      context,
      '第二条',
      key: const Key('second-toast'),
      style: AppToastStyle.error,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('first-toast')), findsNothing);
    expect(find.byKey(const Key('second-toast')), findsOneWidget);
    expect(find.text('第二条'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(find.text('第二条'));
    expect(paragraph.text.style?.inherit, isFalse);
    expect(paragraph.text.style?.decoration, TextDecoration.none);

    AppToast.dismiss();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('dismisses automatically after its duration', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(key: Key('page'))),
      ),
    );
    final context = tester.element(find.byKey(const Key('page')));

    AppToast.show(
      context,
      '短提示',
      key: const Key('timed-toast'),
      duration: const Duration(milliseconds: 500),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('timed-toast')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 180));
    expect(find.byKey(const Key('timed-toast')), findsNothing);
  });
}
