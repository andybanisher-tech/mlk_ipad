//
//  MerchActionViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 14.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "ActionMarkViewController.h"
#import "ActionTypeViewController.h"
#import "MerchActDetViewController.h"

@class OverlayActionViewViewController;
@class ActionMarkViewController;
@class ActionTypeViewController;
@class MerchActDetViewController;

@interface MerchActionViewController : UIViewController <UITableViewDelegate,UITableViewDataSource, UITextFieldDelegate, UISearchBarDelegate, UIAlertViewDelegate, ActionMarkDelegate, TypeFilterDelegate, ActionDetailDelegate> {
    UITableView          *myTableView;
    
    NSMutableArray		 *actionList;
    NSMutableArray		 *copyActionList;
    NSMutableArray		 *actionToLiveInArray;
    
    NSMutableArray		 *actionNameList;
	NSMutableArray		 *copyActionNameList;
    NSMutableArray       *actionNameToLiveInArray;
    
    NSMutableArray		 *brandList;
	NSMutableArray		 *copyBrandList;
    NSMutableArray       *brandToLiveInArray;
    
    NSMutableArray		 *priceList;
	NSMutableArray		 *copyPriceList;
    NSMutableArray       *priceToLiveInArray;
    
    NSMutableArray		 *availQtyList;
	NSMutableArray		 *copyAvailQtyList;
    NSMutableArray       *availQtyToLiveInArray;
    
    NSMutableArray		 *actionTypeList;
	NSMutableArray		 *copyActionTypeList;
    NSMutableArray       *actionTypeToLiveInArray;
    
    NSMutableArray		 *amaountSumList;
	NSMutableArray		 *copyAmountSumList;
    NSMutableArray       *amountSumToLiveInArray;
    
    NSMutableArray		 *amaountQtyList;
	NSMutableArray		 *copyAmountQtyList;
    NSMutableArray       *amountQtyToLiveInArray;
    
    NSMutableArray		 *setList;
	NSMutableArray		 *copySetList;
    NSMutableArray       *setToLiveInArray;
    
    NSMutableArray		 *setDescrList;
	NSMutableArray		 *copySetDescrList;
    NSMutableArray       *setDescrToLiveInArray;
    
    NSMutableArray		 *brandIdList;
	NSMutableArray		 *copyBrandIdList;
    NSMutableArray       *brandIdToLiveInArray;
    
    NSString             *brandId;
    NSString             *typeId;
    
    IBOutlet UISearchBar *searchBar;
	
	BOOL searching;
	BOOL letUserSelectRow;
    BOOL endEditInSearch;
    BOOL mustClosingView;
    BOOL fromMerch;
    
    OverlayActionViewViewController *ovController;
    UINavigationController *infoNavController;
    
    NSInteger        i;
    
    BOOL isViewPushed;
    
    ActionMarkViewController    *actionMark;

    ActionTypeViewController *actionType;

    NSString            *custAccount;
    NSString            *custName;
    
    id brandBtn;
    id typeBtn;
}

@property(nonatomic,retain)NSMutableArray *actionList;
@property(nonatomic,retain)NSMutableArray *actionNameList;
@property(nonatomic,retain)NSMutableArray *brandList;
@property(nonatomic,retain)NSMutableArray *priceList;
@property(nonatomic,retain)NSMutableArray *availQtyList;
@property(nonatomic,retain)NSMutableArray *actionTypeList;
@property(nonatomic,retain)NSMutableArray *amountSumList;
@property(nonatomic,retain)NSMutableArray *amountQtyList;
@property(nonatomic,retain)NSMutableArray *setList;
@property(nonatomic,retain)NSMutableArray *setDescrList;
@property(nonatomic,retain)NSMutableArray *brandIdList;
@property(nonatomic,retain)NSString *brandId;
@property(nonatomic,retain)NSString *typeId;
@property(nonatomic,retain)IBOutlet UISearchBar *searchBar;
@property(nonatomic,readwrite)NSInteger i;
@property(nonatomic, readwrite)BOOL searching;
@property(nonatomic, readwrite)BOOL letUserSelectRow;
@property(nonatomic, readwrite)BOOL endEditInSearch;
@property(nonatomic, readwrite)BOOL isViewPushed;
@property(nonatomic, readwrite)BOOL mustClosingView;
@property(nonatomic, readwrite)BOOL fromMerch;
@property(nonatomic, retain)ActionMarkViewController *actionMark;
@property(nonatomic, retain)ActionTypeViewController *actionType;
@property(nonatomic, retain)NSString *custAccount; 
@property(nonatomic, retain)NSString *custName;
@property(nonatomic,retain)id brandBtn;
@property(nonatomic,retain)id cBtn;

- (void)createItemList;
- (void)refreshData;
- (void)searchTableView;
- (void)doneSearching_Clicked:(id)sender;
- (void)cancel_Clicked:(id)sender;
- (void)markIsSelected:(NSString *)brand;
- (void)showMark:(id)sender;
- (void)showType:(id)sender;
- (void)typeIsSelected:(NSString *)type;
- (void)closeView:(BOOL)closeAll;
-(BOOL)actionInSalesToday:(NSString*)setId;
-(NSString*)roundedNum:(double)num round:(double)round;

@end
