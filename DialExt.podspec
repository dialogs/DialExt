#
# Be sure to run `pod lib lint DialExt.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DialExt'
  s.version          = '0.1.21'
  s.summary          = 'DialExt – small framework for iOS DialogSDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://bitbucket.transmit.im/projects/DLG/repos/dialext'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Vladlex' => 'vladlexion@gmail.com' }
  s.source           = { :git => 'ssh://git@bitbucket.transmit.im:7999/dlg/dialext.git' }

  s.ios.deployment_target = '10.0'

  s.source_files = 'Example/DialExt/Code/**/*'

  s.dependency 'ProtocolBuffers-Swift'
  s.dependency 'DLGSodium'
  s.dependency 'TrustKit'
  
  s.resource_bundles = {
    'DialExt' => ['Example/DialExt/Resources/**/*']
  }

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

end
