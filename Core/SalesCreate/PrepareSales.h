//
//  PrepareSales.h
//  MLK
//
//  Created by Rustem Galyamov on 25.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@interface PrepareSales: NSObject {
    NSString *actionType;
    NSString *actionId;
    NSString *brandForItems;
}
@property(nonatomic, retain)NSString *actionType;
@property(nonatomic, retain)NSString *actionId;
@property(nonatomic, retain)NSString *brandForItems;

#pragma mark - TmpSalesLine
- (void)createTmpSalesLine:(NSString *)custAccount item:(NSDictionary *)item firmID:(NSString *)firmID firmName:(NSString *)firmName firmMarkup:(NSString *)firmMarkup isConsult:(BOOL)isConsult;
- (void)createTmpSalesLine:(NSString *)custAccount itemId:(NSString *)itemId qty:(NSString *)qty price:(NSString *)price lineAmount:(NSString *)lineAmount;

- (void)deleteTmpSalesLine:(NSString *)custAccount itemID:(NSString *)itemID isConsult:(BOOL)isConsult;

#pragma mark - SalesLine
- (void)createSalesLine:(NSString *)custAccount salesID:(NSString *)salesID item:(NSDictionary *)item;

- (void)deleteSalesLine:(NSString *)custAccount itemID:(NSString *)itemID salesID:(NSString *)salesID;

@end
