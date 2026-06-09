//
//  HomeViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "HomeViewController.h"
#import "GlobalSettingsView.h"
#import "GetCustTableRequest.h"
#import "NoticeViewController.h"
#import "PutVisitDateRequest.h"
#import "XMLWriter.h"
#import "PutOrdersNewRequest.h"
#import "PutTTPropertiesValueRequest.h"
#import "PutListStatusDNRequest.h"
#import "Base64Class.h"
#import "TPNameRequest.h"
#import "CheckVersionRequest.h"
#import "PutNewCustomerRequest.h"
#import "PutClientForRouteRequest.h"
#import "PutRouteToServerRequest.h"
#import "PutCommentsRequest.h"
#import "PutContactsRequest.h"
#import "PutTasksRequest.h"
#import "PutDreamStatusRequest.h"
#import "RWBorderedButton.h"
#import "SyncError.h"
#import "SyncStateWorker.h"

#import <MessageUI/MFMailComposeViewController.h>
#import "Reachability.h"
#import "PutContactsRequest.h"
#import "GetItemsRequest.h"

#import "ChooseManagersViewController.h"

#import "ASPPDFReaderViewController.h"
#import "FilesStorageWorker.h"

#import "AnalyticsWorker.h"

static sqlite3 *database = nil;

@interface HomeViewController () <MFMailComposeViewControllerDelegate, ChooseManagersViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *btnLogin;
@property (nonatomic, weak) IBOutlet UIButton *btnLogout;

@property (nonatomic, weak) IBOutlet UILabel *badgeLabel;

@end

@implementation HomeViewController

@synthesize showSyncProgress;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    [self checkAuth];
    
    //Notifications
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(checkAuth) name:@"UserAuthStateChanged" object:nil];
}

- (void)setNoticeCount:(NSInteger)noticeCount {
    if (noticeCount < 1) {
        self.badgeLabel.hidden = YES;
    } else {
        self.badgeLabel.hidden = NO;
        self.badgeLabel.text = noticeCount > 99 ? @"99+" : [NSString stringWithFormat:@"%ld", (long)noticeCount];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Button Actions
- (IBAction)btnLoginTapped:(id)sender {
    if (self.btnLogout.isHidden) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Авторизация" message:@"Код торгового представителя можно уточнить у специалиста технического отдела компании МЛК" preferredStyle:UIAlertControllerStyleAlert];
        
        [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            self->alertTextField = textField;
            self->alertTextField.placeholder = @"Код торгового представителя";
            self->alertTextField.delegate = self;
            self->alertTextField.keyboardType = UIKeyboardTypePhonePad;
#if DEBUG
            self->alertTextField.text = @"89857790405";
#endif
        }];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (self->alertTextField.text.length < 10) {
                [self btnLoginTapped:nil];
            } else {
                [PersistenceWorker save:self->alertTextField.text key:@"login"];
                
                self->alertTextField = nil;
                
                [self getFIO];
            }
        }];
        
        [alertVC addAction:okAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleDefault handler:nil];
        [alertVC addAction:cancelAction];
        
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

- (IBAction)btnLogoutTapped:(id)sender {
    [AlertWorkerObjc alertWithTitle:@"Выход" message:@"Изменить пользователя?" buttons:@[@"Да", @"Отменить"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            [self logoutUser];
        }
    }];
}

- (IBAction)showSettings {
    GlobalSettingsView *fvController = [[GlobalSettingsView alloc] initWithNibName: @"GlobalSettingsView" bundle: nil];
    
    fvController.isViewPushed = NO;
    //fvController.parentViewController.view = self.view;
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    infoNavController.preferredContentSize = CGSizeMake(540,275);
    [self presentViewController:infoNavController animated:YES completion:nil];
    
    fvController = nil;
    infoNavController = nil;
}

- (IBAction)showNotice {
    NoticeViewController *fvController = [[NoticeViewController alloc] initWithNibName: @"NoticeViewController" bundle: nil];
    
    fvController.isViewPushed = NO;
    //fvController.parentViewController.view = self.view;
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    infoNavController.preferredContentSize = CGSizeMake(540,375);
    [self presentViewController:infoNavController animated:YES completion:nil];
    
    fvController = nil;
    infoNavController = nil;
}

- (IBAction)btnSyncTapped:(UIButton *)sender {
    if (self.btnLogout.isHidden) {
        [self btnLoginTapped:nil];
    } else {
        [AlertWorkerObjc actionSheetWithTitle:@"Синхронизация" message:nil sourceView:sender buttons:@[@"Полная синхронизация", @"Обновить только остатки", @"Отмена"] isLastButtonCancel:YES permittedArrowDirections:UIPopoverArrowDirectionRight tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
            if (index == 0) {
                NSArray *iPadsArray = [PersistenceWorker load:@"iPadsArray"];
                if (iPadsArray.count > 0) {
                    ChooseManagersViewController *chooseManagersVC = [[UIStoryboard storyboardWithName:@"ChooseManagers" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(ChooseManagersViewController.class)];
                    chooseManagersVC.delegate = self;
                    chooseManagersVC.iPadsArray = iPadsArray;
                    chooseManagersVC.selectedIPadsSet = LocalAuthWorker.selectedIPadsSet.mutableCopy;
                    
                    chooseManagersVC.modalPresentationStyle = UIModalPresentationPopover;
                    chooseManagersVC.popoverPresentationController.sourceView = sender;
                    chooseManagersVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionRight;
                    
                    [self presentViewController:chooseManagersVC animated:YES completion:nil];
                } else {
                    [self syncAllData];
                }
            } else if (index == 1) {
                [self syncRemains];
            }
        }];
    }
}

