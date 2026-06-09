//
//  TasksViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 11.08.2021.
//

#import "TasksViewController.h"
#import "TaskCreateViewController.h"
#import "TaskCustomersViewController.h"

#import "RWBorderedButton.h"

#import "sqlite3.h"

//Cells
#import "TaskTableViewCell.h"

#import "GeneratedAssetSymbols.h"

//Constants
static const CGFloat kTaskCellHeight = 44.0;

static sqlite3 *database = nil;

@interface TasksViewController() <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, TaskTableViewCellDelegate, CustomersViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *mainSearchBar;
@property (nonatomic, weak) IBOutlet UITableView *mainTableView;

@property (nonatomic, strong) NSMutableArray *tasksArray;
@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation TasksViewController

#pragma mark - View Lifecycle
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self createTasks];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - UI Setup
- (void)setupUI {
    //Notifications
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(createTasks) name:@"updateTasks" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(createTasks) name:@"updateCustTasksNew" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(createTasks) name:@"updateTasksNew" object:nil];
    
    //NavBar Setup
    self.navigationItem.title = @"Задачи";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    if ([self.delegate respondsToSelector:@selector(userDidAddCustomersToRoute:date:)]) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self  action:@selector(cancelButtonTapped)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
//    RWBorderedButton *btnNewTask  = [RWBorderedButton buttonWithFrame:CGRectMake(0.0, 0.0, 130.0, 30.0) title:@"Новая задача"];
//    [btnNewTask addTarget:self action:@selector(btnNewTaskTapped:) forControlEvents:UIControlEventTouchUpInside];
//    
//    UIBarButtonItem *addNewTaskBarButton = [[UIBarButtonItem alloc] initWithCustomView:btnNewTask];
//    self.navigationItem.rightBarButtonItem = addNewTaskBarButton;
    
    //SearchBar
    self.mainSearchBar.searchTextField.backgroundColor = UIColor.whiteColor;
}

#pragma mark - Button Actions
- (void)cancelButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)btnNewTaskTapped:(id)sender {
    [self.mainSearchBar resignFirstResponder];
    
    TaskCreateViewController *fvController = [[TaskCreateViewController alloc] initWithNibName: @"TaskCreateViewController" bundle: nil];
    fvController.isViewPushed = NO;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:fvController];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    navVC.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
    
    navVC.preferredContentSize = CGSizeMake(500.0, 300.0);
    [self.navigationController presentViewController:navVC animated:YES completion:nil];
}

- (void)cellBtnAssignTapped:(TaskTableViewCell *)cell {
    [self.mainSearchBar resignFirstResponder];
    
    NSIndexPath *indexPath = [self.mainTableView indexPathForCell:cell];
    NSDictionary *object = self.dataSource[indexPath.row];
    
    TaskCreateViewController *fvController = [[TaskCreateViewController alloc] initWithNibName: @"TaskCreateViewController" bundle: nil];
    fvController.isViewPushed = NO;
    fvController.settingOldTask = YES;
    fvController.taskId = object[@"taskID"];
    fvController.taskName = object[@"taskName"];
    fvController.dateEnd = object[@"endDate"];
    fvController.typeOfResult = object[@"typeOfResult"];
    fvController.taskSet = object[@"setted"];
    fvController.from1C = object[@"from1C"];
    fvController.taskVisit = object[@"visit"];

    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:fvController];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    navVC.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;

    navVC.preferredContentSize = CGSizeMake(500.0, 300.0);
    [self.navigationController presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - CustomersViewControllerDelegate
- (void)userDidAddCustomersToRoute:(NSArray *)customers date:(NSDate *)date {
    if ([self.delegate respondsToSelector:@selector(userDidAddCustomersToRoute: date:)]) {
        [self.delegate userDidAddCustomersToRoute:customers date:date];
    }
}

#pragma mark - Notifications
- (void)createTasks {
    [self.mainSearchBar resignFirstResponder];
    self.tasksArray = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = nil;
        
        NSString *sqlString = @"select TaskId, TaskName, DateStart, DateEnd, Setted, Source, From1C, TypeOfResult, Visit from TaskTable group by TaskId, TaskName";
        
        sql = [sqlString UTF8String];
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *taskID = @"null";
                NSString *taskName = @"null";
                NSString *startDate = @"null";
                NSString *endDate = @"null";
                NSString *setted = @"null";
                NSString *source = @"null";
                NSString *from1C = @"null";
                NSString *typeOfResult = @"null";
                NSString *visit = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    taskID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                if (sqlite3_column_text(selectstmt, 1))
                    taskName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                if (sqlite3_column_text(selectstmt, 2))
                    startDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                if (sqlite3_column_text(selectstmt, 3))
                    endDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                if (sqlite3_column_text(selectstmt, 4))
                    setted = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                if (sqlite3_column_text(selectstmt, 5))
                    source = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                if (sqlite3_column_text(selectstmt, 6))
                    from1C = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                if (sqlite3_column_text(selectstmt, 7))
                    typeOfResult = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                if (sqlite3_column_text(selectstmt, 8))
                    visit = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                
                NSNumber *canBeAssigned = [NSNumber numberWithBool:NO];
                if ([setted isEqualToString:@"1"] || ([source isEqualToString:@"iPad"] && [from1C isEqualToString:@"0"])) {
                    canBeAssigned = [NSNumber numberWithBool:YES];
                }
                
                [self.tasksArray addObject: @{@"taskID" : taskID, @"taskName" : taskName, @"startDate" : startDate, @"endDate" : endDate, @"canBeAssigned" : canBeAssigned, @"setted" : setted, @"from1C" : from1C, @"typeOfResult" : typeOfResult, @"visit" : visit}];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self applyFilters];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([TaskTableViewCell class]) forIndexPath:indexPath];

    NSDictionary *object = self.dataSource[indexPath.row];
    
    cell.lblTaskName.text = object[@"taskName"];
    
    NSString *startDate = object[@"startDate"];
    NSString *endDate = object[@"endDate"];
    cell.lblTaskPeriod.text = [NSString stringWithFormat:@"%@ - %@", startDate, endDate];
    
    cell.btnAssign.hidden = ![object[@"canBeAssigned"] boolValue];
    cell.delegate = self;

    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kTaskCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TaskCustomersViewController *subTasksVC = [[UIStoryboard storyboardWithName:@"Tasks" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([TaskCustomersViewController class])];
    subTasksVC.delegate = self;
    subTasksVC.selectedTask = self.dataSource[indexPath.row];
    [self.navigationController pushViewController:subTasksVC animated:YES];
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
    [self applyFilters];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [self applyFilters];
}

#pragma mark - Helpers
- (void)applyFilters {
    NSString *searchText = self.mainSearchBar.text;
    if ([searchText stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0) {
        self.dataSource = [self.tasksArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
           
            NSString *itemName = object[@"taskName"];
            NSString *startDate = object[@"startDate"];
            NSString *endDate = object[@"endDate"];

            return [itemName localizedStandardContainsString:searchText]
            || [startDate localizedStandardContainsString:searchText]
            || [endDate localizedStandardContainsString:searchText];
        }]];
    } else {
        self.dataSource = self.tasksArray;
    }
    
    [self.mainTableView reloadData];
}

#pragma mark - Button styling methods
- (void)setBarButton:(UIBarButtonItem *)button highlighted:(BOOL)highlighted {
    [(RWBorderedButton *)button.customView setHighlightedState:highlighted];
}

@end

