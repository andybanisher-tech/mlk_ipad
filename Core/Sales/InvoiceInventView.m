//
//  InvoiceInventView.m
//  MLK
//
//  Created by Rustem Galyamov on 24.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "InvoiceInventView.h"
#import "InvoiceInventTableHeaderView.h"
#import "InvoiceInventProductTableViewCell.h"
#import "InvoiceInventBadProductTableViewCell.h"
#import "PrepareSales.h"
#import "GroupView.h"

#import "GeneratedAssetSymbols.h"

//Constants
static const CGFloat kInvoiceInventProductCellHeight = 78.0;
static const CGFloat kInvoiceInventBadProductCellHeight = 50.0;

static NSString *const kMainStoreID = @"00001";

static sqlite3 *database = nil;

@interface InvoiceInventView() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UISearchBarDelegate, InvoiceInventProductTableViewCellDelegate>

@property (nonatomic, strong) NSMutableArray *itemsArray;
@property (nonatomic, strong) NSMutableArray *filteredItemsArray;

@property (nonatomic, copy) NSString *searchText;

@property (nonatomic, copy) NSString *salesLineTable;

@end

@implementation InvoiceInventView {
    NSArray *_filtersArray;
    NSString *_expandedProductID;
    
    BOOL _didTapDeleteKey;
}

@synthesize
brandId,
group,
closedItems;

@synthesize qtyTotal;
@synthesize sumTotal;
@synthesize searchBar;
@synthesize isViewPushed;
@synthesize custAccount, custName;
@synthesize brandBtn, statusDNBtn, cBtn, matrixBtn, btnDiscounts;
@synthesize labelTotal;
@synthesize itemIdIsSelected;
@synthesize fromCreatedSales, salesId, firmMarkup;
@synthesize m_footerView;
@synthesize fstatusDN;
@synthesize isMatrix, statusDNArray;

