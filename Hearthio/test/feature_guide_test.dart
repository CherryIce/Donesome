import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearthio/feature_guide_page.dart';

void main() {
  test('guide asset mapping follows the resolved app language', () {
    expect(
      featureGuideAssetFor(FeatureGuideTopic.itemProfile, const Locale('zh')),
      'assets/guides/item-profile.zh.html',
    );
    expect(
      featureGuideAssetFor(FeatureGuideTopic.carePlan, const Locale('en')),
      'assets/guides/care-plan.en.html',
    );
    expect(
      featureGuideAssetFor(
        FeatureGuideTopic.completeCare,
        const Locale('zh', 'CN'),
      ),
      'assets/guides/complete-care.zh.html',
    );
    expect(
      featureGuideAssetFor(FeatureGuideTopic.historyReport, const Locale('fr')),
      'assets/guides/history-report.en.html',
    );
  });

  test(
    'each localized HTML guide references an image in the same language',
    () {
      const imageSlugsByGuide = {
        'item-profile': ['item-profile', 'item-profile-details'],
        'care-plan': ['care-plan-entry', 'care-plan'],
        'complete-care': ['complete-care'],
        'history-report': ['lifecycle-record', 'history-report'],
      };
      for (final entry in imageSlugsByGuide.entries) {
        for (final language in ['zh', 'en']) {
          final otherLanguage = language == 'zh' ? 'en' : 'zh';
          final html = File(
            'assets/guides/${entry.key}.$language.html',
          ).readAsStringSync();
          final imageRefs = RegExp(
            r'<img\s+[^>]*src="([^"]+)"',
          ).allMatches(html).map((match) => match.group(1)!).toList();
          expect(
            imageRefs,
            entry.value.map((slug) => 'images/$slug.$language.png').toList(),
          );
          for (final imageRef in imageRefs) {
            expect(imageRef, endsWith('.$language.png'));
            expect(imageRef, isNot(endsWith('.$otherLanguage.png')));
            final image = File('assets/guides/$imageRef');
            expect(image.existsSync(), isTrue, reason: image.path);
            expect(image.lengthSync(), greaterThan(0), reason: image.path);
          }
        }
      }
    },
  );
}
