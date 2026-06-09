//
//  InvoiceInventView.h
//  MLK
//
//  Created by Rustem Galyamov on 24.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "CustItemMarkView.h"
#import "GroupView.h"
#import "CustStatusDN.h"

#import "RWBorderedButton.h"

@interface InvoiceInventView : UIViewController <CustItemMarkDelegate, GroupDelegate, CustStatusDNDelegate> {
    UITableView          *myTableView;
    
    NSMutableArray *statusDNArray;
    
    double qtyTotal;
    double sumTotal;
    
    IBOutlet UISearchBar *searchBar;

    BOOL isMatrix;
    
    UINavigationController *infoNavController;
        
    BOOL isViewPushed;
    
    NSString            *custAccount;
    NSString            *custName;
    
    id brandBtn;
    id cBtn;
    id matrixBtn;
    
    UILabel *labelTotal;
    UILabel *labelTitle;
    
    NSString *itemIdIsSelected;
    
    BOOL fromCreatedSales;
    
    NSString *salesId;
    
    NSString *firmMarkup;
    UIView *m_footerView;
}

@property (nonatomic, strong) CustItemMarkView *custItemMarkVC;

@property(nonatomic, retain) NSString *brandId;
@property(nonatomic, retain) NSString *group;
@property(nonatomic, retain) NSString *closedItems;
@property(assign, nonatomic) BOOL discountsOnly;
@property(nonatomic, readwrite) double qtyTotal;
@property(nonatomic, readwrite) double sumTotal;
@property(nonatomic, retain) UISearchBar *searchBar;
@property(nonatomic, readwrite) BOOL isViewPushed;
@property(nonatomic, retain) NSString *custAccount;
@property(nonatomic, retain) NSString *custName;
@property(nonatomic, retain) id brandBtn;
@property(nonatomic, retain) id statusDNBtn;
@property(nonatomic, retain) id cBtn;
@property(nonatomic, retain) id matrixBtn;
@property(nonatomic, retain) id btnDiscounts;
@property(nonatomic, retain) UILabel *labelTotal;
@property(nonatomic, retain) NSString *brandIsSelected;
@property(nonatomic, retain) NSString *itemIdIsSelected;
@property(nonatomic, readwrite) BOOL fromCreatedSales;
@property(nonatomic, retain) NSString *salesId;
@property(nonatomic, retain) NSString *firmID;
@property(nonatomic, retain) NSString *firmName;
@property(nonatomic, retain) NSString *firmMarkup;
 
@property(nonatomic, retain) NSString *fstatusDN;
@property(nonatomic, retain) NSMutableArray *statusDNArray;
// Andrey
@property(nonatomic, retain) UIView *m_footerView;
@property(nonatomic, assign) BOOL isMatrix;
 
@property (nonatomic, strong) NSDictionary *selectedStore;

@property (nonatomic, assign) BOOL isConsult;

- (void)createItemsArray;
- (void)cancel_Clicked:(id)sender;
- (void)markIsSelected:(NSString *)brand;
- (void)groupIsSelected:(NSString *)groupId;
- (void)showMark:(id)sender;
- (void)closedItems:(id)sender;
- (void)matrixItems:(id)sender;
- (NSString *)totalSalesSum;
- (NSString *)roundedNum:(double)num round:(double)round;
 
@end

