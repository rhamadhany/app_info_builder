#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'app_info_builder'
  s.version          = '0.0.2'
  s.summary          = 'Build-time app metadata generator.'
  s.description      = <<-DESC
Build-time app metadata generator — writes compile-time Dart constants.
                       DESC
  s.homepage         = 'https://github.com/rhamadhany/app_info_builder'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BNeoTech' => 'dev@bneotech.example' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Build-time hook: regenerate lib/generated/app_info.dart in the HOST app
  # project before the pod compiles. Inside a pod script phase the pod's own
  # source dir points at the pod, NOT the host app. Use PROJECT_DIR (the folder
  # containing the .xcodeproj = {app}/ios/) then go up one level.
  s.script_phase = {
    :name => 'Generate AppInfo',
    :script => 'cd "${PROJECT_DIR}/.." && /usr/bin/env dart run app_info_builder:generate',
    :execution_position => :before_compile,
    :shell_path => '/bin/sh'
  }
end
