/// Модель отзыва.
struct Review: Decodable {

    /// Имя пользователя.
    let first_name: String
    /// Фамилия пользователя.
    let last_name: String
    /// Аватар пользователя.
    let avatarURL: String?
    /// Фото пользователя.
    let photoURLs: [String]?
    /// Рейтинг.
    let rating: Int
    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let created: String
    
    enum CodingKeys: String, CodingKey {
        case first_name, last_name, rating, text, created
        case avatarURL = "avatar_url"
        case photoURLs = "photo_urls"
    }

}
    
