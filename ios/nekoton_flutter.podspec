#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint nekoton_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'nekoton_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for TON wallets core.'
  s.description      = <<-DESC
Flutter plugin for TON wallets core.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.public_header_files = 'Classes**/*.h'
  s.source_files = 'Classes/**/*'
  s.static_framework = true
  s.vendored_libraries = '**/*.a'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386', 'STRIP_STYLE' => 'non-global' }
  s.swift_version = '5.0'
end
