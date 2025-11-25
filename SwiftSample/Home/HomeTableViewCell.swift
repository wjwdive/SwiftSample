import UIKit
import SnapKit

class HomeTableViewCell: UITableViewCell {
    // 单元格重用标识符
    static let reuseIdentifier = "HomeTableViewCell"
    
    // 当前加载的图片任务
    private var imageLoadingTask: URLSessionDataTask?
    // 当前图片URL
    private var currentImageURL: URL?
    
    // UI元素
    private let itemImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 2
        label.textColor = .label
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 2
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .light)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()
    
    // 配置数据模型
    var item: HomeItem? {
        didSet {
            updateUI()
        }
    }
    
    // 收藏状态变更回调
    var onFavoriteStatusChanged: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 设置单元格
        backgroundColor = .systemBackground
        selectionStyle = .default
        
        // 添加子视图
        contentView.addSubview(itemImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(favoriteButton)
        
        // 使用SnapKit设置自动布局
        itemImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(12)
            $0.width.height.equalTo(80)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        
        favoriteButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(itemImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
            $0.top.equalTo(itemImageView.snp.top)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.trailing.equalTo(titleLabel.snp.trailing)
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        
        timeLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(8)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
    }
    
    private func setupActions() {
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }
    
    @objc private func favoriteButtonTapped() {
        guard var item = item else { return }
        
        item.isFavorite.toggle()
        self.item = item
        
        // 更新收藏按钮外观
        updateFavoriteButton()
        
        // 回调通知控制器收藏状态变更
        onFavoriteStatusChanged?(item.isFavorite)
    }
    
    private func updateUI() {
        guard let item = item else { return }
        
        // 更新标签内容
        titleLabel.text = item.title
        descriptionLabel.text = item.description
        timeLabel.text = formattedDate(item.createdAt)
        
        // 更新收藏按钮状态
        updateFavoriteButton()
        
        // 优化图片加载
        configureImage(for: item)
    }
    
    // 优化的图片加载方法
    private func configureImage(for item: HomeItem) {
        // 取消正在进行的图片加载任务
        imageLoadingTask?.cancel()
        
        if let imageURLString = item.imageURL, let imageURL = URL(string: imageURLString) {
            // 缓存当前URL
            currentImageURL = imageURL
            
            // 显示占位符
            itemImageView.image = nil
            itemImageView.backgroundColor = .systemGray5
            itemImageView.isHidden = false
            
            // 检查是否在屏幕外，实现延迟加载
            if !isVisibleInWindow() {
                // 视图不在窗口中，延迟加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.loadImageIfVisible(url: imageURL)
                }
            } else {
                // 视图在窗口中，立即加载
                loadImage(url: imageURL)
            }
            
            // 重置标签到带图片的布局
            resetConstraintsForWithImage()
        } else {
            // 无图片情况
            currentImageURL = nil
            itemImageView.image = nil
            itemImageView.backgroundColor = .clear
            itemImageView.isHidden = true
            
            // 调整标签布局以适应没有图片的情况
            adjustConstraintsForWithoutImage()
        }
    }
    
    // 检查视图是否在窗口中可见
    private func isVisibleInWindow() -> Bool {
        return window != nil
    }
    
    // 仅在视图可见时加载图片
    private func loadImageIfVisible(url: URL) {
        guard currentImageURL == url, isVisibleInWindow() else {
            return
        }
        loadImage(url: url)
    }
    
    // 加载图片的核心方法
    private func loadImage(url: URL) {
        // 创建新的加载任务
        imageLoadingTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // 检查是否是被取消的任务或发生错误
            guard let self = self, 
                  error == nil, 
                  let data = data, 
                  let httpResponse = response as? HTTPURLResponse, 
                  httpResponse.statusCode == 200 else {
                // 如果不是取消错误，设置为加载失败状态
                if let error = error, (error as NSError).code != NSURLErrorCancelled {
                    DispatchQueue.main.async {
                        self?.itemImageView.backgroundColor = .systemGray4
                    }
                }
                return
            }
            
            // 检查加载的URL是否与当前需要的URL一致
            guard self.currentImageURL == url else {
                return
            }
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                // 再次检查URL一致性
                guard self.currentImageURL == url else {
                    return
                }
                
                // 使用淡入动画平滑过渡
                UIView.transition(with: self.itemImageView, duration: 0.3, options: .transitionCrossDissolve) {
                    self.itemImageView.image = UIImage(data: data)
                    self.itemImageView.backgroundColor = .clear
                }
            }
        }
        
        // 开始任务
        imageLoadingTask?.resume()
    }
    
    // 重置带图片的约束
    private func resetConstraintsForWithImage() {
        // 使用remakeConstraints而不是updateConstraints，确保约束的一致性
        titleLabel.snp.remakeConstraints {
            $0.leading.equalTo(itemImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
            $0.top.equalTo(itemImageView.snp.top)
        }
    }
    
    // 调整无图片时的约束
    private func adjustConstraintsForWithoutImage() {
        // 使用remakeConstraints而不是updateConstraints，因为我们在改变约束的关系
        // 从基于itemImageView改为基于superview
        titleLabel.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(12)
        }
    }
    
    private func updateFavoriteButton() {
        guard let item = item else { return }
        
        let imageName = item.isFavorite ? "heart.fill" : "heart"
        let image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate)
        favoriteButton.setImage(image, for: .normal)
        favoriteButton.tintColor = item.isFavorite ? .systemRed : .secondaryLabel
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "今天 \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "昨天 \(formatter.string(from: date))"
        } else {
            let components = calendar.dateComponents([.year], from: date, to: Date())
            if components.year == 0 {
                // 今年的日期
                formatter.dateFormat = "MM-dd HH:mm"
            } else {
                // 非今年的日期
                formatter.dateFormat = "yyyy-MM-dd"
            }
            return formatter.string(from: date)
        }
    }
    
    // 重置单元格状态，用于重用时避免显示错误的数据
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // 取消正在进行的图片加载任务
        imageLoadingTask?.cancel()
        imageLoadingTask = nil
        currentImageURL = nil
        
        // 重置内容
        titleLabel.text = nil
        descriptionLabel.text = nil
        timeLabel.text = nil
        item = nil
        onFavoriteStatusChanged = nil
        
        // 重置图片视图
        itemImageView.image = nil
        itemImageView.backgroundColor = .systemGray5
        itemImageView.isHidden = false
        
        // 优化：避免在prepareForReuse中移除和重建所有约束
        // 只需重置位置关键的约束，其他约束保留
        resetEssentialConstraintsForReuse()
    }
    
    // 只重置必要的约束，提高性能
    private func resetEssentialConstraintsForReuse() {
        // 使用remakeConstraints而不是updateConstraints，保持一致性
        titleLabel.snp.remakeConstraints {
            $0.leading.equalTo(itemImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
            $0.top.equalTo(itemImageView.snp.top)
        }
    }
}
