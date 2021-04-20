//
//  DataServer.swift
//  drinkless
//
//  Created by Hari Karam Singh on 20/11/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import Foundation



/**
 Migrate away from Parse semantics and create a wrapper in case we change later.
 
 We'll opt for a big fat singelton here as any more would be needlessly complicated IMO given our very thin external data tier.  Also we'll hard code Parse as we have no plans of leaving anytime soon but obviously if we did then that would be a good time to abstract into an Adapter pattern of sorts. The main gain here now is to efficiently enable server opt out
 */
@objc
public class DataServer : NSObject {
    typealias ObjectSaveCallback = (_ succeeded:Bool, _ objectId:String?,  _ error:Error?)->Void

    
    @objc
    public static let shared = DataServer()
    
    private override init() {}
   
    /// Set to false to silently disable server activity
    @objc 
    public var isEnabled = true {
        didSet {
            Log.d("DataServer \(isEnabled ? "ENABLED" : "DISABLED")")
        }
    }
    
    //---------------------------------------------------------------------

    @objc func connect() {
        guard self.isEnabled else { return }
        
        //NSLog(@"parse localdatastore enabled=%@", Parse.isLocalDatastoreEnabled?@"YES":@"NO");
        //    [Parse enableLocalDatastore];
        Parse.initialize(with: ParseClientConfiguration(block: { (configuration:ParseMutableClientConfiguration) in
            configuration.applicationId = "[PARSE SERVER APP ID]"
            configuration.server = "[PARSE SERVER URL]"
            Log.d("Connecting to Parse server \(configuration.server) with appId \(String(describing: configuration.applicationId))")
        }))
        PFUser.enableAutomaticUser()
        PFUser.enableRevocableSessionInBackground()
    }
    
    
    //---------------------------------------------------------------------
    
    @objc func logError(_ errorClass:String, msg:String, info:[String:Any]?) {
        guard self.isEnabled else { return }
        
        let parseObj = PFObject.init(className: "ErrorLog")
        parseObj["Author"] = PFUser.current()
        parseObj["class"] = errorClass
        parseObj["msg"] = msg
        parseObj["info"] = (info != nil) ? String(describing: info) : ""
        parseObj.saveEventually()
    }
    
    //---------------------------------------------------------------------
    
    @objc func logDebug(_ msg:String, info:[String:Any]?) {
        guard self.isEnabled else { return }
        
        let parseObj = PFObject.init(className: "DebugLog")
        parseObj["Author"] = PFUser.current()
        parseObj["msg"] = msg
        parseObj["info"] = (info != nil) ? String(describing: info) : ""
        parseObj.saveEventually()
    }
    
    //---------------------------------------------------------------------
    
    /** Adds/updates a parameter (table column) to the user table and sets the entry for this user */
    @objc
    func saveUserParameters(_ params:[String: Any], callback:((_ succeeded:Bool, _ error:Error?)->Void)?) {
        guard self.isEnabled else { return }
        
        guard let user = PFUser.current() else {
            assert(false, "No user found")
            return  // cant :( ~~fall thru for silent error when production~~
        }
        
        Log.v("Saving user params \(params)")
        for entry in params {
            user[entry.key] = entry.value
        }
        user.saveEventually { (succeeded:Bool, error:Error?) in
            if !succeeded {
                Log.e("Error saving parse user! \(error.debugDescription)")
            } else {
                Log.d("Saved parse user: \(params)")
            }
            if let cb = callback {
                cb(succeeded, error)
            }
        }
    }
    
    //---------------------------------------------------------------------
    @objc 
    func setUserOptOut(_ optedOut:Bool, callback:((_ succeeded:Bool, _ error:Error?)->Void)?) {
        guard self.isEnabled else { return }

        self.saveUserParameters(["hasOptedOut": optedOut], callback: callback)
    }
    
