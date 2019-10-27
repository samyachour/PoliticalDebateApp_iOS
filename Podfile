# Uncomment the next line to define a global platform for your project
 platform :ios, '10.0'

target 'PoliticalDebateApp_iOS' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # ignore all warnings from all pods
  inhibit_all_warnings!

  # Pods for PoliticalDebateApp_iOS

  pod 'RxSwift', :git => 'https://github.com/ReactiveX/RxSwift.git'
  pod 'RxCocoa', :git => 'https://github.com/ReactiveX/RxSwift.git'
  pod 'RxDataSources'
  pod 'SwiftLint'
  pod 'Moya/RxSwift', '~> 14.0.0-beta.4'

  target 'PoliticalDebateApp_iOSTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'RxBlocking'
    pod 'RxTest'
  end

  target 'PoliticalDebateApp_iOSUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
