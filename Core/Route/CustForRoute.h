//
//  CustForRoute.h
//  MLK
//
//  Created by Rustem Galyamov on 03.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol CustForRouteControllerDelegate
-(IBAction)showCustActionSheet:(id)sender title:(NSString *)titleTxt custAccount:(NSString *)custAccountLoc custName:(NSString *)custNameLoc;
- (void)showCustInfo:(NSString *)custAccount custName:(NSString *)custName;
- (void)reloadCustTable;
@end

@interface CustForRoute : UITableViewController <UITableViewDelegate,UITableViewDataSource, UISearchBarDelegate> {    
	NSMutableArray       *custList;
	
    NSMutableArray		 *custAccList;
    
    NSMutableArray		 *copyCustList;
    NSMutableArray		 *copyCustAccList;
    
    NSString    *dateOfMonth;
    
    BOOL searching;
    BOOL letUserSelectRow;
    
    UISearchBar *searchBar;
    
    NSInteger        i;
    
    NSString *fcity;
    NSString *fkey;
    NSString *fmark;
    NSString *fday;
    
    id cityBtn;
    id markBtn;
    id keyBtn;
    id dayBtn;
    
    UITextField *alertTextField;
}
@property(nonatomic,readwrite) NSInteger i;
@property(nonatomic,retain)NSMutableArray  *custList;
@property(nonatomic,retain)NSMutableArray *custAccList;

@property(nonatomic,retain)NSString *dateOfMonth;
@property(nonatomic,retain)UISearchBar *searchBar;

@property(nonatomic,assign) id<CustForRouteControllerDelegate> delegate;

@property(nonatomic,retain)NSString *fcity;
@property(nonatomic,retain)NSString *fkey;
@property(nonatomic,retain)NSString *fmark;
@property(nonatomic,retain)NSString *fday;

- (void)finalizeStatements;
- (void)refreshData;

- (void)searchTableView;
- (void)doneSearching_Clicked:(id)sender;
- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar;
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText;
- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar;

- (void)city;
- (void)key;
- (void)brand;
- (void)day;

@end

