//
//  DNViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 13.11.12.
//
//

#import "DNViewController.h"
#import "PutListStatusDNRequest.h"

@interface DNViewController ()

@end

static sqlite3 *database = nil;

@implementation DNViewController

@synthesize isViewPushed;
@synthesize custAccount, custNameLbl, custName, brandId;
@synthesize dnGrid;
@synthesize merchBtn;
@synthesize statusListViewController;

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
    if (isViewPushed == NO) {
		UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStylePlain  target:self action:@selector(cancel_Clicked:)];
        
        barButton.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        
        self.navigationItem.rightBarButtonItem = barButton;
    }
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
    self.navigationItem.title = @"Статус DN";
    
    if (dnGrid == nil) {
		dnGrid = [[DNGrid alloc] init];
    }
    
    [dnLine setDataSource:dnGrid];
	[dnLine setDelegate:dnGrid];
    
    dnGrid.custAccount = custAccount;
    dnGrid.view        = dnGrid.tableView;
    
    self.dnGrid.delegate  = self;
    
    custNameLbl.text = custName;
}

- (void)gridIsUpdated {
    dnGrid.custAccount = custAccount;
    [dnGrid refreshData];
    
    [dnLine reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.custNameLbl = nil;
}

-(IBAction)sendData{
    [AlertWorkerObjc actionSheetWithTitle:nil message:nil sourceView:self.view buttons:@[@"Отправить данные", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            self->putDN = [PutListStatusDNRequest new];
            self->putDN.delegate = self;
            self->putDN.custAccount = self->custAccount;
            
            [self->putDN sendDN];
        }
    }];
}

-(IBAction)showDNActionSheet:(id)sender title:(NSString *)titleTxt custAccount:(NSString *)custAccountLoc brandId:(NSString *)_brandId {
    self.brandId = _brandId;
    [AlertWorkerObjc actionSheetWithTitle:nil message:nil sourceView:self.view buttons:@[@"Добавить комментарий", @"Изменить статус", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if ([action.title isEqual:@"Изменить статус"]) {
            [self showList];
        } else if ([action.title isEqual:@"Добавить комментарий"]) {
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Введите комментарий" message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.keyboardType = UIKeyboardTypePhonePad;
                [textField becomeFirstResponder];
            }];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self updateDNComment:alertVC.textFields.firstObject.text brandId:self->brandId];
            }];
            
            [alertVC addAction:okAction];
            
            [self presentViewController:alertVC animated:YES completion:nil];
        }
    }];
}

- (void)updateDNStatus:(NSString *)mngrStatus brandId:(NSString*)_brandId {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        const char *sql = "update DNTable Set MngrStatus = ?, SendStatus = 'Modified' where CustAccount = ? and BrandId = ?";
    
        sqlite3_stmt *updateStmt;
    
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [mngrStatus UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 3, [_brandId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        sqlite3_close(database);
        
        [self gridIsUpdated];
    } else
        sqlite3_close(database);
}

- (void)updateDNComment:(NSString *)comment brandId:(NSString*)_brandId {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        const char *sql = "update DNTable Set Comment = ?, SendStatus = 'Modified' where CustAccount = ? and BrandId = ?";
        
        sqlite3_stmt *updateStmt;
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [comment UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 3, [_brandId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        sqlite3_close(database);
        
        [self gridIsUpdated];
    } else
        sqlite3_close(database);
}

- (void)elementIsSelected:(NSString *)listElement {
    [self updateDNStatus:listElement brandId:brandId];
    
    if (statusListViewController.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        statusListViewController = nil;
    }
}

- (void)showList {
    if (!statusListViewController) {
        statusListViewController = [[StatusListViewController alloc] init];
        statusListViewController.delegate   = self;
        
        statusListViewController.modalPresentationStyle = UIModalPresentationPopover;
        statusListViewController.popoverPresentationController.sourceView = self.view;
        statusListViewController.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1);
        
        [self presentViewController:statusListViewController animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        statusListViewController = nil;
    }
}

- (void)isSended {
    [self gridIsUpdated];
}

@end