- (IBAction)showMailCompose:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [MFMailComposeViewController new];
        
        NSString *body = [NSString stringWithFormat:@"\n\n\n\n-----\nС уважением,\n4й статус: %@\n", LocalAuthWorker.emple];
        
        controller.mailComposeDelegate = self;
        [controller setSubject:@"Ошибки/Пожелания по работе с приложением МЛК"];
        [controller setMessageBody:body isHTML:NO];
        [controller setToRecipients:@[@"texmlk@mirlk.ru"]];
        
        [self presentViewController:controller animated:YES completion:nil];
        
    } else {
        [SVProgressHUD showInfoWithStatus:@"Невозможно открыть почтовый клиент"];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    NSString *message;
    switch (result) {
        case MFMailComposeResultSent:
            message = @"Ваше сообщение отправлено";
            break;
        case MFMailComposeResultCancelled:
            message = nil;
            break;
        case MFMailComposeResultSaved:
            message = @"Ваше сообщение сохранено в черновики";
            break;
        case MFMailComposeResultFailed:
            message = @"Не удалось отправить сообщение";
            break;
            
        default:
            break;
    }
    
    if (message) {
        [SVProgressHUD showInfoWithStatus:message];
    }
}

#pragma mark - ChooseManagersViewControllerDelegate
- (void)userDidChooseManagers:(NSSet *)managers {
    [PersistenceWorker save:managers key:@"selectedIPadsSet"];
    [self dismissViewControllerAnimated:YES completion:^{
        [self syncAllData];
    }];
}

#pragma mark - Actions
- (void)getFIO{
    TPNameRequest *tpRequest = [TPNameRequest new];
    [tpRequest nameReq];
}

- (void)syncAllData {
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        [AlertWorkerObjc alertWithTitle:@"Отсутствует интернет соединение"];
    } else {
        [self runSync];
    }
}

- (void)syncRemains {
    GetItemsRequest *itemsRequest = [GetItemsRequest new];
    itemsRequest.isSingleRequest = YES;
    [itemsRequest itemsReq];
}

- (void)sendCustForRoute {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql;
        
        if (self.globalCustAccount)
            sql = "select CustAccount, DateOfRoute, IsDeleted from CustForRoute where isSended = ? and CustAccount = ?";
        else
            sql = "select CustAccount, DateOfRoute, IsDeleted from CustForRoute where isSended = ? ";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (self.globalCustAccount) {
                sqlite3_bind_int(selectstmt, 1, 0);
                sqlite3_bind_text(selectstmt, 2, [self.globalCustAccount UTF8String], -1, SQLITE_TRANSIENT);
            } else {
                sqlite3_bind_int(selectstmt, 1, 0);
            }
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAccount   = @"null";
                NSString *DateOfRoute      = @"null";
                NSInteger IsDeleted = 0;
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    DateOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_int(selectstmt, 2))
                    IsDeleted = sqlite3_column_int(selectstmt, 2);
                
                XMLWriter* xmlWriter = [[XMLWriter alloc] init];
                
                [xmlWriter writeStartElement:@"sam:Date"];
                [xmlWriter writeCharacters:DateOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                NSString *forDel_val = @"";
                
                if (IsDeleted==1) {
                    forDel_val = @"1";
                } else if (IsDeleted==0) {
                    forDel_val = @"0";
                }
                
                [xmlWriter writeStartElement:@"sam:ForDelete"];
                [xmlWriter writeCharacters:forDel_val];
                [xmlWriter writeEndElement];
                
                PutClientForRouteRequest *sendCustForRoute = [[PutClientForRouteRequest alloc] init];
                sendCustForRoute.notShowErrorMessage = YES;
                sendCustForRoute.notShowProgress = YES;
                
                [sendCustForRoute sendMsg:[xmlWriter toString]];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    [self sendRoute];
}

