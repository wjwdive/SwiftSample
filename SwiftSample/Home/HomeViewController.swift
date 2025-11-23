import UIKit
import SnapKit

// 首页列表数据模型
struct HomeItem {
    let id: Int
    let title: String
    let description: String
    let imageURL: String?
    let createdAt: Date
    var isFavorite: Bool
    
    // 模拟数据生成方法
    static func generateMockData(count: Int) -> [HomeItem] {
        var items = [HomeItem]()
        let currentDate = Date()
        
        for i in 1...count {
            let randomDays = Int.random(in: 0...30)
            let date = Calendar.current.date(byAdding: .day, value: -randomDays, to: currentDate) ?? currentDate
            
            let item = HomeItem(
                id: i,
                title: "示例标题 \(i)",
                description: "这是示例内容描述，包含了关于项目 \(i) 的详细信息和相关说明。这是一个模拟的长文本描述。",
                imageURL: i % 3 == 0 ? nil : "https://via.placeholder.com/100",
                createdAt: date,
                isFavorite: i % 5 == 0
            )
            items.append(item)
        }
        
        return items
    }
}

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "首页"
        
        // 创建一个简单的标签来显示当前页面信息
        let label = UILabel()
        label.text = "首页内容"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        
        // 使用SnapKit自动布局将标签居中
        view.addSubview(label)
        label.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
}