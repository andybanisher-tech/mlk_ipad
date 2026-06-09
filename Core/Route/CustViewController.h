//
//  CustViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "CustCity.h"
#import "CustBrand.h"
#import "CustStatusDN.h"
#import "CustDream.h"
#import "MoreCustViewController.h"
#import "CustAddToRouteController.h"
#import "PutClientForRouteRequest.h"
#import "CustomerTypesTableViewController.h"

#import "ASPDatePickerViewController.h"

@class OverlayCustView;
@class DetailViewController;
@class MoreCustViewController;

@class CustAddToRouteController;

#define kCellImageViewTag		1000
#define kCellLabelTag			1001
#define kCellDetailLabelTag		1002
#define kCellDateOfSaleTag      1003

#define kLabelIndentedRect	CGRectMake(40.0, 0.0, 500.0, 20.0)
#define kLabelRect			CGRectMake(15.0, 0.0, 500.0, 20.0)

#define kDetailLabelIndentedRect	CGRectMake(40.0, 20.0, 500.0, 20.0)
#define kDetailLabelRect			CGRectMake(15.0, 20.0, 500.0, 20.0)

#define kDateOfSaleRect             CGRectMake(520.0, 7.0, 125.0, 35.0)



@interface CustViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate, CustCityDelegate, CustBrandDelegate,
        UISearchBarDelegate, CustDreamDelegate, MoreCustomerDelegate, PutClientForRouteRequestDelegate, CustStatusDNDelegate, CustomerTypesTableViewControllerDelegate, ASPDatePickerViewControllerDelegate> {
    
    UITableView          *myTableView;
    
    NSMutableArray		 *custList;
    NSMutableArray		 *copyCustList;
    
    NSMutableArray		 *custDetList;
	NSMutableArray		 *copyCustDetList;
    
    NSMutableArray		 *custAccList;
	NSMutableArray		 *copyCustAccList;
    
    NSMutableArray		 *custSendStatusList;
    NSMutableArray		 *copyCustSendStatusList;
    
    NSMutableArray		 *custCustPDZList;
    NSMutableArray		 *copyCustPDZList;
    
    NSString             *navigationBarTitle;
    
    IBOutlet UISearchBar *searchBar;
	
	BOOL searching;
	BOOL letUserSelectRow;
	
    OverlayCustView *ovController;

    NSInteger   _checkboxSelections;
    NSInteger   _cellForRow;
    BOOL        buttonTapped;
    BOOL        imageUpdated;
    
	UINavigationController *infoNavController;
    
    id _target;
    SEL _action;
    
    NSMutableArray *custForRoute;
    
    NSMutableArray *selectedArray;
	BOOL inPseudoEditMode;
	
	UIImage *selectedImage;
	UIImage *unselectedImage;
	
	UIBarButtonItem	*deleteButton;
    
    UIToolbar *toolbar;

    NSInteger        i;
    
    NSString *fcity;
    NSMutableArray *cityArray;
    NSString *fkey;
    NSMutableArray *keyArray;
    NSString *fmark;
    NSMutableArray *markArray;
    NSArray *typesArray;
    NSMutableArray *statusDNArray;
    NSString *fday;
    
    id cityBtn;
    id markBtn;
    id keyBtn;
    id dayBtn;
    
    UITextField *alertTextField;
    
    UIBarButtonItem *mButton;
    UIBarButtonItem *visitPlanBtn;
    
    BOOL visitPlan;
    BOOL additionalCusts;
    BOOL selectPDZ;
    BOOL selectSalesDateSort;
    BOOL isNotFirstLaunch;
    
    UILabel *labelCustTotal;
    
    CustAddToRouteController    *custAddToRouteController;
}