- (void)sendCustForRouteOnVisit {
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, DateOfRoute, RegularRoute, Status, GPSPoint, TimeOfRoute, GPSRequest from CustForRoute where isSended = ? and (Status = ? or Status = ? or Status = ?) order by TimeOfRoute ASC";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int(selectstmt, 1, 0);
            sqlite3_bind_text(selectstmt, 2, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 3, [@"visited" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 4, [@"" UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAccount   = @"null";
                NSString *DateOfRoute   = @"null";
                NSString *RegularRoute  = @"null";
                NSString *Status        = @"null";
                NSString *GPSPoint      = @"null";
                NSString *TimeOfRoute   = @"null";
                NSString *GPSRequest    = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    DateOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    RegularRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    Status  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    GPSPoint  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    TimeOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    GPSRequest = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                sqlite3_stmt *selectLineNum;
                const char *sqlLineNum = "select lineNum, Status from Route where CustAccount = ? and DateOfRoute = ? ";
                
                NSString *LineNumVisit = @"";
                NSString *LineNumTapped = @"";
                
                if (sqlite3_prepare_v2(database, sqlLineNum, -1, &selectLineNum, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selectLineNum, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selectLineNum, 2, [DateOfRoute UTF8String], -1, SQLITE_TRANSIENT);
                    while (sqlite3_step(selectLineNum) == SQLITE_ROW)
                    {
                        NSString *statusRoute = @"null";
                        
                        if (sqlite3_column_text(selectLineNum, 1))
                            statusRoute = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectLineNum, 1)];
                        
                        if ([statusRoute isEqualToString:@"visit"])
                        {
                            if (sqlite3_column_text(selectLineNum, 0))
                            {
                                LineNumVisit = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectLineNum, 0)];
                                NSLog(@"Line Num visit = %@",LineNumVisit);
                            }
                        }
                        else
                            if ([statusRoute isEqualToString:@"VISIT TAPPED"])
                            {
                                if (sqlite3_column_text(selectLineNum, 0))
                                {
                                    LineNumTapped = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectLineNum, 0)];
                                    NSLog(@"Line Num tapped = %@",LineNumTapped);
                                }
                            }
                        
                    }
                    sqlite3_finalize(selectLineNum);
                }
                [self sendRoutesByTapping:custAccount date:DateOfRoute time:TimeOfRoute GPSPoint:GPSPoint LineNumTapped:LineNumTapped];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:LineNum"];
                [xmlWriter writeCharacters:LineNumVisit];
                [xmlWriter writeEndElement];
                //NSLog(@"Line Num = %@",LineNum);
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:GPSPoint"];
                [xmlWriter writeCharacters:GPSPoint];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:DateOfRoute"];
                [xmlWriter writeCharacters:DateOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
                [xmlWriter writeCharacters:TimeOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:RegularRoute"];
                [xmlWriter writeCharacters:RegularRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Status"];
                [xmlWriter writeCharacters:Status];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ApprooveReq"];
                [xmlWriter writeCharacters:GPSRequest];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    NSString* xml = [xmlWriter toString];
    //NSLog(xml);
    
    PutRouteToServerRequest *setRouteToserver;
    setRouteToserver = [PutRouteToServerRequest new];
    
    [setRouteToserver sendRoute:xml];
    
    [self sendCustForRouteOnVisited];
}


- (void)sendRoutesByTapping:(NSString *)custAcc date:(NSString *)date time:(NSString *)time GPSPoint:(NSString *)GPSPoint LineNumTapped:(NSString *)LineNumTapped {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    [xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:LineNum"];
    [xmlWriter writeCharacters:LineNumTapped];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:CustAccount"];
    [xmlWriter writeCharacters:custAcc];
    [xmlWriter writeEndElement];
    
    
    [xmlWriter writeStartElement:@"sam:GPSPoint"];
    [xmlWriter writeCharacters:GPSPoint];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:DateOfRoute"];
    [xmlWriter writeCharacters:date];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
    [xmlWriter writeCharacters:time];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:RegularRoute"];
    [xmlWriter writeCharacters:@"YES"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Status"];
    [xmlWriter writeCharacters:@"VISIT TAPPED"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:ApprooveReq"];
    [xmlWriter writeCharacters:@""];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    // get the resulting XML string
    NSString *xml = [xmlWriter toString];
    
    PutRouteToServerRequest *setRouteToServer = [PutRouteToServerRequest new];
    [setRouteToServer sendRoute:xml];
}

- (void)sendCustForRouteOnVisited {
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, LastVisitDate from CustTable where isSended = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int(selectstmt, 1, 0);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *customer = @"null";
                NSString *lvd   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    customer  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    lvd  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:customer];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:LastVisitDate"];
                [xmlWriter writeCharacters:lvd];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    PutVisitDateRequest    *sendLVDToServer = [PutVisitDateRequest new];
    sendLVDToServer.notShowErrorMessage = YES;
    
    [sendLVDToServer sendLVD:xml];
    
    if (self.globalCustAccount) {
        [self sendTTPropertiesValue];
    } else {
        [self sendSalesToServer];
    }
}

- (void)sendContact {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql;
        
        if (self.globalCustAccount)
            sql = "select ContactId, Sname, Name, Mname, Birthday, Position, Phone, Email, ForDelete, Source, CustAccount, ContactId from CustContact where (Status = 'Error' or Status = 'New') and CustAccount = ?";
        else
            sql = "select ContactId, Sname, Name, Mname, Birthday, Position, Phone, Email, ForDelete, Source, CustAccount, ContactId from CustContact where (Status = 'Error' or Status = 'New')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (self.globalCustAccount)
                sqlite3_bind_text(selectstmt, 1, [self.globalCustAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *sname         = @"null";
                NSString *name          = @"null";
                NSString *mname         = @"null";
                NSString *birthday      = @"null";
                NSString *position      = @"null";
                NSString *phone         = @"null";
                NSString *email         = @"null";
                NSString *forDelete     = nil;
                NSString *source        = @"null";
                NSString *custAccount   = @"null";
                NSString *contactId     = @"null";
                
                if (sqlite3_column_text(selectstmt, 1))
                    sname = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    mname = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    birthday = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    position = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    phone = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    email = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (sqlite3_column_blob(selectstmt, 8))
                    forDelete = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                
                if (sqlite3_column_text(selectstmt, 9))
                    source = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                
                if (sqlite3_column_text(selectstmt, 10))
                    custAccount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                
                if (sqlite3_column_text(selectstmt, 11))
                    contactId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:Sname"];
                [xmlWriter writeCharacters:sname];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Name"];
                [xmlWriter writeCharacters:name];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Mname"];
                [xmlWriter writeCharacters:mname];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Birthday"];
                [xmlWriter writeCharacters:birthday];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Position"];
                [xmlWriter writeCharacters:position];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Phone"];
                [xmlWriter writeCharacters:phone];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Email"];
                [xmlWriter writeCharacters:email];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ForDelete"];
                [xmlWriter writeCharacters:forDelete];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Source"];
                [xmlWriter writeCharacters:source];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ContactId"];
                [xmlWriter writeCharacters:contactId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    PutContactsRequest *sendContact = [[PutContactsRequest alloc] init];
    
    if (showSyncProgress)
        sendContact.notShowProgress = NO;
    else
        sendContact.notShowProgress = YES;
    
    sendContact.notShowErrorMessage = YES;
    
    [sendContact sendMsg:[xmlWriter toString]];
}

- (void)sendTasks {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql;
        
        if (self.globalCustAccount)
            sql = "select TaskId, TaskName, DateEnd, TypeOfResult, Result, CustAccount, Status, Source, Image, Setted, Visit, From1C from TaskTable where isSended = ? and CustAccount = ?";
        else
            sql = "select TaskId, TaskName, DateEnd, TypeOfResult, Result, CustAccount, Status, Source, Image, Setted, Visit, From1C from TaskTable where isSended = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (self.globalCustAccount) {
                sqlite3_bind_int(selectstmt, 1, 0);
                sqlite3_bind_text(selectstmt, 2, [self.globalCustAccount UTF8String], -1, SQLITE_TRANSIENT);
            } else {
                sqlite3_bind_int(selectstmt, 1, 0);
            }
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *taskId       = @"null";
                NSString *taskName     = @"null";
                NSString *dateEnd      = @"null";
                NSString *typeOfResult = @"null";
                NSString *result       = @"null";
                NSString *custAcc      = @"null";
                NSString *status       = @"null";
                NSString *source       = @"null";
                NSData   *imgData      = nil;
                NSString *set          = @"null";
                NSString *visit        = @"null";
                NSString *from1C       = @"0";
                NSString *TransTime    = @"null";
                NSString *TransDate    = @"null";
                NSString *author       = @"";
                NSString *comment      = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    taskId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    taskName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    dateEnd = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    typeOfResult = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    custAcc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    source = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (sqlite3_column_blob(selectstmt, 8)) {
                    imgData = [FilesStorageWorker getFileWithName:[NSString stringWithFormat:@"%@_%@", taskId, custAcc] atPath:[FilesStorageWorker taskImagesPath]];
                }
                
                if (sqlite3_column_text(selectstmt, 9))
                    set = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                
                if (sqlite3_column_text(selectstmt, 10))
                    visit = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                
                if (sqlite3_column_text(selectstmt, 11))
                    from1C = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                
                sqlite3_stmt *selectTransStmt;
                
                const char *sqlTrans = "select Status, Result, TypeOfResult, TransTime, TransDate, Comment, Image from TaskTrans where isSended = ? and TaskId = ? and CustAccount = ?";
                
                if (sqlite3_prepare_v2(database, sqlTrans, -1, &selectTransStmt, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_int(selectTransStmt, 1, 0);
                    sqlite3_bind_text(selectTransStmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selectTransStmt, 3, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
                    
                    while (sqlite3_step(selectTransStmt) == SQLITE_ROW)
                    {
                        XMLWriter* xmlWriter = [[XMLWriter alloc] init];
                        
                        NSData   *imgDataTrans      = nil;
                        NSString *imageTrans        = @"null";
                        
                        if (sqlite3_column_text(selectTransStmt, 0))
                            status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 0)];
                        
                        if (sqlite3_column_text(selectTransStmt, 1))
                            result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 1)];
                        
                        if (sqlite3_column_text(selectTransStmt, 2))
                            typeOfResult = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 2)];
                        
                        if (sqlite3_column_text(selectTransStmt, 3))
                            TransTime = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 3)];
                        
                        if (sqlite3_column_text(selectTransStmt, 4))
                            TransDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 4)];
                        
                        if (sqlite3_column_text(selectTransStmt, 5))
                            comment = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectTransStmt, 5)];
                        
                        if (sqlite3_column_blob(selectTransStmt, 6))
                        {
                            imgDataTrans = [FilesStorageWorker getFileWithName:[NSString stringWithFormat:@"%@_%@", taskId, custAcc] atPath:[FilesStorageWorker taskImagesPath]];
                            
                            imageTrans = [Base64Class encode:imgData];
                        }
                        
                        NSLog(@"task name - %@",taskName);
                        NSLog(@"status - %@",status);
                        
                        [xmlWriter writeStartElement:@"sam1:Value"];
                        
                        [xmlWriter writeStartElement:@"sam1:TaskID"];
                        [xmlWriter writeCharacters:taskId];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:TaskName"];
                        [xmlWriter writeCharacters:taskName];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:DateStart"];
                        [xmlWriter writeCharacters:[NSString stringWithFormat:@"%@ %@", TransDate, TransTime]];//dateStart];
                        [xmlWriter writeEndElement];
                        
                        NSString *dateEndVal;
                        if (![status isEqualToString:@"Открытая"]) {
                            dateEndVal = [NSString stringWithFormat:@"%@ %@", TransDate, TransTime];
                        } else {
                            dateEndVal = [NSString stringWithFormat:@"%@ %@", dateEnd, TransTime];
                        }
                        
                        [xmlWriter writeStartElement:@"sam1:DateEnd"];
                        [xmlWriter writeCharacters:dateEndVal];
                        //[xmlWriter writeCharacters:dateEnd];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:TypeOfResult"];
                        [xmlWriter writeCharacters:typeOfResult];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Result"];
                        
                        if ([typeOfResult isEqualToString:@"5"])
                            [xmlWriter writeCharacters:imageTrans];
                        else
                            [xmlWriter writeCharacters:result];
                        
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:ClientCode"];
                        [xmlWriter writeCharacters:custAcc];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Status"];
                        [xmlWriter writeCharacters:status];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Source"];
                        [xmlWriter writeCharacters:source];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Set"];
                        [xmlWriter writeCharacters:set];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Visit"];
                        [xmlWriter writeCharacters:visit];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:From1C"];
                        [xmlWriter writeCharacters:from1C];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Photo"];
                        [xmlWriter writeCharacters:imageTrans];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Author"];
                        [xmlWriter writeCharacters:author];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam1:Comment"];
                        [xmlWriter writeCharacters:comment];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeEndElement];
                        
                        PutTasksRequest *sendTask   = [[PutTasksRequest alloc] init];
                        sendTask.custAccount = custAcc;
                        sendTask.taskId      = taskId;
                        
                        if (showSyncProgress)
                            sendTask.notShowProgress     = NO;
                        else
                            sendTask.notShowProgress     = YES;
                        
                        sendTask.notShowErrorMessage = YES;
                        
                        [sendTask sendMsg:[xmlWriter toString]];
                    }
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
}

