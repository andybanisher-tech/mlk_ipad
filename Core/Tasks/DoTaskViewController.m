//
//  DoTaskViewController.m
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import "DoTaskViewController.h"
#import "PutTasksRequest.h"
#import "CameraViewController.h"
#import "RWBorderedButton.h"

#import "FilesStorageWorker.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@interface DoTaskViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblTaskName;
@property (nonatomic, weak) IBOutlet UILabel *lblTaskAuthorAndDate;

@property (nonatomic, weak) IBOutlet UIButton *btnPhoto;

@property (nonatomic, weak) IBOutlet RWBorderedButton *btnChooseValue;

@property (nonatomic, weak) IBOutlet UITextView *txtResultView;

@property (nonatomic, weak) IBOutlet UIButton *statusButton;

@property (nonatomic, weak) IBOutlet RWBorderedButton *btnSaveTask;

@end

@implementation DoTaskViewController
@synthesize isViewPushed;
@synthesize custAccount, custName, taskId, typeOfResult, result, dateEnd;
@synthesize taskName, status, needPhoto;
@synthesize boolValue, boolValueBtn;
@synthesize taskListView;

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
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:[UIColor blackColor]];
    
    if (isViewPushed == NO) {
        UIImage *closeIconImage = [UIImage imageNamed:ACImageNameClose];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithImage:closeIconImage
                                                                      style:UIBarButtonItemStyleDone
                                                                     target:self
                                                                     action:@selector(cancel_Clicked:)];
        [barButton setTitleTextAttributes:@{NSFontAttributeName :[UIFont systemFontOfSize:24.f]} forState:UIControlStateNormal];
        barButton.tintColor = [ASPFunctions colorFromHex:@"606164"];
        
        self.navigationItem.rightBarButtonItem = barButton;
    }
    
    self.lblTaskName.text = custName;
    self.lblTaskAuthorAndDate.text = [NSString stringWithFormat:@"Срок исполнения: %@", dateEnd];
    
    self.btnPhoto.enabled = ![status isEqualToString:@"Готово"];
    self.btnChooseValue.enabled = ![status isEqualToString:@"Готово"];
    self.txtResultView.editable = ![status isEqualToString:@"Готово"];
    self.statusButton.enabled = ![status isEqualToString:@"Готово"];
    self.btnSaveTask.enabled = ![status isEqualToString:@"Готово"];
    
    if ([typeOfResult isEqualToString:@"1"]) {
        self.txtResultView.superview.hidden = NO;
        self.statusButton.superview.hidden = NO;
    }
    
    if ([typeOfResult isEqualToString:@"2"]) {
        self.btnChooseValue.hidden = NO;
        if (!result) {
            [self.btnChooseValue setTitle:@"Выберите значение" forState:UIControlStateNormal];
        } else {
            [self.btnChooseValue setTitle:[self getListName:result] forState:UIControlStateNormal];
        }
    }
    
    if ([typeOfResult isEqualToString:@"3"]) {
        self.txtResultView.superview.hidden = NO;
        self.txtResultView.keyboardType = UIKeyboardTypeNumberPad;
        self.txtResultView.text = result;
        
        self.statusButton.superview.hidden = NO;
    }
    
    needPhoto = [self getPhotoParm];
    
    if ([needPhoto isEqualToString:@"1"]) {
        self.btnPhoto.hidden = NO;
        
        if (![FilesStorageWorker file:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] existsAtPath:[FilesStorageWorker taskImagesPath]]) {
            [self.btnPhoto setImage:[UIImage imageNamed:ACImageNameWhiteCamera] forState:UIControlStateNormal];
        } else {
            [self.btnPhoto setImage:[UIImage imageNamed:ACImageNameBlueCameraSelected] forState:UIControlStateNormal];
        }
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshView) name:@"refreshAfterPhoto" object:nil];
    } else {
        self.btnPhoto.hidden = YES;
    }
    
    if (self.taskTransData) {
        self.lblTaskAuthorAndDate.text = [NSString stringWithFormat:@"Автор: %@\nДата действия: %@", self.taskTransData[@"author"], self.taskTransData[@"transDate"]];
        
        self.btnPhoto.enabled = NO;
        
        self.btnChooseValue.enabled = NO;
        
        self.txtResultView.text = self.taskTransData[@"result"];
        self.txtResultView.editable = NO;
        
        self.statusButton.enabled = NO;
        [self.statusButton setTitle:self.taskTransData[@"status"] forState:UIControlStateNormal];
        
        self.btnSaveTask.hidden = YES;
    } else {
        [self.statusButton setTitle:[self taskStatuses].firstObject forState:UIControlStateNormal];
    }
    
