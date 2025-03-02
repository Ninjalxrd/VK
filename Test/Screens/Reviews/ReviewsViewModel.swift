import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?

    private var state: State {
        didSet {
            onStateChange?(state)
        }
    }
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
    }
    
    //MARK: - Network
    
    private let session: URLSession = URLSession(configuration: .default)
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    static func obtainAvatar(avatarUrl: String?) async throws -> UIImage? {
        guard let url = avatarUrl else { return nil }
        let result = try await ImageService.downloadImage(by: url)
        return result
    }
    
    static func obtainPhotos(urls: [String]?) async throws -> [UIImage] {
        guard let urls = urls, !urls.isEmpty else { return [] }
        var result: [UIImage] = []
        
        for url in urls {
            let image = try await ImageService.downloadImage(by: url)
            if let image = image {
                result.append(image)
            }
        }
        return result
    }
}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews()  {
        guard state.shouldLoad, !state.isLoading else { return }
        state.isLoading = true
        state.shouldLoad = false
        Task {
            let result = await reviewsProvider.getReviews(offset: state.offset)
            gotReviews(result)
            state.isLoading = false
        }
    }

}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.state.items += reviews.items.map(self.makeReviewItem)
                self.state.offset += self.state.limit
                self.state.count = reviews.count
                self.state.shouldLoad = self.state.offset < reviews.count
                self.onStateChange?(self.state)
            }
        } catch {
            print("Ошибка декодирования: \(error)")
            DispatchQueue.main.async {[weak self] in
                guard let self else { return }
                self.state.shouldLoad = true
                self.state.isLoading = false
                self.onStateChange?(self.state)
            }
        }
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
        var item = state.items[index] as? ReviewItem else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }
}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {
        let avatarURL = review.avatarURL
        let fullNameText = "\(review.first_name) \(review.last_name)".attributed(font: .username)
        let photoURLs = review.photoURLs
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let item = ReviewItem(
            fullNameText: fullNameText,
            rating: review.rating,
            avatarURL: avatarURL,
            photoURLs: photoURLs,
            reviewText: reviewText,
            created: created,
            onTapShowMore: { [weak self] id in
                self?.showMoreReview(with: id)
            }
        )
        return item
    }

}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return state.items.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == state.items.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: TotalReviewsCellConfig.reuseId,
                                                     for: indexPath) as! TotalCell
            TotalReviewsCellConfig(total: state.count).update(cell: cell)
            return cell
        }
        
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)
        return cell
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == state.items.count {
            return TotalReviewsCellConfig(total: 0).height(with: tableView.bounds.size)
        }
        return state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
