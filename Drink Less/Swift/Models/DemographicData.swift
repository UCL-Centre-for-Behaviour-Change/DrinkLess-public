//
//  DemographicData.swift
//  drinkless
//
//  Created by Hari Karam Singh on 01/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import UIKit

@objc
class DemographicData: GroupData {
    
    static let DEMOGRAPHIC_DATA_ANSWERS_KEY = "DemographicData.answersDict"
    
    
    /** Our internal tracking var */
    private var demographicAnswersDict:[String:NSObject] = [:]
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    required init() {
        // Restore
        if let archived = UserDefaults.standard.dictionary(forKey: DemographicData.DEMOGRAPHIC_DATA_ANSWERS_KEY) {
            demographicAnswersDict = archived as! [String:NSObject]
            print("Restored DemographicData answers from archive: \(archived)")
        }
    }
    
    //---------------------------------------------------------------------

    override var debugDescription: String {
        return String(format:"<DemographicData:%p demographicKey=\(demographicKey ?? "") ageGroup=\(ageGroup ?? "") gender=\(gender==GenderType.male ?"M":"F") birthYear=\(birthYear) age=\(age) answers=\(demographicAnswersDict)", self)
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Public Methods
    //////////////////////////////////////////////////////////
    
    //---------------------------------------------------------------------
    
    @objc func setAnswer(questionId: String, answerValue: NSObject) {
        self.demographicAnswersDict[questionId] = answerValue
    }
    @objc func clearAnswer(questionId: String) {
        self.demographicAnswersDict[questionId] = nil
    }
    @objc func answerCount() -> Int {
        return self.demographicAnswersDict.count
    }
    @objc func answer(questionId:String) -> NSObject? {
        return self.demographicAnswersDict[questionId]
    }
    
    //---------------------------------------------------------------------

    private var demographicKey_:String?
    @objc public var demographicKey:String? {
        guard demographicAnswersDict.count > 0 else {
            return ""
        }
        if self.demographicKey_ == nil {
            self.calculateDemographic()
        }
        return self.demographicKey_
    }
    private var ageGroup_:String?
    @objc public var ageGroup:String? {
        guard demographicAnswersDict.count > 0 else {
            return ""
        }
        if self.ageGroup_ == nil {
            self.calculateDemographic()
        }
        return self.ageGroup_
    }
    
    @objc var gender: GroupData.GenderType {
        guard demographicAnswersDict.count > 0 else {
            return GenderType.none
        }
        if let ans = self.demographicAnswersDict["question0"] as! NSNumber? {
            return ans.boolValue ? GroupData.GenderType.female : GroupData.GenderType.male
        }
        return GroupData.GenderType.none
    }
    @objc var birthYear: Int {
        guard demographicAnswersDict.count > 0 else {
            return -1
        }
        return (self.demographicAnswersDict["question1"]! as! NSNumber).intValue
    }
    @objc var age: Int {
        guard demographicAnswersDict.count > 0 else {
            return -1
        }

        let currentYear = CalendarProvider.current.component(Calendar.Component.year, from: DateProvider.now)
        return currentYear - self.birthYear;
    }
    @objc func key(for populationType: GroupData.PopulationType) -> String? {
        return populationType == GroupData.PopulationType.country ? "all-UK" : self.demographicKey
    }
    
    //---------------------------------------------------------------------

    @objc func save(localOnly:Bool=false) {
        
        /////////////////////////////////////////
        // USERDEFS ARCHIVE
        /////////////////////////////////////////
        let defs = UserDefaults.standard
        defs.set(self.demographicAnswersDict, forKey: DemographicData.DEMOGRAPHIC_DATA_ANSWERS_KEY)
        print("Saved demographic data to userdefs")
        
        if localOnly {
            return
        }
        
        /////////////////////////////////////////
        // PARSE
        /////////////////////////////////////////
        DataServer.shared.saveUserParameters(["demographicsAnswers":self.demographicAnswersDict], callback:nil)
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Additional Privates
    //////////////////////////////////////////////////////////

    private func calculateDemographic() {
        assert(demographicAnswersDict.count > 0, "Need demographic answers first!")
        
        self.demographicKey_ = nil
        self.ageGroup_ = nil
        let genderStr = self.gender == GroupData.GenderType.male ? ":male" : ":female"
        
        var keys = self.groupDataAll.first!.keys.filter({ (keyStr:String) -> Bool in
            keyStr.contains(genderStr)
        }).sorted {
            return $0.compare($1, options: String.CompareOptions.numeric) == ComparisonResult.orderedAscending
        }
        
        for i in 0..<(keys.count) {
            let key = keys[i] as String
            let components = key.components(separatedBy: ":")
            let ageGroup = components.first!
            let ageComponents = ageGroup.components(separatedBy: CharacterSet(charactersIn: "-+"))
            let lower = Int(ageComponents.first ?? "") ?? 0
            let upper = Int(ageComponents.last ?? "") ?? 0
            
            let lowerThanFirstBoundary: Bool = i == 0 && self.age < lower
            let withinBoundaryRange: Bool = self.age >= lower && (upper == 0 || self.age <= upper)
            if lowerThanFirstBoundary || withinBoundaryRange {
                self.demographicKey_ = key
                self.ageGroup_ = ageGroup
                break
            }
        }
    }

    
}
