import UIKit
import SnapKit
import MJRefresh

class HotViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 列表视图
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HotTableViewCell.self, forCellReuseIdentifier: HotTableViewCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        // 配置下拉刷新
        tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(handleRefresh))
        
        // 配置上拉加载更多
        tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(handleLoadMore))
        
        return tableView
    }()
    
    /// 加载指示器
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    /// 空数据提示标签
    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "暂无热点内容"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.isHidden = true
        return label
    }()
    
    /// 热点列表数据
    private var hotItems: [HotListItem] = []
    
    /// 是否正在加载数据
    private var isLoading = false
    
    /// 当前页码
    private var currentPage = 1
    
    /// 是否还有更多数据
    private var hasMoreData = true
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData(isRefresh: true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // 横竖屏切换时刷新表格布局
        coordinator.animate {
            _ in
            self.tableView.reloadData()
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "热点"
        
        // 添加子视图
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)
        
        // 设置自动布局约束
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    // MARK: - Data Loading
    
    /// 加载热点数据
    /// - Parameter isRefresh: 是否是下拉刷新
    private func loadData(isRefresh: Bool = false) {
        guard !isLoading else { return }
        
        isLoading = true
        
        // 如果是刷新，显示全局加载指示器；否则由MJRefresh控件处理
        if isRefresh {
            activityIndicator.startAnimating()
            emptyLabel.isHidden = true
        }
        
        // 模拟网络请求延迟
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
            // 生成模拟数据
            let mockData = self.generateMockData(page: isRefresh ? 1 : self.currentPage)
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if isRefresh {
                    self.activityIndicator.stopAnimating()
                    self.hotItems = mockData
                    self.currentPage = 1
                    self.hasMoreData = mockData.count >= 10 // 假设每页至少10条数据
                    
                    // 结束下拉刷新
                    self.tableView.mj_header?.endRefreshing()
                    
                    // 显示空数据提示（如果需要）
                    self.emptyLabel.isHidden = !mockData.isEmpty
                } else {
                    // 追加数据
                    self.hotItems.append(contentsOf: mockData)
                    self.currentPage += 1
                    self.hasMoreData = mockData.count > 0
                    
                    // 结束上拉加载
                    if self.hasMoreData {
                        self.tableView.mj_footer?.endRefreshing()
                    } else {
                        self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                    }
                }
                
                self.tableView.reloadData()
            }
        }
    }
    
    /// 生成模拟数据
    /// - Parameter page: 页码
    private func generateMockData(page: Int) -> [HotListItem] {
        // 每页生成5-10条数据
        let count = Int.random(in: 5...10)
        var items: [HotListItem] = []
        
        // 计算起始索引
        let startIndex = (page - 1) * 10
        
        for i in 1...count {
            let itemIndex = startIndex + i
            let title = "热点标题 #\(itemIndex)"
            let subtitle = "这是热点内容的详细描述，提供更多信息让用户了解热点话题。页码：\(page)"
            let item = HotListItem(title: title, subtitle: subtitle)
            items.append(item)
        }
        
        return items
    }
    
    // MARK: - Event Handling
    
    /// 处理列表项点击事件
    private func handleItemTap(at indexPath: IndexPath) {
        let item = hotItems[indexPath.row]
        
        // 显示简单的提示信息
        let alert = UIAlertController(title: "点击了列表项", message: item.title, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    /// 处理下拉刷新
    @objc private func handleRefresh() {
        loadData(isRefresh: true)
    }
    
    /// 处理上拉加载更多
    @objc private func handleLoadMore() {
        guard hasMoreData && !isLoading else { 
            tableView.mj_footer?.endRefreshing()
            return 
        }
        loadData(isRefresh: false)
    }
}

// MARK: - UITableViewDataSource

extension HotViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hotItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HotTableViewCell.reuseIdentifier, for: indexPath) as? HotTableViewCell else {
            fatalError("Failed to dequeue HotTableViewCell")
        }
        
        let item = hotItems[indexPath.row]
        cell.configure(with: item)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HotViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handleItemTap(at: indexPath)
    }
}

// MARK: - ReuseIdentifier Protocol Extension

extension UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
