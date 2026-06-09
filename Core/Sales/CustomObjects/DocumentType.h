//
//  DocumentType.h
//  MLK
//
//  Created by Alexandr Polienko on 07.11.2025.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DocumentType : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSInteger docID;

+ (void)initialize NS_UNAVAILABLE;
+ (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithName:(nullable NSString *)name docID:(NSInteger)docID;

@end

NS_ASSUME_NONNULL_END
