//
//  TaskTransViewController.m
//  MLK
//
//  Created by garu on 12/4/14.
//
//

#import "TaskTransViewController.h"
#import "DoTaskViewController.h"
#import "PutTasksRequest.h"
#import "RWBorderedButton.h"
#import "CameraViewController.h"

#import "FilesStorageWorker.h"

#import "TaskTransTableSectionHeaderView.h"
#import "TaskTransTableViewCell.h"

#import "GeneratedAssetSymbols.h"

//Constants
static const CGFloat kTaskTransTableSectionHeaderViewHeight = 30.0;
static const CGFloat kTaskTransCellHeight = 50.0;

static const CGFloat kDoTaskVCHeight = 450.0;

static sqlite3 *database = nil;

@interface TaskTransViewController ()

@property (nonatomic, weak) IBOutlet UIButton *photoButton;

@property (nonatomic, strong) NSMutableArray *taskTransArray;

@end

@implementation TaskTransViewController
@synthesize addBtn, taskTransTable, labelTaskName, isViewPushed, labelTaskStatus;
@synthesize taskId, taskName, custAccount, custName;
@synthesize status, typeOfResult, result, dateEnd;
@synthesize doneReason, cancelReason;
@synthesize needPhoto;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //NavBar Setup
    self.navigationItem.title = taskName;
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    if (isViewPushed == NO) {
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        
        self.navigationItem.rightBarButtonItem = barButton;
    }
    
    self.labelTaskName.text = custName;
    
    if (![status isEqualToString:@"Готово"] && ! [status isEqualToString:@"Отказ"]) {
        NSDate *date = NSDate.date;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        
        [formatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        NSCalendar       *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components        = [gregorianCalendar components:NSCalendarUnitDay
                                                                   fromDate:date
                                                                     toDate:[formatter dateFromString:dateEnd]
                                                                    options:0];
        
        if ([components day] < 7) {
            if ([components day] >= 0)
                self.labelTaskStatus.text = @"Горит";
            
            if ([components day] < 0)
                self.labelTaskStatus.text = @"Горит";
            
            self.labelTaskStatus.textColor = [UIColor redColor];
        }
        
    }
    
    [ASPFunctions addLineLayerForView:taskTransTable lineColor:UIColor.whiteColor lineWidth:1.0 cornerRadius:0.0];
    [taskTransTable registerNib:[UINib nibWithNibName: NSStringFromClass([TaskTransTableSectionHeaderView class]) bundle:nil] forHeaderFooterViewReuseIdentifier:NSStringFromClass([TaskTransTableSectionHeaderView class])];
    [taskTransTable registerNib:[UINib nibWithNibName: NSStringFromClass([TaskTransTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([TaskTransTableViewCell class])];
    
    if ([status isEqualToString:@"Готово"] || [status isEqualToString:@"Отказ"]) {
        addBtn.enabled    = NO;
    } else {
        addBtn.enabled    = YES;
    }
    
    needPhoto = [self getPhotoParm];
    
    if ([needPhoto isEqualToString:@"1"]) {
        self.photoButton.hidden = NO;
        
        if (![FilesStorageWorker file:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] existsAtPath:[FilesStorageWorker taskImagesPath]])
            [self.photoButton setImage:[UIImage imageNamed:ACImageNameWhiteCamera] forState:UIControlStateNormal];
        else
            [self.photoButton setImage:[UIImage imageNamed:ACImageNameBlueCameraSelected] forState:UIControlStateNormal];
    } else {
        self.photoButton.hidden = YES;
    }
    
    [self taskTransListCreate];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshData) name:@"updateTaskTrans" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([needPhoto isEqualToString:@"1"]) {
        self.photoButton.hidden = NO;
        
        if (![FilesStorageWorker file:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] existsAtPath:[FilesStorageWorker taskImagesPath]]) {
            [self.photoButton setImage:[UIImage imageNamed:ACImageNameWhiteCamera] forState:UIControlStateNormal];
        } else {
            [self.photoButton setImage:[UIImage imageNamed:ACImageNameBlueCameraSelected] forState:UIControlStateNormal];
        }
    } else {
        self.photoButton.hidden = YES;
    }
}

- (void)refreshData{
    [self taskTransListCreate];
}

