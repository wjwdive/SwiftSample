import UIKit
import SnapKit

// 首页列表数据模型
struct HomeItem: Identifiable, Equatable {
    let id: Int
    let title: String
    let description: String
    let imageURL: String?
    let createdAt: Date
    var isFavorite: Bool
    
    // 用于判断项目是否发生变化
    var contentHash: Int {
        var hasher = Hasher()
        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(imageURL)
        hasher.combine(isFavorite)
        return hasher.finalize()
    }
    
    // 模拟数据生成方法
    static func generateMockData(count: Int) -> [HomeItem] {
        var items = [HomeItem]()
        let currentDate = Date()
        
        for i in 1...count {
            let randomDays = Int.random(in: 0...30)
            let date = Calendar.current.date(byAdding: .day, value: -randomDays, to: currentDate) ?? currentDate
            let urlStr = String(format: "http://fb.jarvissky.com:3001/avatars/avatar%03d.jpg",i)
            let item = HomeItem(
                id: i,
                title: "示例标题 \(i)",
                description: "这是示例内容描述，包含了关于项目 \(i) 的详细信息和相关说明。这是一个模拟的长文本描述。",
                imageURL: i % 3 == 0 ? nil : urlStr,
                createdAt: date,
                isFavorite: i % 5 == 0
            )
            items.append(item)
        }
        
        return items
    }
}

