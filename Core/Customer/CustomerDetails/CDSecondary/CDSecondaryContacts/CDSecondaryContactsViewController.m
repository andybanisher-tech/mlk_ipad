//
//  CDSecondaryContactsViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 26.03.2025.
//

#import "CDSecondaryContactsViewController.h"

//VCs
#import "NewCustomerContactViewController.h"

//Cells
#import "CDSecondaryContactTableViewCell.h"

//Requests
#import "PutContactsRequest.h"

#import "GeneratedAssetSymbols.h"

#import "sqlite3.h"

//UI Constants
static const CGFloat kContactCellHeight = 200.0;

@interface CDSecondaryContactsViewController () <UITableViewDataSource, UITableViewDelegate, NewCustomerContactViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *mainTableView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

static sqlite3 *database = nil;

@implementation CDSecondaryContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self prepareDataSource];
    
    //Notifications
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(customerContactsDidUpdate) name:@"customerContactsUpdated" object:nil];
}

#pragma mark - UI
- (void)setupNavBar {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableArray *buttons = self.navigationItem.rightBarButtonItems.mutableCopy;
        UIBarButtonItem *addContactButton = [[UIBarButtonItem alloc] initWithTitle:@"+ Добавить контакт" style:UIBarButtonItemStylePlain target:self action:@selector(addContactButtonTapped)];
        [buttons addObject:addContactButton];
        self.navigationItem.rightBarButtonItems = buttons;
    });
}

#pragma mark - Button Actions
- (void)addContactButtonTapped {
    [self openAddContactVC:nil];
}

#pragma mark - Observers
- (void)customerContactsDidUpdate {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [self prepareDataSource];
}

#pragma mark - Prepare Data
- (void)prepareDataSource {
    self.dataSource = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select COALESCE(NULLIF(SName, ''), '---') AS SName, COALESCE(NULLIF(Name, ''), '---') AS Name, COALESCE(NULLIF(MName, ''), '---') AS MName, COALESCE(NULLIF(Phone, ''), '---') AS Phone, COALESCE(NULLIF(Email, ''), '---') AS Email, ContactId, Position, Source, ForDelete from CustContact where CustAccount = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            
            sqlite3_bind_text(selectstmt, 1, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *contact = [NSMutableDictionary new];
                
                for (int i = 0; i < sqlite3_column_count(selectstmt); i++) {
                    if (sqlite3_column_text(selectstmt, i)) {
                        NSString *key = [NSString stringWithUTF8String:(char *)sqlite3_column_name(selectstmt, i)];
                        NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, i)];
                        contact[key] = value;
                    }
                }
                
                [self.dataSource addObject:contact];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self.mainTableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDSecondaryContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(CDSecondaryContactTableViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.dataSource[indexPath.row];
    [cell setContact:object];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kContactCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *object = self.dataSource[indexPath.row];
    NSString *sName = object[@"SName"];
    NSString *name = object[@"Name"];
    NSString *mName = object[@"MName"];
    
    NSMutableDictionary *contact = [NSMutableDictionary new];
    contact[@"name"] = [@[sName, name, mName] componentsJoinedByString:@" "];
    contact[@"role"] = @{@"name" : object[@"Position"]};
    contact[@"phone"] = object[@"Phone"];
    contact[@"mail"] = object[@"Email"];
    contact[@"ContactId"] = object[@"ContactId"];
    contact[@"Source"] = object[@"Source"];
    
    [self openAddContactVC:contact];
}

#pragma mark - NewCustomerContactViewControllerDelegate
- (void)userDidAddContact:(NSDictionary *)contact {
    if ([self isContactValid:contact]) {
        [self createContact:contact];
    }
}

#pragma mark - Helpers
- (void)openAddContactVC:(NSDictionary *)contact {
    NewCustomerContactViewController *newCustomerContactVC = [[UIStoryboard storyboardWithName:@"NewCustomer" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(NewCustomerContactViewController.class)];
    newCustomerContactVC.delegate = self;
    newCustomerContactVC.contactData = contact.mutableCopy;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:newCustomerContactVC];
    
    [ASPFunctions setupNavigationController:navVC backgroundColor:[ASPFunctions colorFromHex:@"F2F2F7"] titleColor:[ASPFunctions colorFromHex:@"4F4F4F"] tintColor:[UIColor colorNamed:ACColorNameMLKLightBlue]];
    navVC.navigationBar.standardAppearance.shadowColor = UIColor.clearColor;
    navVC.navigationBar.scrollEdgeAppearance.shadowColor = UIColor.clearColor;
    
    [self presentViewController:navVC animated:YES completion:nil];
}

- (BOOL)isContactValid:(NSDictionary *)contact {
    NSString *errorMessage = @"";
    
    NSArray *nameComponents = [contact[@"name"] componentsSeparatedByString:@" "];
    if (nameComponents.count < 3) {
        errorMessage = [NSString stringWithFormat:@"%@%@", errorMessage, @"\n- ФИО"];
    } else {
        for (NSString *component in nameComponents) {
            if ([component stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0) { continue; }
            
            errorMessage = [NSString stringWithFormat:@"%@%@", errorMessage, @"\n- ФИО"];
            break;
        }
    }
    
    if ([contact[@"role"][@"name"] length] < 1) {
        errorMessage = [NSString stringWithFormat:@"%@%@", errorMessage, @"\n- Должность"];
    }
    
    if ([contact[@"phone"] length] < 11) {
        errorMessage = [NSString stringWithFormat:@"%@%@", errorMessage, @"\n- Телефон"];
    }

    if (![ASPFunctions isEmailValid:contact[@"mail"]]) {
        errorMessage = [NSString stringWithFormat:@"%@%@", errorMessage, @"\n- Email"];
    }
    
    if (errorMessage.length > 0) {
        [AlertWorkerObjc alertWithTitle:@"Следующие поля должны быть заполнены:" message:errorMessage];
    }
    
    return errorMessage.length < 1;
}

#pragma mark - Working with Data
- (void)createContact:(NSDictionary *)contact {
    NSString *uuid = contact[@"ContactId"] ? contact[@"ContactId"] : NSUUID.UUID.UUIDString;
    NSString *source = contact[@"Source"] ? contact[@"Source"] : LocalAuthWorker.login;
    
    NSArray *nameComponents = [contact[@"name"] componentsSeparatedByString:@" "];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *addStmt;
        
        NSString *sqlString;
        if (contact[@"ContactId"]) {
            sqlString = @"update CustContact Set SName = ?, Name = ?, MName = ?, Birthday = ?, Position = ?, Phone = ?, Email = ?, ForDelete = ?, Source = ? where CustAccount = ? and ContactId = ? ";
        } else {
            sqlString = @"insert or ignore into CustContact (SName, Name, MName, Birthday, Position, Phone, Email, ForDelete, Source,  CustAccount, ContactId) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        }
        
        const char *sql = sqlString.UTF8String;
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        }
        
        sqlite3_bind_text(addStmt, 1, [nameComponents[0] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [nameComponents[1] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [nameComponents[2] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, @"".UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [contact[@"role"][@"name"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [contact[@"phone"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [contact[@"mail"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 8, @"0".UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 9, source.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 10, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 11, uuid.UTF8String, -1, SQLITE_TRANSIENT);
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
    }
    sqlite3_close(database);
    
    PutContactsRequest *sendContact = [PutContactsRequest new];
    
    sendContact.custAccount = self.custAccount;
    sendContact.contactId = uuid;
    
    [sendContact sendContact];
}

@end
