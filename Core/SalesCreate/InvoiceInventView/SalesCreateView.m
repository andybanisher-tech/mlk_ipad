//
//  SalesCreateView.m
//  MLK
//
//  Created by Rustem Galyamov on 15.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "SalesCreateView.h"
#import "PreSalesGrid.h"
#import "InvoiceInventView.h"
#import "SelectCustAcc.h"
#import "PrepareSales.h"
#import "InvoiceGrid.h"
#import "AddSalesCommentView.h"
#import "RWBorderedButton.h"
#import "SyncStateWorker.h"

#import "PresalesProductTableViewCell.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@interface SalesCreateView ()
@property (nonatomic, weak) IBOutlet UILabel *availableLabel;

@property (nonatomic, strong) NSArray *storesArray;

@property (nonatomic, copy) NSString *salesLineTable;

@end

@implementation SalesCreateView

@synthesize isViewPushed;
@synthesize labelCust;
@synthesize preSalesGrid;
@synthesize custAccount;
@synthesize custName;
@synthesize labelQtyTotal;
@synthesize labelSumTotal;
@synthesize qtyTotal,sumTotal;
@synthesize putItemsToSalesBtn;
@synthesize selectCustAccount;
@synthesize selectCustAcc;
@synthesize createSale;
@synthesize viewPreInvoice;
@synthesize salesId;
@synthesize addSalesCommentView, createCommentBtn, salesComment, actionBtn;
@synthesize salesDeliveryDate;
@synthesize dontInclCheckQty, dontInclCheckAmount;
@synthesize brand;
@synthesize jurPerson, jurPersonBtn, jurPersonNameValue, jurPersonIdValue, firmViewController, jurPersonMarkupValue, labelMarkup;
@synthesize merge;