class HomeViewController: UIViewController {
    // 表格视图
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        // 设置单元格预估高度以提高性能
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        // 启用预加载
        if #available(iOS 15.0, *) {
            tableView.prefetchDataSource = nil  // 将由 delegate 处理预加载
        }
        
        // 注册单元格
        tableView.register(HomeTableViewCell.self, forCellReuseIdentifier: HomeTableViewCell.reuseIdentifier)
        return tableView
    }()
    
    // 下拉刷新控件
    private let refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        
        // 暗黑模式支持的属性文本
        let attributes: [NSAttributedString.Key: Any] = {
            if #available(iOS 13.0, *) {
                return [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.label
                ]
            } else {
                return [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.systemBlue
                ]
            }
        }()
        
        refreshControl.attributedTitle = NSAttributedString(string: "下拉刷新", attributes: attributes)
        return refreshControl
    }()
    
    // 数据源
    private var items: [HomeItem] = []
    
    // 单元格高度缓存字典，用于优化性能
    private var cellHeightCache: [Int: CGFloat] = [:]
    // 缓存版本，用于在数据更新时判断是否需要清除缓存
    private var contentHashes: [Int: Int] = [:]
    
    // 加载更多状态标志
    private var isLoadingMore: Bool = false
    // 是否有更多数据
    private var hasMoreData: Bool = true
    
    // 加载更多的脚注视图
    private lazy var loadingFooterView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        footerView.backgroundColor = .secondarySystemBackground
        
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .systemBlue
        activityIndicator.startAnimating()
        
        let loadingLabel = UILabel()
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.text = "正在加载更多..."
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.font = UIFont.systemFont(ofSize: 14)
        
        footerView.addSubview(activityIndicator)
        footerView.addSubview(loadingLabel)
        
        // 布局脚注视图的UI元素
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            activityIndicator.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 20),
            loadingLabel.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            loadingLabel.leadingAnchor.constraint(equalTo: activityIndicator.trailingAnchor, constant: 10)
        ])
        
        return footerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView() // 添加这一行，设置表格视图的数据源和代理
        loadData()
    }
    
    // 加载更多数据
    private func loadMoreData() {
        // 防止重复加载
        guard !isLoadingMore && hasMoreData else { return }
        
        isLoadingMore = true
        
        // 模拟网络请求延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 获取当前最大ID，确保新数据ID连续且不重复
            let maxID = self.items.max { $0.id < $1.id }?.id ?? 0
            
            // 生成新数据，指定起始ID
            let newItems = self.generateMockDataWithStartingID(startingID: maxID + 1, count: 10)
            
            // 将新数据追加到现有数据中
            let updatedItems = self.items + newItems
            
            // 随机决定是否还有更多数据（实际应用中应该根据后端返回）
            self.hasMoreData = Int.random(in: 0...4) != 0
            
            // 更新数据源（这里不会清除缓存，因为我们只是追加数据）
            self.items = updatedItems
            self.updateContentHashes()
            
            // 更新UI
            self.tableView.reloadData()
            
            // 重置加载状态
            self.isLoadingMore = false
            
            // 如果没有更多数据，隐藏加载脚注
            if !self.hasMoreData {
                self.tableView.tableFooterView = nil
            }
        }
    }
    
    private func setupUI() {
        // 设置视图背景色
        view.backgroundColor = .white
        
        // 添加表格视图
        view.addSubview(tableView)
        
        // 设置表格视图约束
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 设置刷新控件
        setupRefreshControl()
    }
    
    private func setupTableView() {
        // 设置数据源和代理
        tableView.dataSource = self
        tableView.delegate = self
        
        // 配置下拉刷新
        setupRefreshControl()
        
        // 初始设置脚注视图为空
        tableView.tableFooterView = UIView(frame: .zero)
        
        // 设置预加载数据源（iOS 15+）
        if #available(iOS 15.0, *) {
            tableView.prefetchDataSource = self
        }
    }
    
    private func setupRefreshControl() {
        // 配置刷新控件颜色以支持暗黑模式
        if #available(iOS 13.0, *) {
            refreshControl.tintColor = .label
        } else {
            refreshControl.tintColor = .systemBlue
        }
        
        // 添加下拉刷新控件
        tableView.refreshControl = refreshControl
        
        // 设置刷新回调
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }
    
    @objc private func handleRefresh() {
        // 更新刷新控件状态文本，支持暗黑模式
        let refreshingAttributes: [NSAttributedString.Key: Any] = {
            if #available(iOS 13.0, *) {
                return [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.label
                ]
            } else {
                return [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.systemBlue
                ]
            }
        }()
        refreshControl.attributedTitle = NSAttributedString(string: "正在刷新...", attributes: refreshingAttributes)
        
        // 模拟网络请求延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 重新加载数据
            let newItems = HomeItem.generateMockData(count: 20)
            
            // 使用更新数据源方法，智能管理缓存
            self.updateDataSource(with: newItems)
            
            // 结束刷新动画
            self.refreshControl.endRefreshing()
            
            // 重置刷新状态文本，支持暗黑模式
            let normalAttributes: [NSAttributedString.Key: Any] = {
                if #available(iOS 13.0, *) {
                    return [
                        .font: UIFont.systemFont(ofSize: 14),
                        .foregroundColor: UIColor.label
                    ]
                } else {
                    return [
                        .font: UIFont.systemFont(ofSize: 14),
                        .foregroundColor: UIColor.systemBlue
                    ]
                }
            }()
            self.refreshControl.attributedTitle = NSAttributedString(string: "下拉刷新", attributes: normalAttributes)
        }
    }
    
    private func loadData() {
        // 加载模拟数据
        let mockItems = HomeItem.generateMockData(count: 20)
        updateDataSource(with: mockItems)
    }
    
    // 更新数据源并管理缓存
    private func updateDataSource(with newItems: [HomeItem]) {
        // 检查数据是否发生变化
        let needsClearCache = !isDataSourceContentIdentical(newItems)
        
        // 更新数据源
        self.items = newItems
        
        // 更新内容哈希缓存
        updateContentHashes()
        
        // 如果数据内容发生了变化，清除高度缓存
        if needsClearCache {
            cellHeightCache.removeAll()
        }
        
        // 刷新表格
        tableView.reloadData()
    }
    
    // 检查数据源内容是否与之前相同
    private func isDataSourceContentIdentical(_ newItems: [HomeItem]) -> Bool {
        guard items.count == newItems.count else { return false }
        
        for (index, newItem) in newItems.enumerated() {
            let oldItem = items[index]
            // 使用唯一ID和内容哈希来判断项目是否相同
            if oldItem.id != newItem.id || 
               contentHashes[oldItem.id] != newItem.contentHash {
                return false
            }
        }
        return true
    }
    
    // 更新内容哈希缓存
    private func updateContentHashes() {
        for item in items {
            contentHashes[item.id] = item.contentHash
        }
    }
    
    // 生成指定起始ID的模拟数据
    private func generateMockDataWithStartingID(startingID: Int, count: Int) -> [HomeItem] {
        var items = [HomeItem]()
        let currentDate = Date()
        
        for i in 0..<count {
            let itemID = startingID + i
            let randomDays = Int.random(in: 0...30)
            let date = Calendar.current.date(byAdding: .day, value: -randomDays, to: currentDate) ?? currentDate
            let urlStr = String(format: "http://fb.jarvissky.com:3001/avatars/avatar%03d.jpg", itemID)
            let item = HomeItem(
                id: itemID,
                title: "示例标题 \(itemID)",
                description: "这是示例内容描述，包含了关于项目 \(itemID) 的详细信息和相关说明。这是一个模拟的长文本描述。",
                imageURL: itemID % 3 == 0 ? nil : urlStr,
                createdAt: date,
                isFavorite: itemID % 5 == 0
            )
            items.append(item)
        }
        
        return items
    }
    
    // 更新数据项的收藏状态
    private func updateItemFavoriteStatus(at indexPath: IndexPath, isFavorite: Bool) {
        guard indexPath.row < items.count else { return }
        items[indexPath.row].isFavorite = isFavorite
    }
}

