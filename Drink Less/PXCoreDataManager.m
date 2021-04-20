//
//  PXCoreDataManager.m
//  drinkless
//
//  Created by Edward Warrender on 05/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCoreDataManager.h"
#import "NSManagedObject+PXFindByID.h"
#import "PXDrink.h"
#import "PXDrinkServing.h"
#import "PXDrinkType.h"
#import "PXDrinkAddition.h"
#import "PXDrinkRecord+Extras.h"
#import "PXAlcoholFreeRecord+Extras.h"
#import "PXDrinkCalculator.h"
#import "drinkless-Swift.h"

@interface PXCoreDataManager ()

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation PXCoreDataManager

+ (instancetype)sharedManager {
    static PXCoreDataManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

+ (NSManagedObjectContext *)temporaryContext {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = [PXCoreDataManager sharedManager].persistentStoreCoordinator;
    return context;
}

- (void)resetData {
    NSPersistentStore *store = self.persistentStoreCoordinator.persistentStores.lastObject;
    [self.persistentStoreCoordinator removePersistentStore:store error:nil];
    self.persistentStoreCoordinator = nil;
    [self.managedObjectContext reset];
    self.managedObjectContext = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *storeURL = [[self.class applicationDocumentDirectory] URLByAppendingPathComponent:@"DrinkLess.sqlite"];
    if ([fileManager fileExistsAtPath:storeURL.path]) {
        [fileManager removeItemAtURL:storeURL error:nil];
    }
    [self loadDatabase];
}

#pragma mark - CoreData

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel == nil) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DrinkLess" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator == nil) {
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        NSError *error;
        NSURL *storeURL = [[self.class applicationDocumentDirectory] URLByAppendingPathComponent:@"DrinkLess.sqlite"];
        if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                      configuration:nil
                                                                URL:storeURL
                                                            options:@{NSMigratePersistentStoresAutomaticallyOption:@YES,
                                                                      NSInferMappingModelAutomaticallyOption:@YES}
                                                              error:&error] == nil) {
            NSLog(@"%@", error.localizedDescription);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

+ (NSURL *)applicationDocumentDirectory {
    NSArray *directoryURLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                    inDomains:NSUserDomainMask];
    return directoryURLs.lastObject;
}

- (void)saveContext {
    if (self.managedObjectContext) {
        NSError *error = nil;
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
            NSLog(@"%@", error.localizedDescription);
            abort();
        }
    }
}

#pragma mark - NSManagedObjectContextDidSaveNotification

- (void)contextDidSaveNotification:(NSNotification *)notification {
    NSManagedObjectContext *context = notification.object;
    if (context != _managedObjectContext &&
        context.persistentStoreCoordinator == self.persistentStoreCoordinator) {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }
}

#pragma mark - Loading database

- (void)loadDatabase {
    [self loadDrinksInformation];
    [self deleteTemplateDrinks];
    [self loadDrinksFromPlistWithName:@"StandardDrinks" groupName:@"standardTemplate"];
    [self loadDrinksFromPlistWithName:@"UnitsGuideDrinks" groupName:@"unitsGuide"];
    [self saveContext];
    [self saveDrinkRecordUpdatesToParse];
    [self saveAlcoholFreeRecordUpdatesToParse];
}

- (void)loadDrinksInformation {
    // Updates the coredata DBs with the bundled plists. Not entirely sure why they are in the database, unless there was a thought theyd have custom user values too (which they might already)
    NSString *path = [[NSBundle mainBundle] pathForResource:@"DrinksInformation" ofType:@"plist"];
    NSArray *plist = [NSArray arrayWithContentsOfFile:path];
    [plist enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger idx, BOOL *stop) {
        NSNumber *identifier = dictionary[@"identifier"];
        PXDrink *drink = (PXDrink *)[PXDrink updateWithID:identifier inContext:self.managedObjectContext];
        drink.name = dictionary[@"name"];
        drink.index = @(idx);
        drink.abvMin = dictionary[@"abv-min"];
        drink.abvMax = dictionary[@"abv-max"];
        
        NSArray *types = dictionary[@"types"];
        [types enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger idx, BOOL *stop) {
            NSNumber *identifier = dictionary[@"identifier"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"drink == %@", drink];
            PXDrinkType *drinkType = (PXDrinkType *)[PXDrinkType updateWithID:identifier predicate:predicate inContext:self.managedObjectContext];
            drinkType.name = dictionary[@"name"];
            drinkType.index = @(idx);
            drinkType.drink = drink;
        }];
        
        NSArray *additions = dictionary[@"additions"];
        [additions enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger idx, BOOL *stop) {
            NSNumber *identifier = dictionary[@"identifier"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"drink == %@", drink];
            PXDrinkAddition *drinkAddition = (PXDrinkAddition *)[PXDrinkAddition updateWithID:identifier predicate:predicate inContext:self.managedObjectContext];
            drinkAddition.name = dictionary[@"name"];
            drinkAddition.index = @(idx);
            drinkAddition.drink = drink;
        }];
        
        NSArray *servings = dictionary[@"servings"];
        [servings enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger idx, BOOL *stop) {
            NSNumber *identifier = dictionary[@"identifier"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"drink == %@", drink];
            PXDrinkServing *drinkServing = (PXDrinkServing *)[PXDrinkServing updateWithID:identifier predicate:predicate inContext:self.managedObjectContext];
            drinkServing.size = dictionary[@"size"];
            drinkServing.millilitres = dictionary[@"millilitres"];
            drinkServing.drink = drink;
        }];
    }];
}

- (void)deleteTemplateDrinks {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkRecord"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date == nil"];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    for (NSManagedObject *object in results) {
        [self.managedObjectContext deleteObject:object];
    }
}

- (void)loadDrinksFromPlistWithName:(NSString *)plistName groupName:(NSString *)groupName {
    NSString *path = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    NSArray *plist = [NSArray arrayWithContentsOfFile:path];
    for (NSDictionary *dictionary in plist) {
        NSNumber *drinkID = dictionary[@"drinkID"];
        PXDrinkRecord *drinkRecord = (PXDrinkRecord *)[PXDrinkRecord createInContext:self.managedObjectContext];
        drinkRecord.groupName = groupName;
        drinkRecord.drink = (PXDrink *)[PXDrink findWithID:drinkID inContext:self.managedObjectContext];
        drinkRecord.typeID = dictionary[@"typeID"];
        drinkRecord.additionID = dictionary[@"additionID"];
        drinkRecord.servingID = dictionary[@"servingID"];
        drinkRecord.abv = dictionary[@"abv"];
        if (!drinkRecord.abv) {
            drinkRecord.abv = @(PXDefaultAbv(drinkID.integerValue));
        }
    }
}

// @TODO: Is this unnecessary if we use Parse saveEventually?
- (void)saveDrinkRecordUpdatesToParse {
    if (AppConfig.userHasOptedOut) return;
    
    // Save drink record changes to parse which haven't been updated
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkRecord"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date != nil && parseUpdated == NO"];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    for (PXDrinkRecord *drinkRecord in results) {
        [drinkRecord saveToServer];
    }
}

// @TODO: Is this unnecessary if we use Parse saveEventually?
- (void)saveAlcoholFreeRecordUpdatesToParse {
    if (AppConfig.userHasOptedOut) return;
    
    // Save alcohol free record changes to parse which haven't been updated
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXAlcoholFreeRecord"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"parseUpdated == NO"];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    for (PXAlcoholFreeRecord *alcoholFreeRecord in results) {
        [alcoholFreeRecord saveToServer];
    }
}

@end
