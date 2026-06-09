//
//  LocalAuthWorker.h
//  SOCOLOR
//
//  Created by Alexandr Polienko on 30.04.2020.
//  Copyright © 2020 MIR. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalAuthWorker: NSObject

#pragma mark - UserData
+ (NSString *)login;
+ (NSString *)userName;
+ (NSString *)userPass;
+ (NSString *)emple;

#pragma mark - User Preferences
+ (NSSet *)selectedIPadsSet;
+ (NSSet *)synchronizedIPadsSet;
+ (double)routeNearCustomersSearchRadius;


@end

NS_ASSUME_NONNULL_END