// MARK: - UITableViewDataSource

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableViewCell.reuseIdentifier, for: indexPath) as? HomeTableViewCell else {
            return UITableViewCell()
        }
        
        // 配置单元格数据
        let item = items[indexPath.row]
        cell.item = item
        
        // 设置收藏状态变更回调
        cell.onFavoriteStatusChanged = { [weak self] isFavorite in
            self?.updateItemFavoriteStatus(at: indexPath, isFavorite: isFavorite)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate 滚动处理扩展
extension HomeViewController {
    // 监听系统主题变化 - 简化为基础实现
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // iOS会自动处理系统颜色的深色/浅色模式切换
        // 仅在需要额外处理时添加代码
    }
    
    // 检测滚动以触发加载更多
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 确保是表格视图且正在滚动
        guard scrollView === tableView && !isLoadingMore && hasMoreData else { return }
        
        // 计算滚动位置
        let contentOffsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height
        
        // 当滚动到底部附近时，触发加载更多
        if contentOffsetY + frameHeight > contentHeight - 100 {
            // 设置脚注视图显示加载指示器
            tableView.tableFooterView = loadingFooterView
            tableView.tableFooterView?.isHidden = false
            
            // 加载更多数据
            loadMoreData()
        }
    }
}

// MARK: - UITableViewDataSourcePrefetching (iOS 15+)

@available(iOS 15.0, *)
extension HomeViewController: UITableViewDataSourcePrefetching {
    // 预加载即将显示的单元格数据
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // 获取即将显示的项目ID
        let itemIDs = indexPaths
            .compactMap { $0.row < items.count ? items[$0.row].id : nil }
        
        // 在实际应用中，可以提前加载这些项目的相关资源（例如图片）
        // 这里可以调用相应的预加载方法
        print("预加载项目ID: \(itemIDs)")
    }
    
    // 取消预加载
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        // 取消不再需要的预加载资源
        // 在实际应用中，可以实现资源释放逻辑
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {
    // 处理单元格点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 取消选中状态，提供视觉反馈
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 获取被点击的数据项
        let selectedItem = items[indexPath.row]
        
        // 显示项目详情
        showItemDetails(for: selectedItem)
    }
    
    // 显示项目详情的辅助方法
    private func showItemDetails(for item: HomeItem) {
        // 格式化日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let formattedDate = dateFormatter.string(from: item.createdAt)
        
        let alertController = UIAlertController(
            title: item.title,
            message: "\n描述: \(item.description)\n\n发布时间: \(formattedDate)\n\n已收藏: \(item.isFavorite ? "是" : "否")",
            preferredStyle: .alert
        )
        
        // 添加关闭按钮
        let closeAction = UIAlertAction(title: "关闭", style: .default)
        alertController.addAction(closeAction)
        
        // 显示警告框
        present(alertController, animated: true)
    }
    
    // 优化：缓存和返回单元格高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.row]
        
        // 检查是否有缓存的高度
        if let cachedHeight = cellHeightCache[item.id] {
            return cachedHeight
        }
        
        // 对于自动计算的高度，我们依赖于UITableView.automaticDimension
        return UITableView.automaticDimension
    }
    
    // 单元格布局完成后缓存高度
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        // 缓存单元格的实际高度
        let actualHeight = cell.frame.height
        cellHeightCache[item.id] = actualHeight
    }
}
