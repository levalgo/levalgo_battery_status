#
# Syntax reference: http://guides.cocoapods.org/syntax/podspec.html.
# To validate before publishing:
#   pod lib lint ios/levalgo_battery_status.podspec --configuration=Debug --skip-tests
#
Pod::Spec.new do |s|
  s.name             = 'levalgo_battery_status'
  s.version          = '0.1.0'
  s.summary          = 'Battery level and charging state of the device.'
  s.description      = <<-DESC
Flutter plugin exposing the battery level, the charging state and a stream of
state changes. The iOS implementation is written in Objective-C.
                       DESC
  s.homepage         = 'https://github.com/levalgo/levalgo_battery_status'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Luis Vallejo' => 'levalgo03@gmail.com' }
  s.source           = { :path => '.' }

  # The .m files are compiled and the .h files published: the registrant
  # Flutter generates is Objective-C and needs to import the class header.
  s.source_files        = 'Classes/**/*.{h,m}'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain an i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  # The plugin does not track users and uses no required-reason APIs, but
  # Apple expects every dependency to declare its privacy manifest.
  s.resource_bundles = {
    'levalgo_battery_status_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
end