- (void)custIsSelected:(NSString *)custAcc custName:(NSString *)custN {
    custAccount = custAcc;
    
    custName    = custN;
    
    if (jurPersonIdValue == nil)
        [self getJurPersonDefault];
}

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *zakaz = [PersistenceWorker load:@"zakaz"];
    self.view.userInteractionEnabled = [zakaz isEqualToString:@"1"];
    
    if (custName) {
        labelCust.text = custName;
    }
    
    if ([preSalesGrid getCountLine] > 0) {
        if (closeBarButton) {
            self.navigationItem.rightBarButtonItems = @[closeBarButton, editButton];
        } else {
            self.navigationItem.rightBarButtonItems = @[editButton];
        }
    } else if (!isViewPushed && closeBarButton) {
        self.navigationItem.rightBarButtonItems = @[closeBarButton];
        [self setEditing:NO];
    } else {
        self.navigationItem.rightBarButtonItems = nil;
        [self setEditing:NO];
    }
    
    if (isViewPushed) {
        preSalesTable.contentInset = UIEdgeInsetsMake(0,0,60,0);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    preSalesGrid.custAccount = custAccount;
    [preSalesGrid refreshData];
    [self reloadData];
    
    labelSumTotal.text = [preSalesGrid getSumAmount];
    labelQtyTotal.text = [preSalesGrid getSumQty];
    
    if (custAccount) {
        if ([[self getActionType:custAccount] isEqualToString:@"1"]) {
            actionBtn.enabled  = NO;
            putItemsToSalesBtn.enabled = NO;
        } else if ([[self getActionType:custAccount] isEqualToString:@"2"]) {
            actionBtn.enabled  = NO;
            putItemsToSalesBtn.enabled = YES;
        } else if ([[self getActionType:custAccount] isEqualToString:@"3"]) {
            actionBtn.enabled  = NO;
            putItemsToSalesBtn.enabled = YES;
        } else if ([labelQtyTotal.text doubleValue] != 0 || [labelSumTotal.text doubleValue] != 0) {
            actionBtn.enabled  = NO;
            putItemsToSalesBtn.enabled = YES;
        } else {
            actionBtn.enabled  = YES;
            putItemsToSalesBtn.enabled = YES;
        }
        
        
        if ([[self getActionType:custAccount] isEqualToString:@"0"]) {
            if ([labelQtyTotal.text doubleValue] > 0) {
                createSale.enabled = YES;
            } else {
                createSale.enabled = NO;
            }
        } else if (![[self getActionType:custAccount] isEqualToString:@"1"]) {
            [preSalesGrid fillCheckParms];
            [self setDontChekParms:custAccount type:@"3"];
            
            if ([[preSalesGrid getCheckedAmount] doubleValue] == 0 & [[preSalesGrid getCheckedQty] doubleValue] == 0) {
                createSale.enabled = YES;
            } else {
                if ([[preSalesGrid getCheckedAmount] doubleValue] == 0 & [[preSalesGrid getCheckedQty] doubleValue] != 0) {
                    if (([[self getActionQty:custAccount type:[self getActionType:custAccount]] doubleValue]) > ([labelQtyTotal.text doubleValue] - [dontInclCheckQty doubleValue])) {
                        createSale.enabled = NO;
                    } else {
                        createSale.enabled = YES;
                    }
                } else if ([[preSalesGrid getCheckedAmount] doubleValue] != 0 & [[preSalesGrid getCheckedQty] doubleValue] == 0) {
                    if (([[self getActionSum:custAccount type:[self getActionType:custAccount]] doubleValue]) > ([labelSumTotal.text doubleValue] - [dontInclCheckAmount doubleValue])) {
                        createSale.enabled = NO;
                    } else {
                        createSale.enabled = YES;
                    }
                } else if ([[preSalesGrid getCheckedAmount] doubleValue] != 0 & [[preSalesGrid getCheckedQty] doubleValue] != 0) {
                    if (([[self getActionSum:custAccount type:[self getActionType:custAccount]] doubleValue]) > ([labelSumTotal.text doubleValue] - [dontInclCheckAmount doubleValue])) {
                        createSale.enabled = NO;
                    } else if (([[self getActionQty:custAccount type:[self getActionType:custAccount]] doubleValue]) > ([labelQtyTotal.text doubleValue] - [dontInclCheckQty doubleValue])) {
                        createSale.enabled = NO;
                    } else {
                        createSale.enabled = YES;
                    }
                }
            }
        } else if ([[self getActionType:custAccount] isEqualToString:@"1"]) {
            [preSalesGrid fillCheckParms];
            
            if ([[preSalesGrid getCheckedQty] doubleValue] != 0)  {
                if ([[preSalesGrid getCheckedQty] doubleValue] > [labelQtyTotal.text doubleValue]) {
                    createSale.enabled = NO;
                } else {
                    createSale.enabled = YES;
                }
            }
        }
    }
    
    [self updateFormState];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    
    UIColor *barColor;
    if (self.isConsult) {
        self.availableLabel.hidden = YES;
        self.salesLineTable = @"tmpConsultSalesLine";
        barColor = [UIColor colorNamed:ACColorNameMLKBlue];
    } else {
        self.salesLineTable = @"tmpSalesLine";
        barColor = [UIColor colorNamed:ACColorNameGrayNavBarBackground];
    }
    
    //NavBar Setup
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:barColor titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    self.navigationController.navigationBar.barStyle = 1;
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width,1.f/UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];
    
    [self.navigationController.navigationBar addSubview:titleView];
    
    //Notifications
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(prepareStores) name:kSyncStateChanged object:nil];
    
    // Do any additional setup after loading the view from its nib.
    if (preSalesGrid == nil) {
        preSalesGrid = [[PreSalesGrid alloc] init];
        preSalesGrid.isConsult = self.isConsult;
    }
    
    [preSalesTable setDataSource:preSalesGrid];
    [preSalesTable setDelegate:preSalesGrid];
    
    [preSalesTable registerNib:[UINib nibWithNibName: NSStringFromClass([PresalesProductTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([PresalesProductTableViewCell class])];
    
    preSalesGrid.view = preSalesGrid.tableView;
    
    self.preSalesGrid.delegate  = self;
    
    //if (custName)
    //    labelCust.text = custName;
    
    
    if (isViewPushed == NO) {
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        
        self.navigationItem.rightBarButtonItem  = barButton;
        // Andrey self.navigationItem.rightBarButtonItem = barButton;
        closeBarButton = barButton;
        selectCustAccount.enabled = NO;
    }
    
    if (custName) {
        NSString *title;
        if (self.isConsult) {
            title = @"Консультация";
            [createSale setTitle:@"Завершить" forState:UIControlStateNormal];
        } else {
            title = [NSString stringWithFormat:@"Создание заказа для %@", custName];
        }
        self.navigationItem.title = title;
        
        [self getJurPersonDefault];
    } else {
        self.navigationItem.title = [NSString stringWithFormat:@"Создание заказа"];
    }
    [self updateFormState];
    RWBorderedButton *editBtn = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,130,30) title:@"Изменить"];
    [editBtn addTarget:self
                action:@selector(setEditing)
      forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:editBtn];
    
    editButton = barButton;
    
    if ([labelQtyTotal.text doubleValue] != 0) {
        self.navigationItem.rightBarButtonItems = @[closeBarButton, editButton];
    } else if (isViewPushed == NO) {
        self.navigationItem.rightBarButtonItems =  @[closeBarButton];
        [self setEditing:NO];
    } else {
        self.navigationItem.rightBarButtonItems = nil;
        [self setEditing:NO];
    }
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    salesDeliveryDate.text = [dateFormatter stringFromDate:date];
    
    //Switch
    self.mergeSwitch.on = merge;
    self.mergeSwitch.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.8];
    self.mergeSwitch.tintColor = UIColor.clearColor;
    self.mergeSwitch.layer.cornerRadius = self.mergeSwitch.bounds.size.height / 2.0;
    
    txtStoreField.delegate = self;
    
    [self prepareStores];
    
    createSale.enabled = NO;
}