@property(nonatomic,readwrite) NSInteger i;
@property(nonatomic,retain)NSMutableArray *custList;
@property(nonatomic,retain)NSMutableArray *custDetList;
@property(nonatomic,retain)NSMutableArray *custAccList;
@property(nonatomic,retain)NSMutableArray *custSendStatusList;
@property(nonatomic,retain)NSMutableArray *custPDZList;
@property(nonatomic,retain)NSString *navigationBarTitle;
@property(nonatomic,retain)IBOutlet UISearchBar *searchBar;
@property(nonatomic,retain)NSDate *selectedDate;
@property(nonatomic,retain)id target;
@property(nonatomic,assign)SEL action;
@property(nonatomic,retain)NSMutableArray *custForRoute;
@property(nonatomic,retain)NSMutableArray *selectedArray;
@property(nonatomic,retain)UIImage *selectedImage;
@property(nonatomic,retain)UIImage *unselectedImage;
@property(nonatomic,retain)IBOutlet UIBarButtonItem *deleteButton;
@property(nonatomic,retain)IBOutlet UIToolbar *toolbar;
@property(nonatomic,retain)NSString *fcity;
@property(nonatomic,retain)NSMutableArray *cityArray;
@property(nonatomic,retain)NSString *fkey;
@property(nonatomic,retain)NSMutableArray *keyArray;
@property(nonatomic,retain)NSString *fmark;
@property(nonatomic,retain)NSMutableArray *markArray;
@property(nonatomic,retain)NSString *fstatusDN;
@property(nonatomic,retain)NSArray *typesArray;
@property(nonatomic,retain)NSString *fType;
@property(nonatomic,retain)NSMutableArray *statusDNArray;
@property(nonatomic,retain)NSString *fday;
@property(nonatomic,retain)id cityBtn;
@property(nonatomic,retain)id markBtn;
@property(nonatomic,retain)UIBarButtonItem* statusDNBtn;
@property(nonatomic,retain)UIBarButtonItem *typeBtn;
@property(nonatomic,retain)id keyBtn;
@property(nonatomic,retain)id dayBtn;
@property(nonatomic,retain)UITableView *myTableView;
@property(nonatomic,retain)UIBarButtonItem *mButton;
@property(nonatomic,retain)UIBarButtonItem *visitPlanBtn;
@property(nonatomic,readwrite)BOOL visitPlan;
@property(nonatomic,readwrite)BOOL selectPDZ;
@property(nonatomic,readwrite)BOOL selectSalesDateSort;
@property(nonatomic,retain)UIBarButtonItem *selectPDZBtn;
@property(nonatomic,retain)UIBarButtonItem *selectSalesDateSortBtn;
@property(nonatomic,readwrite)BOOL additionalCusts;
@property(nonatomic,retain)UILabel *labelCustTotal;
@property(nonatomic,readwrite)BOOL isNotFirstLaunch;
@property BOOL inPseudoEditMode;

// Andrey
@property(nonatomic,retain)UIBarButtonItem *aButton;
@property(nonatomic,retain)CustAddToRouteController *custAddToRouteController;

-(IBAction)togglePseudoEditMode:(id)sender;
-(IBAction)doDelete;
- (void)populateSelectedArray;

- (void)hideCustActionListAndShow:(UIViewController *)vcToPresent;

- (void)finalizeStatements;
- (void)searchTableView;
- (void)doneSearching_Clicked:(id)sender;
-(int)getCustInRouteCount:(NSString *)strDate;
- (void)addCustomersToRoute:(NSString *)custAccount custName:(NSString *)custName custAddr:(NSString *)custAddress strDate:(NSString *)strDate;
//add Customer to local DB
- (void)addCustomerToRouteDB:(NSString *)custAccount custName:(NSString *)custName custAddr:(NSString *)custAddress strDate:(NSString *)strDate;
- (void)selectForMark;
- (void)showCity:(id)sender;
- (void)showBrand:(id)sender;
- (void)showDream:(id)sender;
-(IBAction)visitDay:(id)sender;
- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar;
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText;
- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar;
- (void)selectAllCustomers;
- (void)selectWithFilters;
- (void)clearFilter;
- (void)createCustomer:(id)sender;

- (void)refresh;

- (void)requestCustomer:(id)sender;
//remove Customer from DB
- (void)removeCustomerFromRouteDB:(NSString *)custAccount;


@end
