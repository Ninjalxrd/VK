import UIKit

final class ReviewsView: UIView {

    let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private let activityIndicator = CustomActivityIndicator()
    private var isLoading = false

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds.inset(by: safeAreaInsets)
        activityIndicator.center = center
    }

}

// MARK: - Private

extension ReviewsView {

    private func setupView() {
        backgroundColor = .systemBackground
        setupTableView()
        setupRefreshControl()
        setupActivityIndicator()
    }

    private func setupTableView() {
        addSubview(tableView)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedRowHeight = 100
        tableView.register(ReviewCell.self, forCellReuseIdentifier: ReviewCellConfig.reuseId)
        tableView.register(TotalCell.self, forCellReuseIdentifier: TotalReviewsCellConfig.reuseId)
    }
    
    private func setupActivityIndicator() {
        addSubview(activityIndicator)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.isHidden = true
    }
    
    func showLoadingIndicator() {
        guard !isLoading else { return }
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        isLoading = true
    }
    
   func hideLoadingIndicator() {
       activityIndicator.isHidden = true
       activityIndicator.stopAnimating()
    }
    

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshData() {
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
    }

}
