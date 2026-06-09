//
//  TaskCreateViewController.m
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import "TaskCreateViewController.h"
#import "Base64Class.h"
#import "PutTasksRequest.h"
#import "RWBorderedButton.h"
#import "MLKBorderedTextField.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@interface TaskCreateViewController ()

@end

@implementation TaskCreateViewController
@synthesize isViewPushed;
@synthesize custAcc, custNameStr, taskId, typeOfResult, result, dateEnd, dateStart;
@synthesize labelCustName, labelTaskEndDate, textTypeField, saveTask, taskName, status;
@synthesize custListBtn;
@synthesize setDeliveryDateBtn;
@synthesize settingOldTask;
@synthesize taskSet, taskVisit, from1C;

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
    self.navigationItem.title = @"Новая задача";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    if (isViewPushed == NO) {
        RWBorderedButton *closeButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *closeBarButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        
        self.navigationItem.rightBarButtonItem = closeBarButton;
    }
    
    
    textTypeField = [[MLKBorderedTextField alloc] initWithFrame:CGRectMake(20.0, 135.0, 460.0, 60.0)];
    textTypeField.borderStyle = UITextBorderStyleRoundedRect;
    textTypeField.font = [UIFont systemFontOfSize:18];
    textTypeField.placeholder = @"Введите наименование задачи";
    textTypeField.autocorrectionType = UITextAutocorrectionTypeNo;
    textTypeField.keyboardType = UIKeyboardTypeDefault;
    textTypeField.returnKeyType = UIReturnKeyDone;
    textTypeField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textTypeField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textTypeField.delegate = self;
    textTypeField.text = @"";
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];
    textTypeField.leftView = paddingView;
    textTypeField.leftViewMode = UITextFieldViewModeAlways;
    
    if (settingOldTask) {
        textTypeField.text         = taskName;
        textTypeField.enabled      = NO;
        labelTaskEndDate.text      = dateEnd;
        setDeliveryDateBtn.enabled = NO;
    }
    
    [self.view addSubview:textTypeField];
    
    RWBorderedButton *btn = [RWBorderedButton buttonWithFrame:CGRectMake(20.0, 210.0, 460.0, 40.0) title:@"Выберите клиента"];
    UIButtonConfiguration *config = btn.configuration;
    config.contentInsets = NSDirectionalEdgeInsetsMake(0.0, 10.0, 0.0, 0.0);
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    [btn addTarget:self action:@selector(listBtn_pressed:) forControlEvents:UIControlEventTouchUpInside];
    
    custListBtn = btn;
    
    if (custAcc) {
        custListBtn.enabled = NO;
        [custListBtn setTitle:custNameStr forState:UIControlStateNormal];
    }
    
    [self.view addSubview:custListBtn];
    
    if (!settingOldTask) {
        taskId = NSUUID.UUID.UUIDString;
    }
}

- (void)listBtn_pressed:(id)sender {
    if (self.presentedViewController) { return; }
    
    CustForTaskView *custForTaskVC = [CustForTaskView new];
    custForTaskVC.delegate = self;
    custForTaskVC.taskId = taskId;
    
    custForTaskVC.modalPresentationStyle = UIModalPresentationPopover;
    custForTaskVC.popoverPresentationController.sourceView = custListBtn;
    custForTaskVC.popoverPresentationController.sourceRect = CGRectOffset(custListBtn.frame,-CGRectGetWidth(custListBtn.frame)/2,0);
    
    [self presentViewController:custForTaskVC animated:YES completion:nil];
}

- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveTaskPressed {
    if ([self.labelTaskEndDate.text isEqualToString:@"Дата"]) {
        [AlertWorkerObjc alertWithTitle:@"Укажите срок исполнения"];
    } else if ([textTypeField.text isEqualToString:@""]) {
        [AlertWorkerObjc alertWithTitle:@"Укажите наименование задачи"];
    } else if (!custAcc || [custAcc isEqualToString:@""]) {
        [AlertWorkerObjc alertWithTitle:@"Выберите клиента"];
    } else {
        NSDate *date = NSDate.date;
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
        
        NSString *dateString = [dateFormat stringFromDate:date];
        
        sqlite3_int64 lastTransRowId = sqlite3_last_insert_rowid(database);
        
        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
            NSDate          *date           = NSDate.date;
            NSString        *strDate;
            NSString        *strTransTime;
            
            [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
            
            strDate = [dateFormatter stringFromDate:date];
            
            [dateFormatter setDateFormat:@"HH:mm:ss"];
            
            strTransTime = [dateFormatter stringFromDate:date];
            
            char *sErrMsg;
            sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
            
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into TaskTable (TaskId, TaskName, DateStart, DateEnd, TypeOfResult, Result, CustAccount, Status, Source, TransDate, Setted, Visit, From1C, isSended) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            if (settingOldTask) {
                sqlite3_bind_text(addStmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 2, [taskName UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 3, [dateString UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 4, [self.labelTaskEndDate.text UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 5, [typeOfResult UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 6, [@"" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 7, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 8, [@"Открытая" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 9, [@"iPad" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 10,[strDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 11,[taskSet UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 12,[taskVisit UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 13,[from1C UTF8String], -1, SQLITE_TRANSIENT);
            } else {
                NSString *taskDate = [ASPFunctions changeDateFormatOfString:self.labelTaskEndDate.text];
                sqlite3_bind_text(addStmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 2, [textTypeField.text UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 3, [dateString UTF8String], -1, SQLITE_TRANSIENT);
                //                        sqlite3_bind_text(addStmt, 4, [self.labelTaskEndDate.text UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 4, [taskDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 5, [@"1" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 6, [@"" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 7, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 8, [@"Открытая" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 9, [@"iPad" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 10,[strDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 11,[@"1" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 12,[@"0" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 13,[@"0" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_int(addStmt, 14, 0);
            }
            
            sqlite3_bind_int(addStmt, 14,0);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
            
            static sqlite3_stmt *addStmt_2;
            
            const char *sql_2 = "insert or ignore into TaskTrans (TaskId, CustAccount, TransDate, Result, TypeOfResult, Status, isSended, TransTime, SendStatus, Author, Source) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql_2, -1, &addStmt_2, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt_2, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 4, [@"Новая запись" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (settingOldTask)
                sqlite3_bind_text(addStmt_2, 5, [typeOfResult UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(addStmt_2, 5, [@"1" UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_bind_text(addStmt_2, 6, [@"Открытая" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(addStmt_2, 7, 0);
            sqlite3_bind_text(addStmt_2, 8, [strTransTime UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 9, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 10, [LocalAuthWorker.emple UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 11, [@"АйПэд" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt_2) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt_2);
            
            lastTransRowId = sqlite3_last_insert_rowid(database);
            
            sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        }
        sqlite3_close(database);
        
        if (settingOldTask)
            [NSNotificationCenter.defaultCenter postNotificationName:@"updateCustTasksNew" object:nil];
        else
            [NSNotificationCenter.defaultCenter postNotificationName:@"updateTasksNew" object:nil];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            PutTasksRequest *sendTask = [PutTasksRequest new];
            
            sendTask.notShowProgress = YES;
            sendTask.custAccount     = self->custAcc;
            sendTask.taskId          = self->taskId;
            sendTask.delegate        = self;
            sendTask.lastTransRowId  = lastTransRowId;
            sendTask.result          = @"Новая запись";
            
            [sendTask sendTask];
        });
    }
}

- (void)refresh{
    if (settingOldTask) {
        [NSNotificationCenter.defaultCenter postNotificationName:@"updateCustTasksNew" object:nil];
    } else {
        [NSNotificationCenter.defaultCenter postNotificationName:@"updateTasksNew" object:nil];
    }
}

- (void)selectCustAcc:(NSString *)custAccount custName:(NSString *)custName {
    [custListBtn setTitle:custName forState:UIControlStateNormal];
    
    custAcc = custAccount;
    
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)btnSelectDateTapped:(id)sender {
    if (self.presentedViewController) { return; }
    
    ASPDatePickerViewController *datePickerVC = [ASPDatePickerViewController new];
    datePickerVC.delegate = self;
    datePickerVC.modalPresentationStyle = UIModalPresentationPopover;
    datePickerVC.popoverPresentationController.sourceView = sender;
    [self presentViewController:datePickerVC animated:YES completion:nil];
    [datePickerVC setMinimumDate:NSDate.date];
}

#pragma mark - ASPDatePickerViewControllerDelegate
- (void)datePickerDidCancel {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)datePickerDidPickDate:(NSDate *)date {
    [self datePickerDidCancel];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat_dd_MMM_YYYY];
    NSString *strDate = [formatter stringFromDate:date];
    self.labelTaskEndDate.text = strDate;
}

@end

