//
//  AuditData.swift
//  drinkless
//
//  Created by Hari Karam Singh on 27/09/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import UIKit
import CoreData

/** Models the user's answers, calculates derivatives and handles persistence (Parse & CD via proxy @see AuditDataMO) for the audit survey */
@objc
public class AuditData: GroupData {

    //////////////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////
    
    /** Our internal tracking var */
    private var auditAnswersDict:[String:NSNumber] = [:]
    private var backingMO: AuditDataMO?
    
    
    @objc public var auditScore = -1
    @objc public var auditCScore = -1;
    @objc public var date: NSDate?
    @objc public var timezone: TimeZone?
    @objc public var countryEstimate:Float = -1.0
    @objc public var demographicEstimate:Float = -1.0
    @objc public var countryActual:Float = -1.0
    @objc public var demographicActual:Float = -1.0
    @objc public var countryDrinkersActual:Float = -1.0
    @objc public var demographicDrinkersActual:Float = -1.0
    @objc public var demographicKey:String?  // At the time of the audit
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    /** The last one recorded by the user */
    @objc
    class func latest() -> AuditData? {
        guard let context = PXCoreDataManager.shared()?.managedObjectContext else {
            assert(false, "Need moContext first!")
            return nil
        }
        if let mo = AuditDataMO.latest(in: context) {
            return AuditData(auditDataMO: mo)
        } else {
            return nil
        }
    }
    
    //---------------------------------------------------------------------

    class func first() -> AuditData? {
        guard let context = PXCoreDataManager.shared()?.managedObjectContext else {
            assert(false, "Need moContext first!")
            return nil
        }
        if let mo = AuditDataMO.first(in: context) {
            return AuditData(auditDataMO: mo)
        } else {
            return nil
        }
    }
    
    //---------------------------------------------------------------------

    /** Sorts by the date in the calendar/timezone that the test was taken in */
    class func allSortedByCalendarDate(descending:Bool = false) -> [AuditData]? {
        guard let context = PXCoreDataManager.shared()?.managedObjectContext else {
            assert(false, "Need moContext first!")
            return nil
        }
        
        guard var records = AuditDataMO.all(in: context) else {
            return nil
        }
        
        // Sort by the date from the appropriate time zone
        records.sort { (rec1:AuditDataMO, rec2:AuditDataMO) -> Bool in
            let isAsc = rec1.hasEarlierCalendarDateThan(obj: rec2)
            return (isAsc && !descending) || (!isAsc && descending)
        }
        
        // Convert to this class
        var rtn:[AuditData] = []
        for mo in records  {
            rtn.append(AuditData(auditDataMO: mo))
        }
        return rtn
    }
    
    //---------------------------------------------------------------------
    
    convenience init(auditDataMO:AuditDataMO) {
        self.init()
        let mo = auditDataMO
        backingMO = mo
        auditScore = mo.auditScore?.intValue ?? 0
        auditCScore = mo.auditCScore?.intValue ?? 0
        date = mo.date
        timezone = TimeZone(identifier: auditDataMO.timezone!)
        countryEstimate = mo.countryEstimate?.floatValue ?? 0
        demographicEstimate = mo.demographicEstimate?.floatValue ?? 0
        countryActual = mo.countryActual?.floatValue ?? 0
        demographicActual = mo.demographicActual?.floatValue ?? 0
        countryDrinkersActual = mo.countryDrinkersActual?.floatValue ?? 0
        demographicDrinkersActual = mo.demographicDrinkersActual?.floatValue ?? 0
        demographicKey = mo.demographic
        auditAnswersDict = mo.auditAnswers as! [String: NSNumber]
        
//        // Convert string to dictionary
//        let dictData = mo.auditAnswers?.data(using: String.Encoding.utf8)!
//        let codex = JSONDecoder()
//        if let dict = try? codex.decode(Dictionary<String,Int>.self, from: dictData!) {
//            for entry in dict {
//                auditAnswersDict[entry.key] = NSNumber(integerLiteral: entry.value)
//            }
//        }
    }
    
