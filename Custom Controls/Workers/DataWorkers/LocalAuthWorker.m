//
//  LocalAuthWorker.m
//  SOCOLOR
//
//  Created by Alexandr Polienko on 30.04.2020.
//  Copyright © 2020 MIR. All rights reserved.
//

#import "LocalAuthWorker.h"

//Constants
static const double kDefaultSearchRadius = 1.0;

@implementation LocalAuthWorker

#pragma mark - UserData
+ (NSString *)login {
    NSString *login = [PersistenceWorker load:@"login"];
    if (!login) {
        login = @"";
    }
    return login;
}

+ (NSString *)userName {
    NSString *userName = [PersistenceWorker load:@"userName"];
    if (!userName) {
        userName = @"ipad_mlk";
    }
    return userName;
}

+ (NSString *)userPass {
    NSString *userPass = [PersistenceWorker load:@"userPass"];
    if (!userPass) {
        userPass = @"qazsewsxdr";
    }
    return userPass;
}

+ (NSString *)emple {
    NSString *emple = [PersistenceWorker load:@"emple"];
    if (!emple) {
        emple = @"";
    }
    return emple;
}

#pragma mark - User Preferences
+ (NSSet *)selectedIPadsSet {
    return [PersistenceWorker load:@"selectedIPadsSet"];
}

+ (NSSet *)synchronizedIPadsSet {
    return [PersistenceWorker load:@"synchronizedIPadsSet"];
}

+ (double)routeNearCustomersSearchRadius {
    NSNumber *searchRadius = [PersistenceWorker load:@"routeNearCustomersSearchRadius"];
    return searchRadius ? searchRadius.doubleValue : kDefaultSearchRadius;
}

@end