- (void)taskTransListCreate {
    self.taskTransArray = [NSMutableArray new];
    
    NSDateFormatter *mainDateFormatter = NSDateFormatter.new;
    mainDateFormatter.dateFormat = dateFormat_HH_mm_ss_dd_MM_YYYY;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = nil;
        
        NSString *squl;
        
        squl = @"select Result, TransDate, TransTime, Status, Source, Author, Comment from TaskTrans where CustAccount = ? and TaskId = ?";
        
        sql  = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
        {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *taskTransObject = [NSMutableDictionary new];
                
                NSString *resultStr = @"null";
                NSString *transDate = @"";
                NSString *transTime = @"";
                NSString *statusStr = @"null";
                NSString *sourceStr = @"";
                NSString *authorStr = @"";
                NSString *commentStr = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    resultStr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    transDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    transTime = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    statusStr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    sourceStr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    authorStr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    commentStr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                taskTransObject[@"result"] = resultStr;
                taskTransObject[@"transDate"] = transDate;
                taskTransObject[@"transTime"] = transTime;
                taskTransObject[@"status"] = statusStr;
                taskTransObject[@"source"] = sourceStr;
                taskTransObject[@"author"] = authorStr;
                taskTransObject[@"comment"] = commentStr;
                
                [self.taskTransArray addObject:taskTransObject];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    [self.taskTransArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSDate *date1 = [mainDateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", obj1[@"transTime"], obj1[@"transDate"]]];
        NSDate *date2 = [mainDateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", obj2[@"transTime"], obj2[@"transDate"]]];
        return [date2 compare: date1];
    }];
    
    [taskTransTable reloadData];
}

#pragma mark - Button Actions
- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addButtonPressed {
    DoTaskViewController *fvController = [[DoTaskViewController alloc] initWithNibName: @"DoTaskViewController" bundle: nil];
    
    fvController.isViewPushed = NO;
    
    fvController.custAccount  = custAccount;
    fvController.custName     = custName;
    fvController.taskId       = taskId;
    fvController.taskName     = taskName;
    fvController.status       = status;
    fvController.typeOfResult = typeOfResult;
    fvController.result       = result;
    fvController.dateEnd      = dateEnd;
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    infoNavController.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
    
    infoNavController.preferredContentSize = CGSizeMake(500.0, kDoTaskVCHeight);
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];
    
    infoNavController.view.superview.bounds = CGRectMake(0.0, 0.0, 500.0, kDoTaskVCHeight);
    
    fvController = nil;
    infoNavController = nil;
}

- (void)doneWithPhoto {
    [AlertWorkerObjc alertWithTitle:@"Смена статуса" message:@"По задаче рекомендуется сделать фото" buttons:@[@"Сделать фото", @"Готово без фото", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if ([action.title isEqualToString:@"Сделать фото"]) {
            [self photoButtonTapped:nil];
        } else if ([action.title isEqualToString:@"Готово без фото"]) {
            [self doneWithoutPhoto];
        }
    }];
}

- (void)doneWithoutPhoto {
    UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"Смена статуса"  message:@"Перевести задачу в статус Готово?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Причина";
        textField.keyboardType = UIKeyboardTypeDefault;
        [textField becomeFirstResponder];
    }];
    
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Готово" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self->doneReason = alertVC.textFields.firstObject.text;
        [self doneTask];
    }];
    [alertVC addAction:doneAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil];
    [alertVC addAction:cancelAction];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)doneTask {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    NSString        *strDate;
    NSString        *strTransTime;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    strDate = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    
    strTransTime = [dateFormatter stringFromDate:date];
    
    sqlite3_int64 lastTransRowId = sqlite3_last_insert_rowid(database);
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        const char *sql_2 = "update TaskTable Set Status = ?, Result = ?, TransDate = ?, isSended = ?, Image = ? where TaskId = ? and CustAccount = ?";
        
        sqlite3_stmt *updateStmt;
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &updateStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(updateStmt, 1, [@"Готово" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [[doneReason isEqualToString:@""]  ? @"Завершение задачи" : doneReason UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 4, 0);
            
            if ([needPhoto isEqualToString:@"1"]) {
                
                NSData *imgData = [FilesStorageWorker getFileWithName:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] atPath:[FilesStorageWorker taskImagesPath]];
                
                if (imgData)
                    sqlite3_bind_blob(updateStmt, 5, [imgData bytes], (int)[imgData length], NULL);
            }
            
            sqlite3_bind_text(updateStmt, 6, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 7, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_step(updateStmt);
            sqlite3_finalize(updateStmt);
        }
        
        static sqlite3_stmt *addStmt;
        
        const char *sql = "insert or ignore into TaskTrans (TaskId, CustAccount, TransDate, Result, TypeOfResult, Status, SendStatus, isSended, TransTime, Author, Source, Image) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [[doneReason isEqualToString:@""]  ? @"Завершение задачи" : doneReason UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [typeOfResult UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [@"Готово" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(addStmt, 8, 0);
        sqlite3_bind_text(addStmt, 9, [strTransTime UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 10, [LocalAuthWorker.emple UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 11, [@"АйПэд" UTF8String], -1, SQLITE_TRANSIENT);
        
        if ([needPhoto isEqualToString:@"1"]) {
            NSData *imgData = [FilesStorageWorker getFileWithName:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] atPath:[FilesStorageWorker taskImagesPath]];
            
            if (imgData)
                sqlite3_bind_blob(addStmt, 12, [imgData bytes], (int)[imgData length], NULL);
        }
        
        if (sqlite3_step(addStmt) != SQLITE_DONE) {
            NSLog(@"Commit Failed!");
        }
        
        sqlite3_finalize(addStmt);
        
        lastTransRowId = sqlite3_last_insert_rowid(database);
        
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"updateTasks" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    PutTasksRequest *sendTask = [[PutTasksRequest alloc] init];
    
    sendTask.notShowProgress = YES;
    sendTask.taskId          = taskId;
    sendTask.custAccount     = custAccount;
    sendTask.delegate        = self;
    sendTask.lastTransRowId  = lastTransRowId;
    
    [sendTask sendTask];
    
    [self refreshData];
}

- (void)cancelTask {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    NSString        *strDate;
    NSString        *strTransTime;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    strDate = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    
    strTransTime = [dateFormatter stringFromDate:date];
    
    sqlite3_int64 lastTransRowId = sqlite3_last_insert_rowid(database);
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        const char *sql_2 = "update TaskTable Set Status = ?, Result = ?, TransDate = ?, isSended = ?  where TaskId = ? and CustAccount = ?";
        
        sqlite3_stmt *updateStmt;
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &updateStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(updateStmt, 1, [@"Отказ" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 2, [cancelReason UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateStmt, 4, 0);
            sqlite3_bind_text(updateStmt, 5, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 6, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_step(updateStmt);
            sqlite3_finalize(updateStmt);
        }
        
        static sqlite3_stmt *addStmt;
        
        const char *sql = "insert or ignore into TaskTrans (TaskId, CustAccount, TransDate, Result, TypeOfResult, Status, SendStatus, isSended, TransTime, Author, Source) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [cancelReason UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [typeOfResult UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [@"Отказ" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(addStmt, 8, 0);
        sqlite3_bind_text(addStmt, 9, [strTransTime UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 10, [LocalAuthWorker.emple UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 11, [@"АйПэд" UTF8String], -1, SQLITE_TRANSIENT);
        
        
        if (sqlite3_step(addStmt) != SQLITE_DONE) {
            NSLog(@"Commit Failed!");
        }
        sqlite3_finalize(addStmt);
        
        lastTransRowId = sqlite3_last_insert_rowid(database);
        
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"updateTasks" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    PutTasksRequest *sendTask = [[PutTasksRequest alloc] init];
    
    sendTask.notShowProgress = YES;
    sendTask.taskId          = taskId;
    sendTask.custAccount     = custAccount;
    sendTask.delegate        = self;
    sendTask.lastTransRowId = lastTransRowId;
    
    
    [sendTask sendTask];
    
    [self refreshData];
}

- (void)refresh {
    [NSNotificationCenter.defaultCenter postNotificationName:@"updateTasks" object:nil];
    [self refreshData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.taskTransArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TaskTransTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([TaskTransTableViewCell class]) forIndexPath:indexPath];
    
    NSDictionary *object = self.taskTransArray[indexPath.row];
    
    cell.lblSource.text = object[@"source"];
    cell.lblAuthor.text = object[@"author"];
    cell.lblValue.text = object[@"result"];
    cell.lblStatus.text = object[@"status"];
    cell.lblDate.text = object[@"transDate"];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kTaskTransTableSectionHeaderViewHeight;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    TaskTransTableSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([TaskTransTableSectionHeaderView class])];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kTaskTransCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DoTaskViewController *fvController = [[DoTaskViewController alloc] initWithNibName: @"DoTaskViewController" bundle: nil];
    
    fvController.isViewPushed = NO;
    
    fvController.custAccount  = custAccount;
    fvController.custName     = custName;
    fvController.taskId       = taskId;
    fvController.taskName     = taskName;
    fvController.status       = status;
    fvController.typeOfResult = typeOfResult;
    fvController.result       = result;
    fvController.dateEnd      = dateEnd;
    fvController.taskTransData = self.taskTransArray[indexPath.row];
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    infoNavController.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
    
    infoNavController.preferredContentSize = CGSizeMake(500.0, kDoTaskVCHeight);
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];
    
    infoNavController.view.superview.bounds = CGRectMake(0.0, 0.0, 500.0, kDoTaskVCHeight);
    
    fvController = nil;
    infoNavController = nil;
}

- (IBAction)photoButtonTapped:(id)sender {
    CameraViewController *fvController = [[CameraViewController alloc] init];
    
    fvController.taskId      = taskId;
    fvController.fromTask    = YES;
    fvController.custAccount = custAccount;
    
    [self presentViewController:fvController animated:YES completion:nil];
    
    fvController = nil;
}

- (NSString *)getPhotoParm {
    NSString *parm = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = nil;
        
        sql = "select Photo from TaskTable where CustAccount = ? and TaskId = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                    parm  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return parm;
}

@end
