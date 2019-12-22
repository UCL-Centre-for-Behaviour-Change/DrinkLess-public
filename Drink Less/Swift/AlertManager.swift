//
//  AlertManager.swift
//  drinkless
//
//  Created by Hari Karam Singh on 25/09/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import UIKit

@objc
final class AlertManager : NSObject, UIAlertViewDelegate {
    @objc public static let shared = AlertManager();
    
    typealias AlertCallback = (_ buttonIndex:Int) -> Void
    
    private var alertViewCallbacks:[UIAlertView: AlertCallback] = [:]
    
    private override init() {}

    @objc public func showSimpleAlert(title:String?, msg:String?, buttonTxt:String="Ok") {
        UIAlertView(title: title, message: msg, delegate: nil, cancelButtonTitle: buttonTxt).show()
    }
    
    //---------------------------------------------------------------------

    @objc func showErrorAlert(_ error:NSError) {
        showErrorAlert(error, callback: nil)
    }

    //---------------------------------------------------------------------

    @objc func showErrorAlert(_ error:NSError, callback:AlertCallback? = nil) {
        let alert = UIAlertView(title: "An error has occured. Please contact support.", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok");
        alert.delegate = self
        alert.show()
        
        if let cb = callback {
            alertViewCallbacks[alert] = cb
        }
    }
    
    //---------------------------------------------------------------------

    
    
    //////////////////////////////////////////////////////////
    // MARK: - Additional Privates
    //////////////////////////////////////////////////////////

    @objc public func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        
        if let cb = alertViewCallbacks[alertView] {
            cb(buttonIndex)
            alertViewCallbacks[alertView] = nil
        }
    }
}
