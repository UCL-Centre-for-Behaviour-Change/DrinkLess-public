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
    
    @objc class func confirmationAlert(title:String?, message:String?, confirmButtonTitle:String="Yes", cancelButtonTitle:String="Cancel", confirmedFunc:@escaping ()->Void) -> UIAlertController {
        
        // Style's are set to have "Ye" as green and No as red. A bit hackish but for consistency with the old system that's what we have. Really you should have separate confirms for when there is a destructive affirmative and you shouldnt say "Yes" rather "Delete".
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAx = UIAlertAction(title: confirmButtonTitle, style: .cancel) { (_) in
            confirmedFunc()
        }
        let cancelAx = UIAlertAction(title: cancelButtonTitle, style: .destructive, handler: nil)
        alert.addAction(cancelAx)
        alert.addAction(confirmAx)
        
        return alert
    }
    
    //---------------------------------------------------------------------

    @objc class func textPromptAlert(title:String?, message:String?, confirmButtonTitle:String="Ok", cancelButtonTitle:String="Cancel", completion:@escaping (String?)->Void) -> UIAlertController {
        
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

    @objc class func simpleAlert(title:String?, msg:String?, buttonTxt:String="Ok", callback:(()->Void)?) -> UIAlertController {
        let alertCon = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alertCon.addAction(UIAlertAction(title: buttonTxt, style: .default, handler: { (action:UIAlertAction) in
            callback?()
        }))
        return alertCon
    }
    
    // for objc only really. Otherwise we'd assign a default of nil to the callback
    @objc class func simpleAlert(title:String?, msg:String?, buttonTxt:String="Ok") -> UIAlertController {
        return simpleAlert(title: title, msg: msg, callback: nil)
    }
    
    //---------------------------------------------------------------------

    @objc class func errorAlert(_ error:NSError, callback:(()->Void)? = nil) -> UIAlertController {
        return simpleAlert(title: "An error has occured. Please contact support.", msg: error.localizedDescription, buttonTxt: "Ok") {
            callback?()
        }
    }
    
    @objc class func errorAlert(_ error:NSError) -> UIAlertController {
        return errorAlert(error, callback: nil)
    }
    
    //---------------------------------------------------------------------

    @objc class func simpleActionSheet(title:String?, msg:String?, destructiveButtonTitle:String, cancelButtonTitle:String="Cancel", callback:((_ userChoseDestructiveAction:Bool)->Void)? = nil) -> UIAlertController {
        
        let alertCon = UIAlertController(title: title, message: msg, preferredStyle: .actionSheet)
        alertCon.addAction(UIAlertAction(title: destructiveButtonTitle, style: .destructive, handler: { (action:UIAlertAction) in
            callback?(true)
        }))
        alertCon.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: { (action:UIAlertAction) in
            callback?(false)
        }))
        
        return alertCon
    }
    
    //---------------------------------------------------------------------

    @objc public func show(in vc:UIViewController) {
        vc.present(self, animated: true, completion: nil)
    }
    
    @objc public func show() {
        let vc = UIApplication.shared.windows.first(where: {$0.isKeyWindow})!.rootViewController!
        show(in: vc)
    }
    
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