    private func asManagedObject(in context:NSManagedObjectContext) -> AuditDataMO {
        let mo = backingMO ?? AuditDataMO(context: context)
        
        mo.auditScore = NSNumber(integerLiteral: auditScore)
        mo.auditCScore = NSNumber(integerLiteral: auditCScore)
        mo.date = date
        mo.timezone = timezone!.identifier
        mo.countryEstimate = NSNumber(floatLiteral: Double(countryEstimate))
        mo.demographicEstimate = NSNumber(floatLiteral: Double(demographicEstimate))
        mo.countryActual = NSNumber(floatLiteral: Double(countryActual))
        mo.demographicActual = NSNumber(floatLiteral: Double(demographicActual))
        mo.countryDrinkersActual = NSNumber(floatLiteral: Double(countryDrinkersActual))
        mo.demographicDrinkersActual = NSNumber(floatLiteral: Double(demographicDrinkersActual))
        mo.auditAnswers = auditAnswersDict
        mo.demographic = demographicKey

//        let codex = JSONEncoder()
//        var d:[String:Int] = [:]
//        auditAnswersDict.forEach {
//            d[$0] = $1.intValue
//        }
//        if let data = try? codex.encode(d) {
//            let str = String(data: data, encoding: String.Encoding.utf8)
//            mo.auditAnswers = str
//        }
//
        return mo
    }
    
    //---------------------------------------------------------------------

