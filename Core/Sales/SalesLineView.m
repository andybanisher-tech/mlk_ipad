//
//  SalesLineView.m
//  MLK
//
//  Created by Rustem Galyamov on 03.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SalesLineView.h"
#import "InvoiceInventView.h"
#import "AddSalesCommentView.h"
#import "RWBorderedButton.h"

#import "PresalesProductTableViewCell.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@interface SalesLineView ()
@property (nonatomic, weak) IBOutlet RWBorderedButton *btnSend;
@property (nonatomic, weak) IBOutlet UIButton *btnDate;

@property (nonatomic, strong) NSArray *storesArray;
@property (nonatomic, strong) NSDictionary *selectedStore;

@end

@implementation SalesLineView

@synthesize custName, qty, amount; 
@synthesize isViewPushed;
@synthesize customer, salesId, sumQty, sumAmount, num1C;
@synthesize salesLineGrid;
@synthesize isOpen;
@synthesize putItemsToSalesBtn;
@synthesize jurPerson, jurPersonBtn, jurPersonNameValue, jurPersonIdValue, firmViewController, jurPersonMarkupValue;
@synthesize addSalesCommentView, createCommentBtn, salesComment;
@synthesize salesDeliveryDate;
@synthesize merge;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    //NavBar Setup
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.navigationController.navigationBar.frame.size.width, 1.f / UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];
    [self.navigationController.navigationBar addSubview:titleView];
    
    self.navigationItem.title = [NSString stringWithFormat:@"Заказ № %@", num1C];
    
    NSString *zakaz = [PersistenceWorker load:@"zakaz"];
    
    if (![zakaz isEqualToString:@"1"])
        isOpen = NO;
    
    if (!isViewPushed) {
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];

        self.navigationItem.rightBarButtonItem  = barButton;
        closeBarButton = barButton;
    }

    CGFloat editButtonWidth = 130.f;
    self.custName.layer.borderColor = UIColor.lightGrayColor.CGColor;
    [self.custName setTextColor:UIColor.lightGrayColor];
    
    //Switch
    self.mergeSwitch.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.8];
    self.mergeSwitch.tintColor = UIColor.clearColor;
    self.mergeSwitch.layer.cornerRadius = self.mergeSwitch.bounds.size.height / 2.0;
    
    txtStoreField.delegate = self;
    
    self.storesArray = [PersistenceWorker load:@"storesArray"];    
    self.selectedStore = [self getSalesStore];
    
    if (!isOpen) {
        putItemsToSalesBtn.enabled = NO;
        jurPersonBtn.enabled       = NO;
        salesDeliveryDate.enabled  = NO;
        self.btnDate.enabled = NO;
        self.mergeSwitch.enabled = NO;
        self.mergeSwitch.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.4];
        
//        createCommentBtn.enabled = NO;
        editButtonWidth = 0.f;
        self.jurPerson.layer.borderColor = UIColor.lightGrayColor.CGColor;
        self.salesDeliveryDate.layer.borderColor = UIColor.lightGrayColor.CGColor;
        [self.jurPerson setTextColor:UIColor.lightGrayColor];
        [self.salesDeliveryDate setTextColor:UIColor.lightGrayColor];
    }

    if (salesLineGrid == nil) {
		salesLineGrid = [[SalesLineGrid alloc] init];
    }
    
    [salesLine setDataSource:salesLineGrid];
	[salesLine setDelegate:salesLineGrid];
    
    [salesLine registerNib:[UINib nibWithNibName: NSStringFromClass([PresalesProductTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([PresalesProductTableViewCell class])];
    
	salesLineGrid.salesId = salesId;
    salesLineGrid.isOpen  = isOpen;
    //salesLineGrid.view = salesLineGrid.tableView;
    
    self.salesLineGrid.delegate  = self;
    
    custName.text = customer;
    amount.text   = [salesLineGrid getSumAmount];
    qty.text      = [salesLineGrid getSumQty];
    
    salesDeliveryDate.text  = [self getSalesDlvDate];

    RWBorderedButton *editBtn = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,editButtonWidth,30) title:@"Изменить"];
    [editBtn addTarget:self
                action:@selector(setEditing)
      forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:editBtn];

    editButton = barButton;

    if ([qty.text doubleValue] != 0) {
        if (closeBarButton)
            self.navigationItem.rightBarButtonItems = @[closeBarButton, editButton];
        else
            self.navigationItem.rightBarButtonItems = @[editButton];
    } else if (isViewPushed == NO && closeBarButton) {
        self.navigationItem.rightBarButtonItems = @[closeBarButton];
        [self setEditing:NO];
    } else {
        self.navigationItem.rightBarButtonItems = nil;
        [self setEditing:NO];
    }
    
    [self getJurPersonDefault];
    [self getSalesComment];
    
    if ([[self getMerge] isEqualToString:@"0"]) {
        self.mergeSwitch.on = NO;

    } else {
        self.mergeSwitch.on = YES;
    }
}

