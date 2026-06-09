//
//  NoticeDescrViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 18.12.12.
//
//

#import "NoticeDescrViewController.h"
#import "RWBorderedButton.h"
#import "AppDelegate.h"
#import "HomeViewController.h"

@interface NoticeDescrViewController ()

@end

@implementation NoticeDescrViewController

static sqlite3 *database = nil;

@synthesize noticeId, noticeName, noticeDescription, isViewPushed, delegate, delBtn;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title       = noticeName;
    description.text = noticeDescription;

    if (isViewPushed == NO) {
        NSString *title = self.isNewNotice ? @"Готово" : @"Закрыть";
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:title];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        self.navigationItem.rightBarButtonItem = barButton;
    }

    delBtn.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cancel_Clicked:(id)sender {
    [self updateNotice:noticeId];
    [self.delegate gridIsUpdated];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)test {
    NSLog(@"Dismiss completed");
}

- (void)updateNotice:(NSString *)notId {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        const char *sql = "update NoticeTable Set Status = ? where ID = ?";
        
        sqlite3_stmt *updateStmt;
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [@"read" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [notId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        sqlite3_close(database);
        
    } else
        sqlite3_close(database);
    
    if ([self checkForNew] == NO)
        [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)deleteNotice:(id)sender {
    [AlertWorkerObjc alertWithTitle:@"Удаление сообщения" message:@"Вы уверены, что хотите удалить сообщение?" buttons:@[@"Да", @"Нет"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
                sqlite3_stmt *deleteStmt;
                
                const char *sql = "delete from NoticeTable where ID = ?";
                
                sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
                sqlite3_bind_text(deleteStmt, 1, [self->noticeId UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_step(deleteStmt);
                sqlite3_finalize(deleteStmt);
                sqlite3_close(database);
            }
            else
                sqlite3_close(database);
            
            [self.delegate gridIsUpdated];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

-(BOOL)checkForNew{
    BOOL haveNew = NO;

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select count(ID) from NoticeTable where Status = ?";
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [@"new" UTF8String], -1, SQLITE_TRANSIENT);

            if (sqlite3_step(statement) == SQLITE_ROW) {
//                haveNew = YES;
                int count = sqlite3_column_int(statement, 0);
                haveNew = count > 0;
                AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
                if (appDelegate)
                    [appDelegate.homeViewController setNoticeCount:count];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);

    return haveNew;
}


@end