- (void)sendCustStatusDN {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql;
        
        if (self.globalCustAccount)
            sql = "select CustAccount, StatusDN from CustStatusDN where isSended = ? and CustAccount = ?";
        else
            sql = "select CustAccount, StatusDN from CustStatusDN where isSended = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (self.globalCustAccount) {
                sqlite3_bind_int(selectstmt, 1, 0);
                sqlite3_bind_text(selectstmt, 2, [self.globalCustAccount UTF8String], -1, SQLITE_TRANSIENT);
            } else {
                sqlite3_bind_int(selectstmt, 1, 0);
            }
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *customer = @"null";
                NSString *status   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    customer  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    status  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:customer];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Dream"];
                [xmlWriter writeCharacters:status];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    PutDreamStatusRequest    *setDreamToServer = [PutDreamStatusRequest new];
    setDreamToServer.notShowErrorMessage = YES;
    
    [setDreamToServer sendDream:xml];
}

- (void)runSyncFromOtherView:(NSString *)custAccount {
    self.globalCustAccount = custAccount;
    
    [SyncStateWorker setErrorState:NO];
    
    [self sendCustStatusDN];
    
    [self sendTasks];
    
    [self sendContact];
    
    [self sendComments];
    
    [self sendCustForRoute];
}

- (void)runSync {
    [SyncStateWorker setErrorState:NO];
    
    [self sendCustStatusDN];
    [self sendTasks];
    [self sendContact];
    [self sendComments];
    [self sendCustForRoute];
    [self checkVersion];
    
    NSSet *selectedIPadsSet = LocalAuthWorker.selectedIPadsSet;
    if (selectedIPadsSet.count > 0 && ![selectedIPadsSet isEqualToSet:LocalAuthWorker.synchronizedIPadsSet]) {
        [self clearSQLTables];
    }
    
    GetCustTableRequest *custTableRequest = [GetCustTableRequest new];
    [custTableRequest requestCustTable];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *nonNumberSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    
    if (range.length == 1)
        return YES;
    else
    {
        if (textField.text.length > 10)
            return NO;
        
        if ([string intValue] < 0)
            return NO;
        
        return ([string stringByTrimmingCharactersInSet:nonNumberSet].length > 0);
    }
    return YES;
}

