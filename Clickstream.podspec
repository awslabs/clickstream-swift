Pod::Spec.new do |s|
  s.name             = 'Clickstream'
  s.version          = '0.5.1'
  s.summary          = 'aws solution clickstream analytics swift sdk'
  s.homepage         = 'https://github.com/awslabs/clickstream-swift'
  s.license          = { :type => 'Apache License 2.0', :file => 'LICENSE' }
  s.author           = { 'zhu-xiaowei' => 'xiaoweii@amazom.com' }
  s.source           = { :git => "https://github.com/awslabs/clickstream-swift.git",
                         :tag => s.version }
  s.module_name = 'Clickstream'
  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5.7']
  s.source_files = 'Sources/Clickstream/**/*'

  s.dependency 'GzipSwift', '5.1.1'
  s.dependency 'Amplify', '1.30.3'
  s.dependency 'SQLite.swift', '0.13.2'
end
