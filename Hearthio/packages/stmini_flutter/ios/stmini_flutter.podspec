#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint stmini_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'stmini_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter host for STMini online Mini programs.'
  s.description      = <<-DESC
Reusable Flutter host for verified, downloadable STMini packages.
                       DESC
  s.homepage         = 'https://example.invalid/stmini_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  # STMini is vendored with the plugin so the consuming Flutter App has no
  # dependency on a different App project's absolute source path.
  s.source_files = 'Classes/**/*', 'STMini/classes/**/*'
  s.resource_bundles = {
    'STMini' => ['STMini/assets/*.bundle']
  }
  s.dependency 'Flutter'
  s.dependency 'Masonry'
  s.dependency 'SDWebImage'
  s.dependency 'HXWRefresh'
  s.dependency 'MBProgressHUD'
  s.dependency 'Toast-Swift'
  s.dependency 'ZIPFoundation', '~> 0.9'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'stmini_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