//    __weak typeof(self) weakSelf = self;
    NSMutableArray *actions = [NSMutableArray new];
    for (NSString *status in [self taskStatuses]) {
        UIAction *action = [UIAction actionWithTitle:status image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
        }];
        
        [actions addObject:action];
    }
    
    self.statusButton.menu = [UIMenu menuWithTitle:@"Статус для задачи:" children:actions];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([needPhoto isEqualToString:@"1"]) {
        self.btnPhoto.hidden = NO;
        
        if (![FilesStorageWorker file:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] existsAtPath:[FilesStorageWorker taskImagesPath]]) {
            [self.btnPhoto setImage:[UIImage imageNamed:ACImageNameWhiteCamera] forState:UIControlStateNormal];
        } else {
            [self.btnPhoto setImage:[UIImage imageNamed:ACImageNameBlueCameraSelected] forState:UIControlStateNormal];
        }
    } else {
        self.btnPhoto.hidden = YES;
    }
}

- (void)refreshView {
    //[photoBtn setTitle:[self getTaskResult] forState:UIControlStateNormal];
}

- (NSString *)getTaskResult {
    NSString *resultStr = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = nil;
        
        sql = "select Result from TaskTable where CustAccount = ? and TaskId = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                    resultStr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return resultStr;
}

-(NSString *)getPhotoParm {
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

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([typeOfResult isEqualToString:@"3"]) {
        return [string isEqualToString:@""] || [string isEqualToString:@"0"] || [string intValue];
    } else {
        return YES;
    }
}

#pragma mark - Button Actions
- (IBAction)btnPhotoTapped:(id)sender {
    CameraViewController *fvController = [[CameraViewController alloc] init];
    
    fvController.taskId      = taskId;
    fvController.fromTask    = YES;
    fvController.custAccount = custAccount;
    
    [self presentViewController:fvController animated:YES completion:nil];
    
    fvController = nil;
}

