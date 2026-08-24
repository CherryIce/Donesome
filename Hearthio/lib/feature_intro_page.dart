import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'theme/app_theme.dart';
import 'widgets/app_back_button.dart';
import 'widgets/app_safe_area.dart';

class FeatureIntroPage extends StatelessWidget {
  const FeatureIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.featureIntroTitle),
      ),
      body: ListView(
        key: const Key('feature-intro-list'),
        padding: appSafeScrollPadding(
          context,
          const EdgeInsets.fromLTRB(20, 12, 20, 32),
        ),
        children: [
          _FeatureIntroHero(
            eyebrow: l10n.featureIntroHeroEyebrow,
            title: l10n.featureIntroHeroTitle,
            body: l10n.featureIntroHeroBody,
          ),
          const SizedBox(height: 22),
          Text(
            l10n.featureIntroStepsTitle,
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureStepCard(
            key: const Key('feature-intro-step-archive'),
            number: '01',
            icon: Icons.inventory_2_outlined,
            title: l10n.featureIntroArchiveTitle,
            body: l10n.featureIntroArchiveBody,
          ),
          const SizedBox(height: 12),
          _FeatureStepCard(
            key: const Key('feature-intro-step-plan'),
            number: '02',
            icon: Icons.event_repeat_rounded,
            title: l10n.featureIntroPlanTitle,
            body: l10n.featureIntroPlanBody,
          ),
          const SizedBox(height: 12),
          _FeatureStepCard(
            key: const Key('feature-intro-step-complete'),
            number: '03',
            icon: Icons.task_alt_rounded,
            title: l10n.featureIntroCompleteTitle,
            body: l10n.featureIntroCompleteBody,
          ),
          const SizedBox(height: 12),
          _FeatureStepCard(
            key: const Key('feature-intro-step-review'),
            number: '04',
            icon: Icons.insights_rounded,
            title: l10n.featureIntroReviewTitle,
            body: l10n.featureIntroReviewBody,
          ),
          const SizedBox(height: 18),
          _FeatureTip(
            key: const Key('feature-intro-sample-tip'),
            title: l10n.featureIntroSampleTipTitle,
            body: l10n.featureIntroSampleTipBody,
          ),
          const SizedBox(height: 12),
          _FeatureTip(
            icon: Icons.shield_outlined,
            title: l10n.featureIntroBackupTitle,
            body: l10n.featureIntroBackupBody,
          ),
        ],
      ),
    );
  }
}

class _FeatureIntroHero extends StatelessWidget {
  const _FeatureIntroHero({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.palette.mist,
          context.palette.accent.withValues(alpha: .14),
        ],
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: context.palette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.paper.withValues(alpha: .82),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      eyebrow,
                      style: TextStyle(
                        color: context.palette.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: TextStyle(
                      color: context.palette.ink,
                      fontSize: 24,
                      height: 1.2,
                      letterSpacing: -.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: context.palette.paper.withValues(alpha: .86),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work_outlined,
                color: context.palette.primary,
                size: 29,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          body,
          style: TextStyle(
            color: context.palette.muted,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

class _FeatureStepCard extends StatelessWidget {
  const _FeatureStepCard({
    super.key,
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.palette.paper,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.palette.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.palette.mist,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: context.palette.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: context.palette.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    number,
                    style: TextStyle(
                      color: context.palette.subtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                body,
                style: TextStyle(
                  color: context.palette.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FeatureTip extends StatelessWidget {
  const _FeatureTip({
    super.key,
    this.icon = Icons.lightbulb_outline_rounded,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.palette.successSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.palette.success.withValues(alpha: .22)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.palette.successStrong, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.palette.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: TextStyle(
                  color: context.palette.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
