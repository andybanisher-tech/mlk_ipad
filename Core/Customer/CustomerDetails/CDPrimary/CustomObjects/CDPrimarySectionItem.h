//
//  CDPrimarySectionItem.h
//  MLK
//
//  Created by Alexandr Polienko on 27.09.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CDPrimarySectionItem : NSObject

@property (nonatomic, copy) NSString *type;

@property (nonatomic, strong) UIImage *icon;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIColor *titleColor;

@property (nonatomic, copy) NSString *titleDetail;

@property (nonatomic, copy) NSString *subtitle;

@property (nonatomic, assign) BOOL isEnabled;

@end

NS_ASSUME_NONNULL_END
