//
//  TestClass.m
//  Sample
//
//  Created by Suren Sarkisyan on 20.04.2022.
//  Copyright © 2022 Qonversion Inc. All rights reserved.
//

#import "TestClass.h"
@import QonversionSandwich;

@interface TestClass () <QonversionEventListener>

@property (nonatomic, strong) QonversionSandwich *sandwich;

@end

@implementation TestClass

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _sandwich = [[QonversionSandwich alloc] initWithQonversionEventListener:self];
        [self functionToTestObjCSandwich];
    }
    
    return self;
}

- (void)functionToTestObjCSandwich {
    // write any code here
    
}

#pragma mark - QonversionEventListener

- (void)qonversionDidReceiveUpdatedPermissions:(NSDictionary<NSString *,id> *)permissions {
    
}

- (void)shouldPurchasePromoProductWith:(NSString *)productId {
    
}

@end