- (void)updateFormState {
    if (!custName) {
        self.labelCust.backgroundColor = [ASPFunctions colorFromHex:@"00b4ff"];
        self.labelCust.layer.borderWidth = 0.f;
    } else {
        self.labelCust.backgroundColor = UIColor.clearColor;
        self.labelCust.layer.borderWidth = 2.f/UIScreen.mainScreen.scale;
    }
    BOOL haveSales = [preSalesGrid getCountLine] > 0;
    [createSale setHighlightedState:(custName && haveSales)];
    [putItemsToSalesBtn setHighlightedState:(custName && !haveSales)];
}

- (void)setEditing {
    BOOL editing = !self.editing;
    [self setBarButton:editButton highlighted:editing];
    [super setEditing: editing animated: YES];
    [preSalesTable setEditing:editing animated:YES];
}

- (UITableView*)getTV{
    return preSalesTable;
}

/*- (void)setEditing:(BOOL)editing animated:(BOOL)animated
 {
 if (editing == YES)
 self.editButtonItem.tintColor = [UIColor redColor];
 else
 self.editButtonItem.tintColor = [UIColor blueColor];
 
 [super setEditing: editing animated: animated];
 [preSalesTable setEditing:editing animated:animated];
 }*/

- (void) cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)qtySelected:(double)qty price:(double)price {
    labelQtyTotal.text = [NSString stringWithFormat:@"%0lf", qty];
    labelSumTotal.text = [NSString stringWithFormat:@"%0.2lf", price];
}

#pragma mark - Button Actions
- (IBAction)btnPutItemsToSaleTapped:(id)sender {
    if (custAccount) {
        double pdzDouble = [[self getCustPDZAmount:custAccount] doubleValue];
        
        if (pdzDouble != 0 && (!salesComment || [salesComment isEqualToString:@""])) {
            [self createComment];
        } else {
            InvoiceInventView *fvController = [[InvoiceInventView alloc] init];
            
            fvController.custAccount  = custAccount;
            fvController.custName     = custName;
            fvController.firmID = jurPersonIdValue;
            fvController.firmName = jurPersonNameValue;
            fvController.firmMarkup   = jurPersonMarkupValue;
            fvController.selectedStore = self.selectedStore;
            fvController.isViewPushed = NO;
            fvController.isConsult = self.isConsult;
            
            if (![[self getActionBrandId:custAccount type:@"2"] isEqualToString:@"null"])
                fvController.brandId = [self getActionBrandId:custAccount type:@"2"];
            
            
            if (inventNavController == nil)
                inventNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
            
            inventNavController.modalPresentationStyle = UIModalPresentationFullScreen;
            
            [inventNavController.navigationBar setTitleTextAttributes:
             @{NSForegroundColorAttributeName:[ASPFunctions colorFromHex:@"f0f0f0"]}];
            
            UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width,1.f/UIScreen.mainScreen.scale)];
            [titleView setBackgroundColor:[UIColor blackColor]];
            
            [inventNavController.navigationBar addSubview:titleView];
            
            [self presentViewController:inventNavController animated:YES completion:nil];
            
            fvController = nil;
            inventNavController = nil;
        }
    } else {
        [AlertWorkerObjc alertWithTitle:@"Ошибка" message:@"Необходимо выбрать клиента."];
    }
}

