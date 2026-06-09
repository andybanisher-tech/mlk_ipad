//
//  SQLWorker.m
//  MLK
//
//  Created by Alexandr Polienko on 16.10.2021.
//

#import "SQLWorker.h"

@implementation SQLWorker

+ (NSString *)dbPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = searchPaths.firstObject;
    NSString *dbPath = [documentsDir stringByAppendingPathComponent:@"MLK.sqlite"];
    return dbPath;
}

+ (NSString *)bundleDBPath {
    return [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"MLK.sqlite"];
}

+ (int)getDBVersion:(sqlite3 *)db atPath:(NSString *)dbPath {
    sqlite3_stmt *selectstmt;
    int dbVersion = 0;
    
    if (sqlite3_open(dbPath.UTF8String, &db) == SQLITE_OK) {
        if (sqlite3_prepare_v2(db, "PRAGMA user_version;", -1, &selectstmt, NULL) == SQLITE_OK) {
            if (sqlite3_step(selectstmt) == SQLITE_ROW ) {
                dbVersion = sqlite3_column_int(selectstmt, 0);
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(db);
    
    return dbVersion;
}

@end