- (void)loadView {
    [super loadView];
    _filtersArray = @[@"Все", @">0", @"<=0"];
    
    closedItems = @"Все";
    
    //NavBar Setup
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    self.navigationController.navigationBar.barStyle = 1;
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height)];
    [self.view addSubview:backgroundView];
    self.view.backgroundColor = UIColor.clearColor;
    
    UIImageView *bgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameGrayBackground]];
    [backgroundView addSubview:bgImage];
    
    bgImage.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[bgImage.leadingAnchor constraintEqualToAnchor:backgroundView.leadingAnchor],
       [bgImage.trailingAnchor constraintEqualToAnchor:backgroundView.trailingAnchor],
       [bgImage.topAnchor constraintEqualToAnchor:backgroundView.topAnchor],
       [bgImage.bottomAnchor constraintEqualToAnchor:backgroundView.bottomAnchor]]];
    
    if (isViewPushed == NO) {
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        
        self.navigationItem.rightBarButtonItem = barButton;
        
        RWBorderedButton *marksButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,70,30) title:@"Марки"];
        [marksButton addTarget:self
                        action:@selector(showMark:)
              forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *markBtn = [[UIBarButtonItem alloc] initWithCustomView:marksButton];
        
        brandBtn = markBtn;
        
        UIToolbar* tools = [[UIToolbar alloc] initWithFrame:CGRectMake (0, 0, 170, 44)];
        tools.clipsToBounds = YES;
        tools.barTintColor = [UIColor colorNamed:ACColorNameGrayNavBarBackground];
        tools.translucent = NO;
        UIView *toolsView = [[UIView alloc] initWithFrame:CGRectMake(0,0,tools.frame.size.width,1.f/UIScreen.mainScreen.scale)];
        [toolsView setBackgroundColor:[UIColor blackColor]];
        [tools addSubview:toolsView];
        
        NSMutableArray* buttons = [[NSMutableArray alloc] initWithCapacity:3];
        
        UIBarButtonItem *bi = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        
        [buttons addObject:bi];
        
        [buttons addObject:markBtn];
        
        RWBorderedButton *brandFilter = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,90,30) title:@"Статус DN"];
        [brandFilter addTarget:self
                        action:@selector(showStatusDN:)
              forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *statDNBtn = [[UIBarButtonItem alloc] initWithCustomView:brandFilter];
        statusDNBtn = statDNBtn;
        
        RWBorderedButton *closedButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,55,30) title:@"Все"];
        closedButton.menu = [UIMenu menuWithChildren:@[]];
        closedButton.showsMenuAsPrimaryAction = YES;
        [closedButton addTarget:self
                         action:@selector(closedItems:)
               forControlEvents:UIControlEventMenuActionTriggered];
        cBtn = closedButton;
        
        UIBarButtonItem *closedBtn = [[UIBarButtonItem alloc] initWithCustomView:closedButton];
        
        RWBorderedButton *matrixButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Матрица"];
        [matrixButton addTarget:self
                         action:@selector(matrixItems:)
               forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *mBtn = [[UIBarButtonItem alloc] initWithCustomView:matrixButton];
        matrixBtn = mBtn;
        
        RWBorderedButton *discountsButton = [RWBorderedButton buttonWithFrame:CGRectMake(0.0, 0.0, 40.0, 30.0) title:@"%"];
        [discountsButton addTarget:self
                            action:@selector(btnDiscountsTapped:)
                  forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *discountsBarButton = [[UIBarButtonItem alloc] initWithCustomView:discountsButton];
        btnDiscounts = discountsBarButton;
        
        [buttons addObject:statusDNBtn];
        [buttons addObject:closedBtn];
        [buttons addObject:matrixBtn];
        [buttons addObject:btnDiscounts];
        
        [tools setItems:buttons animated:NO];
        
        self.navigationItem.leftBarButtonItems = buttons;
    }
    
    //SearchBar
    CGFloat navigationBarWidth = CGRectGetWidth(self.navigationController.navigationBar.frame);
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, navigationBarWidth * 0.6, 40.0)];
    searchBar.backgroundColor = [UIColor colorWithRed:62.0/255.0 green:63.0/255.0 blue:64.0/255.0 alpha:1];
    searchBar.backgroundImage = [UIImage new];
    searchBar.delegate = self;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.placeholder = @"Поиск";
    searchBar.tintColor = [UIColor blackColor];
    searchBar.searchTextField.backgroundColor = UIColor.whiteColor;
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:searchBar];
    
    [NSLayoutConstraint activateConstraints:
     @[[searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [searchBar.widthAnchor constraintEqualToConstant:searchBar.frame.size.width],
       [searchBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor]]];
    
    UILabel *lblStore = [[UILabel alloc] initWithFrame:CGRectMake(searchBar.frame.size.width, 0.0, navigationBarWidth * 0.4, 40.0)];
    lblStore.textAlignment = NSTextAlignmentLeft;
    lblStore.textColor = UIColor.whiteColor;
    lblStore.font = [UIFont systemFontOfSize:16.0];
    lblStore.backgroundColor = [UIColor colorWithRed:62.0/255.0 green:63.0/255.0 blue:64.0/255.0 alpha:1];
    lblStore.text = [NSString stringWithFormat:@"Склад: %@", self.selectedStore[@"StoreName"]];
    
    [self.view addSubview:lblStore];
    lblStore.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[lblStore.leadingAnchor constraintEqualToAnchor:searchBar.trailingAnchor],
       [lblStore.widthAnchor constraintEqualToConstant:lblStore.frame.size.width],
       [lblStore.heightAnchor constraintEqualToAnchor:searchBar.heightAnchor],
       [lblStore.centerYAnchor constraintEqualToAnchor:searchBar.centerYAnchor]]];
    
    InvoiceInventTableHeaderView *tableViewHeaderView = [[NSBundle.mainBundle loadNibNamed:NSStringFromClass([InvoiceInventTableHeaderView class]) owner:self options:nil] firstObject];
    tableViewHeaderView.frame = CGRectMake(0.0, 40.0, CGRectGetWidth(self.navigationController.navigationBar.frame), 40.0);
    tableViewHeaderView.availableLabel.hidden = self.isConsult;
    tableViewHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tableViewHeaderView];

    [NSLayoutConstraint activateConstraints:
     @[[tableViewHeaderView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [tableViewHeaderView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       [tableViewHeaderView.topAnchor constraintEqualToAnchor:searchBar.bottomAnchor],
       [tableViewHeaderView.heightAnchor constraintEqualToConstant:tableViewHeaderView.frame.size.height]]];
    
    myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 80.0, CGRectGetWidth(self.navigationController.navigationBar.frame), self.view.frame.size.height)];
    
    myTableView.delegate = self;
    myTableView.dataSource = self;
    
    [myTableView setBackgroundColor:UIColor.clearColor];
    
    myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.view addSubview:myTableView];
    myTableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[myTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [myTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       [myTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
       [myTableView.topAnchor constraintEqualToAnchor:tableViewHeaderView.bottomAnchor]]];
    
    [myTableView registerNib:[UINib nibWithNibName: NSStringFromClass([InvoiceInventProductTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([InvoiceInventProductTableViewCell class])];
    [myTableView registerNib:[UINib nibWithNibName: NSStringFromClass([InvoiceInventBadProductTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([InvoiceInventBadProductTableViewCell class])];
    
    myTableView.estimatedRowHeight = 0.0;
    
    UILabel *lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(435.0, 16.0, 345.0, 20.0)];
    lblTitle.tag = 2;
    lblTitle.backgroundColor = UIColor.clearColor;
    lblTitle.font = [UIFont boldSystemFontOfSize:16];
    lblTitle.adjustsFontSizeToFitWidth = NO;
    lblTitle.textAlignment = NSTextAlignmentLeft;
    lblTitle.textColor = UIColor.whiteColor;
    lblTitle.text = custName;
    lblTitle.highlightedTextColor = [UIColor blackColor];
    [self.navigationController.navigationBar addSubview:lblTitle];
    
    labelTotal = [[UILabel alloc] initWithFrame:CGRectMake(785.0, 16.0, 180.0, 20.0)];
    labelTotal.tag = 1;
    labelTotal.backgroundColor = UIColor.clearColor;
    labelTotal.font = [UIFont boldSystemFontOfSize:16];
    labelTotal.adjustsFontSizeToFitWidth = NO;
    labelTotal.textAlignment = NSTextAlignmentCenter;
    labelTotal.textColor = UIColor.whiteColor;
    labelTotal.text = [self totalSalesSum];
    labelTotal.highlightedTextColor = [UIColor blackColor];
    [self.navigationController.navigationBar addSubview:labelTotal];
    
    if (brandId)
        self.navigationItem.leftBarButtonItem.enabled = NO;
    else
        self.navigationItem.leftBarButtonItem.enabled = YES;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    
    [SVProgressHUD showWithStatus:@"Загрузка списка товаров"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self createItemsArray];
    });
}

#pragma mark - Prepare Data
- (void)createItemsArray {
    self.itemsArray = [NSMutableArray new];
    self.filteredItemsArray = [NSMutableArray new];
    
    NSMutableSet *brandIDsWithProductsSet = [NSMutableSet new];
    NSMutableSet *groupIDsWithProductsSet = [NSMutableSet new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;
        
        NSString *squl = @"select ItemId, ItemName, BrandId, cast(Qty as real) as q, Promo, Discount, StoresJSON, BadProductJSON, isBadProduct, GroupId from ItemTable where Closed != '1' and Action != '1'and exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == ItemTable.BrandId) and exists(select cast(Price as real) as p from BasePriceTable where BasePriceTable.ItemId == ItemTable.ItemId) order by ItemName";
        
        sql = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                
                NSMutableDictionary *productData = [NSMutableDictionary new];
                
                NSString *itemID = @"null";
                NSString *itemName = @"null";
                NSString *brandID = @"null";
                NSString *qty = @"null";
                NSString *price = @"null";
                NSString *priceTypeId = @"null";
                NSString *disc = @"null";
                NSString *round = @"null";
                NSString *comDiscount = @"null";
                NSString *origPrice = @"null";
                NSString *promo = @"null";
                NSString *discount = @"null";
                NSString *storesJSON = @"null";
                NSString *badProductJSON = @"null";
                NSString *isBadProduct = @"null";
                NSString *groupID = @"null";
                NSString *brandMatrixID = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    itemID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    itemName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    brandID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3)) {
                    qty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                    qty = [NSString stringWithFormat:@"%0.0f", [qty doubleValue]];
                }
                
                if (sqlite3_column_text(selectstmt, 4))
                    promo = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    discount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6)) {
                    storesJSON = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                }
                
                if (sqlite3_column_text(selectstmt, 7)) {
                    badProductJSON = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                }
                
                if (sqlite3_column_text(selectstmt, 8)) {
                    isBadProduct = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                }
                
                if (sqlite3_column_text(selectstmt, 9)) {
                    groupID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                }
                
                const char *sql_2;
                
                sql_2 = "select PriceTypeId, Discount, Round, ComDiscount, MatrixId from PersonalPriceList where BrandId = ? and CustAccount = ?";
                
                sqlite3_stmt *selstmt_2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
                    sqlite3_bind_text(selstmt_2, 1, [brandID UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
                        if (sqlite3_column_text(selstmt_2, 0))
                            priceTypeId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                        
                        if (sqlite3_column_text(selstmt_2, 1))
                            disc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 1)];
                        
                        if (sqlite3_column_text(selstmt_2, 2))
                            round = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 2)];
                        
                        if (sqlite3_column_text(selstmt_2, 3))
                            comDiscount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 3)];
                        
                        if (sqlite3_column_text(selstmt_2, 4))
                            brandMatrixID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 4)];
                    }
                }
                sqlite3_finalize(selstmt_2);
                
                const char *sql_1;
                
                if ([priceTypeId isEqualToString:@"null"])
                    sql_1 = "select Price from BasePriceTable where ItemId = ?";
                else
                    sql_1 = "select Price from BasePriceTable where ItemId = ? and PriceTypeId = ?";
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK)
                {
                    if ([priceTypeId isEqualToString:@"null"])
                        sqlite3_bind_text(selstmt, 1, [itemID UTF8String], -1, SQLITE_TRANSIENT);
                    else
                    {
                        sqlite3_bind_text(selstmt, 1, [itemID UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(selstmt, 2, [priceTypeId UTF8String], -1, SQLITE_TRANSIENT);
                    }
                    
                    if (sqlite3_step(selstmt) == SQLITE_ROW)
                    {
                        if ([disc isEqualToString:@"null"])
                        {
                            if (sqlite3_column_text(selstmt, 0))
                                price = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                            
                            if (![comDiscount isEqualToString:@"null"])
                            {
                                double totalPrice = 0.0;
                                
                                totalPrice = [price doubleValue]*(100.0 - [comDiscount doubleValue])/100.0;
                                
                                price = [NSString stringWithFormat:@"%0.2lf", totalPrice];
                            }
                        }
                        else
                        {
                            if (sqlite3_column_text(selstmt, 0))
                                price = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                            
                            double totalPrice = 0.0;
                            
                            if (![comDiscount isEqualToString:@"null"])
                            {
                                totalPrice = ([price doubleValue]*(100.0 - [disc doubleValue])/100.0)*(100.0 - [comDiscount doubleValue])/100.0;
                                
                                price = [NSString stringWithFormat:@"%0.2lf", totalPrice];
                            } else {
                                totalPrice = ([price doubleValue]*(100.0 - [disc doubleValue]/100));
                                
                                price = [NSString stringWithFormat:@"%0.2lf", totalPrice];
                            }
                        }
                        
                        origPrice = price;
                        origPrice = [self roundedNum:[origPrice doubleValue] round:[round doubleValue]];
                        
                        price = [NSString stringWithFormat:@"%0.2lf", ([price doubleValue] - ([price doubleValue] * [firmMarkup doubleValue]/100.0))];
                        
                        price = [self roundedNum:[price doubleValue] round:[round doubleValue]];
                    }
                }
                sqlite3_finalize(selstmt);
                
                //Adding product data values
                productData[@"itemID"] = itemID;
                productData[@"itemName"] = itemName;
                productData[@"brandID"] = brandID;
                productData[@"promo"] = promo;
                productData[@"discount"] = discount;
                productData[@"isBadProduct"] = isBadProduct;
                productData[@"qty"] = qty;
                productData[@"groupID"] = groupID;
                
                if (brandMatrixID.length > 0) {
                    productData[@"matrixID"] = [self getItemMatrixID:itemID brandMatrixID:brandMatrixID];
                }
                
                productData[@"price"] = price;
                productData[@"origPrice"] = origPrice;
                
                NSData *storesData = [storesJSON dataUsingEncoding:NSUTF8StringEncoding];
                NSMutableArray *stores = [[NSJSONSerialization JSONObjectWithData:storesData options:0 error:nil] mutableCopy];
                
                NSUInteger searchIndex = [stores indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    return [obj[@"StoreID"] isEqual:self.selectedStore[@"StoreID"]];
                }];
                
                if (searchIndex != NSNotFound) {
                    productData[@"StoreName"] = stores[searchIndex][@"StoreName"];
                    productData[@"StoreID"] = stores[searchIndex][@"StoreID"];
                    productData[@"qty"] = stores[searchIndex][@"QtyS"];
                    productData[@"expDate"] = stores[searchIndex][@"Exp"];
                    
                    [stores removeObjectAtIndex:searchIndex];
                    productData[@"stores"] = stores;
                    
                    NSData *badProductData = [badProductJSON dataUsingEncoding:NSUTF8StringEncoding];
                    NSArray *badProduct = [NSJSONSerialization JSONObjectWithData:badProductData options:0 error:nil];
                    productData[@"badProduct"] = badProduct;
                    
                    [self.itemsArray addObject:[self getPreQtyAndLineAmount:productData]];
                    [self.itemsArray addObjectsFromArray:[self createBadProductsArray:productData]];
                }
                
                [brandIDsWithProductsSet addObject:brandID];
                [groupIDsWithProductsSet addObject:groupID];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self applyFilters];

    self.custItemMarkVC = [[CustItemMarkView alloc] init];
    self.custItemMarkVC.modalPresentationStyle = UIModalPresentationPopover;
    self.custItemMarkVC.delegate = self;
    self.custItemMarkVC.custAccount = custAccount;
    self.custItemMarkVC.filterByStatusDN = fstatusDN;
    self.custItemMarkVC.requiredBrandIDsArray = [brandIDsWithProductsSet allObjects];
    self.custItemMarkVC.requiredGroupIDsArray = [groupIDsWithProductsSet allObjects];
    
    [SVProgressHUD dismiss];
}