-(IBAction)putCustToSale {
    selectCustAcc = [[SelectCustAcc alloc] init];
    
    selectCustAcc.isViewPushed = NO;
    selectCustAcc.delegate = self;
    
    if (inventNavController == nil)
        inventNavController = [[UINavigationController alloc] initWithRootViewController:selectCustAcc];
    
    inventNavController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [inventNavController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[ASPFunctions colorFromHex:@"f0f0f0"]}];
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width,1.f/UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];
    
    [inventNavController.navigationBar addSubview:titleView];
    
    [self presentViewController:inventNavController animated:YES completion:nil];
    
    selectCustAcc = nil;
    inventNavController = nil;
}

- (void)createBtnPressed:(BOOL)sendSales {
    NSString *prevSalesId = [PersistenceWorker load:@"salesID"];
    salesId = [NSString stringWithFormat:@"%i", ([prevSalesId intValue] + 1)];
    
    [PersistenceWorker save:salesId key:@"salesID"];
    
    preSalesGrid.sendSales = sendSales;
    preSalesGrid.comment   = salesComment;
    preSalesGrid.firmId    = jurPersonIdValue;
    preSalesGrid.firmName  = jurPersonNameValue;
    preSalesGrid.firmMarkup = jurPersonMarkupValue;
    preSalesGrid.deliveryDate = salesDeliveryDate.text;
    preSalesGrid.storeID = self.selectedStore[@"StoreID"];
    preSalesGrid.isConsult = self.isConsult;
    
    [preSalesGrid createSalesFromTmp:salesId merge:merge];
    
    PrepareSales    *prepareSales = [PrepareSales new];
    [prepareSales deleteTmpSalesLine:custAccount itemID:nil isConsult:self.isConsult];
    
    preSalesGrid.custAccount = custAccount;
    [preSalesGrid refreshData];
    [self reloadData];
    
    salesComment = @"";
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    salesDeliveryDate.text = [dateFormatter stringFromDate:date];
    
    labelSumTotal.text = [preSalesGrid getSumAmount];
    labelQtyTotal.text = [preSalesGrid getSumQty];
    
    if ([labelQtyTotal.text doubleValue] > 0) {
        createSale.enabled = YES;
    } else {
        createSale.enabled = NO;
    }
    
    if (custAccount != nil) {
        if ([[self getActionType:custAccount] isEqualToString:@"1"]) {
            actionBtn.enabled  = NO;
            putItemsToSalesBtn.enabled = NO;
        } else if ([[self getActionType:custAccount] isEqualToString:@"2"]) {
            actionBtn.enabled  = NO;
            putItemsToSalesBtn.enabled = YES;
        }
        else
            if ([[self getActionType:custAccount] isEqualToString:@"3"])
            {
                actionBtn.enabled  = NO;
                putItemsToSalesBtn.enabled = YES;
            } else {
                actionBtn.enabled  = YES;
                putItemsToSalesBtn.enabled = YES;
            }
    }
    
    [self updateFormState];
}

- (void)createSales {
    if (![preSalesGrid noSalesLine]) {
        if (self.isConsult) {
            [AlertWorkerObjc alertWithTitle:@"Завершение консультации" message:@"Завершить консультацию и отправить отчёт?" buttons:@[@"Да", @"Отменить"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
                if (index == 0) {
                    [self createBtnPressed:YES];
                }
            }];
        } else {
            [AlertWorkerObjc alertWithTitle:nil message:nil buttons:@[@"Сформировать", @"Сформировать и отправить", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
                if (index == 0) {
                    [self createBtnPressed:NO];
                } else if (index == 1) {
                    [self createBtnPressed:YES];
                }
            }];
        }
    }
}

- (void)preInvoice {
    InvoiceGrid *fvController = [[InvoiceGrid alloc] init];
    
    fvController.isPreInvoice = YES;
    fvController.custAccount  = custAccount;
    
    if (inventNavController == nil)
        inventNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    inventNavController.modalPresentationStyle = UIModalPresentationPageSheet;
    
    [self presentViewController:inventNavController animated:YES completion:nil];
    
    fvController = nil;
    inventNavController = nil;
}

