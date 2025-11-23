import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
    }
    
    private func setupTabBar() {
        // 设置TabBar的基本外观
        tabBar.tintColor = UIColor.systemBlue
        tabBar.unselectedItemTintColor = UIColor.systemGray
        
        // 适配iOS 15及以上版本的TabBar外观
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            
            // 配置背景和阴影
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // 移除顶部阴影线
            appearance.shadowColor = nil
            
            // 配置选中和未选中状态
            appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemBlue,
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray,
                .font: UIFont.systemFont(ofSize: 10, weight: .regular)
            ]
            
            // 应用配置
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        } else {
            // iOS 14及以下版本的配置
            tabBar.shadowImage = UIImage()
            tabBar.backgroundImage = UIImage()
            tabBar.backgroundColor = UIColor.systemBackground
            
            // 配置标签栏字体
            UITabBarItem.appearance().setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.systemBlue
            ], for: .selected)
            
            UITabBarItem.appearance().setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.systemGray
            ], for: .normal)
        }
        
        // 配置视图控制器
        setupViewControllers()
    }
    
    private func setupViewControllers() {
        // 创建四个视图控制器
        let homeVC = HomeViewController()
        let hotVC = HotViewController()
        let discoveryVC = DiscoveryViewController()
        let profileVC = ProfileViewController()
        
        // 为每个视图控制器创建导航控制器，以便支持导航功能
        let homeNav = createNavigationController(rootViewController: homeVC, title: "首页", imageName: "house", selectedImageName: "house.fill")
        let hotNav = createNavigationController(rootViewController: hotVC, title: "热点", imageName: "flame", selectedImageName: "flame.fill")
        let discoveryNav = createNavigationController(rootViewController: discoveryVC, title: "发现", imageName: "compass", selectedImageName: "compass.fill")
        let profileNav = createNavigationController(rootViewController: profileVC, title: "我的", imageName: "person", selectedImageName: "person.fill")
        
        // 设置TabBar的视图控制器
        viewControllers = [homeNav, hotNav, discoveryNav, profileNav]
    }
    
    private func createNavigationController(rootViewController: UIViewController, title: String, imageName: String, selectedImageName: String) -> UINavigationController {
        // 创建导航控制器
        let navController = UINavigationController(rootViewController: rootViewController)
        
        // 设置TabBar项目
        navController.tabBarItem.title = title
        navController.tabBarItem.image = UIImage(systemName: imageName)
        navController.tabBarItem.selectedImage = UIImage(systemName: selectedImageName)
        
        // 配置导航栏
        navController.navigationBar.prefersLargeTitles = true
        rootViewController.navigationItem.title = title
        
        return navController
    }
}