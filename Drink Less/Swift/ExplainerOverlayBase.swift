//
//  ExplainerWindowBase.swift
//  drinkless
//
//  Created by Hari Karam Singh on 25/09/2019.
//  Copyright © 2019 UCL. All rights reserved.
//

import UIKit
import QuartzCore

@objc
class ExplainerOverlayBase: NSObject {

    final private let kGradientThickness:CGFloat = 20.0
    final private let kOverlayBgOpacity:CGFloat = 0.7
    final private let kFadeAnimTime:TimeInterval = 0.4
    

    private var currentPage = -1
    
    private var window:UIWindow?
    private var rootVC:UIViewController?
    
    @objc public func show() {
        // Create the window and display the gradient
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.windowLevel = UIWindow.Level.alert + 1
        rootVC = UIViewController()
        rootVC!.view.frame = window!.frame
        window!.rootViewController = rootVC
        currentPage = -1
        showNextPage()
        
        window!.makeKeyAndVisible()
    }
    
    //---------------------------------------------------------------------

    private func showNextPage() {
        // Get the gradient positions
        currentPage += 1
        var portalBounds = CGRect()
        var type = CAGradientLayerType.axial as CAGradientLayerType
        self.gradientPortalConfiguration(page: currentPage, bounds: &portalBounds, type: &type)
        
        // Create the overlay layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = window!.frame
        // screen top, end of solid/begin of gradient, end of gradient/begin of portal, end of portal....screen bottom
        var positions = [CGFloat]()
        let W = window!.frame.size.width
        let H = window!.frame.size.height
        gradientLayer.type = type // as String
        if type == CAGradientLayerType.axial {
            gradientLayer.startPoint = CGPoint(x:0, y:0)
            gradientLayer.endPoint = CGPoint(x: 0, y: 1.0)
            gradientLayer.colors = [UIColor.black.cgColor,
                                    UIColor.black.cgColor,
                                    UIColor.init(white: 0, alpha: 0).cgColor,
                                    UIColor.init(white: 0, alpha: 0).cgColor,
                                    UIColor.black.cgColor,
                                    UIColor.black.cgColor]
            positions = [0.0,
                         (portalBounds.minY - kGradientThickness) / H,
                         portalBounds.minY / H,
                         portalBounds.maxY / H,
                         (portalBounds.maxY + kGradientThickness) / H,
                         1.0]


            // Convert to NSNumber
            var locations = [NSNumber]()
            for y in positions {
                locations.append(NSNumber(floatLiteral: Double(y)))
            }
            gradientLayer.locations = locations

        } else /* Radial*/ {
            // !! this isnt quite right.... We wont use it for now
            gradientLayer.startPoint = CGPoint(x:portalBounds.midX/W, y:portalBounds.midY/H)
            gradientLayer.endPoint = CGPoint(x:(portalBounds.midX - kGradientThickness) / W, y:(portalBounds.midY - kGradientThickness) / H)
            gradientLayer.colors = [UIColor.init(white: 0, alpha: 0).cgColor,
                                    UIColor.init(white: 0, alpha: 0).cgColor,
                                    UIColor.black.cgColor]
            positions = [0.0,
                         portalBounds.width/2.0 / H,
                         (portalBounds.width/2.0 + kGradientThickness) / H]

            // Convert to NSNumber
            var locations = [NSNumber]()
            for y in positions {
                locations.append(NSNumber(floatLiteral: Double(y)))
            }
            gradientLayer.locations = locations
        }

        gradientLayer.opacity = Float(kOverlayBgOpacity)
        
        let nextPageView = UIView(frame: window!.frame)
        nextPageView.layer.addSublayer(gradientLayer)
        
        configureExplainerViewForDisplay(view: nextPageView, page: currentPage, portalBounds: portalBounds)
        
        // Add a tap gesture recogniser
        let gr = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        nextPageView.addGestureRecognizer(gr)
        
        // Add as subview and fade / crossfade
        let prevPageView = rootVC!.view.subviews.last
        rootVC!.view.addSubview(nextPageView)
        nextPageView.alpha = 0
        gr.isEnabled = false // enable after fade
        prevPageView?.isUserInteractionEnabled = false;
        
        UIView.animate(withDuration: kFadeAnimTime, animations: {
            nextPageView.alpha = 1
            prevPageView?.alpha = 0
        }) { (complete:Bool) in
            prevPageView?.removeFromSuperview()
            gr.isEnabled = true
        }
    }
    
    //---------------------------------------------------------------------
    
    @objc private func handleTap() {
        if currentPage >= numPages() - 1 {
            dismiss()
        } else {
            showNextPage()
        }
    }
    
    //---------------------------------------------------------------------

    private func dismiss() {
        UIView.animate(withDuration: kFadeAnimTime, animations: {
            self.rootVC?.view.alpha = 0
        }) { (s:Bool) in
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            self.window = nil
            self.rootVC = nil
        }
    }

    
    //////////////////////////////////////////////////////////
    // MARK: - Data Source methods for subclass to fulfill
    //////////////////////////////////////////////////////////
    
    /**
     @abstract */
    public func numPages() -> Int { return 0; }
    /** @abstract
     Define where the portal is showing the underlying view item
     @param bounds The bounds of the item you want to show through the background */
    public func gradientPortalConfiguration(page:Int, bounds:inout CGRect, type: inout CAGradientLayerType) {}
    /**
     @abstract
     Called before displaying (fading/crossfading) the page's view. Subclass configures it's own elements
     @param view The view into which to add your text, etc.
     @param portalBounds Bounds of item to show through gradient (determined via call to gradientPortalConfiguration)
     */
    public func configureExplainerViewForDisplay(view:UIView, page:Int, portalBounds:CGRect) {}
    
    //////////////////////////////////////////////////////////
    // MARK: - Utility methods (for subclass)
    //////////////////////////////////////////////////////////

    public func frameForView(_ view:UIView) -> CGRect {
//        return window!.convert(view.frame, from: view.window)

//        return rootVC!.view.convert(view.frame, from: view.superview!)
        // Bug in iOS13 means above doesnt work
        return view.superview!.convert(view.frame, to:rootVC!.view)
    }
    
    public func anchor(_ view:UIView, to item:UIView) {
        
    }
    
    
    
}