- (void)reloadData {
    [preSalesTable reloadData];
    txtStoreField.enabled = self.storesArray.count > 1 && [preSalesGrid getCountLine] < 1;
    
    //Retrieving Previous selected Data
    NSString *prevStoreID = [preSalesGrid getStoreID];
    NSUInteger searchIndex = [self.storesArray indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj[@"StoreID"] isEqual:prevStoreID];
    }];
    
    if (searchIndex != NSNotFound) {
        self.selectedStore = self.storesArray[searchIndex];
    }
    
    NSString *prevFirmID = [preSalesGrid getFirmID];
    NSString *prevFirmName = [preSalesGrid getFirmName];
    NSString *prevFirmMarkup = [preSalesGrid getFirmMarkup];
    
    if (prevFirmID.length > 0 && prevFirmName.length > 0) {
        jurPersonIdValue = prevFirmID;
        jurPersonNameValue = prevFirmName;
        jurPersonMarkupValue = prevFirmMarkup;
        
        jurPerson.text = jurPersonNameValue;
        
        if (![jurPersonMarkupValue isEqualToString:@"0"] && ![jurPersonMarkupValue isEqualToString:@""]) {
            double num1 = [jurPersonMarkupValue floatValue];
            
            if (num1 > 0) {
                labelMarkup.text = [NSString stringWithFormat:@"Скидка %0.0lf%%", num1];
            } else if (num1 < 0) {
                labelMarkup.text = [NSString stringWithFormat:@"Наценка %0.0lf%%", (num1 * -1)];
            }else {
                labelMarkup.text = @"";
            }
        } else {
            labelMarkup.text = @"";
        }
    }
}

- (void)gridIsUpdated {
    preSalesGrid.custAccount = custAccount;
    [preSalesGrid refreshData];
    [self reloadData];
    
    labelSumTotal.text = [preSalesGrid getSumAmount];
    labelQtyTotal.text = [preSalesGrid getSumQty];
    
    //if ([labelQtyTotal.text doubleValue] != 0)
    if ([preSalesGrid getCountLine] > 0) {
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
    
    if (custAccount != nil) {
        if ([[self getActionType:custAccount] isEqualToString:@"1"]) {
            actionBtn.enabled  = NO;
            putItemsToSalesBtn.enabled = NO;
        } else if ([[self getActionType:custAccount] isEqualToString:@"2"]) {
            actionBtn.enabled  = NO;
            putItemsToSalesBtn.enabled = YES;
        } else if ([[self getActionType:custAccount] isEqualToString:@"3"]) {
            actionBtn.enabled  = NO;
            putItemsToSalesBtn.enabled = YES;
        } else if ([labelQtyTotal.text doubleValue] != 0 || [labelSumTotal.text doubleValue] != 0) {
            actionBtn.enabled  = NO;
            putItemsToSalesBtn.enabled = YES;
        } else {
            actionBtn.enabled  = YES;
            putItemsToSalesBtn.enabled = YES;
        }
        
        if ([[self getActionType:custAccount] isEqualToString:@"0"]) {
            if ([labelQtyTotal.text doubleValue] > 0) {
                createSale.enabled = YES;
            } else {
                createSale.enabled = NO;
            }
        }
    } else if (![[self getActionType:custAccount] isEqualToString:@"1"]) {
        [preSalesGrid fillCheckParms];
        [self setDontChekParms:custAccount type:@"3"];
        
        if ([[preSalesGrid getCheckedAmount] doubleValue] == 0 & [[preSalesGrid getCheckedQty] doubleValue] == 0)
        {
            createSale.enabled = YES;
        } else {
            if ([[preSalesGrid getCheckedAmount] doubleValue] == 0 & [[preSalesGrid getCheckedQty] doubleValue] != 0)
            {
                if (([[self getActionQty:custAccount type:[self getActionType:custAccount]] doubleValue]) > ([labelQtyTotal.text doubleValue] - [dontInclCheckQty doubleValue]))
                {
                    createSale.enabled = NO;
                }
                else
                {
                    createSale.enabled = YES;
                }
            } else if ([[preSalesGrid getCheckedAmount] doubleValue] != 0 & [[preSalesGrid getCheckedQty] doubleValue] == 0) {
                if (([[self getActionSum:custAccount type:[self getActionType:custAccount]] doubleValue]) > ([labelSumTotal.text doubleValue] - [dontInclCheckAmount doubleValue]))
                {
                    createSale.enabled = NO;
                } else {
                    createSale.enabled = YES;
                }
            } else if ([[preSalesGrid getCheckedAmount] doubleValue] != 0 & [[preSalesGrid getCheckedQty] doubleValue] != 0)
            {
                if (([[self getActionSum:custAccount type:[self getActionType:custAccount]] doubleValue]) > ([labelSumTotal.text doubleValue] - [dontInclCheckAmount doubleValue]))
                {
                    createSale.enabled = NO;
                }
                else
                    if (([[self getActionQty:custAccount type:[self getActionType:custAccount]] doubleValue]) > ([labelQtyTotal.text doubleValue] - [dontInclCheckQty doubleValue]))
                    {
                        createSale.enabled = NO;
                    }
                    else
                    {
                        createSale.enabled = YES;
                    }
            }
        }
    } else if ([[self getActionType:custAccount] isEqualToString:@"1"]) {
        [preSalesGrid fillCheckParms];
        
        if ([[preSalesGrid getCheckedQty] doubleValue] != 0)
        {
            if ([[preSalesGrid getCheckedQty] doubleValue] > [labelQtyTotal.text doubleValue])
            {
                createSale.enabled = NO;
            }
            else
            {
                createSale.enabled = YES;
            }
        }
    }
    [self updateFormState];
}

- (void)commentAdded:(NSString *)comment {
    salesComment = comment;
    
    if (salesComment == nil) {
        
    }
}

- (IBAction)createComment {
    AddSalesCommentView *fvController = [[AddSalesCommentView alloc] initWithNibName: @"AddSalesCommentView" bundle: nil];
    
    fvController.custAccount    = custAccount;
    fvController.salesComment   = salesComment;
    fvController.delegate       = self;
    fvController.customerHasPDZ = [[self getCustPDZAmount:custAccount] doubleValue] > 0 ? YES : false;
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];
    
    fvController = nil;
    infoNavController = nil;
}