- (NSString *)getItemMatrixID:(NSString *)itemID brandMatrixID:(NSString *)brandMatrixID {
    const char *sqlItemMatrix = [@"select MatrixId from MatrixTable where ItemId = ? and MatrixId = ?" UTF8String];
    sqlite3_stmt *selectstmt;
    
    NSString *matrixID = @"";
    if (sqlite3_prepare_v2(database, sqlItemMatrix, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [itemID UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selectstmt, 2, [brandMatrixID UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selectstmt) == SQLITE_ROW) {
            if (sqlite3_column_text(selectstmt, 0))
                matrixID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
        }
    }
    sqlite3_finalize(selectstmt);
    
    return matrixID;
}

- (NSArray *)createBadProductsArray:(NSDictionary *)product {
    NSMutableArray *badProducts = [NSMutableArray new];
    for (NSDictionary *object in product[@"badProduct"]) {
        NSMutableDictionary *badProduct = product.mutableCopy;
        
        badProduct[@"badProduct"] = nil;
        badProduct[@"isBadProduct"] = @"1";
        badProduct[@"discount"] = object[@"Discount"];
        badProduct[@"qty"] = object[@"QtyS"];
        badProduct[@"StoreName"] = object[@"StoreName"];
        badProduct[@"StoreID"] = object[@"StoreID"];
        badProduct[@"stores"] = @[object];
        badProduct[@"itemID"] = [NSString stringWithFormat:@"%@/%@", badProduct[@"itemID"],  badProduct[@"StoreID"]];
        
        [badProducts addObject:[self getPreQtyAndLineAmount:badProduct]];
    }
    
    return badProducts;
}

- (NSMutableDictionary *)getPreQtyAndLineAmount:(NSMutableDictionary *)product {
    if (!custAccount) {
        return product;
    }
    
    NSString *preQty = @"";
    NSString *lineAmount = @"0.00";
    
    const char *sql_3;
    if (!fromCreatedSales) {
        NSString *sqlString = [NSString stringWithFormat:@"select Qty, LineAmount from %@ where CustAccount = ? and ItemId = ?", self.salesLineTable];
        sql_3 = sqlString.UTF8String;
        
        sqlite3_stmt *selstmt_3;
        
        if (sqlite3_prepare_v2(database, sql_3, -1, &selstmt_3, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_3, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_3, 2, [product[@"itemID"] UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_3) == SQLITE_ROW) {
                if (sqlite3_column_text(selstmt_3, 0))
                    preQty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_3, 0)];
                
                if (sqlite3_column_text(selstmt_3, 1))
                    lineAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_3, 1)];
            }
        }
        sqlite3_finalize(selstmt_3);
    } else {
        sql_3 = "select Qty, LineAmount from SalesLine where SalesId = ? and ItemId = ?";
        
        sqlite3_stmt *selstmt_3;
        
        if (sqlite3_prepare_v2(database, sql_3, -1, &selstmt_3, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_3, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_3, 2, [product[@"itemID"] UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_3) == SQLITE_ROW) {
                if (sqlite3_column_text(selstmt_3, 0))
                    preQty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_3, 0)];
                
                if (sqlite3_column_text(selstmt_3, 1))
                    lineAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_3, 1)];
            }
        }
        
        sqlite3_finalize(selstmt_3);
    }
    
    product[@"text"] = preQty;
    product[@"lineAmount"] = lineAmount;
    
    return product;
}

