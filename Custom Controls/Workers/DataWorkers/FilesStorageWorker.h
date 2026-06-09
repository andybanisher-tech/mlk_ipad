//
//  FilesStorageWorker.h
//  MLK
//
//  Created by Alexandr Polienko on 20.04.2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FilesStorageWorker: NSObject

+ (nullable NSData *)getFileWithName:(NSString *)fileName atPath:(NSString *)path;
+ (void)saveFile:(NSData *)file fileName:(NSString *)fileName atPath:(NSString *)path;

+ (NSString *)removeFileWithName:(NSString *)fileName atPath:(NSString *)path;
+ (void)removeDirectoryAtPath:(NSString *)path;

#pragma mark - Helpers
+ (BOOL)file:(NSString *)fileName existsAtPath:(NSString *)path;

#pragma mark - Root Directories paths
+ (NSString *)taskImagesPath;

@end

NS_ASSUME_NONNULL_END