-(IBAction)openAction {
    if (custAccount) {
        MerchActionViewController *fvController = [[MerchActionViewController alloc] init];
        
        fvController.custAccount = custAccount;
        NSLog(@"%@", custAccount);
        
        if (infoNavController == nil)
            infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
        
        infoNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [self.navigationController presentViewController:infoNavController animated:YES completion:nil];
        
        fvController = nil;
        infoNavController = nil;
    } else {
        [AlertWorkerObjc alertWithTitle:@"Ошибка" message:@"Необходимо выбрать клиента."];
    }
}

- (void)getJurPersonDefault {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select FirmId, Name, Markup from FirmTable where Def = 1";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                {
                    jurPersonIdValue  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
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
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    jurPerson.text = jurPersonNameValue;
    
    if (![jurPersonMarkupValue isEqualToString:@"0"] && ![jurPersonMarkupValue isEqualToString:@""]) {
        double num1 = [jurPersonMarkupValue floatValue];
        
        if (num1 > 0)
            labelMarkup.text = [NSString stringWithFormat:@"Скидка %0.0lf%%", num1];
        else
            if (num1 < 0)
                labelMarkup.text = [NSString stringWithFormat:@"Наценка %0.0lf%%", (num1 * -1)];
            else
                labelMarkup.text = @"";
    } else
        labelMarkup.text = @"";
}

-(IBAction)selectJurPerson {
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
    
    if (![jurPersonMarkupValue isEqualToString:@"0"] && ![jurPersonMarkupValue isEqualToString:@""]) {
        double num1 = [jurPersonMarkupValue floatValue];
        
        if (num1 > 0)
            labelMarkup.text = [NSString stringWithFormat:@"Скидка %0.0lf%%", num1];
        else
            if (num1 < 0)
                labelMarkup.text = [NSString stringWithFormat:@"Наценка %0.0lf%%", (num1 * -1)];
            else
                labelMarkup.text = @"";
    } else
        labelMarkup.text = @"";
    
    if (firmViewController.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        firmViewController = nil;
    }
    
    [self updateTmpSalesLine];
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
}

-(NSString*)getActionType:(NSString *)custAcc {
    NSString *actionType = @"0";
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        
        NSString *sqlString = [NSString stringWithFormat:@"select ActionType from %@ where CustAccount = ? and ActionType != '0'", self.salesLineTable];
        const char *sql = sqlString.UTF8String;
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                actionType = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return actionType;
}

