//
//  FilesStorageWorker.m
//  MLK
//
//  Created by Alexandr Polienko on 20.04.2022.
//

#import "FilesStorageWorker.h"

//Constants
static NSString *const kTaskImagesDirectory = @"/TaskImages";

@implementation FilesStorageWorker

+ (nullable NSData *)getFileWithName:(NSString *)fileName atPath:(NSString *)path {
    if ([self file:fileName existsAtPath:path]) {
        return [[NSData alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", path, fileName]];
    }
    return nil;
}

+ (void)saveFile:(NSData *)file fileName:(NSString *)fileName atPath:(NSString *)path {
    //Create a Directory inside Document Directory
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) {
        [NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *fileFullPath = [self removeFileWithName:fileName atPath:path];
    [file writeToFile:fileFullPath atomically:YES];
}

+ (NSString *)removeFileWithName:(NSString *)fileName atPath:(NSString *)path {
    NSString *fileFullPath = [NSString stringWithFormat:@"%@/%@", path, fileName];
    if ([NSFileManager.defaultManager fileExistsAtPath:fileFullPath]) {
        [NSFileManager.defaultManager removeItemAtPath:fileFullPath error:nil];
    }
    return fileFullPath;
}

+ (void)removeDirectoryAtPath:(NSString *)path {
    if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
        [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    }
}

#pragma mark - Helpers
+ (BOOL)file:(NSString *)fileName existsAtPath:(NSString *)path {
    return [NSFileManager.defaultManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", path, fileName]];
}

#pragma mark - Root Directories paths
+ (NSString *)taskImagesPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = searchPaths.firstObject;
    NSString *imagesPath = [documentsDir stringByAppendingPathComponent:kTaskImagesDirectory];
    return imagesPath;
}

@end