- (NSString *)roundedNum:(double)num round:(double)round {
    double result = 0.0;
    double numOfRound = 0.0;
    double numOfRounds_Int = 0.0;
    
    numOfRound = num/round;
    
    numOfRounds_Int = trunc(numOfRound);
    
    if (numOfRound == numOfRounds_Int) {
        result = num;
    } else {
        result = round * (numOfRounds_Int + 1);
    }
    
    return [NSString stringWithFormat:@"%0.2lf", result];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
    //[myTableView setFrame:CGRectMake(0.0, 40.0, 1024.0, 300.0)];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    //[myTableView setFrame:CGRectMake(0.0, 40.0, 1024.0, 650.0)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.isConsult) {
        self.salesLineTable = @"tmpConsultSalesLine";
    } else {
        self.salesLineTable = @"tmpSalesLine";
    }
    
    m_footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, myTableView.frame.size.width, 415.0f)];
    [m_footerView setBackgroundColor:UIColor.clearColor];
    [myTableView setTableFooterView:m_footerView];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag - 2 inSection:0];
    if (indexPath.row < [myTableView numberOfRowsInSection:0]) {
        [myTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [myTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        return YES;
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self->myTableView setContentOffset:CGPointZero animated:YES];
        });
        return NO;
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag - 2 inSection:0];
    
    NSString *textValue = textField.text;
    if (textValue.length == 0) {
        textValue = @"0";
    }
    
    NSMutableDictionary *object = self.filteredItemsArray[indexPath.row];
    NSString *qtyValue = object[@"qty"];
    
    if (!self.isConsult && [textValue doubleValue] > [qtyValue doubleValue]) {
        [AlertWorkerObjc alertWithTitle:@"Ошибка" message:@"Вы пытаетесь заказать больше, чем доступно"];
        textValue = qtyValue;
        textField.text = qtyValue;
    }
    
    object[@"text"] = textValue;
    
    NSString *itemValue = object[@"itemID"];
    NSString *priceValue = object[@"price"];
    NSString *discount = object[@"discount"];
    
    qtyTotal = [textValue doubleValue];
    sumTotal = qtyTotal * (100.0 - discount.doubleValue) / 100.0 * priceValue.doubleValue;
    
    object[@"lineAmount"] = [NSString stringWithFormat:@"%0.2lf", sumTotal];
    
    NSUInteger searchIndex = [self.itemsArray indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj[@"itemID"] isEqual:itemValue] && [obj[@"StoreID"] isEqual:object[@"StoreID"]];
    }];
    
    if (searchIndex != NSNotFound) {
        [self.itemsArray replaceObjectAtIndex:searchIndex withObject:object];
    }
    
    [self.filteredItemsArray replaceObjectAtIndex:indexPath.row withObject:object];
    
    if (qtyTotal != 0) {
        PrepareSales *prepareSales = [PrepareSales new];
        if (!fromCreatedSales) {
            [prepareSales createTmpSalesLine:custAccount item:object firmID:self.firmID firmName:self.firmName firmMarkup:self.firmMarkup isConsult:self.isConsult];
        } else {
            [prepareSales createSalesLine:custAccount salesID:salesId item:object];
        }
    } else {
        PrepareSales *prepareSales = [PrepareSales new];
        
        if (!fromCreatedSales) {
            [prepareSales deleteTmpSalesLine:custAccount itemID:itemValue isConsult:self.isConsult];
        } else {
            [prepareSales deleteSalesLine:custAccount itemID:itemValue salesID:salesId];
        }
    }
    
    labelTotal.text = [self totalSalesSum];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->myTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return [string isEqualToString:@""] || [string isEqualToString:@"0"] || [string integerValue];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredItemsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.filteredItemsArray[indexPath.row];
    
    if ([object[@"isBadProduct"] isEqual:@"1"]) {
        InvoiceInventBadProductTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(InvoiceInventBadProductTableViewCell.class) forIndexPath:indexPath];
        
        cell.lblName.text = object[@"StoreName"];
        [cell setPrice:object[@"price"] discount:object[@"discount"]];
        
        cell.txtAmountField.text = object[@"text"];
        cell.txtAmountField.tag = indexPath.row + 2;
        cell.txtAmountField.enabled = NO;
        cell.txtAmountField.delegate = self;
        
        cell.lblQtyStore.hidden = self.isConsult;
        cell.lblQtyStore.text = object[@"qty"];
        
        cell.lblSum.text = object[@"lineAmount"];
        
        return cell;
    } else {
        InvoiceInventProductTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(InvoiceInventProductTableViewCell.class)];
        
        cell.lblNumber.text = [NSString stringWithFormat:@"%d", (int)(indexPath.row + 1)];
        cell.lblName.text = object[@"itemName"];
        cell.lblCode.text = object[@"itemID"];
        [cell setExpirationDate:object[@"expDate"]];
        
        cell.txtAmountField.text = object[@"text"];
        cell.txtAmountField.tag = indexPath.row + 2;
        cell.txtAmountField.enabled = NO;
        cell.txtAmountField.delegate = self;
        
        [cell setPrice:object[@"price"] discount:object[@"discount"]];
        
        cell.lblSum.text = object[@"lineAmount"];
        
        NSArray *storesArray = object[@"stores"];
        NSString *btnQtyTitle;
        cell.btnQtyStore.hidden = self.isConsult;
        if (storesArray.count > 0) {
            btnQtyTitle = [NSString stringWithFormat:@"%@   ", object[@"qty"]];
            [cell.btnQtyStore setImage:[UIImage imageNamed:ACImageNameStore] forState:UIControlStateNormal];
            cell.btnQtyStore.enabled = YES;
        } else {
            btnQtyTitle = object[@"qty"];
            [cell.btnQtyStore setImage:nil forState:UIControlStateNormal];
            cell.btnQtyStore.enabled = NO;
        }
        
        [ASPFunctions setButtonTitleWithoutAnimation:cell.btnQtyStore title:btnQtyTitle state:UIControlStateNormal];
        
        if ([object[@"promo"] isEqualToString:@"1"]) {
            cell.backgroundColor = [UIColor colorWithRed:109.0/255.0 green:236.0/255.0 blue:143.0/255.0 alpha:1.0];
        } else {
            cell.backgroundColor = UIColor.whiteColor;
        }
        
        [cell setBadProduct:object[@"badProduct"] isExpanded:[object[@"itemID"] isEqual:_expandedProductID]];
        
        cell.delegate = self;
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.filteredItemsArray[indexPath.row];
    if ([object[@"isBadProduct"] isEqual:@"1"]) {
        return kInvoiceInventBadProductCellHeight;
    }
    return kInvoiceInventProductCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.filteredItemsArray[indexPath.row];
    
    NSString *priceValue = object[@"price"];
    
    if (![priceValue isEqualToString:@"null"] && !self.presentedViewController) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UITextField *targetTextField;
        
        if ([cell isKindOfClass:[InvoiceInventProductTableViewCell class]]) {
            targetTextField = [(InvoiceInventProductTableViewCell *)cell txtAmountField];
        } else if ([cell isKindOfClass:[InvoiceInventBadProductTableViewCell class]]) {
            if (![self.selectedStore[@"StoreID"] isEqual:kMainStoreID]) {
                [AlertWorkerObjc alertWithTitle:@"Выберите основной склад"];
                return;
            }
            targetTextField = [(InvoiceInventBadProductTableViewCell *)cell txtAmountField];
        }
        
        targetTextField.enabled = YES;
        [targetTextField becomeFirstResponder];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - InvoiceInventProductTableViewCellDelegate