    //---------------------------------------------------------------------
    @objc
    func trackScreenView(_ screenName:String) {
        guard self.isEnabled else { return }
        
        Log.v("Tracking screen name \(screenName)")
        let obj = PFObject(className: "PXScreenView")
        obj["user"] = PFUser.current()
        obj["name"] = screenName
        obj.saveEventually();
    }
    
    //---------------------------------------------------------------------
    
    /**
     The generic object save method. New tables are created automagically in parse.
     
     @param objectId Specify to perform an update rather than new object creation
     @param isUser Assigns the current PFUser to the `user` field before save
     @param ensureSave  If true then object will be saved (eventually) even if the app quits before the network is connected. HOWEVER in this case the callback will NOT be called. Set to false if you need to record the local object ID on a new saved object  */
    @objc
    func saveDataObject(className:String, objectId:String?, isUser:Bool, params:[String:Any], ensureSave:Bool,  callback:ObjectSaveCallback?) {
        guard self.isEnabled else { return }
        
        let object = PFObject(className: className, dictionary: params)

        // Assign User
        if isUser {
            let user = PFUser.current()
            if user == nil {
                assert(false, "Parse user not found!")
                return // cant :( ~~fall thru for silent error when production~~
            }
            if user != nil {
                object["user"] = user
            }
        }

        // ObjectID for updates
        if let oid = objectId {
            object.objectId = oid
        }
        
        // Callback...
        let parseCB:PFBooleanResultBlock = { (succeeded:Bool, error:Error?) in
            Log.v("'\(className)' Save result: succeeded=\(succeeded ? "T":"F") objectId=\(object.objectId ?? "") error=\(String(describing:error))")
            if let cb = callback {
                cb(succeeded, object.objectId, error)
            }
        }
        
        Log.v("\(objectId == nil ? "Saving new '\(className)'":"Updating (id=\(objectId ?? ""))") (user=\(object["user"] ?? "") data object with params \(params) ensureSave=\(ensureSave ? "true" : "false")")
        
        if ensureSave {
            object.saveEventually { (s:Bool, e:Error?) in
                parseCB(s, e)
            }
        } else {
            object.saveInBackground(block: parseCB)
        }
    }
    
    //---------------------------------------------------------------------
    @objc
    func deleteDataObject(_ className:String, objectId:String) {
        guard self.isEnabled else { return }
        
        Log.v("Deleting object of type \(className) with ID \(objectId)")
        
        let object = PFObject(withoutDataWithClassName: className, objectId: objectId)
        object.deleteEventually()
    }
    
    //---------------------------------------------------------------------
    @objc
    func updateDataObjects(_ className:String, queryParams:[String: Any], updateParams:[String:Any], callback:ObjectSaveCallback?) {
        guard self.isEnabled else { return }
        
        Log.v("Updating DataObject with params matching: \(queryParams). Will set to \(updateParams)")
        
        let query = PFQuery(className: className)
        for (key, value) in queryParams {
            query.whereKey(key, equalTo: value)
        }
        query.findObjectsInBackground { (objects:[PFObject]?, error:Error?) in
            Log.v("'\(className)' Find results: Cnt=\((objects ?? []).count) error=\(String(describing:error))")
            if let err = error, let cb = callback {
                cb(false, nil, err)
                return
            }
            
            // Not sure if this is needed or not
//            let acl = PFACL()
//            acl.getPublicWriteAccess = true
            for object in objects ?? [] {
//                object.acl = acl
                for (key, value) in updateParams {
                    object[key] = value
                }
                
                object.saveEventually({ (succeeded:Bool, error:Error?) in
                    Log.v("'\(className)' Save result: succeeded=\(succeeded ? "T":"F") objectId=\(object.objectId ?? "") error=\(String(describing:error))")
                    if let cb = callback {
                        cb(succeeded, object.objectId, error)
                    }
                })
            } // end for
        }// end find
    }
    
    //---------------------------------------------------------------------

    @objc func userId() -> String? {
        guard self.isEnabled else { return nil }

        return PFUser.current()?.objectId
    }
    
    
}