- (void)checkVersion {
    CheckVersionRequest *verReq = [CheckVersionRequest new];
    verReq.notShowProgress = YES;
    [verReq verReq];
}

- (void)sendRoute {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select DateOfRoute, lineNum, GPSPoint, TimeOfRoute, CustAccount, RegularRoute, Status, GPSRequest from Route where SendStatus = ? order by TimeOfRoute ASC";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *dateOfRoute   = @"null";
                NSString *lineNum       = @"null";
                NSString *GPSPoint      = @"null";
                NSString *timeOfRoute   = @"null";
                NSString *cAccount      = @"null";
                NSString *rRoute        = @"null";
                NSString *status        = @"null";
                NSString *apprReq       = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    dateOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    lineNum  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    GPSPoint  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    timeOfRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    cAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    rRoute  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    status  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    apprReq  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:LineNum"];
                [xmlWriter writeCharacters:lineNum];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:cAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:GPSPoint"];
                [xmlWriter writeCharacters:GPSPoint];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:DateOfRoute"];
                [xmlWriter writeCharacters:dateOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:TimeOfRoute"];
                [xmlWriter writeCharacters:timeOfRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:RegularRoute"];
                [xmlWriter writeCharacters:rRoute];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Status"];
                [xmlWriter writeCharacters:status];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ApprooveReq"];
                [xmlWriter writeCharacters:apprReq];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    PutRouteToServerRequest *setRouteToserver = [PutRouteToServerRequest new];
    setRouteToserver.routeType = @"track";
    [setRouteToserver sendRoute:xml];
    
    [self sendCustForRouteOnVisit];
}

- (void)sendSalesToServer {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select SalesDate, CustAccount, ContractId, AmountSum, ChannelTypeId, SalesStatus, Comment, SalesUUID, DeliveryDate, CreatedTime, ActionId, FirmId, SalesId, Merge from SalesTable where SalesStatus = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [@"Ошибка" UTF8String], -1, SQLITE_TRANSIENT);
            //sqlite3_bind_text(selectstmt, 2, [@"Ошибка" UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *salesDate;
                NSString *custAcc;
                NSString *contractId;
                NSString *amountSum;
                NSString *channelTypeId;
                NSString *salesStatus;
                NSString *comment;
                NSString *uuid;
                NSString *dlvDate;
                NSString *crTime;
                NSString *actionId;
                NSString *f_id;
                NSString *salesNumber;
                NSString *merge;
                
                if (!sqlite3_column_text(selectstmt, 0))
                    salesDate  = @"";
                else
                    salesDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (!sqlite3_column_text(selectstmt, 1))
                    custAcc  = @"";
                else
                    custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (!sqlite3_column_text(selectstmt, 2))
                    contractId  = @"";
                else
                    contractId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (!sqlite3_column_text(selectstmt, 3))
                    amountSum  = @"";
                else
                    amountSum  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (!sqlite3_column_text(selectstmt, 4))
                    channelTypeId  = @"";
                else
                    channelTypeId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (!sqlite3_column_text(selectstmt, 5))
                    salesStatus  = @"";
                else
                    salesStatus  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (!sqlite3_column_text(selectstmt, 6))
                    comment  = @"";
                else
                    comment  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (!sqlite3_column_text(selectstmt, 7))
                    uuid  = @"";
                else
                    uuid  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (!sqlite3_column_text(selectstmt, 8))
                    dlvDate  = @"";
                else
                    dlvDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                
                if (!sqlite3_column_text(selectstmt, 9))
                    crTime  = @"";
                else
                    crTime  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                
                if (!sqlite3_column_text(selectstmt, 10))
                    actionId  = @"";
                else
                    actionId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                
                if (!sqlite3_column_text(selectstmt, 11))
                    f_id  = @"";
                else
                    f_id  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                
                if (!sqlite3_column_text(selectstmt, 12))
                    salesNumber  = @"";
                else
                    salesNumber  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 12)];
                
                if (!sqlite3_column_text(selectstmt, 13))
                    merge  = @"0";
                else
                    merge  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 13)];
                
                
                XMLWriter* xmlWriter = [[XMLWriter alloc]init];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:SalesNum"];
                [xmlWriter writeCharacters:salesNumber];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:SalesDate"];
                [xmlWriter writeCharacters:salesDate];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAcc];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ContractID"];
                [xmlWriter writeCharacters:contractId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:AmountSum"];
                [xmlWriter writeCharacters:amountSum];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ChannelTypeID"];
                [xmlWriter writeCharacters:channelTypeId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:SalesStatus"];
                [xmlWriter writeCharacters:salesStatus];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Comment"];
                [xmlWriter writeCharacters:comment];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:SalesUUID"];
                [xmlWriter writeCharacters:uuid];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:DeliveryDate"];
                [xmlWriter writeCharacters:dlvDate];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CreatedTime"];
                [xmlWriter writeCharacters:crTime];
                [xmlWriter writeEndElement];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                NSDate *today = NSDate.date;
                [dateFormatter setDateFormat:@"HH:mm:ss"];
                NSString *sendTime = [dateFormatter stringFromDate:today];
                
                [self updateSalesTable:salesNumber sendTime:sendTime];
                
                [xmlWriter writeStartElement:@"sam:SendTime"];
                [xmlWriter writeCharacters:sendTime];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ActionID"];
                [xmlWriter writeCharacters:actionId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:FirmID"];
                [xmlWriter writeCharacters:f_id];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:NoMerge"];
                [xmlWriter writeCharacters:merge];
                [xmlWriter writeEndElement];
                
                const char *sql_1;
                
                sql_1 = "select ItemId, Qty, Price, LineAmount from SalesLine where SalesId = ?";
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selstmt, 1, [salesNumber UTF8String], -1, SQLITE_TRANSIENT);
                    
                    while (sqlite3_step(selstmt) == SQLITE_ROW)
                    {
                        NSString *itemId     = @"null";
                        NSString *qty        = @"null";
                        NSString *price      = @"null";
                        NSString *lineAmount = @"null";
                        
                        if (sqlite3_column_text(selstmt, 0))
                            itemId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                        
                        if (sqlite3_column_text(selstmt, 1))
                            qty  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 1)];
                        
                        if (sqlite3_column_text(selstmt, 2))
                            price  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 2)];
                        
                        if (sqlite3_column_text(selstmt, 3))
                            lineAmount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 3)];
                        
                        [xmlWriter writeStartElement:@"sam:SalesLines"];
                        
                        [xmlWriter writeStartElement:@"sam:ItemID"];
                        [xmlWriter writeCharacters:itemId];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam:Qty"];
                        [xmlWriter writeCharacters:qty];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam:Price"];
                        [xmlWriter writeCharacters:price];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam:LineAmount"];
                        [xmlWriter writeCharacters:lineAmount];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeEndElement];
                        
                        itemId      = nil;
                        qty         = nil;
                        price       = nil;
                        lineAmount  = nil;
                    }
                }
                sqlite3_finalize(selstmt);
                
                [xmlWriter writeEndElement];
                
                PutOrdersNewRequest *setSalesToServer = [PutOrdersNewRequest new];
                
                setSalesToServer.salesId = salesNumber;
                
                [setSalesToServer sendSales:[xmlWriter toString]];
                
                salesDate       = nil;
                custAcc         = nil;
                contractId      = nil;
                amountSum       = nil;
                channelTypeId   = nil;
                salesStatus     = nil;
                comment         = nil;
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self sendNewCustomer];
}

