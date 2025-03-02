    import UIKit

    /// Конфигурация ячейки. Содержит данные для отображения в ячейке.
    struct ReviewCellConfig {

        /// Идентификатор для переиспользования ячейки.
        static let reuseId = String(describing: ReviewCellConfig.self)

        /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
        let id = UUID()
        /// Имя пользователя.
        let fullNameText: NSAttributedString
        /// Рейтинг.
        let rating: Int
        /// Аватар пользователя.
        let avatarURL: String?
        /// Фото пользователя.
        let photoURLs: [String]?
        /// Текст отзыва.
        let reviewText: NSAttributedString
        /// Максимальное отображаемое количество строк текста. По умолчанию 3.
        var maxLines = 3
        /// Время создания отзыва.
        let created: NSAttributedString
        /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
        let onTapShowMore: (UUID) -> Void

        /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
        fileprivate let layout = ReviewCellLayout()

    }

    // MARK: - TableCellConfig

    extension ReviewCellConfig: TableCellConfig {

        /// Метод обновления ячейки.
        /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
        func update(cell: UITableViewCell) {
            guard let cell = cell as? ReviewCell else { return }
            
            cell.photoImageViews.forEach {
                $0.isHidden = true
                $0.image = nil
            }
            cell.ratingImageView.image = RatingRenderer().ratingImage(rating)
            cell.fullNameLabel.attributedText = fullNameText
            cell.reviewTextLabel.attributedText = reviewText
            cell.reviewTextLabel.numberOfLines = maxLines
            cell.createdLabel.attributedText = created
            cell.config = self
            
            guard let avatarURL = avatarURL else {
                return cell.avatarImageView.image = UIImage(named: "defaultAvatar")
            }
            Task {
                let image = try await ReviewsViewModel.obtainAvatar(avatarUrl: avatarURL)
                await MainActor.run {
                    cell.avatarImageView.image = image
                }
            }
            if let photoURLs = photoURLs {
                Task {
                    let images = try await ReviewsViewModel.obtainPhotos(urls: photoURLs)
                    
                    await MainActor.run {
                        for (index, image) in images.enumerated() {
                            cell.photoImageViews[index].image = image
                            cell.photoImageViews[index].isHidden = false
                        }
                        cell.setNeedsLayout()
                        cell.layoutIfNeeded()
                    }
                }
            }
        }

        /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
        /// Вызывается из `heightForRowAt:` делегата таблицы.
        func height(with size: CGSize) -> CGFloat {
            layout.height(config: self, maxWidth: size.width)
        }

    }

    // MARK: - Private

    private extension ReviewCellConfig {

        /// Текст кнопки "Показать полностью...".
        static let showMoreText = "Показать полностью..."
            .attributed(font: .showMore, color: .showMore)

    }

    // MARK: - Cell

    final class ReviewCell: UITableViewCell {

        fileprivate var config: Config?

        fileprivate let avatarImageView = UIImageView()
        fileprivate let ratingImageView = UIImageView()
        fileprivate let fullNameLabel = UILabel()
        fileprivate let photoImageViews = (0..<5).map { _ in UIImageView() }
        fileprivate let reviewTextLabel = UILabel()
        fileprivate let createdLabel = UILabel()
        fileprivate let showMoreButton = UIButton()

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupCell()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            guard let layout = config?.layout else { return }
            avatarImageView.frame = layout.avatarImageFrame
            fullNameLabel.frame = layout.fullNameLabelFrame
            ratingImageView.frame = layout.ratingImageViewFrame
            photoImageViews.forEach {
                $0.frame = .zero
            }
            for (index, imageView) in photoImageViews.enumerated() {
                if index < layout.photoImageViewFrames.count {
                    imageView.frame = layout.photoImageViewFrames[index]
                }
            }
            reviewTextLabel.frame = layout.reviewTextLabelFrame
            createdLabel.frame = layout.createdLabelFrame
            showMoreButton.frame = layout.showMoreButtonFrame
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            avatarImageView.image = nil
            for photo in photoImageViews {
                photo.image = nil
                photo.isHidden = true
                photo.frame = .zero
            }
            reviewTextLabel.text = nil
            createdLabel.text = nil
        }
    }

    // MARK: - Private

    private extension ReviewCell {

        func setupCell() {
            setupAvatarImageView()
            setupFullNameLabel()
            setupRatingImageView()
            setupPhotoImageViews()
            setupReviewTextLabel()
            setupCreatedLabel()
            setupShowMoreButton()
        }
        
        func setupFullNameLabel() {
            contentView.addSubview(fullNameLabel)
            fullNameLabel.lineBreakMode = .byWordWrapping
        }
        
        func setupRatingImageView() {
            contentView.addSubview(ratingImageView)
        }
        
        func setupAvatarImageView() {
            contentView.addSubview(avatarImageView)
            avatarImageView.layer.cornerRadius = ReviewCellLayout.avatarCornerRadius
            avatarImageView.clipsToBounds = true
            avatarImageView.contentMode = .scaleAspectFill
        }
        
        func setupPhotoImageViews() {
            for imageView in photoImageViews {
                contentView.addSubview(imageView)
                imageView.clipsToBounds = true
                imageView.contentMode = .scaleAspectFill
                imageView.layer.cornerRadius = ReviewCellLayout.photoCornerRadius
                imageView.isHidden = true
            }
        }

        func setupReviewTextLabel() {
            contentView.addSubview(reviewTextLabel)
            reviewTextLabel.lineBreakMode = .byWordWrapping
        }

        func setupCreatedLabel() {
            contentView.addSubview(createdLabel)
        }

        func setupShowMoreButton() {
            contentView.addSubview(showMoreButton)
            
            lazy var onShowMoreAction = UIAction {[weak self] _ in
                guard let self else { return }
                guard let configId = config?.id else { return }
                self.config?.onTapShowMore(configId)
            }
            
            showMoreButton.contentVerticalAlignment = .fill
            showMoreButton.addAction(onShowMoreAction, for: .touchUpInside)
            showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        }

    }

    // MARK: - Layout

    /// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
    /// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {
    
    // MARK: - Размеры
    
    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0
    private static let ratingSize = CGSize(width: 86.0, height: 16.0)
    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()
    
    // MARK: - Фреймы
    
    private(set) var avatarImageFrame = CGRect.zero
    private(set) var fullNameLabelFrame = CGRect.zero
    private(set) var ratingImageViewFrame = CGRect.zero
    private(set) var photoImageViewFrames: [CGRect] = []
    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero
    
    // MARK: - Отступы
    
    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
    
    /// Горизонтальный отступ от аватара до имени пользователя.
    private let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private let showMoreToCreatedSpacing = 6.0
    
    // MARK: - Расчёт фреймов и высоты ячейки
    
    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let width = maxWidth - avatarImageFrame.width - avatarToUsernameSpacing - insets.right
        
        var maxY = insets.top
        var showShowMoreButton = false
        
        avatarImageFrame = CGRect(
            x: insets.left,
            y: insets.top,
            width: Self.avatarSize.width,
            height: Self.avatarSize.height
        )
        
        fullNameLabelFrame = CGRect(
            origin: CGPoint(x: avatarImageFrame.maxX + avatarToUsernameSpacing, y: insets.top),
            size: config.fullNameText.boundingRect(width: width - avatarImageFrame.width - avatarToUsernameSpacing).size
        )
        maxY = fullNameLabelFrame.maxY + usernameToRatingSpacing
        
        ratingImageViewFrame = CGRect(
            x: fullNameLabelFrame.minX,
            y: maxY,
            width: Self.ratingSize.width,
            height: Self.ratingSize.height
        )
        
        maxY = ratingImageViewFrame.maxY + ratingToTextSpacing
        if let photoURLs = config.photoURLs, !photoURLs.isEmpty {
            var startX = fullNameLabelFrame.minX
            var currentX = startX
            var currentY = maxY
            
            photoImageViewFrames.removeAll()
            
            for _ in photoURLs {
                let photoFrame = CGRect(
                    x: currentX,
                    y: currentY,
                    width: Self.photoSize.width,
                    height: Self.photoSize.height
                )
                photoImageViewFrames.append(photoFrame)
                
                currentX += Self.photoSize.width + photosSpacing
            }
            
            maxY = currentY + Self.photoSize.height + photosToTextSpacing
            
        }

        if !config.reviewText.isEmpty() {
            // Высота текста с текущим ограничением по количеству строк.
            let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
            // Максимально возможная высота текста, если бы ограничения не было.
            let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
            // Показываем кнопку "Показать полностью...", если максимально возможная высота текста больше текущей.
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight
            
            reviewTextLabelFrame = CGRect(
                origin: CGPoint(x: fullNameLabelFrame.minX, y: maxY),
                size: config.reviewText.boundingRect(width: width, height: currentTextHeight).size
            )
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }
        
        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: fullNameLabelFrame.minX, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }
        
        createdLabelFrame = CGRect(
            origin: CGPoint(x: fullNameLabelFrame.minX, y: maxY),
            size: config.created.boundingRect(width: width).size
        )
        
        return createdLabelFrame.maxY + insets.bottom
    }
   
}

    // MARK: - Typealias

    fileprivate typealias Config = ReviewCellConfig
    fileprivate typealias Layout = ReviewCellLayout
