//
//  SetTaskToCustViewController.m
//  MLK
//
//  Created by garu on 12/12/14.
//
//

#import "SetTaskToCustViewController.h"
#import "PutTasksRequest.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@interface SetTaskToCustViewController ()
@property (nonatomic, weak) IBOutlet RWBorderedButton *btnTaskList;

@end

@implementation SetTaskToCustViewController;
@synthesize isViewPushed;
@synthesize custAcc, custNameStr, taskId, typeOfResult, result, dateEnd, dateStart;
@synthesize labelCustName, labelTaskEndDate, saveTask, taskName, status;
@synthesize taskSet, taskVisit, taskSource, from1C, photo;

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
    self.navigationItem.title = @"Назначение задачи";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    if (!isViewPushed) {
        RWBorderedButton *closeButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *closeBarButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        
        self.navigationItem.rightBarButtonItem = closeBarButton;
    }
}

#pragma mark - Button Actions
- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnListTapped:(UIButton *)sender {
    if (self.presentedViewController) { return; }
    
    TaskForCustView *taskForCustView = [TaskForCustView new];
    taskForCustView.delegate = self;
    taskForCustView.custAccount = custAcc;
    
    taskForCustView.modalPresentationStyle = UIModalPresentationPopover;
    taskForCustView.popoverPresentationController.sourceView = sender;
    
    [self presentViewController:taskForCustView animated:YES completion:nil];
}

- (IBAction)btnSaveTaskTapped:(id)sender {
    if (!taskId || [taskId isEqualToString:@""]) {
        [AlertWorkerObjc alertWithTitle:@"Выберите задачу"];
    } else {
        NSDate *date = NSDate.date;
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
        
        NSString *dateString = [dateFormat stringFromDate:date];
        
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
            
            const char *sql = "insert or ignore into TaskTable (TaskId, TaskName, DateStart, DateEnd, TypeOfResult, Result, CustAccount, Status, Source, TransDate, Setted, Visit, From1C, Photo, isSended) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [taskName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [dateString UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [self.labelTaskEndDate.text UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [typeOfResult UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [@"" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [@"Открытая" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 9, [taskSource UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 10,[strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 11,[taskSet UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 12,[taskVisit UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 13,[from1C UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 14,[photo UTF8String], -1, SQLITE_TRANSIENT);
            

            sqlite3_bind_int(addStmt, 15, 0);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
            
            static sqlite3_stmt *addStmt_2;
            
            const char *sql_2 = "insert or ignore into TaskTrans (TaskId, CustAccount, TransDate, Result, TypeOfResult, Status, SendStatus, isSended, TransTime, Author, Source) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql_2, -1, &addStmt_2, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt_2, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 4, [@"Новая запись" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 5, [typeOfResult UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 6, [@"Открытая" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 7, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(addStmt_2, 8, 0);
            sqlite3_bind_text(addStmt_2, 9, [strTransTime UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 10, [LocalAuthWorker.emple UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt_2, 11, [@"АйПэд" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt_2) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt_2);
            
            sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        }
        sqlite3_close(database);
        
        [NSNotificationCenter.defaultCenter postNotificationName:@"updateTasksNew" object:nil];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            PutTasksRequest *sendTask = [PutTasksRequest new];
            
            sendTask.notShowProgress = YES;
            sendTask.custAccount     = self->custAcc;
            sendTask.taskId          = self->taskId;
            sendTask.delegate        = self;
            sendTask.result          = @"Новая запись";
            
            [sendTask sendTask];
        });
    }
}

- (void)refresh{
    [NSNotificationCenter.defaultCenter postNotificationName:@"updateTasksNew" object:nil];
}

- (void)selectTask:(NSString *)taskNum taskName:(NSString *)taskN {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self.btnTaskList setTitle:taskN forState:UIControlStateNormal];
    
    taskId = taskNum;
    
    taskName = taskN;
    
    [self getTaskFields];
}

- (void)getTaskFields {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = nil;
        
        sql = "select DateStart, DateEnd, TypeOfResult, Source, Setted, Visit, From1C, Photo from TaskTable where TaskId = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                {
                    dateStart  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                }
                
                if (sqlite3_column_text(selectstmt, 1))
                {
                    dateEnd  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                    
                    self.labelTaskEndDate.text = dateEnd;
                }
                
                if (sqlite3_column_text(selectstmt, 2))
                {
                    typeOfResult  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                }
                
                if (sqlite3_column_text(selectstmt, 3))
                {
                    taskSource  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                }
                
                if (sqlite3_column_text(selectstmt, 4))
                {
                    taskSet  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                }
                
                if (sqlite3_column_text(selectstmt, 5))
                {
                    taskVisit  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                }
                
                if (sqlite3_column_text(selectstmt, 6))
                {
                    from1C  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                }
                
                if (sqlite3_column_text(selectstmt, 7))
                {
                    photo  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
}

@end

