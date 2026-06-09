//
//  PersistenceWorker.h
//  SOCOLOR
//
//  Created by Alexandr Polienko on 30.04.2020.
//  Copyright © 2020 MIR. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PersistenceWorker: NSObject

+ (void)save:(id)value key:(NSString *)key;
+ (void)remove:(NSString *)key;
+ (id)load:(NSString *)key;

+ (void)logoutUser;

@end

NS_ASSUME_NONNULL_END
