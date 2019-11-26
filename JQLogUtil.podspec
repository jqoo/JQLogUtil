#
# Be sure to run `pod lib lint JQLogUtil.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JQLogUtil'
  s.version          = '0.1.0'
  s.summary          = 'A short description of JQLogUtil.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/jqoo/JQLogUtil'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jqoo' => 'jinquanzhang@blackfish.cn' }
  s.source           = { :git => 'https://github.com/jqoo/JQLogUtil.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |ss|
    ss.ios.deployment_target = '8.0'
    ss.source_files = 'JQLogUtil/Classes/**/*'
    ss.dependency 'CocoaLumberjack', '~> 3.5'
  end
  
  s.subspec 'DevTool' do |ss|
    ss.ios.deployment_target = '9.0'
    ss.source_files = 'JQLogUtil/DevTool/**/*'
    ss.dependency 'XLForm', '~> 4.0'
    ss.dependency 'FLEX', '~> 2.4'
    ss.dependency 'QMUIKit', '~> 4.0'
    ss.dependency 'JQLogUtil/Core'
  end

  # s.resource_bundles = {
  #   'JQLogUtil' => ['JQLogUtil/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
