import 'package:flutter/material.dart';

/// The shared back control used by secondary-page app bars.
///
/// App bars can be taller than the default toolbar. Keeping both the painted
/// button and its constraints square prevents the tonal background from
/// expanding into a vertical capsule.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  static const double dimension = 40;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 14),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox.square(
        dimension: dimension,
        child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          constraints: const BoxConstraints.tightFor(
            width: dimension,
            height: dimension,
          ),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEAF1E9),
            foregroundColor: const Color(0xFF31584B),
            minimumSize: const Size.square(dimension),
            maximumSize: const Size.square(dimension),
            shape: const CircleBorder(),
          ),
          onPressed: onPressed ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
        ),
      ),
    ),
  );
}
