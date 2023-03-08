//
//  FullScreenSlideshowViewController.swift
//  ImageSlideshow
//
//  Created by Petr Zvoníček on 31.08.15.
//

import UIKit

@objcMembers
open class FullScreenSlideshowViewController: UIViewController {

    open var slideshow: ImageSlideshow = {
        let slideshow = ImageSlideshow()
        slideshow.zoomEnabled = true
        slideshow.contentScaleMode = UIViewContentMode.scaleAspectFit
        slideshow.pageIndicatorPosition = PageIndicatorPosition(horizontal: .center, vertical: .bottom)
        let pageIndicator = UIPageControl()
        pageIndicator.currentPageIndicatorTintColor = UIColor(red: 30/255.0, green: 136/255.0, blue: 229/255.0, alpha: 1.0)
        pageIndicator.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.2)
        slideshow.pageIndicator = pageIndicator
        // turns off the timer
        slideshow.slideshowInterval = 0
        slideshow.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]

        return slideshow
    }()

    /// Close button 
    open var closeButton = UIButton()

    /// Close button frame
    open var closeButtonFrame: CGRect?

    /// Closure called on page selection
    open var pageSelected: ((_ page: Int) -> Void)?

    /// Index of initial image
    open var initialPage: Int = 0

    /// Input sources to 
    open var inputs: [InputSource]?
    open var inputs: [InputSource]? {
        didSet {
            for input in inputs ?? [] {
                (input as? KingfisherSource)?.contentMode = .scaleAspectFit
            }
        }
    }

    /// Background color
    open var backgroundColor = UIColor.white

    /// Enables/disable zoom
    open var zoomEnabled = true {
        didSet {
            slideshow.zoomEnabled = zoomEnabled
        }
    }
    
    /// top bar height
    open var topBarHeight: CGFloat = 0.0

    fileprivate var isInit = true

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .custom
        if #available(iOS 13.0, *) {
            // Use KVC to set the value to preserve backwards compatiblity with Xcode < 11
            self.setValue(true, forKey: "modalInPresentation")
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = backgroundColor
        slideshow.backgroundColor = backgroundColor

        if let inputs = inputs {
            slideshow.setImageInputs(inputs)
        }

        view.addSubview(slideshow)
    }
    
    private func addNavBar() {
        let navView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: topBarHeight))
        navView.backgroundColor = .white
        self.view.addSubview(navView)
        
        let borderView = UIView(frame: CGRect(x: 0, y: topBarHeight, width: view.frame.width, height: 1))
        borderView.backgroundColor = UIColor.black.withAlphaComponent(0.12)
        navView.addSubview(borderView)
        
        let label = UILabel()
        label.font = UIFont(name: "Lato-Regular", size: 17.0)
        label.textColor = UIColor.black.withAlphaComponent(0.6)
        label.text = "\(initialPage+1)/\(inputs?.count ?? 1)"
        label.translatesAutoresizingMaskIntoConstraints = false
        navView.addSubview(label)
        label.leadingAnchor.constraint(equalTo: navView.leadingAnchor, constant: 16.0).isActive = true
        label.bottomAnchor.constraint(equalTo: navView.bottomAnchor, constant: -12.0).isActive = true
        slideshow.currentPageChanged = { [weak self] page in
            guard let self = self else { return }
            label.text = "\(page+1)/\(self.inputs?.count ?? 1)"
        }
        
        let cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor(red: 30.0/255, green: 136.0/255, blue: 229/255, alpha: 1.0), for: .normal)
        cancelButton.titleLabel?.font = UIFont(name: "Lato-Regular", size: 17.0)
        cancelButton.addTarget(self, action: #selector(FullScreenSlideshowViewController.close), for: UIControlEvents.touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        navView.addSubview(cancelButton)
        cancelButton.trailingAnchor.constraint(equalTo: navView.trailingAnchor, constant: -16.0).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: navView.bottomAnchor, constant: -6.0).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
    }

    override open var prefersStatusBarHidden: Bool {
        return true
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isInit {
            isInit = false
            slideshow.setCurrentPage(initialPage, animated: false)
            addNavBar()
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        slideshow.slideshowItems.forEach { $0.cancelPendingLoad() }

        // Prevents broken dismiss transition when image is zoomed in
        slideshow.currentSlideshowItem?.zoomOut()
    }

    open override func viewDidLayoutSubviews() {
        if !isBeingDismissed {
            let safeAreaInsets: UIEdgeInsets
            if #available(iOS 11.0, *) {
                safeAreaInsets = view.safeAreaInsets
            } else {
                safeAreaInsets = UIEdgeInsets.zero
            }

            closeButton.frame = closeButtonFrame ?? CGRect(x: max(10, safeAreaInsets.left), y: max(10, safeAreaInsets.top), width: 40, height: 40)
        }

        slideshow.frame = CGRect(x: view.frame.origin.x, y: topBarHeight, width: view.frame.width, height: view.frame.height - topBarHeight)
    }

    func close() {
        // if pageSelected closure set, send call it with current page
        if let pageSelected = pageSelected {
            pageSelected(slideshow.currentPage)
        }

        dismiss(animated: true, completion: nil)
    }
}
