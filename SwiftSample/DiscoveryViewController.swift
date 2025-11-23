import UIKit
import SnapKit

class DiscoveryViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "发现"
        
        // 创建一个简单的标签来显示当前页面信息
        let label = UILabel()
        label.text = "发现内容"
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