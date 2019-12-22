//
//  PXCoreDataManager+Debug.m
//  drinkless
//
//  Created by Hari Karam Singh on 24/09/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

#import "PXCoreDataManager+Debug.h"
#import "PXDrinkServing.h"
#import "PXDebug.h"

@implementation PXCoreDataManager (Debug)

- (void)dbg_deleteCustomDrinkServings
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSFetchRequest *allServings = [[NSFetchRequest alloc] init];
    [allServings setEntity:[NSEntityDescription entityForName:@"PXDrinkServing" inManagedObjectContext:context]];
    [allServings setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray <PXDrinkServing *> *servings = [context executeFetchRequest:allServings error:nil];
    int c = 0;
    for (PXDrinkServing *s in servings) {
        if (s.isCustom) {
            [context deleteObject:s];
            c++;
        }
//        if (s.identifier.integerValue == 999 || s.identifier.integerValue == 9999 || s.identifier.integerValue == 99999)  {
//            [context deleteObject:s];
//            c++;
//        }
    }
    NSError *e;
    [context save:&e];
    logd(@"[DEBUG] Deleted %i Custom Drink Servings (%@)", c, e);
    
}

@end