- (void)setEditing {
    BOOL editing = !self.editing;
    [self setBarButton:editButton highlighted:editing];
    [super setEditing: editing animated: YES];
    [salesLine setEditing:editing animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (editing == YES)
        self.editButtonItem.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
    else
        self.editButtonItem.tintColor = UIColor.clearColor;
    
    [super setEditing: editing animated: animated];
    [salesLine setEditing:editing animated:animated];
}

- (void)gridIsUpdated {
    salesLineGrid.salesId = salesId;
    [salesLineGrid refreshData];
    
    amount.text   = [salesLineGrid getSumAmount];
    qty.text      = [salesLineGrid getSumQty];

    if ([salesLineGrid getCountLine] > 0) {
        if (closeBarButton)
            self.navigationItem.rightBarButtonItems = @[closeBarButton, editButton];
        else
            self.navigationItem.rightBarButtonItems = @[editButton];
    } else if (isViewPushed == NO && closeBarButton) {
        self.navigationItem.rightBarButtonItems =  @[closeBarButton];
        [self setEditing:FALSE];
    } else {
        self.navigationItem.rightBarButtonItems = nil;
        [self setEditing:FALSE];
    }

    [salesLine reloadData];
    txtStoreField.enabled = self.storesArray.count > 1 && [salesLineGrid getCountLine] < 1;
}

- (UITableView *)getTV{
    return salesLine;
}

- (IBAction)putItemsToSales {
    InvoiceInventView *fvController = [[InvoiceInventView alloc] init];
        
    fvController.isViewPushed     = NO;
    fvController.custAccount      = [self getCustAccount];
    fvController.custName         = customer;
    fvController.fromCreatedSales = YES;
    fvController.salesId          = salesId;
    fvController.firmMarkup       = jurPersonMarkupValue;
    fvController.selectedStore    = self.selectedStore;
        
    if (inventNavController == nil)
        inventNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
        
    inventNavController.modalPresentationStyle = UIModalPresentationFullScreen;
        
    [self presentViewController:inventNavController animated:YES completion:nil];

    fvController = nil;
    inventNavController = nil;
}

- (NSString *)getCustAccount {
    NSString *custAccount = @"null";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select CustAccount from SalesTable where SalesId = ?";
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                if (sqlite3_column_text(statement, 0))
                    custAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return custAccount;
}

- (NSDictionary *)getSalesStore {
    NSString *storeID;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select StoreID from SalesTable where SalesId = ?";
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                if (sqlite3_column_text(statement, 0))
                    storeID  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    NSUInteger searchIndex = [self.storesArray indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj[@"StoreID"] isEqual:storeID];
    }];
    
    if (searchIndex != NSNotFound) {
        return self.storesArray[searchIndex];
    }
    
    return self.storesArray.firstObject;
}

- (NSString *)getSalesDlvDate {
    NSString *deliveryDate = @"";
    NSString *salesDate = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select DeliveryDate, SalesDate from SalesTable where SalesId = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                    deliveryDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                if (sqlite3_column_text(selectstmt, 1))
                    salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);

    return deliveryDate.length > 0 ? deliveryDate : salesDate;
}

- (NSString *)getMerge {
    NSString *merge = @"0";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Merge from SalesTable where SalesId = ?";
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                if (sqlite3_column_text(statement, 0))
                    merge  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return merge;
}

- (void) cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.custName            = nil;
    self.amount              = nil;
    self.qty                 = nil;
    self.salesDeliveryDate   = nil;
    self.jurPerson           = nil;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self gridIsUpdated];

    salesLineGrid.sumAmount = [salesLineGrid getSumAmount];
    [salesLineGrid updateSalesTable];

    if (isOpen) {
        putItemsToSalesBtn.layer.borderWidth = 0.f/UIScreen.mainScreen.scale;
        putItemsToSalesBtn.backgroundColor = [ASPFunctions colorFromHex:@"00b4ff"];
        
        self.btnSend.layer.borderWidth = 0.f/UIScreen.mainScreen.scale;
        self.btnSend.backgroundColor = [ASPFunctions colorFromHex:@"00b4ff"];

        createCommentBtn.layer.borderWidth = 2.f/UIScreen.mainScreen.scale;
        putItemsToSalesBtn.layer.borderColor = UIColor.whiteColor.CGColor;
        createCommentBtn.layer.borderColor = UIColor.whiteColor.CGColor;
    }
}

