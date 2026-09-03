#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint stmini_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'stmini_flutter'
  s.version          = '0.1.1'
  s.summary          = 'Flutter host for STMini online Mini programs.'
  s.description      = <<-DESC
Reusable Flutter host for verified, downloadable STMini packages.
                       DESC
  s.homepage         = 'https://github.com/fsst-ios/stmini_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'FSST iOS' => 'https://github.com/fsst-ios' }
  s.source           = { :path => '.' }
  # STMini is vendored with the plugin so the consuming Flutter App has no
  # dependency on a different App project's absolute source path.
  s.source_files = 'Classes/**/*', 'STMini/classes/**/*'
  # This legacy helper is not referenced by the download implementation. Keep
  # the unused required-reason disk-space API out of the compiled framework.
  s.exclude_files = 'STMini/classes/lib/Network/Download/Tiercel/Extensions/UIDevice+Free.swift'
  # A dynamic framework must carry its own manifest at the framework root.
  s.resources = ['Resources/PrivacyInfo.xcprivacy']
  s.resource_bundles = {
    'STMini' => ['STMini/assets/*.bundle']
  }
  s.dependency 'Flutter'
  s.dependency 'Masonry'
  s.dependency 'SDWebImage'
  s.dependency 'HXWRefresh'
  s.dependency 'Toast-Swift'
  s.dependency 'ZIPFoundation', '~> 0.9'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

end
