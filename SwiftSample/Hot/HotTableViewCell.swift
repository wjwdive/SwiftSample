import UIKit
import SnapKit

/// 热点列表自定义Cell，包含图标、标题、副标题和时间显示
class HotTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    /// 当前显示的热点列表项
    private var currentItem: HotListItem?
    
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
    
    /// 时间显示Label
    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        label.textColor = .systemBlue
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true
        return label
    }()
    
    /// 定时器点击回调
    var onTimerTap: (() -> Void)?
    
    /// 点击手势识别器
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTimerTap))
        return gesture
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
        contentView.addSubview(timerLabel)
        
        // 添加点击手势
        timerLabel.addGestureRecognizer(tapGesture)
        
        // 设置自动布局约束
        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalTo(timerLabel.snp.leading).offset(-12)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.trailing.equalTo(titleLabel)
            $0.bottom.equalToSuperview().offset(-12)
        }
        
        timerLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.greaterThanOrEqualTo(60)
        }
    }
    
    // MARK: - Configuration
    
    /// 配置Cell数据
    /// - Parameter item: 热点列表项数据
    func configure(with item: HotListItem) {
        self.currentItem = item
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        updateTimerDisplay(time: item.getCurrentTime())
        
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
    
    /// 更新时间显示
    func updateTime() {
        guard let item = currentItem else { return }
        
        let currentTime = item.getCurrentTime()
        updateTimerDisplay(time: currentTime)
    }
    
    private func updateTimerDisplay(time: TimeInterval) {
        timerLabel.text = formatTime(time: time)
        
        // 当倒计时结束时，改变文字颜色为红色
        if time <= 0 {
            timerLabel.textColor = .systemRed
        } else {
            timerLabel.textColor = .systemBlue
        }
    }
    
    private func formatTime(time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Event Handling
    
    /// 处理定时器点击事件
    @objc private func handleTimerTap() {
        // 直接调用闭包，所有状态修改由HotViewController统一处理
        onTimerTap?()
    }
}
