//
//  UIKitExtensions.swift
//  drinkless
//
//  Created by Hari Karam Singh on 15/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import Foundation

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

@objc
extension UIApplication {
    
    @objc class func versionString() -> String? {
        return Bundle.main.infoDictionary?["CFBundleVersion"]  as? String
    }
    
    @objc class func versionInt() -> Int {
        let v = Int(versionString() ?? "-1") ?? -1
        assert(v > 0, "Problem parsing version number: \(versionString() ?? "")")
        return v
    }
}

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

extension UIViewController {
    // For convenience. AFAIK, there's pretty much only ever one context, except maybe on some startup sync stuff..?
    @nonobjc
    public var context:NSManagedObjectContext {
        get {
            return PXCoreDataManager.shared().managedObjectContext!
        }
    }
    
    internal var server:DataServer {
        return DataServer.shared
    }
}


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

extension UIAlertController {
    
    class func confirmationAlert(title:String?, message:String?, confirmButtonTitle:String="Yes", cancelButtonTitle:String="Cancel", confirmedFunc:@escaping ()->Void) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAx = UIAlertAction(title: confirmButtonTitle, style: .destructive) { (_) in
            confirmedFunc()
        }
        let cancelAx = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: nil)
        alert.addAction(confirmAx)
        alert.addAction(cancelAx)
        
        return alert
    }
    
    //---------------------------------------------------------------------

    class func textPromptAlert(title:String?, message:String?, confirmButtonTitle:String="Ok", cancelButtonTitle:String="Cancel", completion:@escaping (String?)->Void) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField()
        let confirmAx = UIAlertAction(title: confirmButtonTitle, style: .destructive) { (_) in
            let userText = alert.textFields!.first?.text
            completion(userText)
        }
        let cancelAx = UIAlertAction(title: cancelButtonTitle, style: .cancel) { (_) in
            completion(nil)
        }
        alert.addAction(confirmAx)
        alert.addAction(cancelAx)
        
        return alert
    }
    
    //---------------------------------------------------------------------

//    public func present(in vc:UIViewController) {
//        vc.present(vc, animated: true, completion: nil)
//    }
    
}

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

extension UIView {
    public var x:CGFloat {
        get {
            return frame.origin.x
        }
        set {
            var f = frame
            f.origin.x = newValue
            frame = f
        }
    }
    public var y:CGFloat {
        get {
            return frame.origin.y
        }
        set {
            var f = frame
            f.origin.y = newValue
            frame = f
        }
    }
    public var width:CGFloat {
        get {
            return frame.size.width
        }
        set {
            var f = frame
            f.size.width = newValue
            frame = f
        }
    }
    public var height:CGFloat {
        get {
            return frame.size.height
        }
        set {
            var f = frame
            f.size.height = newValue
            frame = f
        }
    }
}


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

extension UILabel {
    /**
     Example: sublayer.frame = label.boundingRect(forCharacterRange: NSRange(text.range(of: "bb")!, in: text))
     */
    func boundingRect(forCharacterRange range: NSRange) -> CGRect? {
        
        guard let attributedText = attributedText else { return nil }
        
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: bounds.size)
        textContainer.lineFragmentPadding = 0.0
        
        layoutManager.addTextContainer(textContainer)
        
        var glyphRange = NSRange()
        
        // Convert the range for glyphs.
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
}


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

extension UIFont {
//    public func withTraits(_ traits:UIFontDescriptor.SymbolicTraits) -> UIFont {
//        let dsc = self.fontDescriptor.withSymbolicTraits(traits)!
//        return UIFont(descriptor: dsc, size: self.pointSize)
//    }
//
    public func withBoldToggled(_ toBold:Bool?) -> UIFont {
        var traits = self.fontDescriptor.symbolicTraits
        let bold = UIFontDescriptor.SymbolicTraits.traitBold
        if let doBold = toBold {
            if doBold {
                traits.formUnion(bold)
            } else {
                traits.remove(bold)
            }
        } else {
            traits.formSymmetricDifference(bold)
        }
        let dsc = self.fontDescriptor.withSymbolicTraits(traits)!
        return UIFont(descriptor: dsc, size: self.pointSize)
    }
}
