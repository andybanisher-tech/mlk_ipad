//
//  CDSecondaryTasksViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 29.03.2025.
//

#import "CDSecondaryTasksViewController.h"

//VCs
#import "CustDream.h"
#import "TaskSource.h"
#import "SetTaskToCustViewController.h"
#import "TaskTransViewController.h"

//Cells
#import "CDSecondaryTaskCollectionViewCell.h"

#import "GeneratedAssetSymbols.h"

#import "sqlite3.h"

@interface CDSecondaryTasksViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate, CustDreamDelegate, TaskSourceDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *mainCollectionView;

@property (weak, nonatomic) IBOutlet UISearchBar *mainSearchBar;

@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (weak, nonatomic) IBOutlet UIButton *sourceButton;
@property (weak, nonatomic) IBOutlet UIButton *assignButton;

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSArray *filteredDataSource;

//Filters
@property (nonatomic, strong) NSArray *statusFilters;
@property (nonatomic, strong) NSArray *sourceFilters;

@end

static sqlite3 *database = nil;

@implementation CDSecondaryTasksViewController

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.mainSearchBar resignFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareLayout];
    [self setupUI];
    [self prepareObservers];
    [self prepareDataSource];
}

#pragma mark - Setup UI
- (void)prepareLayout {
    UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    configuration.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    configuration.headerMode = UICollectionLayoutListHeaderModeSupplementary;
    configuration.itemSeparatorHandler = ^UIListSeparatorConfiguration * _Nonnull(NSIndexPath * _Nonnull indexPath, UIListSeparatorConfiguration * _Nonnull sectionSeparatorConfiguration) {
        sectionSeparatorConfiguration.bottomSeparatorInsets = NSDirectionalEdgeInsetsZero;
        return sectionSeparatorConfiguration;
    };
    
    UICollectionViewCompositionalLayout *layout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:configuration];
    self.mainCollectionView.collectionViewLayout = layout;
}

- (void)setupUI {
    self.mainSearchBar.searchTextField.backgroundColor = UIColor.whiteColor;
}

- (void)prepareObservers {
    //Observers
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(tasksDidUpdate) name:@"updateTasksNew" object:nil];
}

#pragma mark - Data preparation
- (void)prepareDataSource {
    self.dataSource = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "SELECT tt.TaskId, tt.TaskName, tt.DateEnd, tt.TransDate, tt.Visit, tt.Result, tt.TypeOfResult, tt.Status, tt.Source, tt.From1C, tl.LineDescription FROM TaskTable AS tt LEFT JOIN TaskList AS tl ON tt.TaskId = tl.TaskId AND tt.Result = tl.LineId WHERE tt.CustAccount = ? group by tt.TaskId, tt.TaskName";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *order = [NSMutableDictionary new];
                
                for (int i = 0; i < sqlite3_column_count(selectstmt); i++) {
                    if (sqlite3_column_text(selectstmt, i)) {
                        NSString *key = [NSString stringWithUTF8String:(char *)sqlite3_column_name(selectstmt, i)];
                        order[key] = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, i)];
                    }
                }
                
                [self.dataSource addObject:order];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self applyFilters];
}

#pragma mark - Button Actions
- (IBAction)statusButtonTapped:(id)sender {
    if (self.presentedViewController) { return; }
    
    [self.mainSearchBar resignFirstResponder];
    
    CustDream *chooseStatusVC = [CustDream new];
    chooseStatusVC.custAcccount = self.custAccount;
    chooseStatusVC.delegate = self;
    chooseStatusVC.fromCustTask = YES;
    chooseStatusVC.fromTask = YES;
    chooseStatusVC.selected = self.statusFilters.mutableCopy;
    
    [self presentPopover:chooseStatusVC sourceView:sender];
}

- (IBAction)sourceButtonTapped:(id)sender {
    if (self.presentedViewController) { return; }
    
    [self.mainSearchBar resignFirstResponder];
    
    TaskSource *taskSourceVC = [TaskSource new];
    taskSourceVC.custAccount = self.custAccount;
    taskSourceVC.delegate = self;
    taskSourceVC.fromCust = YES;
    taskSourceVC.selected = self.sourceFilters.mutableCopy;
    
    [self presentPopover:taskSourceVC sourceView:sender];
}

