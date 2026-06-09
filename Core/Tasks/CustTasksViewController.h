//
//  CustTasksViewController.h
//  MLK
//
//  Created by garu on 11/24/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "CustBrand.h"
#import "CustDream.h"
#import "TaskSource.h"
#import "SetTask.h"

@class OverlayCustTasksViewController;

#define kCellImageViewTag		1000
#define kCellLabelTag			1001
#define kCellDetailLabelTag		1002

#define kLabelIndentedRect	CGRectMake(40.0, 0.0, 500.0, 20.0)
#define kLabelRect			CGRectMake(15.0, 0.0, 500.0, 20.0)

#define kDetailLabelIndentedRect	CGRectMake(40.0, 20.0, 500.0, 20.0)
#define kDetailLabelRect			CGRectMake(15.0, 20.0, 500.0, 20.0)

@interface CustTasksViewController : UIViewController <UITableViewDelegate,UITableViewDataSource, CustBrandDelegate, UISearchBarDelegate, CustDreamDelegate, TaskSourceDelegate, SetTaskDelegate> {
    
    UITableView          *myTableView;
    
    NSMutableArray		 *taskList;
    NSMutableArray		 *copyTaskList;
    
    NSMutableArray		 *taskDetList;
	NSMutableArray		 *copyTaskDetList;
    
    NSString             *navigationBarTitle;
    
    IBOutlet UISearchBar *searchBar;
	
	BOOL searching;
	BOOL letUserSelectRow;
	
    OverlayCustTasksViewController *ovController;
    
    UINavigationController *infoNavController;
    
    UIBarButtonItem	*deleteButton;
    
    UIToolbar *toolbar;
    
    CustBrand  *custBrand;
    
    CustDream           *custDream;
    
    TaskSource  *taskSource;
    
    SetTask  *setTask;
    
    NSInteger        i;
    
    NSString *fmark;
    NSString *fdream;
    NSString *fsource;
    NSString *fset;
    
    id markBtn;
    id dreamBtn;
    id sourceBtn;
    id setBtn;
    
    UIBarButtonItem *mButton;
    
    BOOL isViewPushed;
    NSString *custAccount;
}

@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,readwrite) BOOL isViewPushed;
@property(nonatomic,readwrite) NSInteger i;
@property(nonatomic,retain)NSMutableArray *taskList;
@property(nonatomic,retain)NSMutableArray *taskDetList;
@property(nonatomic,retain)NSString *navigationBarTitle;
@property(nonatomic,retain)IBOutlet UISearchBar *searchBar;
@property(nonatomic,retain)IBOutlet UIBarButtonItem *deleteButton;
@property(nonatomic,retain)IBOutlet UIToolbar *toolbar;
@property(nonatomic,retain)CustBrand *custBrand;
@property(nonatomic,retain)CustDream           *custDream;
@property(nonatomic,retain)TaskSource  *taskSource;
@property(nonatomic,retain)SetTask  *setTask;
@property(nonatomic,retain)NSString *fmark;
@property(nonatomic,retain)NSString *fdream;
@property(nonatomic,retain)NSString *fsource;
@property(nonatomic,retain)NSString *fset;
@property(nonatomic,retain)id markBtn;
@property(nonatomic,retain)id dreamBtn;
@property(nonatomic,retain)id sourceBtn;
@property(nonatomic,retain)id setBtn;
@property(nonatomic,retain)UITableView *myTableView;
@property(nonatomic,retain)UIBarButtonItem *mButton;
@property(nonatomic,retain)UIBarButtonItem *aButton;

- (void)finalizeStatements;
- (void)searchTableView;
- (void)doneSearching_Clicked:(id)sender;
- (void)showDream:(id)sender;
- (void)showBrand:(id)sender;
- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar;
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText;
- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar;
- (void)scrollToTop;
- (void)selectAllTasks;
- (void)selectWithFilters;
- (void)clearFilter;
- (void)createTask:(id)sender;
- (void)taskAdded;
- (void)cancel_Clicked:(id)sender;
- (void)showSource:(id)sender;
- (void)showSet:(id)sender;
- (void)selectSetTask:(NSString *)setValue;

@end
