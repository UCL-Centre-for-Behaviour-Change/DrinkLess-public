//
//  PXDrinkCalculator.h
//  drinkless
//
//  Created by Edward Warrender on 12/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#ifndef drinkless_PXDrinkCalculator_h
#define drinkless_PXDrinkCalculator_h

typedef NS_ENUM(NSInteger, PXDrinkID) {
    PXDrinkBeerID = 1,
    PXDrinkCiderID = 2,
    PXDrinkWineID = 3,
    PXDrinkFortifiedWineID = 4,
    PXDrinkSpiritID = 5,
    PXDrinkAlcopopID = 6
};

typedef NS_ENUM(NSInteger, PXWineTypeID) {
    PXWineTypeRedID = 1,
    PXWineTypeWhiteID = 2,
    PXWineTypeRoseID = 3,
    PXWineTypeSparklingID = 4,
    PXWineTypeDessertID = 5
};

typedef NS_ENUM(NSInteger, PXFortifiedWineTypeID) {
    PXFortifiedWineTypeSherryID = 1,
    PXFortifiedWineTypePortID = 2,
    PXFortifiedWineTypeMadeiraID = 3,
    PXFortifiedWineTypeMarsalaID = 4,
    PXFortifiedWineTypeVermouthID = 5
};

typedef NS_ENUM(NSInteger, PXSpiritAdditionID) {
    PXSpiritCokeAdditionID = 2,
    PXSpiritLemonadeAdditionID = 3,
    PXSpiritJuiceAdditionID = 4,
    PXSpiritAdditionGingerBeerAleID = 8,
    PXSpiritAdditionLimeID = 11,
    PXSpiritAdditionTonicID = 7,
    PXSpiritAdditionOtherID = 10,
};

CG_INLINE CGFloat
PXDefaultAbv(NSInteger drinkID) {
    switch (drinkID) {
        case PXDrinkBeerID:
        case PXDrinkCiderID:
            return 5.0;
        case PXDrinkWineID:
            return 12.0;
        case PXDrinkFortifiedWineID:
            return 20.0;
        case PXDrinkSpiritID:
            return 40.0;
        case PXDrinkAlcopopID:
            return 4.5;
        default:
            return 0.0;
    }
}

CG_INLINE CGFloat
PXCaloriesIn1Ml(NSInteger drinkID, NSInteger typeID, NSInteger additionID, NSInteger abv) {
    switch (drinkID) {
        case PXDrinkBeerID:
            switch (abv) {
                case 1:
                    return 0.18;
                case 2:
                    return 0.23;
                case 3:
                    return 0.29;
                case 4:
                    return 0.36;
                case 5:
                    return 0.43;
                case 6:
                    return 0.5;
                case 7:
                    return 0.6;
                case 8:
                    return 0.75;
                case 9:
                    return 0.93;
            }
        case PXDrinkCiderID:
            return 0.41;
        case PXDrinkWineID:
            switch (typeID) {
                case PXWineTypeRedID:
                case PXWineTypeRoseID:
                    return 0.85;
                case PXWineTypeWhiteID:
                case PXWineTypeSparklingID:
                    return 0.82;
                case PXWineTypeDessertID:
                    return 1.6;
            }
        case PXDrinkFortifiedWineID:
            switch (typeID) {
                PXFortifiedWineTypeSherryID:
                    return 1.30;
                case PXFortifiedWineTypePortID:
                case PXFortifiedWineTypeMadeiraID:
                case PXFortifiedWineTypeMarsalaID:
                case PXFortifiedWineTypeVermouthID:
                    return 1.57;
            }
        case PXDrinkSpiritID: {
            CGFloat calories = 2.44;
            switch (additionID) {
                case PXSpiritCokeAdditionID:
                    return calories + 0.43;
                case PXSpiritLemonadeAdditionID:
                    return calories + 0.42;
                case PXSpiritJuiceAdditionID:
                    return calories + 0.53;
                case PXSpiritAdditionGingerBeerAleID:
                    return calories + 0.35;
                case PXSpiritAdditionLimeID:
                    return calories + 1.06;
                case PXSpiritAdditionTonicID:
                    return calories + 0.40;
                case PXSpiritAdditionOtherID:
                    return calories + 0.44;
                default:
                    return calories;
            }
        }
        case PXDrinkAlcopopID:
            return 0.57;
        default:
            return 0.0;
    }
}

CG_INLINE CGFloat
PXCalories(NSInteger drinkID, NSInteger typeID, NSInteger additionID, NSInteger abv, CGFloat millilitres) {
    return PXCaloriesIn1Ml(drinkID, typeID, additionID, abv) * millilitres;
}

#endif
