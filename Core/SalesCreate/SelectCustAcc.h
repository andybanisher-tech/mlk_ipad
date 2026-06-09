//
//  SelectCustAcc.h
//  MLK
//
//  Created by Rustem Galyamov on 27.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "CustCity.h"
#import "CustBrand.h"
#import "CustDream.h"

@class OverlaySelectCustAcc;

@protocol SelectCustDelegate
- (void)custIsSelected:(NSString *)custAcc custName:(NSString *)custN;
@end

@interface SelectCustAcc : UIViewController <UITableViewDelegate,UITableViewDataSource, CustCityDelegate, CustBrandDelegate, UISearchBarDelegate, CustDreamDelegate> {    
    
    UITableView          *myTableView;
    NSMutableArray		 *custList;
    NSMutableArray		 *copyCustList;
    NSMutableArray		 *custsToLiveInArray;
    
    NSMutableArray		 *custDetList;
	NSMutableArray		 *copyCustDetList;
    NSMutableArray       *custDetToLiveInArray;
    
    NSMutableArray		 *custAccList;
	NSMutableArray		 *copyCustAccList;
    NSMutableArray       *custAccToLiveInArray;
    
    IBOutlet UISearchBar *searchBar;
	
	BOOL searching;
	BOOL letUserSelectRow;
	
    OverlaySelectCustAcc *ovController;

    NSInteger        i;
    
    BOOL isViewPushed;
    
    NSString *fcity;
    NSMutableArray *cityArray;
    NSString *fkey;
    NSMutableArray *keyArray;
    NSString *fmark;
    NSMutableArray *markArray;
    NSString *fday;
    
    id cityBtn;
    id markBtn;
    id keyBtn;
    id dayBtn;
}

@property(nonatomic,assign) id<SelectCustDelegate> delegate;
@property(nonatomic,readwrite) NSInteger i;
@property(nonatomic,retain)NSMutableArray *custList;
@property(nonatomic,retain)NSMutableArray *custDetList;
@property(nonatomic,retain)NSMutableArray *custAccList;
@property(nonatomic,retain)IBOutlet UISearchBar *searchBar;
@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic,retain)NSString *fcity;
@property(nonatomic,retain)NSMutableArray *cityArray;
@property(nonatomic,retain)NSString *fkey;
@property(nonatomic,retain)NSMutableArray *keyArray;
@property(nonatomic,retain)NSString *fmark;
@property(nonatomic,retain)NSMutableArray *markArray;
@property(nonatomic,retain)NSString *fday;
@property(nonatomic,retain)id cityBtn;
@property(nonatomic,retain)id markBtn;
@property(nonatomic,retain)id keyBtn;
@property(nonatomic,retain)id dayBtn;

+(void)finalizeStatements;
- (void)searchTableView;
- (void)showCity:(id)sender;
- (void)showBrand:(id)sender;
- (void)showDream:(id)sender;
- (void)selectBrand:(NSString *)brand;
- (void)selectDay:(id)sender;
-(IBAction)visitDay:(id)sender;
- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar;
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText;
- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar;
- (void)doneSearching_Clicked:(id)sender;
- (void)scrollToTop;
- (void)selectAllCustomers;
- (void)selectWithFilters;
- (void)clearFilter;


@end

