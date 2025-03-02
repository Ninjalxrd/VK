import Foundation

/// Класс для загрузки отзывов.
final class ReviewsProvider {

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

}

// MARK: - Internal

extension ReviewsProvider {

    typealias GetReviewsResult = Result<Data, GetReviewsError>

    enum GetReviewsError: Error {

        case badURL
        case badData(Error)

    }

    ///Исправил проблему подгрузки UI, теперь данные из сети подгружаются не на главном потоке
    func getReviews(offset: Int = 0) async -> GetReviewsResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {[weak self] in
                guard let self else { return }
                guard let url = self.bundle.url(forResource: "getReviews.response", withExtension: "json")
                else {
                    continuation.resume(returning: .failure(.badURL))
                    return
                }
                
                // Симулируем сетевой запрос - не менять
                usleep(.random(in: 100_000...1_000_000))
                
                do {
                    let data = try Data(contentsOf: url)
                    continuation.resume(returning: .success(data))
                } catch {
                    continuation.resume(returning: .failure(.badData(error)))
                }
            }
        }
    }
}
