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
    
    /// 定时器，用于更新所有可见cell的时间显示
    private var updateTimer: Timer?
    
    /// 搜索框
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "搜索热点标题"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage() // 移除搜索框背景
        return searchBar
    }()
    
    /// 原始数据（用于搜索恢复）
    private var originalHotItems: [HotListItem] = []
    
    /// 搜索关键词
    private var searchKeyword: String? = nil
    
    /// 防抖实例，用于搜索操作
    private let searchDebouncer = Debouncer(delay: 0.5)
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        startUpdateTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        stopUpdateTimer()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "热点"
        
        // 添加子视图
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)
        
        // 设置自动布局约束
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
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
            print("模拟网络请求1s 返回")
            DispatchQueue.main.async {
                self.isLoading = false
                
                if isRefresh {
                    self.activityIndicator.stopAnimating()
                    self.hotItems = mockData
                    self.originalHotItems = mockData // 保存原始数据用于搜索
                    self.currentPage = 1
                    self.hasMoreData = mockData.count >= 10 // 假设每页至少10条数据
                    
                    // 结束下拉刷新
                    self.tableView.mj_header?.endRefreshing()
                    
                    // 显示空数据提示（如果需要）
                    self.emptyLabel.isHidden = !mockData.isEmpty
                    
                    // 如果有搜索关键词，应用搜索
                    if let keyword = self.searchKeyword?.trimmingCharacters(in: .whitespacesAndNewlines), !keyword.isEmpty {
                        self.performSearch(with: keyword)
                    }
                } else {
                    // 追加数据
                    self.hotItems.append(contentsOf: mockData)
                    self.originalHotItems.append(contentsOf: mockData) // 更新原始数据
                    self.currentPage += 1
                    self.hasMoreData = mockData.count > 0
                    
                    // 结束上拉加载
                    if self.hasMoreData {
                        self.tableView.mj_footer?.endRefreshing()
                    } else {
                        self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                    }
                    
                    // 如果有搜索关键词，应用搜索
                    if let keyword = self.searchKeyword?.trimmingCharacters(in: .whitespacesAndNewlines), !keyword.isEmpty {
                        self.performSearch(with: keyword)
                    }
                }
                
                self.tableView.reloadData()
            }
        }
    }
    
    /// 生成模拟数据
    /// - Parameter page: 页码
    /// - Returns: 热点列表项数组
    private func generateMockData(page: Int) -> [HotListItem] {
        var data: [HotListItem] = []
        let startIndex = (page - 1) * 20
        let endIndex = startIndex + 19
        
        for i in startIndex...endIndex {
            var item = HotListItem(
                title: "热点标题 \(i) - 第 \(page) 页",
                subtitle: "这是热点内容描述，用于展示热点的详细信息和摘要。",
                imageUrl: "https://picsum.photos/300/200?random=\(i)",
                id: UUID()
            )
            
            // 所有倒计时都从1分钟开始
            item.elapsedSeconds = 0
            
            // 默认启动定时器
            item.startTimer()
            
            data.append(item)
        }
        
        return data
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
    
    /// 启动全局定时器
    private func startUpdateTimer() {
        guard updateTimer == nil else { return }
        updateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateVisibleCells), userInfo: nil, repeats: true)
        RunLoop.main.add(updateTimer!, forMode: .common)
    }
    
    /// 停止全局定时器
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// 更新所有可见Cell的时间显示
    @objc private func updateVisibleCells() {
        tableView.visibleCells.forEach { cell in
            if let hotCell = cell as? HotTableViewCell {
                hotCell.updateTime()
            }
        }
    }
    
    // MARK: - Search Functionality
    
    /// 执行搜索
    /// - Parameter keyword: 搜索关键词
    private func performSearch(with keyword: String) {
        // 如果关键词为空，恢复原始数据
        guard !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            hotItems = originalHotItems
            searchKeyword = nil
            tableView.reloadData()
            emptyLabel.isHidden = !hotItems.isEmpty
            return
        }
        
        // 保存搜索关键词
        searchKeyword = keyword
        
        // 执行搜索（不区分大小写）
        let lowercaseKeyword = keyword.lowercased()
        hotItems = originalHotItems.filter { item in
            return item.title.lowercased().contains(lowercaseKeyword)
        }
        
        // 刷新表格和空数据提示
        tableView.reloadData()
        emptyLabel.isHidden = !hotItems.isEmpty
        
        // 当搜索时，隐藏加载更多控件
        tableView.mj_footer?.isHidden = true
    }
    
    /// 重置搜索
    private func resetSearch() {
        searchKeyword = nil
        searchBar.text = nil
        searchBar.resignFirstResponder()
        hotItems = originalHotItems
        tableView.reloadData()
        emptyLabel.isHidden = !hotItems.isEmpty
        tableView.mj_footer?.isHidden = false
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
        
        // 设置定时器点击事件
        cell.onTimerTap = {
            // 从数据源获取最新的item，而不是使用闭包创建时捕获的旧值
            let currentItem = self.hotItems[indexPath.row]
            var mutableItem = currentItem
            
            if mutableItem.isTimerRunning {
                mutableItem.pauseTimer()
            } else {
                mutableItem.startTimer()
            }
            
            // 更新数据源
            self.hotItems[indexPath.row] = mutableItem
            
            // 更新当前cell的显示
            cell.configure(with: mutableItem)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HotViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handleItemTap(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Cell即将显示时的处理，可用于启动Cell级别的定时器（如果需要）
        if let hotCell = cell as? HotTableViewCell {
            hotCell.updateTime()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Cell不再显示时的处理，可用于停止Cell级别的定时器（如果需要）
        // 由于使用全局定时器，此处可能无需处理
    }
    
    // MARK: - Scroll View Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 使用节流处理滚动事件，避免频繁触发
        ThrottlerManager.shared.scrollThrottler.throttle { [weak self] in
            self?.handleScrollEvent()
        }
    }
    
    /// 处理滚动事件（带节流）
    private func handleScrollEvent() {
        // 这里可以添加滚动相关的处理逻辑
        // 例如：在滚动时暂停定时器更新，减少性能消耗
        // 或者在滚动到一定位置时执行某些操作
        
        // 示例：打印滚动位置（实际开发中可以根据需求修改）
        print("当前滚动位置：\(tableView.contentOffset.y)")
    }
}

// MARK: - UISearchBarDelegate

extension HotViewController: UISearchBarDelegate {
    
    /// 搜索文本变化时调用
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 使用防抖功能，延迟执行搜索
        searchDebouncer.debounce { [weak self] in
            self?.performSearch(with: searchText)
        }
    }
    
    /// 点击搜索按钮时调用
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let searchText = searchBar.text {
            performSearch(with: searchText)
        }
    }
    
    /// 点击取消按钮时调用
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        resetSearch()
    }
    
    /// 搜索框开始编辑时调用
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    /// 搜索框结束编辑时调用
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
}

// MARK: - ReuseIdentifier Protocol Extension

extension UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
