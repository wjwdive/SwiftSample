
# 定义CocoaPods的索引库源 - CDN源速度更快
source 'https://cdn.cocoapods.org/' # 优先使用CDN源
# source 'https://github.com/CocoaPods/Specs.git' # 注释掉完整git源以避免克隆大型仓库

# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
# 禁用输入输出路径，避免 Podfile.lock 冲突.
# 关闭 input/output paths 设置（修复部分编译警告，提升兼容性）。
install! 'cocoapods', :disable_input_output_paths => true

# 忽略所有 Pod 依赖的编译警告（推荐仅在确定警告无害时使用）。
# ignore all warnings from all dependencies
inhibit_all_warnings!

def dev_pods
  pod 'SwiftLint', '= 0.42.0', configurations: ['Debug']
  pod 'SwiftGen', '= 6.4.0', configurations: ['Debug']
end
def core_pods
  # pod 'RxSwift', '= 5.1.3'
  # pod 'RxRelay', '= 5.1.1'
  pod 'Alamofire', '= 5.3.0'
  pod 'Moya', '= 14.0.0'
  # pod 'Moya/RxSwift', '= 14.0.0'
  pod 'ObjectMapper', '= 4.4.2'
  pod 'Toast-Swift', '= 5.1.0'
end

# def thirdparty_pods
#   pod 'Firebase/Analytics', '= 7.0.0'
#   pod 'Firebase/Crashlytics', '= 7.0.0'
#   pod 'Firebase/RemoteConfig', '= 7.0.0'
#   pod 'Firebase/Performance', '= 7.0.0'
# end

def ui_pods
  pod 'SnapKit', '= 5.0.1'
  pod 'Kingfisher', '= 7.0'
  #pod 'RxCocoa', '= 5.1.1'
  #pod 'RxDataSources', '= 4.0.1'
  # 表格视图优化
  # pod 'DiffableDataSources', '~> 0.9'
  # 视图控制器转场动画
  # pod 'Hero', '~> 1.6'
end

# def test_pods
#   pod 'Quick', '= 3.0.0'
#   pod 'Nimble', '= 9.0.0'
#   pod 'RxTest', '= 5.1.1'
#   pod 'RxBlocking', '= 5.1.1'
# end

target 'SwiftSample' do
  # Comment the next line if you don't want to use dynamic frameworks
  # 所有 Pod 都将作为动态 Framework 接入项目。可支持 Swift Pods，避免静态库冲突。
  use_frameworks!

  core_pods
  # thirdparty_pods
  ui_pods
end

target 'SwiftSampleTests' do
  inherit! :search_paths
  # Pods for testing
end

target 'SwiftSampleUITests' do
  # Pods for testing
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      # 为模拟器排除arm64架构，为真机包含arm64架构
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      # 确保Pods项目支持所有需要的架构
      config.build_settings["VALID_ARCHS"] = "x86_64 arm64"
      config.build_settings["ONLY_ACTIVE_ARCH"] = "YES"
    end
  end
  
  # 更新Pods项目的架构设置
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    config.build_settings["VALID_ARCHS"] = "x86_64 arm64"
  end
end