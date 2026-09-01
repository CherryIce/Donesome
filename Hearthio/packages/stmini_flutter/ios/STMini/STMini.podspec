Pod::Spec.new do |s|
  s.name                 = "STMini"
  s.version              = "1.0.0"
  s.summary              = "小程序组件"
  s.author               = "hxw"
  s.homepage             = "http://www.baidu.com"
  s.platform             = :ios, "12"
  s.source               = { :git => 'https://github.com/', :tag => s.version.to_s }
  s.source_files        = 'classes/**/*'
  s.exclude_files       = 'classes/**/*.md', '**/readme.md'
  s.resource_bundles = {
    'STMini' => ['assets/*.bundle']
  }
  s.dependency 'Masonry'
  s.dependency 'SDWebImage'
  s.dependency 'HXWRefresh'
  s.dependency 'MBProgressHUD'
  s.dependency 'Toast-Swift'
  s.dependency 'ZIPFoundation', '~> 0.9'

end
