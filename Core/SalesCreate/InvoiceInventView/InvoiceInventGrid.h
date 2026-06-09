//
//  InvoiceInventView.h
//  MLK
//
//  Created by Rustem Galyamov on 15.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol InvoiceInventGridDelegate
- (void)markIsSelected:(NSString *)brand;
- (void)qtySelected:(double)qty price:(double)price;
- (void)reloadData;
@end

@interface InvoiceInventGrid : UITableViewController <UITableViewDelegate,UITableViewDataSource, UITextFieldDelegate> {
    NSMutableArray		 *itemList;
    NSMutableArray		 *itemToLiveInArray;
    
    NSMutableArray		 *itemNameList;
    NSMutableArray       *itemNameToLiveInArray;
    
    NSMutableArray		 *brandList;
    NSMutableArray       *brandToLiveInArray;
    
    NSMutableArray		 *unitList;
    NSMutableArray       *unitToLiveInArray;
    
    NSMutableArray		 *qtyList;
    NSMutableArray       *qtyToLiveInArray;
    
    NSMutableArray		 *basePriceList;
    NSMutableArray       *bPToLiveInArray;
    
    NSString             *brandId;
    NSString             *custAccount;
    
    NSMutableArray		 *sectionArray;
    NSMutableArray		 *textToLiveInArray;
    
    double qtyTotal;
    double sumTotal;
    
    NSInteger        i;
}

@property(nonatomic,assign) id<InvoiceInventGridDelegate> delegate;

@property(nonatomic,retain)NSMutableArray *itemList;
@property(nonatomic,retain)NSMutableArray *itemNameList;
@property(nonatomic,retain)NSMutableArray *brandList;
@property(nonatomic,retain)NSMutableArray *unitList;
@property(nonatomic,retain)NSMutableArray *qtyList;
@property(nonatomic,retain)NSMutableArray *basePriceList;
@property(nonatomic,retain)NSMutableArray *sectionArray;
@property(nonatomic,retain)NSString       *brandId;
@property(nonatomic,retain)NSString       *custAccount;
@property(nonatomic,readwrite)double qtyTotal;
@property(nonatomic,readwrite)double sumTotal;
@property(nonatomic,readwrite)NSInteger i;

- (void)createItemList;
- (void)refreshData;

@end
