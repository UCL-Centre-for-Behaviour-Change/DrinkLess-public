//
//  YourDrinkingCues.swift
//  drinkless
//
//  Created by Hari Karam Singh on 11/03/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import UIKit

class DrinkingCues: Collection {
    
    let UserDefsKey = "YourDrinkingCuesDataKey"
    
    public struct Cue {
        var label:String
        var isSelected = false
    }
    typealias CuesType = [Cue]
    
    //////////////////////////////////////////////////////////
    // MARK: Properties
    //////////////////////////////////////////////////////////

    private var cues = CuesType()

    
    //////////////////////////////////////////////////////////
    // MARK: -
    //////////////////////////////////////////////////////////

    init() {
        let rawArray:[Dictionary<String, AnyObject>] = UserDefaults.standard.array(forKey: UserDefsKey) as? [Dictionary<String, AnyObject>] ?? [Dictionary<String, AnyObject>]()
        
        for rawEntry in rawArray {
            let cue = Cue(label: rawEntry["label"] as! String, isSelected: rawEntry["isSelected"] as! Bool)
            cues.append(cue)
        }
        
        // Add additional ones from payload
        for entry in DrinkingCues.defaultCuesPayload() {
            let hasMatching = cues.contains(where: { (cue:DrinkingCues.Cue) -> Bool in
                cue.label == entry
            })
            if !hasMatching {
                cues.append(Cue(label: entry , isSelected: false))
            }
        }
        
        startIndex = 0
        endIndex = cues.count - 1
        
        sortCues()
        save()  // save any new payload
    }
    
    //---------------------------------------------------------------------

    public func save() {
        var rawArray = [Dictionary<String, AnyObject>]()
        
        for cue in cues {
            let rawEntry:[String:AnyObject] = [
                "label": cue.label as AnyObject,
                "isSelected": cue.isSelected as AnyObject
            ]
            rawArray.append(rawEntry)
        }
        
        UserDefaults.standard.set(rawArray, forKey: UserDefsKey)
    }
    
    //---------------------------------------------------------------------

    public func addCue(_ label:String, isSelected:Bool) {
        let cue = Cue(label: label, isSelected: isSelected)
        cues.append(cue)
        startIndex = 0
        endIndex = cues.count - 1
        sortCues()
        save()
    }
    
    //---------------------------------------------------------------------

    public func remove(_ cue:Cue) {
        cues.removeAll { (testCue:DrinkingCues.Cue) -> Bool in
            return testCue.label == cue.label && testCue.isSelected == cue.isSelected
        }
        save()
        startIndex = 0
        endIndex = cues.count - 1
    }
    
    //---------------------------------------------------------------------

    public func index(of cueLabel: String) -> Int {
        var matchIdx = -1;
        for idx in 0..<cues.count {
            if cues[idx].label == cueLabel {
                matchIdx = idx
                break
            }
        }
        return matchIdx
    }
    
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Collection Conformity
    //////////////////////////////////////////////////////////

    typealias Index = CuesType.Index
    typealias Element = CuesType.Element
    var startIndex: DrinkingCues.CuesType.Index
    var endIndex: DrinkingCues.CuesType.Index
    func index(after i: DrinkingCues.CuesType.Index) -> DrinkingCues.CuesType.Index {
        return cues.index(after: i)
    }
    subscript(position: DrinkingCues.CuesType.Index) -> DrinkingCues.CuesType.Element {
        get {
            return cues[position]
        }
        set {
            cues[position] = newValue
        }
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Additional Privates
    //////////////////////////////////////////////////////////

    private class func defaultCuesPayload() -> [String] {
        let path = Bundle.main.path(forResource: "DrinkingCues", ofType: "plist")!
        return NSArray(contentsOfFile: path) as! [String]
    }
    
    
    private func sortCues() {
        cues.sort { (cue1:DrinkingCues.Cue, cue2:DrinkingCues.Cue) -> Bool in
            if cue1.isSelected != cue2.isSelected {
                return cue1.isSelected
            } else {
                return cue1.label <= cue2.label
            }
        }
    }
}
