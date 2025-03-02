//
//  TotalReviewsCell.swift
//  Test
//
//  Created by Павел on 02.03.2025.
//

import Foundation
import UIKit

// MARK: - TotalReviewsCellConfig

struct TotalReviewsCellConfig {
    
    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: TotalReviewsCellConfig.self)
    /// Количество отзывов.
    let total: Int
}

extension TotalReviewsCellConfig: TableCellConfig {
    
    func update(cell: UITableViewCell) {
        guard let cell = cell as? TotalCell else { return }
        cell.configureCell(total: total)
    }
    
    func height(with size: CGSize) -> CGFloat {
        return 44.0
    }
}

// MARK: TotalCell
final class TotalCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        totalLabel.text = nil
    }
    
    private lazy var totalLabel: UILabel = {
        let label = UILabel()
        label.font = .reviewCount
        label.textColor =  .reviewCount
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private func setupUI() {
        contentView.addSubview(totalLabel)
        
        NSLayoutConstraint.activate([
            totalLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            totalLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    
    fileprivate func configureCell(total: Int) {
        totalLabel.text = "\(total) отзывов"
    }
}
