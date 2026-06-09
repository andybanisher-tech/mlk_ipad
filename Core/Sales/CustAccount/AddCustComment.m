//
//  AddCustComment.m
//  MLK
//
//  Created by Rustem Galyamov on 04.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AddCustComment.h"
#import "PutCommentsRequest.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@implementation AddCustComment

@synthesize createButton, cancellButton, custAccount;
@synthesize comment, commentType;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    //NavBar Setup
    self.navigationItem.title = @"Создание комментария";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    comment.layer.borderColor = [UIColor blackColor].CGColor;
    comment.layer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    [self getCustComment];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)getCustComment {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        if ([commentType isEqualToString:@"merch"]) {
            const char *sql_2;
            
            sql_2 = "select Description from CustComment where CustAccount = ? and CommentType = ? and Date = ?";
            
            sqlite3_stmt *selstmt_2;
            
            if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selstmt_2, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(selstmt_2, 2, [commentType UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(selstmt_2, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(selstmt_2) == SQLITE_ROW)
                {
                    if (sqlite3_column_text(selstmt_2, 0))
                        comment.text  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                }
            }
            sqlite3_finalize(selstmt_2);
            sqlite3_close(database);
        }
    } else
        sqlite3_close(database);

}

-(IBAction)create {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    [timeFormatter setDateFormat:@"HH:mm:ss"];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    NSString *time = [timeFormatter stringFromDate:date];
    NSString *uuid = NSUUID.UUID.UUIDString;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        if ([commentType isEqualToString:@"merch"]) {
            const char *sql_2;
            
            sql_2 = "select Description from CustComment where CustAccount = ? and CommentType = ? and Date = ?";
            
            sqlite3_stmt *selstmt_2;
            
            if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selstmt_2, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(selstmt_2, 2, [commentType UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(selstmt_2, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(selstmt_2) == SQLITE_ROW)
                {
                    const char *sql_3 = "update CustComment Set Description = ?, SendStatus = ? where CustAccount = ? and CommentType = ? and Date = ?";
                    
                    sqlite3_stmt *updateStmt;
                    
                    if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK)
                    {
                        sqlite3_bind_text(updateStmt, 1, [comment.text UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(updateStmt, 2, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(updateStmt, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(updateStmt, 4, [commentType UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(updateStmt, 5, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                        
                        sqlite3_step(updateStmt);
                        sqlite3_finalize(updateStmt);
                        
                    }
                } else {
                    char *sErrMsg;
                    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
                    
                    sqlite3_stmt *addStmt;
                    
                    const char *sql = "insert or ignore into CustComment (CustAccount, CommentId, Description, UserId, Date, CommentType, SendStatus, Time, ForDelete) Values(?, ?, ?, ?, ?, ?, ?, ?, ?)";
                    
                    if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                        NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                    
                    sqlite3_bind_text(addStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(addStmt, 2, [uuid UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(addStmt, 3, [comment.text UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(addStmt, 4, [LocalAuthWorker.emple UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(addStmt, 5, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(addStmt, 6, [commentType UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(addStmt, 7, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(addStmt, 8, [time UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(addStmt, 9, [@"0" UTF8String], -1, SQLITE_TRANSIENT);
                    
                    sqlite3_step(addStmt);
                    sqlite3_finalize(addStmt);
                    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
                }
            }
            sqlite3_finalize(selstmt_2);
            sqlite3_close(database);
        } else {
            sqlite3_stmt *addStmt;
        
            const char *sql = "insert or ignore into CustComment (CustAccount, CommentId, Description, UserId, Date, CommentType, SendStatus, Time, ForDelete) Values(?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [uuid UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [comment.text UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [LocalAuthWorker.emple UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [commentType UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [time UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 9, [@"0" UTF8String], -1, SQLITE_TRANSIENT);
        
            sqlite3_step(addStmt);
            sqlite3_finalize(addStmt);
            sqlite3_close(database);
        }
    } else
        sqlite3_close(database);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self.delegate commentAdded];
    
    PutCommentsRequest *putComments = [PutCommentsRequest new];
    putComments.custAccount     = custAccount;
    putComments.commentId       = uuid;
    putComments.notShowProgress = YES;
    [putComments sendComments];
}

-(IBAction)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
