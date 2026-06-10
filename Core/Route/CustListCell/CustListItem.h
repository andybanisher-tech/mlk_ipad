//
//  CustListItem.h
//  MLK
//
//  Lightweight model for the modern customers list (diffable data source item).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustListItem : NSObject <NSCopying>

@property (nonatomic, copy) NSString *uid;          // unique identifier for diffable data source
@property (nonatomic, copy) NSString *custAccount;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy, nullable) NSString *sendStatus;
@property (nonatomic, copy) NSString *pdz;

@end

NS_ASSUME_NONNULL_END