- (void)getJurPersonDefault {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select FirmId, Name, Markup from FirmTable where Def = 1";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            sqlite3_bind_text(selectstmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                {
                    jurPersonIdValue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                }
                
                if (sqlite3_column_text(selectstmt, 1))
                {
                    jurPersonNameValue  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                }
                
                if (sqlite3_column_text(selectstmt, 2))
                {
                    jurPersonMarkupValue  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                }
            }
		}
        sqlite3_finalize(selectstmt);
	}
    sqlite3_close(database);
    
    jurPerson.text = jurPersonNameValue;
}

- (IBAction)selectJurPerson {
    if (!firmViewController) {
        firmViewController = [[FirmViewController alloc] init];
        firmViewController.delegate = self;
        firmViewController.modalPresentationStyle = UIModalPresentationPopover;
    }
    
    if (firmViewController.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        firmViewController = nil;
    } else {
        firmViewController.popoverPresentationController.sourceView = jurPersonBtn;
        [self presentViewController:firmViewController animated:YES completion:nil];
    }
}

- (void)selectFirm:(NSString *)firmId firmName:(NSString *)firmName firmMarkup:(NSString *)firmMarkup{
    jurPersonIdValue = firmId;

    jurPersonNameValue = firmName;

    jurPersonMarkupValue = firmMarkup;

    jurPerson.text = jurPersonNameValue;
    
    if (firmViewController.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        firmViewController = nil;
    }

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *updateStmt;

        const char *sql = "update SalesTable Set FirmId = ?, FirmName = ?, FirmMarkup = ? where SalesId = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [jurPersonIdValue UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [jurPersonNameValue UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 3, [jurPersonMarkupValue UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 4, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
    
    [self updateSalesLine];
}

- (void)commentAdded:(NSString *)comment {
    salesComment = comment;

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *updateStmt;
        
        const char *sql = "update SalesTable Set Comment = ? where SalesId = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [salesComment UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)setSalesStore {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *updateStmt;
        
        const char *sql = "update SalesTable Set StoreID = ? where SalesId = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [self.selectedStore[@"StoreID"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
}

- (void)setDlvDate {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *updateStmt;
        
        const char *sql = "update SalesTable Set DeliveryDate = ?, SalesDate = ? where SalesId = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [salesDeliveryDate.text UTF8String], -1, SQLITE_TRANSIENT);
        
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;
        
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        NSString *salesDate = [dateFormatter stringFromDate:date];

//        sqlite3_bind_text(updateStmt, 2, [salesDeliveryDate.text UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [salesDate UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 3, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (IBAction)createComment {
	AddSalesCommentView *fvController = [[AddSalesCommentView alloc] initWithNibName: @"AddSalesCommentView" bundle: nil];
    
    fvController.custAccount  = [self getCustAccount];
    fvController.salesComment = salesComment;
    fvController.delegate     = self;
    fvController.allowEditNo  = !isOpen;
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];

    fvController = nil;
    infoNavController = nil;
}