- (void)updateSalesTable:(NSString *)salesNum sendTime:(NSString*)sendTime {
    const char *sql_2 = "update SalesTable Set SendTime = ? where SalesId = ?";
    
    sqlite3_stmt *updateStmt;
    
    if (sqlite3_prepare_v2(database, sql_2, -1, &updateStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(updateStmt, 1, [sendTime UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [salesNum UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
}

- (void)sendTTPropertiesValue {
    BOOL sended = NO;
    
    PutTTPropertiesValueRequest *putTTPropValue = [PutTTPropertiesValueRequest new];
    putTTPropValue.withoutProgress = YES;
    
    XMLWriter* xmlWriter = [[XMLWriter alloc]init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql;
        
        if (self.globalCustAccount)
            sql = "select CreatedDateTime, PropertyId, Value, Image, ttId, CustAccount, ElementListId from TTPropertiesValue where (SendStatus = 'Error' or SendStatus = 'New') and CustAccount = ?";
        else
            sql = "select CreatedDateTime, PropertyId, Value, Image, ttId, CustAccount, ElementListId from TTPropertiesValue where (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (self.globalCustAccount)
                sqlite3_bind_text(selectstmt, 1, [self.globalCustAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSData   *imgData       = nil;
                NSString *date          = @"null";
                NSString *propertyId    = @"null";
                NSString *value         = @"null";
                NSString *image         = @"null";
                NSString *ttid          = @"null";
                NSString *custAccount   = @"null";
                NSString *imageSize     = @"null";
                NSString *elementListId = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    date  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    propertyId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    value  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_blob(selectstmt, 3))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 3) length:sqlite3_column_bytes(selectstmt, 3)];
                    
                    imageSize = [NSString stringWithFormat:@"%lu", (unsigned long)[imgData length]];
                    
                    image = [Base64Class encode:imgData];
                }
                
                if (sqlite3_column_text(selectstmt, 4))
                    ttid  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    custAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    elementListId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                

                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:Period"];
                [xmlWriter writeCharacters:date];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:TTID"];
                [xmlWriter writeCharacters:ttid];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyID"];
                [xmlWriter writeCharacters:propertyId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyValue"];
                [xmlWriter writeCharacters:value];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyValueID"];
                [xmlWriter writeCharacters:elementListId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Image"];
                [xmlWriter writeCharacters:image];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Size"];
                [xmlWriter writeCharacters:imageSize];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
                if (!self.globalCustAccount) {
                    putTTPropValue.custAccount = custAccount;
                    [putTTPropValue sendMsg:[xmlWriter toString]];
                    
                    sended = YES;
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);

    if (self.globalCustAccount) {
        putTTPropValue.custAccount = self.globalCustAccount;
        [putTTPropValue sendMsg:[xmlWriter toString]];
        
        sended = YES;
    }
    
    [self sendDN:sended];
    
}

- (void)sendNewCustomer {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, Name, FactAddress, Phone, Email, GPSPoint, Note, NewCustomer, SendStatus from CustTable where (SendStatus = 'Error' or SendStatus = 'new') and NewCustomer = 'yes'";
        //const char *sql = "select CustAccount, Name, FactAddress, Phone, Email, GPSPoint, Note, NewCustomer, SendStatus from CustTable where (SendStatus != 'null' and SendStatus != 'Sended') and NewCustomer = 'yes'";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAcc       = @"null";
                NSString *name          = @"null";
                NSString *factAddress   = @"null";
                NSString *phone         = @"null";
                NSString *email         = @"null";
                NSString *GPSPoint      = @"null";
                NSString *note          = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    name      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    factAddress          = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    phone      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    email  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    GPSPoint        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    note     = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                NSDate *date = NSDate.date;
                
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"dd.MM.yyyy HH:mm"];
                
                NSString *dateString = [dateFormat stringFromDate:date];
                
                XMLWriter* xmlWriter = [[XMLWriter alloc] init];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:Date"];
                [xmlWriter writeCharacters:dateString];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Name"];
                [xmlWriter writeCharacters:name];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:FactAddress"];
                [xmlWriter writeCharacters:factAddress];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Phone"];
                [xmlWriter writeCharacters:phone];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Email"];
                [xmlWriter writeCharacters:email];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Contact"];
                [xmlWriter writeCharacters:note];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Location"];
                [xmlWriter writeCharacters:GPSPoint];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Uid"];
                [xmlWriter writeCharacters:custAcc];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
                // get the resulting XML string
                NSString* xml = [xmlWriter toString];
                
                PutNewCustomerRequest    *sendNewCustomer = [PutNewCustomerRequest new];
                
                sendNewCustomer.custAccount = custAcc;
                
                [sendNewCustomer sendCustomer:xml];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self sendTTPropertiesValue];
}

- (void)sendGroupPropertiesValue {
    PutGroupPropertiesValueRequest *putGPropValue = [PutGroupPropertiesValueRequest new];
    putGPropValue.notShowProgress = YES;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql;
        if (self.globalCustAccount)
            sql = "select Date, GroupId, BrandId, PropertyId, Value, Image, CustAccount, ElementListId from PropertiesValue where (SendStatus = 'Error' or SendStatus = 'New') and CustAccount = ?";
        else
            sql = "select Date, GroupId, BrandId, PropertyId, Value, Image, CustAccount, ElementListId from PropertiesValue where (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (self.globalCustAccount)
                sqlite3_bind_text(selectstmt, 1, [self.globalCustAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSData   *imgData       = nil;
                NSString *date          = @"null";
                NSString *groupId       = @"null";
                NSString *brandId       = @"null";
                NSString *propertyId    = @"null";
                NSString *value         = @"null";
                NSString *image         = @"null";
                NSString *custAcc       = @"null";
                NSString *imageSize     = @"null";
                NSString *elementListId = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    date  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    groupId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    brandId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    propertyId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    value  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_blob(selectstmt, 5))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 5) length:sqlite3_column_bytes(selectstmt, 5)];
                    
                    imageSize = [NSString stringWithFormat:@"%lu", (unsigned long)[imgData length]];
                    
                    image = [Base64Class encode:imgData];
                }
                
                if (sqlite3_column_text(selectstmt, 6))
                    custAcc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    elementListId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                XMLWriter* xmlWriter = [[XMLWriter alloc]init];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:Period"];
                [xmlWriter writeCharacters:date];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:custAcc];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:GroupID"];
                [xmlWriter writeCharacters:groupId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:BrandID"];
                [xmlWriter writeCharacters:brandId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyID"];
                [xmlWriter writeCharacters:propertyId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyValue"];
                [xmlWriter writeCharacters:value];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyValueID"];
                [xmlWriter writeCharacters:elementListId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Image"];
                [xmlWriter writeCharacters:image];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Size"];
                [xmlWriter writeCharacters:imageSize];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
                putGPropValue.custAccount     = custAcc;
                putGPropValue.notShowProgress = YES;
                [putGPropValue sendMsg:[xmlWriter toString]];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
}

- (void)sendDN:(BOOL)sendedTTP {
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    PutListStatusDNRequest *putDN = [PutListStatusDNRequest new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql;
        
        if (self.globalCustAccount)
            sql = "select CustAccount, Name, BrandId, BrandName, Date, MngrStatus, Comment, SendStatus from DNTable where (SendStatus = 'Error' or SendStatus = 'Modified') and CustAccount = ?";
        else
            sql = "select CustAccount, Name, BrandId, BrandName, Date, MngrStatus, Comment, SendStatus from DNTable where (SendStatus = 'Error' or SendStatus = 'Modified')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (self.globalCustAccount)
                sqlite3_bind_text(selectstmt, 1, [self.globalCustAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAcc       = @"null";
                NSString *name          = @"null";
                NSString *brandId       = @"null";
                NSString *brandName     = @"null";
                NSString *month         = @"null";
                NSString *managerStatus = @"null";
                NSString *comment       = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    name      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    brandId          = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    brandName      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    month  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    managerStatus        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    comment     = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAcc];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Name"];
                [xmlWriter writeCharacters:name];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:BrandID"];
                [xmlWriter writeCharacters:brandId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:BrandName"];
                [xmlWriter writeCharacters:brandName];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Date"];
                [xmlWriter writeCharacters:month];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Status"];
                [xmlWriter writeCharacters:managerStatus];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Comment"];
                [xmlWriter writeCharacters:comment];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
                if (!self.globalCustAccount) {
                    putDN.custAccount = custAcc;
                    putDN.notShowProgress = YES;
                    
                    [putDN sendMsg:[xmlWriter toString]];
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);

    if (self.globalCustAccount) {
        putDN.custAccount = self.globalCustAccount;
        putDN.notShowProgress = YES;
        
        [putDN sendMsg:[xmlWriter toString]];
    }
    
    //if (sendedTTP ==  FALSE)
    [self sendGroupPropertiesValue];
    //else
    //[self sendComments];
}

- (void)sendComments {
    PutCommentsRequest *putComments = [PutCommentsRequest new];
    
    putComments.notShowProgress = YES;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql;
        
        if (self.globalCustAccount)
            sql = "select CustAccount, CommentId from CustComment where (SendStatus = 'Error' or SendStatus = 'New') and CustAccount = ?";
        else
            sql = "select CustAccount, CommentId from CustComment where (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (self.globalCustAccount)
                sqlite3_bind_text(selectstmt, 1, [self.globalCustAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAccount           = @"null";
                NSString *commentId             = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    commentId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                putComments.custAccount = custAccount;
                putComments.commentId   = commentId;
                putComments.notShowErrorMessage = YES;
                [putComments sendComments];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    //[self sendContacts];
}

- (void)sendContacts {
    PutContactsRequest *sendContact = [PutContactsRequest new];
    
    sendContact.notShowProgress = YES;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, ContactId from CustContacts where (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAccount           = @"null";
                NSString *contactId             = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    contactId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                sendContact.custAccount = custAccount;
                sendContact.contactId   = contactId;
                [sendContact sendContact];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
}


- (IBAction)openUserDoc:(id)sender {
    ASPPDFReaderViewController *pdfReaderVC = [[ASPPDFReaderViewController alloc] initWithPdfPath:[NSBundle.mainBundle pathForResource:@"МЛК" ofType:@"pdf"]];
    [self presentViewController:pdfReaderVC animated:YES completion:nil];
}

#pragma mark - Helpers
- (void)checkAuth {
    if ([LocalAuthWorker.login isEqualToString:@""]) {
        [self.btnLogin setTitle:@"Авторизация" forState: UIControlStateNormal];
        self.btnLogout.hidden = YES;
    } else {
        [self.btnLogin setTitle:LocalAuthWorker.emple forState: UIControlStateNormal];
        self.btnLogout.hidden = NO;
        
        [AnalyticsWorker configureAppMetricaIfNeeded];
    }
}

- (void)logoutUser {
    [PersistenceWorker logoutUser];
    
    [self clearSQLTables];
    [FilesStorageWorker removeDirectoryAtPath:[FilesStorageWorker taskImagesPath]];

    [SyncStateWorker setSynchronized:NO];
    [self checkAuth];
}

- (void)clearSQLTables {
    NSArray *tablesArray = [self fetchSQLTableNames];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        for (NSString *tableName in tablesArray) {
            sqlite3_exec(database, [[NSString stringWithFormat: @"delete from %@", tableName] UTF8String], NULL, NULL, NULL);
        }
    }
    sqlite3_close(database);
}

- (NSArray *)fetchSQLTableNames {
    NSMutableArray *tablesArray = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "SELECT name FROM sqlite_master WHERE type=\'table\'";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *tableName = [NSString stringWithCString:(const char *)sqlite3_column_text(selectstmt, 0) encoding:NSUTF8StringEncoding];
                [tablesArray addObject:tableName];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);

    return [NSArray arrayWithArray:tablesArray];
}

@end