- (IBAction)btnChooseValueTapped:(UIButton *)sender {
    if (!taskListView) {
        taskListView              = [[TaskListView alloc] init];
        taskListView.delegate     = self;
        taskListView.taskId       = taskId;
        
        taskListView.modalPresentationStyle = UIModalPresentationPopover;
        taskListView.popoverPresentationController.sourceView = sender;
        
        [self presentViewController:taskListView animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        taskListView = nil;
    }
}

- (IBAction)boolBtn_pressed:(id)sender {
    if (boolValue) {
        boolValue = NO;
        [boolValueBtn setImage:[UIImage imageNamed:ACImageNameCheckmark] forState:UIControlStateNormal];
    } else {
        boolValue = YES;
        [boolValueBtn setImage:[UIImage imageNamed:ACImageNameCheckmarkSelected] forState:UIControlStateNormal];
    }
}

- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnSaveTaskTapped:(id)sender {
    if (!self.txtResultView.hidden && [self.txtResultView.text stringByReplacingOccurrencesOfString:@" " withString:@""].length < 1) {
        [AlertWorkerObjc alertWithTitle:@"Необходимо ввести значение"];
    } else {
        if ([typeOfResult isEqualToString:@"1"] || [typeOfResult isEqualToString:@"3"]) {
            result = self.txtResultView.text;
        }
        
        if ([typeOfResult isEqualToString:@"4"]) {
            if (boolValue) {
                result = @"1";
            } else {
                result = @"0";
            }
        }
        
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
                sqlite3_bind_text(updateStmt, 1, self.statusButton.currentTitle.UTF8String, -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 2, [result UTF8String], -1, SQLITE_TRANSIENT);
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
            
            const char *sql = "insert or ignore into TaskTrans (TaskId, CustAccount, TransDate, Result, TypeOfResult, Status, SendStatus, isSended, TransTime, Author, Comment, Source, Image) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            NSLog(@"test7");
            sqlite3_bind_text(addStmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            
            if ([typeOfResult isEqualToString:@"2"]) {
                const char *sql = "select LineDescription from TaskList where TaskId = ? and LineId = ?";
                
                sqlite3_stmt *selectstmt;
                
                if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selectstmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selectstmt, 2, [result UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selectstmt) == SQLITE_ROW)
                    {
                        if (sqlite3_column_text(selectstmt, 0))
                            sqlite3_bind_text(addStmt, 4, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)] UTF8String], -1, SQLITE_TRANSIENT);
                    }
                    sqlite3_step(selectstmt);
                    sqlite3_finalize(selectstmt);
                }
            }
            else
                if ([typeOfResult isEqualToString:@"4"])
                {
                    if (boolValue)
                        sqlite3_bind_text(addStmt, 4, [@"Да" UTF8String], -1, SQLITE_TRANSIENT);
                    else
                        sqlite3_bind_text(addStmt, 4, [@"Нет" UTF8String], -1, SQLITE_TRANSIENT);
                }
                else
                    sqlite3_bind_text(addStmt, 4, [result UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_bind_text(addStmt, 5, [typeOfResult UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, self.statusButton.currentTitle.UTF8String, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(addStmt, 8, 0);
            sqlite3_bind_text(addStmt, 9, [strTransTime UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 10, [LocalAuthWorker.emple UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 11, [@"" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 12, [@"АйПэд" UTF8String], -1, SQLITE_TRANSIENT);
            
            if ([needPhoto isEqualToString:@"1"]) {
                NSData *imgData = [FilesStorageWorker getFileWithName:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] atPath:[FilesStorageWorker taskImagesPath]];
                
                if (imgData) {
                    sqlite3_bind_blob(addStmt, 13, [imgData bytes], (int)[imgData length], NULL);
                }
                if ([result stringByReplacingOccurrencesOfString:@" " withString:@""].length < 1) {
                    sqlite3_bind_text(addStmt, 4, [@"Фото" UTF8String], -1, SQLITE_TRANSIENT);
                }
                
            }
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
            
            lastTransRowId = sqlite3_last_insert_rowid(database);
            
            sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
            
        }
        sqlite3_close(database);
        
        [self refresh];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        PutTasksRequest *sendTask = [[PutTasksRequest alloc] init];
        
        sendTask.notShowProgress = YES;
        sendTask.taskId          = taskId;
        sendTask.custAccount     = custAccount;
        sendTask.delegate        = self;
        sendTask.lastTransRowId  = lastTransRowId;
        
        [sendTask sendTask];
        
        [FilesStorageWorker removeFileWithName:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] atPath:[FilesStorageWorker taskImagesPath]];
        [NSNotificationCenter.defaultCenter postNotificationName:@"refreshAfterPhoto" object:nil];
    }
}

- (void)refresh {
    [NSNotificationCenter.defaultCenter postNotificationName:@"updateTasks" object:nil];
    [NSNotificationCenter.defaultCenter postNotificationName:@"updateTaskTrans" object:nil];
}

- (void)selectListId:(NSString *)listId listName:(NSString *)listName {
    [self.btnChooseValue setTitle:listName forState:UIControlStateNormal];
    result = listId;
    
    if (taskListView.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        taskListView = nil;
    }
}

-(NSString *)getListName:(NSString *)listId {
    NSString *name = @"Выбрать из списка";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select LineDescription from TaskList where TaskId = ? and LineId = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [listId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                    name  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    return name;
}

#pragma mark - ConstData
- (NSArray *)taskStatuses {
    return @[@"В работе", @"Готово", @"Отказ"];
}

@end