- (void)cellBtnQtyStoreTapped:(InvoiceInventProductTableViewCell *)sender {
    NSIndexPath *indexPath = [myTableView indexPathForCell:sender];
    NSDictionary *object = self.filteredItemsArray[indexPath.row];
    
    NSArray *stores = object[@"stores"];
    NSMutableArray *buttonsArray = [NSMutableArray new];
    for (NSDictionary *store in stores) {
        [buttonsArray addObject: [NSString stringWithFormat:@"%@ - %@шт.", store[@"StoreName"], store[@"QtyS"]]];
    }
    [buttonsArray addObject:@"Закрыть"];
    
    [AlertWorkerObjc actionSheetWithTitle:@"Склады:" message:nil sourceView:sender.btnQtyStore buttons:buttonsArray tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        
    }];
}

- (void)cellBtnExpandTapped:(InvoiceInventProductTableViewCell *)sender {
    NSIndexPath *indexPath = [myTableView indexPathForCell:sender];
    NSDictionary *object = self.filteredItemsArray[indexPath.row];
    if (![object[@"itemID"] isEqual:_expandedProductID]) {
        _expandedProductID = object[@"itemID"];
    } else {
        _expandedProductID = nil;
    }
    
    [self.view endEditing:YES];
    [self applyFilters];
}