- (void)getSalesComment {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select Comment from SalesTable where SalesId = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            sqlite3_bind_text(selectstmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                {
                    salesComment  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                }
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
}

#pragma mark - Button Actions

- (IBAction)btnSendTapped:(id)sender {
    if (jurPerson.text.length < 1) {
        [AlertWorkerObjc alertWithTitle:@"Необходимо выбрать юр. лицо"];
    } else if (salesDeliveryDate.text.length < 1) {
        [AlertWorkerObjc alertWithTitle:@"Необходимо выбрать дату заказа"];
    } else {
        [AlertWorkerObjc alertWithTitle:nil message:nil buttons:@[@"Сохранить", @"Сохранить и отправить", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
            if (index == 0) {
                [self cancel_Clicked:nil];
            } else if (index == 1) {
                if ([self.delegate respondsToSelector:@selector(userDidSendSales:)]) {
                    [self.delegate userDidSendSales:self.salesId];
                }
            }
        }];
    }
}

- (IBAction)btnDateTapped:(id)sender {
    if (!self.datePickerVC) {
        self.datePickerVC = [ASPDatePickerViewController new];
        self.datePickerVC.delegate = self;
        self.datePickerVC.modalPresentationStyle = UIModalPresentationPopover;
    }
    
    if (!self.datePickerVC.presentingViewController) {
        self.datePickerVC.popoverPresentationController.sourceView = sender;
        [self presentViewController:self.datePickerVC animated:YES completion:nil];
        [self.datePickerVC setMinimumDate:NSDate.date];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - ASPDatePickerViewControllerDelegate
- (void)datePickerDidCancel {
    if (self.datePickerVC.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)datePickerDidPickDate:(NSDate *)date {
    [self datePickerDidCancel];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat_dd_MM_YYYY];
    NSString *strDate = [formatter stringFromDate:date];
    salesDeliveryDate.text = strDate;
    
    [self setDlvDate];
}

- (void)updateSalesLine {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        sql = "select ItemId, Qty, Price, Discount from SalesLine where SalesId = ?";
		
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
			sqlite3_bind_text(selectstmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *itemId            = @"null";
                NSString *lineQty           = @"null";
                NSString *discount          = @"null";
                NSString *lineAmountLocal   = @"null";
                NSString *price             = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    itemId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    lineQty  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    price  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    discount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                
                price      = [NSString stringWithFormat:@"%0.2lf", ([price doubleValue] - ([price doubleValue] * [jurPersonMarkupValue doubleValue]/100.0))];
                lineAmountLocal = [NSString stringWithFormat:@"%0.2lf", ((100.0 - [discount doubleValue])/100.0 * [price doubleValue] * [lineQty doubleValue])];
                
                [self updateSalesLineByFirm:itemId qty:lineQty lineAmount:lineAmountLocal price:price];
                
            }
        }
        sqlite3_finalize(selectstmt);
	}
    sqlite3_close(database);
    
    [self gridIsUpdated];
    
    amount.text   = [salesLineGrid getSumAmount];
    qty.text      = [salesLineGrid getSumQty];
}

- (void)updateSalesLineByFirm:(NSString *)itemId qty:(NSString *)newQty lineAmount:(NSString *)lineAmount price:(NSString *)price {
    static sqlite3_stmt *updateStmt;
    
    const char *sql = "update SalesLine Set Qty = ?, lineAmount = ?, Price = ? where SalesId = ? and ItemId = ?";
    
    sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
    
    sqlite3_bind_text(updateStmt, 1, [newQty UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateStmt, 2, [lineAmount UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateStmt, 3, [price UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_bind_text(updateStmt, 4, [salesId UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateStmt, 5, [itemId UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_step(updateStmt);
    sqlite3_finalize(updateStmt);
}

- (IBAction)mergeChange:(id)sender {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);

        static sqlite3_stmt *updateStmt;

        const char *sql = "update SalesTable Set Merge = ? where SalesId = ?";

        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);

        if (self.mergeSwitch.on == YES)
            sqlite3_bind_text(updateStmt, 1, [@"1" UTF8String], -1, SQLITE_TRANSIENT);
        else
            sqlite3_bind_text(updateStmt, 1, [@"0" UTF8String], -1, SQLITE_TRANSIENT);

        sqlite3_bind_text(updateStmt, 2, [salesId UTF8String], -1, SQLITE_TRANSIENT);

        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

#pragma mark - Store logic
- (void)setSelectedStore:(NSDictionary *)selectedStore {
    _selectedStore = selectedStore;
    txtStoreField.text = selectedStore[@"StoreName"];
    [self setSalesStore];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    NSMutableArray *buttonsArray = [NSMutableArray new];
    for (NSDictionary *store in self.storesArray) {
        [buttonsArray addObject: [NSString stringWithFormat:@"%@", store[@"StoreName"]]];
    }
    [buttonsArray addObject:@"Закрыть"];
    if (textField == txtStoreField) {
         [AlertWorkerObjc actionSheetWithTitle:@"Выберите склад" message:nil sourceView:textField buttons:buttonsArray tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
             if (index != buttonsArray.count - 1) {
                 self.selectedStore = self.storesArray[index];
             }
         }];
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - Button styling methods
- (void)setBarButton:(UIBarButtonItem *)button highlighted:(BOOL)highlighted {
    [(RWBorderedButton *)button.customView setHighlightedState:highlighted];
}

@end