    override public var debugDescription: String {
        return String(format:"<AuditData:%p auditScore=\(auditScore) auditCScore=\(auditCScore)  date=\(String(describing: date))  timezone=\(String(describing: timezone))  countryEstimate=\(countryEstimate)  demographicEstimate=\(demographicEstimate)  countryActual=\(countryActual)  demographicActual=\(demographicActual)  countryDrinkersActual=\(countryDrinkersActual)  demographicDrinkersActual=\(demographicDrinkersActual)  demographicKey=\(demographicKey ?? "") auditAnswersDict=\(auditAnswersDict)", self)
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////
    
    /** Only meaningful once scores have been calculated */
    @objc var isFollowUp: Bool {
        return auditCScore > -1 && auditScore == -1
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Public
    //////////////////////////////////////////////////////////
    
    @objc func setAnswer(questionId: String, answerValue: NSNumber) {
        self.auditAnswersDict[questionId] = answerValue
    }
    @objc func clearAnswer(questionId: String) {
        self.auditAnswersDict[questionId] = nil
    }
    @objc func answerCount() -> Int {
        return self.auditAnswersDict.count
    }
    @objc func answer(questionId:String) -> NSNumber? {
        return self.auditAnswersDict[questionId]
    }
    
    //---------------------------------------------------------------------

    @objc func estimatePercentile(for populationType: GroupData.PopulationType) -> Float {
        if populationType == GroupData.PopulationType.country {
            return countryEstimate
        } else {
            return demographicEstimate
        }
    }
    
    //---------------------------------------------------------------------
    
    @objc func actualPercentile(groupType: GroupType, populationType: PopulationType) -> Float {
        if populationType == GroupData.PopulationType.country {
            return groupType == GroupType.drinkers ? self.countryDrinkersActual : self.countryActual;
        } else {
            return groupType == GroupType.drinkers ? self.demographicDrinkersActual : self.demographicActual;
        }
    }
    
    
    //---------------------------------------------------------------------

    /// Sets the actual properties. Could have had this on an auditScore setter but we'll keep it explicit j.i.c. Don't forget to call it!
    @objc func calculateActualPercentiles() {
        guard self.auditCScore >= 0 else {
            NSException(name: NSExceptionName.genericException, reason: "auditCScore must be set first!", userInfo: nil).raise()
            return
        }
        
        countryActual = calculateActualPercentile(groupType: GroupData.GroupType.everyone, populationType: GroupData.PopulationType.country, cutOffBelowAverage: true)
        countryDrinkersActual = calculateActualPercentile(groupType: GroupData.GroupType.drinkers, populationType: GroupData.PopulationType.country, cutOffBelowAverage: true)
        demographicActual = calculateActualPercentile(groupType: GroupData.GroupType.everyone, populationType: GroupData.PopulationType.demographic, cutOffBelowAverage: true)
        demographicDrinkersActual = calculateActualPercentile(groupType: GroupData.GroupType.drinkers, populationType: GroupData.PopulationType.demographic, cutOffBelowAverage: true)
    }
    
    private func calculateActualPercentile(groupType: GroupType, populationType: PopulationType, cutOffBelowAverage: Bool) -> Float {
        let groupData = groupType == GroupData.GroupType.everyone ? self.groupDataAll : self.groupDataDrinkers
        let key = populationType == PopulationType.country ? "all-UK" : self.demographicKey!
        let score = self.auditCScore
        
        // Exact match
        let entryWithEqualScore = groupData.filter { (entry:Dictionary<String, NSNumber>) -> Bool in
            if let val = entry[key]?.intValue {
                return val == score
            }
            return false
        }.last
        if entryWithEqualScore != nil {
            return Float(entryWithEqualScore?["percentile"] ?? 0)
        }
        
        let lowestNeighbour = groupData.filter { (entry:Dictionary<String, NSNumber>) -> Bool in
            if let val = entry[key]?.intValue {
                return val < score
            }
            return false
        }.last
        
        let highestNeighbour = groupData.filter { (entry:Dictionary<String, NSNumber>) -> Bool in
            if let val = entry[key]?.intValue {
                return val > score
            }
            return false
        }.first
        
        if cutOffBelowAverage && lowestNeighbour == nil {
            // Don't interpolate if the score was lower than the lowest percentile boundary
            // The user's drinking is shown as average or lower so they don't drink more
            return Float(highestNeighbour?["percentile"] ?? 0)
        }
        
        let lowerScore = Float(lowestNeighbour?[key] ?? 0)
        let lowerPercentile = Float(lowestNeighbour?["percentile"] ?? 0)
        let upperScore = Float(highestNeighbour?[key] ?? 0)
        let upperPercentile = Float(highestNeighbour?["percentile"] ?? 0)
        let scoreDifferenceDecimal = (Float(score) - lowerScore) / (upperScore - lowerScore)
        return lowerPercentile + ((upperPercentile - lowerPercentile) * scoreDifferenceDecimal)
    }

    
    //---------------------------------------------------------------------

    /** For use on onboarding only */
    @objc func oldSaveToParseUser () {
        
        var params = [String:Any]()
        params["auditAnswers"] = self.auditAnswersDict
        params["auditScore"] = self.auditScore
        params["auditCScore"] = self.auditCScore
        
        // Reconfig the dicts in the old way
        params["estimateAnswers"] = [
            "all-UK:estimate": self.countryEstimate,
            "\(self.demographicKey!):estimate": self.demographicEstimate
        ]
        params["actualAnswers"] = [
            "all-UK:actual": self.countryActual,
            "all-UK:actualDrinkersAnswer": self.countryDrinkersActual,
            "\(self.demographicKey!):actual": self.demographicActual,
            "\(self.demographicKey!):actualDrinkersAnswer": self.demographicDrinkersActual
        ]
        
        DataServer.shared.saveUserParameters(params, callback: nil)
    }
    
    /** Saves to CoreData and to Parse */
    @objc func save(localOnly:Bool = false) {
        do {
            guard let context = PXCoreDataManager.shared()?.managedObjectContext else {
                NSException(name: NSExceptionName.genericException, reason: "We need an MOContext!", userInfo: nil).raise()
                return
            }
            /////////////////////////////////////////
            // VALIDATION
            /////////////////////////////////////////
            guard self.countryActual >= 0,
                self.countryDrinkersActual >= 0,
                self.demographicActual >= 0,
                self.demographicDrinkersActual >= 0,
                self.auditAnswersDict.count > 0,
                self.auditCScore >= 0,        // auditScore we dont validate as its only used on the onboarding
                self.date != nil,
                self.timezone != nil,
                self.demographicKey != nil,
                self.countryEstimate >= 0,
                self.demographicEstimate >= 0
                else {
                    NSException(name:NSExceptionName.genericException, reason: "Missing required params").raise()
                    return
            }
            
            
            
            /////////////////////////////////////////
            // DATA PREP & CORE DATA
            /////////////////////////////////////////
            
            let auditDataMO = self.asManagedObject(in: context)
            try context.save()
            Log.d("Saved local auditData successfully \(auditDataMO.debugDescription)")
            
            /////////////////////////////////////////
            // PARSE
            /////////////////////////////////////////
            if !localOnly {
                var params = [String:Any]()
                params["countryActual"] = auditDataMO.countryActual
                params["countryDrinkersActual"] = auditDataMO.countryDrinkersActual
                params["demographicActual"] = auditDataMO.demographicActual
                params["demographicDrinkersActual"] = auditDataMO.demographicDrinkersActual
                params["auditAnswers"] = auditDataMO.auditAnswers
                params["auditScore"] = auditDataMO.auditScore
                params["auditCScore"] = auditDataMO.auditCScore
                params["date"] = auditDataMO.date
                params["demographic"] = auditDataMO.demographic
                params["countryEstimate"] = auditDataMO.countryEstimate
                params["demographicEstimate"] = auditDataMO.demographicEstimate
                
                // Never edited to objectId can always be nil and no need to delete them ever so we dont need the resultant objectId and can thus use saveEventually
                DataServer.shared.saveDataObject(className: String(describing: type(of: self)), objectId: nil, isUser: true, params: params, ensureSave: true, callback: nil)
            }
            
        } catch let error as NSError {
            Log.e("Save error \(error)");
        }
    }

    //---------------------------------------------------------------------

    /** Port to use in migrations as well as question screen. This could all use a rethink */
    @objc public func calculateAuditScores(isOnboarding:Bool) {
        let plistFilename = isOnboarding ? "AuditQuestions" : "AuditQuestionsFollowUp"
        
        let questionsPlistFile = Bundle.main.path(forResource: plistFilename, ofType: "plist")!;
        let questionsPlist = NSDictionary(contentsOfFile: questionsPlistFile) as! [String:[String:Any]]
        //    self.plist = [NSDictionary dictionaryWithContentsOfFile:path];
        
        
        // Porting from original. This really sucks....
        var questions = [[String:Any]]()
        let questionIDs = questionsPlist.keys.sorted { (k1:String, k2:String) -> Bool in
            return k1.compare(k2, options: .numeric, range: nil, locale: nil) == .orderedAscending
        }
        for qid in questionIDs {
            var question = questionsPlist[qid]!
            question["questionID"] = qid
            questions.append(question)
        }
        
        // Do the tally
        var auditScore = 0;
        var auditCScore = 0;
        for questionDict in questions {
            let questionID = questionDict["questionID"] as! String
            guard let ans = answer(questionId: questionID) else {
                continue
            }
            
            let ansDict = (questionDict["answers"] as! [[String:Any]])[ans.intValue]
            let score = Int(ansDict["scorevalue"] as! String)!
            auditScore = auditScore + score
            if ["question1", "question2", "question3"].contains(questionID) {
                auditCScore = auditCScore + score
            }
        }
        
        if (isOnboarding) {
            self.auditScore = auditScore;
        }
        self.auditCScore = auditCScore;
    }
    
    
    /// For debug purposes
    @objc public func delete() {
        guard let context = PXCoreDataManager.shared()?.managedObjectContext else {
            assert(false, "Need moContext first!")
            return
        }
        context.delete(self.backingMO!)
    }
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Additional Privates
    //////////////////////////////////////////////////////////

    

    //- (void)setActualAnswersGroupType:(GroupType)groupType populationType:(PopulationType)populationType graphicType:(PXGraphicType)graphicType {
    //
    //    PXIntroManager *introManager = [PXIntroManager sharedManager];
    //
    //    double everyOnepercentile = [self.helper percentileForScore:introManager.auditScore groupType:PXGroupTypeEveryone populationType:populationType cutOffBelowAverage:YES];
    //    double drinkersPercentile = [self.helper percentileForScore:introManager.auditScore groupType:PXGroupTypeDrinkers populationType:populationType cutOffBelowAverage:YES];
    //
    //    NSString *everyOneDemographicKey, *drinkersDemographicKey;
    //
    //    if (populationType == PXPopulationTypeAgeGender) {
    //        everyOneDemographicKey = [NSString stringWithFormat:@"%@:actual", self.helper.demographicKey];
    //        drinkersDemographicKey = [NSString stringWithFormat:@"%@:actualDrinkersAnswer", self.helper.demographicKey];
    //    } else {
    //        everyOneDemographicKey = @"all-UK:actual";
    //        drinkersDemographicKey = @"all-UK:actualDrinkersAnswer";
    //    }
    //
    //    [introManager.actualAnswers setObject:@(everyOnepercentile) forKey:everyOneDemographicKey];
    //    [introManager.actualAnswers setObject:@(drinkersPercentile) forKey:drinkersDemographicKey];
    //}

    
}
