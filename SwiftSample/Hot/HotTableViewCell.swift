import UIKit
import SnapKit

/// 热点列表自定义Cell，包含图标、标题和副标题
class HotTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    /// 图标ImageView
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    /// 标题Label
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 1
        return label
    }()
    
    /// 副标题Label
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // 添加子视图
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        // 设置自动布局约束
        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }
    
    // MARK: - Configuration
    
    /// 配置Cell数据
    /// - Parameter item: 热点列表项数据
    func configure(with item: HotListItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        
        // 设置图标，如果没有提供图片URL，则使用默认图标
        if let imageUrl = item.imageUrl {
            // 这里可以替换为实际的图片加载逻辑（如SDWebImage、AlamofireImage等）
            // 目前使用系统默认图片作为示例
            iconImageView.image = UIImage(systemName: "flame.fill")?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = .systemRed
        } else {
            iconImageView.image = UIImage(systemName: "flame.fill")?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = .systemRed
        }
    }
}