#pragma mark - UISearchBarDelegate
- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    _didTapDeleteKey = text.length == 0;
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (![searchText isEqualToString:self.searchText]) {
        self.searchText = searchText;

        if (!_didTapDeleteKey && searchText.length == 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self applyFilters];
            });
        } else {
            [self applyFilters];
        }
        
        _didTapDeleteKey = NO;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)cancel_Clicked:(id)sender {
    searchBar.text = @"";
    self.searchText = @"";
    [searchBar resignFirstResponder];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showMark:(id)sender {
    if (self.presentedViewController) { return; }
    
    if (brandId) {
        self.custItemMarkVC.selectedBrandID = brandId;
    }
    
    if (group) {
        self.custItemMarkVC.selectedGroupID = group;
    }
    self.custItemMarkVC.filterByStatusDN = fstatusDN;
    
    self.custItemMarkVC.popoverPresentationController.barButtonItem = brandBtn;
    [self presentViewController: self.custItemMarkVC animated:YES completion:nil];
}

- (void)showStatusDN:(id)sender {
    [myTableView reloadData];
    
    if (self.presentedViewController) { return; }
    
    CustStatusDN *custStatusDN = [CustStatusDN new];
    custStatusDN.delegate = self;
    custStatusDN.visitPlan = NO;
    custStatusDN.addCust = NO;
    custStatusDN.selected = statusDNArray;
    
    custStatusDN.modalPresentationStyle = UIModalPresentationPopover;
    custStatusDN.popoverPresentationController.barButtonItem = self.statusDNBtn;
    
    [self presentViewController:custStatusDN animated:YES completion:nil];
}

- (void)markIsSelected:(NSString *)brand {
    brandId = brand;
    group = nil;
    
    [self.view endEditing:YES];
    [self applyFilters];
    
    if (self.custItemMarkVC.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self setBarButton:brandBtn highlighted:brandId != nil];
    
    if (!brand) {
        [self userDidSelectStatusDN:nil];
        self.fstatusDN = nil;
    }
}

- (void)groupIsSelected:(NSString *)groupId {
    brandId = nil;
    group = groupId;
    
    [self.view endEditing:YES];
    [self applyFilters];
    
    if (self.custItemMarkVC.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self setBarButton:brandBtn highlighted:YES];
}

- (void)closedItems:(UIButton *)sender {
    __weak typeof(self) weakSelf = self;
    NSMutableArray *actions = [NSMutableArray arrayWithCapacity:_filtersArray.count];
    
    for (NSString *filter in _filtersArray) {
        UIAction *action = [UIAction actionWithTitle:filter image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
            weakSelf.closedItems = action.title;
            
            [weakSelf.cBtn setTitle:action.title forState:UIControlStateNormal];
            [weakSelf.cBtn setHighlightedState:![self->closedItems isEqualToString:@"Все"]];
            
            [weakSelf.view endEditing:YES];
            [weakSelf applyFilters];
            
            if (weakSelf.brandId == nil && weakSelf.group == nil) {
                [weakSelf setBarButton:weakSelf.brandBtn highlighted:NO];
            }
        }];
        
        [actions addObject:action];
    }
    
    sender.menu = [sender.menu menuByReplacingChildren:actions];
}