- (IBAction)assignButtonTapped:(id)sender {
    SetTaskToCustViewController *assignTaskVC = [[SetTaskToCustViewController alloc] initWithNibName:@"SetTaskToCustViewController" bundle:nil];
    assignTaskVC.custAcc = self.custAccount;
    assignTaskVC.custNameStr = self.custName;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:assignTaskVC];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    navVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    navVC.preferredContentSize = CGSizeMake(540.0, 300.0);
    
    [self presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - Observers
- (void)tasksDidUpdate {
    [self prepareDataSource];
}

#pragma mark - CustDreamDelegate
- (void)userDidSelectDream:(NSMutableArray *)dreamArray {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.statusFilters = dreamArray;
    [self applyFilters];
    [self setButton:self.statusButton highlighted:self.statusFilters.count > 0];
}

#pragma mark - TaskSourceDelegate
- (void)userDidSelectTaskSources:(NSMutableArray *)taskSources {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.sourceFilters = taskSources;
    [self applyFilters];
    [self setButton:self.sourceButton highlighted:self.sourceFilters.count > 0];
}

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CDSecondaryTasksSectionHeaderView" forIndexPath:indexPath];
        return headerView;
    }
    
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredDataSource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDSecondaryTaskCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDSecondaryTaskCollectionViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.filteredDataSource[indexPath.item];
    [cell setTask:object];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    
    NSDictionary *task = self.dataSource[indexPath.item];
    [self handleTaskSelection:task];
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
    [self applyFilters];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [theSearchBar resignFirstResponder];
}

#pragma mark - Selection Handlers
- (void)handleTaskSelection:(NSDictionary *)task {
    NSString *visit = task[@"Visit"];
    
    if ([visit isEqualToString:@"0"] || self.isCustInVisit) {
        TaskTransViewController *taskTransVC = [[TaskTransViewController alloc] initWithNibName:@"TaskTransViewController" bundle:nil];
        taskTransVC.custAccount = self.custAccount;
        taskTransVC.custName = self.custName;
        taskTransVC.taskId = task[@"TaskId"];
        taskTransVC.taskName = task[@"TaskName"];
        taskTransVC.status = task[@"Status"];
        taskTransVC.typeOfResult = task[@"TypeOfResult"];
        taskTransVC.result = task[@"Result"];
        taskTransVC.dateEnd = task[@"DateEnd"];

        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:taskTransVC];
        navVC.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentViewController:navVC animated:YES completion:nil];
    } else {
        [AlertWorkerObjc alertWithTitle:@"Задача" message:@"Задача может выполняться только в режиме посещения."];
    }
}

#pragma mark - Data Helpers
- (void)applyFilters {
    NSString *searchText = self.mainSearchBar.text;
    
    if (!self.statusFilters && !self.sourceFilters && searchText.length < 1) {
        self.filteredDataSource = self.dataSource;
    } else {
        self.filteredDataSource = [self.dataSource filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
            
            BOOL statusFilterFlag = YES;
            if (self.statusFilters.count > 0) {
                statusFilterFlag = [self.statusFilters containsObject:object[@"Status"]];
            }
            
            BOOL sourceFilterFlag = YES;
            if (self.sourceFilters.count > 0) {
                NSString *source = object[@"Source"];
                if ([object[@"From1C"] isEqual:@"1"]) {
                    if ([source isEqualToString:@"iPad"]) {
                        source = @"Назначено iPad";
                    } else {
                        source = @"Назначено 1C";
                    }
                } else {
                    source = @"Собственная";
                }
    
                sourceFilterFlag = [self.sourceFilters containsObject:source];
            }
            
            BOOL searchFilterFlag = YES;
            if (searchText.length > 0) {
                NSString *taskName = object[@"TaskName"];
                NSString *taskID = object[@"TaskId"];
                searchFilterFlag = [taskName localizedStandardContainsString:searchText]
                || [taskID localizedStandardContainsString:searchText];
            }
            
            return statusFilterFlag && sourceFilterFlag && searchFilterFlag;
        }]];
    }
    
    [self.mainCollectionView reloadData];
}

#pragma mark - Helpers
- (void)presentPopover:(UIViewController *)popover sourceView:(UIView *)sourceView{
    popover.modalPresentationStyle = UIModalPresentationPopover;
    popover.popoverPresentationController.sourceView = sourceView;
    
    [self presentViewController:popover animated:YES completion:nil];
}

- (void)setButton:(UIButton *)button highlighted:(BOOL)highlighted {
    UIColor *titleColor = highlighted ? UIColor.whiteColor : [UIColor colorNamed:ACColorNameMLKBlue];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    
    UIColor *backgroundColor = highlighted ? [UIColor colorNamed:ACColorNameMLKLightBlue] : [ASPFunctions colorFromHex:@"F2F2F7"];
    button.backgroundColor = backgroundColor;
}

@end
