//
//  FilterViewController.swift
//  Impression
//
//  Created by Echo on 11/16/18.
//

import UIKit

public protocol FilterViewControllerDelegate {
    func filterViewControllerDidCancel(_ filterViewController: FilterViewController, original: UIImage)
    func filterViewControllerDidFailToFilter(_ filterViewController: FilterViewController, original: UIImage)
    func filterViewControllerDidFilter(_ filterViewController: FilterViewController, filtered: UIImage)
}

extension FilterViewControllerDelegate {
    func filterViewControllerDidCancel(_ filterViewController: FilterViewController, original: UIImage) {}
    func filterViewControllerDidFailToFilter(_ filterViewController: FilterViewController, original: UIImage) {}
}

public enum FilterViewControllerMode {
    case normal
    case custom
}

public class FilterViewController: UIViewController {
    public var image: UIImage {
        didSet {
            setUIWith(image)
            updateDemoView()
        }
    }

    var demoViewBigImage: UIImage?

    var demoView: FilterDemoImageView?
    var selectedFilter: FilterProtocol?
    var filterCollectionView: FilterCollectionView?
    var stackView: UIStackView?
    
    var containerVerticalHeightConstraint: NSLayoutConstraint?
    var containerHorizontalWidthConstraint: NSLayoutConstraint?
    
    var mode: FilterViewControllerMode = .normal
    
    public var delegate: FilterViewControllerDelegate?
    
    public init(image: UIImage, mode: FilterViewControllerMode = .normal) {
        self.image = image
        self.mode = mode
        super.init(nibName: nil, bundle: nil)

        setUIWith(image)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override public func viewDidLoad() {
        super.viewDidLoad()
                
        if mode == .normal {
            navigationController?.isNavigationBarHidden = true
            navigationController?.isToolbarHidden = false
            
            createToolbar()
        }
        
        setUIWith(image)
        
        stackView = UIStackView()
        view.addSubview(stackView!)
        
        initLayout()
        setCollectionViewDirection()
        updateLayout()
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    func setUIWith(_ image: UIImage) {
        let bigImageHeight = max(view.frame.width - filterThumbnailContainerHeight, view.frame.height - filterThumbnailContainerHeight)
        guard let bigImage = resizeImage(image: image, targetSize: CGSize(width: bigImageHeight, height: bigImageHeight)) else {
            demoViewBigImage = nil
            return
        }
        demoViewBigImage = bigImage
        
        guard let smallImage = resizeImage(image: image, targetSize: CGSize(width: filterThumbnailContainerHeight - 10, height: filterThumbnailContainerHeight - 10)) else {
            return
        }
        
        if demoView == nil {
            demoView = FilterDemoImageView(frame: .zero, image: bigImage)
        } else {
            demoView?.image = bigImage
        }
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        layout.itemSize = CGSize(width: filterThumbnailWidth, height: filterThumbnailWidth + filterThumbnailLabelHeight)
        
        if filterCollectionView == nil {
            filterCollectionView = FilterCollectionView(frame: view.bounds, collectionViewLayout: layout)
            filterCollectionView?.register(FilterCollectionViewCell.self, forCellWithReuseIdentifier: "FilterCell")
        }

        filterCollectionView?.image = smallImage
        filterCollectionView?.viewModel = FilterCollectionViewModel()

        filterCollectionView?.didSelectFilter = {[weak self] filter in
            guard let self = self else { return }
            self.selectedFilter = filter
            self.updateDemoView()
        }
    }

    func updateDemoView() {
        guard let filter = selectedFilter, let bigImage = demoViewBigImage else { return }
        demoView?.image = filter.process(image: bigImage)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        filterCollectionView?.reloadData()
    }
    
    func setCollectionViewDirection() {
        guard let flowLayout = filterCollectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        if UIDevice.current.orientation.isLandscape {
            flowLayout.scrollDirection = .vertical
        } else {
            flowLayout.scrollDirection = .horizontal
        }
        
        flowLayout.invalidateLayout()
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setCollectionViewDirection()
    }
    
    @objc func rotated() {
        updateLayout()
        view.layoutIfNeeded()
    }
    
    fileprivate func initLayout() {
        guard let collectionView = filterCollectionView else {
            return
        }
        
        stackView?.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        stackView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        stackView?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        stackView?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        
        containerVerticalHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: filterThumbnailContainerHeight)
        containerHorizontalWidthConstraint = collectionView.widthAnchor.constraint(equalToConstant: filterThumbnailContainerHeight)
    }
    
    fileprivate func updateLayout() {
        guard let demoView = demoView, let collectionView = filterCollectionView else {
            return
        }
        
        stackView?.removeArrangedSubview(demoView)
        stackView?.removeArrangedSubview(collectionView)
        
        if UIApplication.shared.statusBarOrientation.isPortrait {
            stackView?.axis = .vertical
            
            stackView?.addArrangedSubview(demoView)
            stackView?.addArrangedSubview(collectionView)
            
            containerHorizontalWidthConstraint?.isActive = false
            containerVerticalHeightConstraint?.isActive = true
        } else {
            stackView?.axis = .horizontal
            
            if UIApplication.shared.statusBarOrientation == .landscapeLeft {
                stackView?.addArrangedSubview(collectionView)
                stackView?.addArrangedSubview(demoView)
            } else {
                stackView?.addArrangedSubview(demoView)
                stackView?.addArrangedSubview(collectionView)
            }
            
            containerVerticalHeightConstraint?.isActive = false
            containerHorizontalWidthConstraint?.isActive = true
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

// Create Toolbar UI for normal mode
extension FilterViewController {
    func createToolbar() {
        let cancelButton = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancel))
        let confirmButton = UIBarButtonItem(title: confirmTitle, style: .plain, target: self, action: #selector(confirm))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbarItems = [cancelButton, spacer, confirmButton]
        navigationController?.toolbar.barTintColor = .black
    }
    
    @objc func cancel() {
        delegate?.filterViewControllerDidCancel(self, original: image)
        dismiss(animated: true)
    }
    
    @objc func confirm() {
        let spinner = displaySpinner(onView: self.view)
        
        DispatchQueue.global().async {
            guard let image = self.applySelectedFilter() else {
                self.delegate?.filterViewControllerDidFailToFilter(self, original: self.image)
                return
            }

            DispatchQueue.main.async {
                self.removeSpinner(spinner: spinner)
                self.delegate?.filterViewControllerDidFilter(self, filtered: image)
                self.dismiss(animated: true)
            }
        }
    }
}

// Public API
extension FilterViewController {
    public func applySelectedFilter() -> UIImage? {
        return selectedFilter?.process(image: image)
    }
    
    public func process(_ image: UIImage) -> UIImage? {
        return selectedFilter?.process(image: image)
    }
}