- (void)matrixItems:(id)sender {
    isMatrix = !isMatrix;
    
    [self.view endEditing:YES];
    [self applyFilters];
    
    [self setBarButton:matrixBtn highlighted:isMatrix];
}

- (void)btnDiscountsTapped:(id)sender {
    self.discountsOnly = !self.discountsOnly;
    
    [self.view endEditing:YES];
    [self applyFilters];
    
    [self setBarButton:self.btnDiscounts highlighted:self.discountsOnly];
}

- (NSString *)totalSalesSum {
    double total = 0.0;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select LineAmount from %@ where CustAccount = ?", self.salesLineTable];
        const char *sql = sqlString.UTF8String;

        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *lineAmount = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                {
                    lineAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                    
                    total += [lineAmount doubleValue];
                }
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    return [NSString stringWithFormat:@"Итого: %0.2f руб.", total];
}

- (void)userDidSelectStatusDN:(NSMutableArray *)statusDNArray{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    statusDNArray = [statusDNArray copy];
    
    NSString *squl;
    for (NSString *statusDN in statusDNArray) {
        if ([statusDN isEqualToString:statusDNArray.firstObject]) {
            squl = [NSString stringWithFormat:@"sDNBrand.Status = '%@'", statusDN];
        } else {
            squl = [NSString stringWithFormat:@"%@ or sDNBrand.Status = '%@'", squl, statusDN];
        }
    }
    
    self.fstatusDN = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;
    
    //[self selectWithFilters];
    //[self populateSelectedArray];
    [myTableView reloadData];
    
    [self setBarButton:statusDNBtn highlighted:fstatusDN != nil];
}

