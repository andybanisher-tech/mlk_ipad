//
//  SQLWorker.h
//  MLK
//
//  Created by Alexandr Polienko on 16.10.2021.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

NS_ASSUME_NONNULL_BEGIN

@interface SQLWorker: NSObject

+ (NSString *)dbPath;
+ (NSString *)bundleDBPath;

+ (int)getDBVersion:(nullable sqlite3 *)db atPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
