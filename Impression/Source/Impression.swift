//
//  Impression.swift
//  Impression
//
//  Created by Echo on 11/16/18.
//

import UIKit

public var filterThumbnailWidth: CGFloat = 120
public var filterThumbnailLabelHeight: CGFloat = 30
public var filterThumbnailLabelFont: UIFont = .systemFont(ofSize: 15)
public var filterThumbnailHighlightColor: UIColor = .blue
public var filterThumbnailHighlightBorderWidth: CGFloat = 4

public var cancelTitle = "Cancel"
public var confirmTitle = "Confirm"

public enum LocaleLanguageCode: String {
    case English = "en"
    case SimplifiedChinese = "zh-Hans"
    case TraditionalChinese = "zh-Hant"
    case Japanese = "ja"
    case French = "fa"
    case Spanish = "es"
    case German = "de"
    case Arabic = "ar"
    case Russia = "ru"
    case Korea = "ko"
    case Portuguese = "pt-PT"
}

func createDefaultFilters() {
    FilterManager.shared.register(filter: Filter1977Theme())
    FilterManager.shared.register(filter: NashvilleFilter())
}

public func createFilterViewController(image: UIImage, delegate: FilterViewControllerDelegate?, useDefaultFilters: Bool = true) -> UIViewController {
    if useDefaultFilters {
        createDefaultFilters()
    }
    
    let filterViewController = FilterViewController(image: image)
    filterViewController.delegate = delegate
    let navigationController = UINavigationController(rootViewController: filterViewController)
    return navigationController
}

public func createCustomFilterViewController(image: UIImage, delegate: FilterViewControllerDelegate?, useDefaultFilters: Bool = true) -> FilterViewController {
    if useDefaultFilters {
        createDefaultFilters()
    }
    
    let filterViewController = FilterViewController(image: image, mode: .custom)
    filterViewController.delegate = delegate
    return filterViewController
}

public func removeAllFilters() {
    FilterManager.shared.removeAll()
}

public func addCustomFilters(filter: FilterProtocol) {
    FilterManager.shared.register(filter: filter)
}

public func addCustomFilters(filters: [FilterProtocol]) {
    filters.forEach {
        FilterManager.shared.register(filter: $0)
    }    
}

