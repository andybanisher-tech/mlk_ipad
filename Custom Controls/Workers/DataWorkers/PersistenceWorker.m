//
//  PersistenceWorker.m
//  SOCOLOR
//
//  Created by Alexandr Polienko on 30.04.2020.
//  Copyright © 2020 MIR. All rights reserved.
//

#import "PersistenceWorker.h"

@implementation PersistenceWorker

+ (void)save:(id)value key:(NSString *)key{
    if (value) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value requiringSecureCoding:NO error:nil];
        [NSUserDefaults.standardUserDefaults setValue:data forKey:key];
    }
}

+ (void)remove:(NSString *)key{
    [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
}

+ (id)load:(NSString *)key{
    id value = [NSUserDefaults.standardUserDefaults valueForKey:key];
    if ([value isKindOfClass:[NSData class]]) {
        return [NSKeyedUnarchiver unarchivedObjectOfClasses:
                [NSSet setWithArray:@[
                    NSArray.class,
                    NSSet.class,
                    NSDictionary.class,
                    NSDate.class,
                    NSString.class,
                    NSNumber.class
                ]] fromData:value error:nil];
    }
    return value;
}

+ (void)logoutUser {
    [self remove:@"login"];
    [self remove:@"storesArray"];
    [self remove:@"contactRolesArray"];
    [self remove:@"iPadsArray"];
    [self remove:@"selectedIPadsSet"];
}

@end
