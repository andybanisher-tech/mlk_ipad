//
//  CDPrimarySection.h
//  MLK
//
//  Created by Alexandr Polienko on 21.07.2025.
//

#import <Foundation/Foundation.h>

#import "CDPrimarySectionItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CDPrimarySection : NSObject

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSArray<CDPrimarySectionItem *> *items;

+ (void)initialize NS_UNAVAILABLE;
+ (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTitle:(nullable NSString *)title items:(NSArray<CDPrimarySectionItem *> *)items;

@end

NS_ASSUME_NONNULL_END
