import 'package:flutter/material.dart';

const _alertPaper = Color(0xFFFFFEFA);
const _alertInk = Color(0xFF263630);
const _alertGreen = Color(0xFF137B67);
const _alertRed = Color(0xFFB42318);
const _alertDivider = Color(0xFFE2E9E2);
const _alertScrim = Color(0x990F1714);

enum AppAlertActionTone { standard, destructive }

class AppAlertAction<T> {
  const AppAlertAction({
    required this.label,
    required this.result,
    this.key,
    this.tone = AppAlertActionTone.standard,
    this.isDefaultAction = false,
  });

  final String label;
  final T result;
  final Key? key;
  final AppAlertActionTone tone;
  final bool isDefaultAction;
}

Future<T?> showAppAlert<T>(
  BuildContext context, {
  Key? key,
  required String title,
  required String message,
  required List<AppAlertAction<T>> actions,
  bool barrierDismissible = true,
}) {
  assert(actions.isNotEmpty, 'An alert needs at least one action.');
  return showDialog<T>(
    context: context,
    barrierColor: _alertScrim,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => AppAlertDialog<T>(
      key: key,
      title: title,
      message: message,
      actions: actions,
    ),
  );
}

class AppAlertDialog<T> extends StatelessWidget {
  const AppAlertDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<AppAlertAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    assert(actions.isNotEmpty, 'An alert needs at least one action.');
    final availableHeight = MediaQuery.sizeOf(context).height - 48;
    final messageAlign = message.length > 58 || message.contains('\n')
        ? TextAlign.left
        : TextAlign.center;

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Dialog(
        backgroundColor: _alertPaper,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        elevation: 14,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          key: const Key('app-alert-surface'),
          constraints: BoxConstraints(
            maxWidth: 318,
            maxHeight: availableHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _alertInk,
                          fontSize: 20,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        message,
                        textAlign: messageAlign,
                        style: const TextStyle(
                          color: _alertInk,
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _AppAlertActions<T>(actions: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppAlertActions<T> extends StatelessWidget {
  const _AppAlertActions({required this.actions});

  final List<AppAlertAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.length == 1) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _alertDivider)),
        ),
        child: _AppAlertActionButton<T>(action: actions.single),
      );
    }

    if (actions.length == 2) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _alertDivider)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _AppAlertActionButton<T>(action: actions[0])),
              const SizedBox(width: 1, child: ColoredBox(color: _alertDivider)),
              Expanded(child: _AppAlertActionButton<T>(action: actions[1])),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions)
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _alertDivider)),
            ),
            child: _AppAlertActionButton<T>(action: action),
          ),
      ],
    );
  }
}

class _AppAlertActionButton<T> extends StatelessWidget {
  const _AppAlertActionButton({required this.action});

  final AppAlertAction<T> action;

  @override
  Widget build(BuildContext context) {
    final foreground = action.tone == AppAlertActionTone.destructive
        ? _alertRed
        : _alertGreen;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: TextButton(
        key: action.key,
        onPressed: () => Navigator.of(context).pop(action.result),
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(foreground),
          overlayColor: WidgetStatePropertyAll(
            foreground.withValues(alpha: 0.08),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 60)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        ),
        child: Text(
          action.label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            height: 1.2,
            fontWeight:
                action.isDefaultAction ||
                    action.tone == AppAlertActionTone.destructive
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