#pragma mark - Helpers
- (void)applyFilters {
    NSArray *filteredArray = [self.itemsArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
        BOOL brandFilter = YES;
        if (self->brandId) {
            brandFilter = [object[@"brandID"] isEqualToString:self->brandId];
        }
        
        BOOL groupFilter = YES;
        if (self->group) {
            groupFilter = [object[@"groupID"] isEqualToString:self->group];
        }
        
        BOOL qtyFilter = NO;
        if ([self->closedItems isEqualToString:@"<=0"]) {
            qtyFilter = [object[@"qty"] integerValue] <= 0;
        } else if ([self->closedItems isEqualToString:@">0"]) {
            qtyFilter = [object[@"qty"] integerValue] > 0;
        } else {
            qtyFilter = YES;
        }
        
        BOOL matrixFilter = YES;
        if (self->isMatrix) {
            matrixFilter = [object[@"matrixID"] length] > 0;
        }
        
        BOOL discountFilter = YES;
        if (self.discountsOnly) {
            NSNumber *discount = object[@"discount"];
            NSArray *badProduct = object[@"badProduct"];
            discountFilter = discount.integerValue > 0 || badProduct.count > 0;
        }
        
        NSString *itemID = object[@"itemID"];
        
        BOOL searchFilter = YES;
        if (self.searchText.length > 0) {
            NSString *itemName = object[@"itemName"];
            searchFilter = [itemName localizedStandardContainsString:self.searchText] || [itemID localizedStandardContainsString:self.searchText];
        }
        
        if (![object[@"isBadProduct"] isEqual:@"1"]) {
            return brandFilter && groupFilter && qtyFilter && matrixFilter && discountFilter && searchFilter;
        } else {
            if (self->_expandedProductID) {
                BOOL includeBadProduct = [itemID localizedStandardContainsString:self->_expandedProductID];
                return brandFilter && groupFilter && qtyFilter && matrixFilter && discountFilter && searchFilter && includeBadProduct;
            } else {
                return NO;
            }
        }
    }]];
    
    self.filteredItemsArray = filteredArray.mutableCopy;
    [myTableView reloadData];
}

#pragma mark - Button styling methods
- (void)setBarButton:(UIBarButtonItem *)button highlighted:(BOOL)highlighted {
    [(RWBorderedButton *)button.customView setHighlightedState:highlighted];
}

@end