-(NSString*)getActionQty:(NSString *)custAcc type:(NSString*)type {
    NSString *qty = @"0";
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        
        NSString *sqlString = [NSString stringWithFormat:@"select Qty from %@ where CustAccount = ? and ActionType = 2", self.salesLineTable];
        const char *sql = sqlString.UTF8String;
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [type UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                qty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return qty;
}

-(NSString*)getActionSum:(NSString *)custAcc type:(NSString*)type {
    NSString *amount = @"0";
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select LineAmount from %@ where CustAccount = ? and ActionType = 2", self.salesLineTable];
        const char *sql = sqlString.UTF8String;

        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [type UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                amount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return amount;
}

-(NSString*)getActionBrandId:(NSString *)custAcc type:(NSString*)type {
    NSString *brandId = @"null";
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select BrandId from %@ where CustAccount = ? and ActionType = ?", self.salesLineTable];
        const char *sql = sqlString.UTF8String;
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [type UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                brandId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return brandId;
}

- (void)setDontChekParms:(NSString *)custAcc type:(NSString*)type {
    dontInclCheckQty    = nil;
    dontInclCheckAmount = nil;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select Qty, LineAmount from %@ where CustAccount = ? and ActionType = ?", self.salesLineTable];
        const char *sql = sqlString.UTF8String;

        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [type UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                dontInclCheckQty    = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                
                dontInclCheckAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

- (void)updateTmpSalesLine {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select ItemId, Qty, OrigPrice from %@ where CustAccount = ?", self.salesLineTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *itemId        = @"null";
                NSString *qty           = @"null";
                NSString *origPrice     = @"null";
                NSString *lineAmount    = @"null";
                NSString *price         = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    itemId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    qty  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    origPrice  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                
                price      = [NSString stringWithFormat:@"%0.2lf", ([origPrice doubleValue] - ([origPrice doubleValue] * [jurPersonMarkupValue doubleValue]/100.0))];
                lineAmount = [NSString stringWithFormat:@"%0.2lf", ([price doubleValue] * [qty doubleValue])];
                
                [self updateTmpSalesLineByFirm:itemId qty:qty lineAmount:lineAmount custAcc:custAccount price:price];
                
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    [preSalesGrid refreshData];
    [self reloadData];
    
    labelSumTotal.text = [preSalesGrid getSumAmount];
    labelQtyTotal.text = [preSalesGrid getSumQty];
}

- (void)updateTmpSalesLineByFirm:(NSString *)itemId qty:(NSString *)newQty lineAmount:(NSString *)lineAmount custAcc:(NSString *)custAcc price:(NSString *)price {
    static sqlite3_stmt *updateStmt;
    
    NSString *sqlString = [NSString stringWithFormat:@"update %@ Set Qty = ?, lineAmount = ?, Price = ? where CustAccount = ? and ItemId = ?", self.salesLineTable];
    const char *sql = sqlString.UTF8String;
    
    sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
    
    sqlite3_bind_text(updateStmt, 1, [newQty UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateStmt, 2, [lineAmount UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateStmt, 3, [price UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_bind_text(updateStmt, 4, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateStmt, 5, [itemId UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_step(updateStmt);
    sqlite3_finalize(updateStmt);
}


-(IBAction)mergeSale {
    if (merge) {
        merge = FALSE;
    } else {
        merge = YES;
    }
    self.mergeSwitch.on = merge;
}

- (IBAction)mergeSaleChanged:(id)sender {
    merge = self.mergeSwitch.on ? YES : FALSE;
}

#pragma mark - Store logic
- (void)prepareStores {
    if ([SyncStateWorker synchronized]) {
        self.storesArray = [PersistenceWorker load:@"storesArray"];
        if (!self.selectedStore) {
            self.selectedStore = self.storesArray.firstObject;
        } else {
            NSUInteger searchIndex = [self.storesArray indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [obj[@"StoreID"] isEqual:self.selectedStore[@"StoreID"]];
            }];
            
            if (searchIndex == NSNotFound) {
                self.selectedStore = self.storesArray.firstObject;
            }
        }
    }
}

- (void)setSelectedStore:(NSDictionary *)selectedStore {
    _selectedStore = selectedStore;
    txtStoreField.text = selectedStore[@"StoreName"];
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

- (NSString *)getCustPDZAmount:(NSString *)custAccountSQL {
    NSString *pdz = @"0";
    static sqlite3_stmt *selectstmt = nil;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select PDZAmount from CustTable where CustAccount = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccountSQL UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                    pdz = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    return pdz;
}

#pragma mark - Button styling methods
- (void)setBarButton:(UIBarButtonItem *)button highlighted:(BOOL)highlighted {
    [(RWBorderedButton *)button.customView setHighlightedState:highlighted];
}

@end
