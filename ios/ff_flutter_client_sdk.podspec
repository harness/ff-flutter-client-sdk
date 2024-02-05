#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ff_flutter_client_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |ff|
  ff.name             = 'ff_flutter_client_sdk'
  ff.version          = '1.1.3'
  ff.summary          = 'Flutter SDK for Harness Feature Flags Management'
  ff.description      = <<-DESC
Feature Flag Management platform from Harness. Flutter SDK can be used to integrate with the platform in your Flutter applications.
                       DESC
  ff.homepage         = 'https://github.com/harness/ff-flutter-client-sdk'
  ff.license          = { :type => "Apache License, Version 2.0", :file => "../LICENSE" }
  ff.author           = "Harness Inc"
  ff.source           = { :git => ff.homepage + '.git', :tag => ff.version }
  ff.source_files = 'Classes/**/*'

  ff.dependency 'Flutter'
  ff.dependency 'ff-ios-client-sdk', '1.1.2'
  ff.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice.
  ff.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  ff.swift_version = '5.0'
end
