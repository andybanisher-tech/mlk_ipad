//
//  CustViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "CustViewController.h"
#import "OverlayCustView.h"
#import "NewCustomerViewController.h"
#import "MoreCustViewController.h"
#import "PutClientForRouteRequest.h"
#import "RWBorderedButton.h"
#import "XMLWriter.h"
#import "PutNewCustomerRequest.h"

#import "GeneratedAssetSymbols.h"

const NSInteger SELECTION_INDICATOR_TAG = 54321;

static sqlite3 *database = nil;

@interface CustViewController ()

@end

@implementation CustViewController {
    PutClientForRouteRequest *lastSend;
}

@synthesize navigationBarTitle;
@synthesize searchBar;
@synthesize custDetList, custList, custAccList, custSendStatusList;
@synthesize selectedDate = _selectedDate;
@synthesize target = _target;
@synthesize action = _action;
@synthesize custForRoute;
@synthesize selectedArray;
@synthesize inPseudoEditMode;
@synthesize selectedImage;
@synthesize unselectedImage;
@synthesize deleteButton;
@synthesize toolbar;
@synthesize fcity, cityArray, fkey, keyArray, statusDNArray, fmark, markArray, fday, typesArray, fType;
@synthesize cityBtn, markBtn, statusDNBtn, typeBtn, keyBtn, dayBtn;
@synthesize myTableView;
@synthesize mButton;

@synthesize visitPlan, visitPlanBtn;
@synthesize additionalCusts;
@synthesize labelCustTotal;
@synthesize custPDZList;
@synthesize selectPDZ, selectPDZBtn;
@synthesize selectSalesDateSort, selectSalesDateSortBtn;
@synthesize isNotFirstLaunch;

@synthesize i;

//Andrey
@synthesize aButton;

@synthesize custAddToRouteController;

-(IBAction)doDelete {
	NSMutableArray *rowsToBeDeleted = [NSMutableArray new];
	NSMutableArray *indexPaths = [NSMutableArray new];
	
    NSDictionary *dictCustAcc  = [custAccList objectAtIndex:0];
    NSArray      *arrayCustAcc = [dictCustAcc objectForKey:@"CustAcc"];
    
    int index = 0;
	for (NSNumber *rowSelected in selectedArray)
	{
		if ([rowSelected boolValue])
		{
			[rowsToBeDeleted addObject:[arrayCustAcc objectAtIndex:index]];
			NSUInteger pathSource[2] = {0, index};
			NSIndexPath *path = [NSIndexPath indexPathWithIndexes:pathSource length:2];
			[indexPaths addObject:path];
		}		
		index++;
	}
	
	for (id value in rowsToBeDeleted)
	{
		[custAccList removeObject:value];
	}
	
	[myTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];

    inPseudoEditMode = NO;
	[self populateSelectedArray];
	[myTableView reloadData];
}

-(IBAction)toggleVisitPlan:(id)sender {    
    isNotFirstLaunch = YES;
    
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        if (view.tag == 1) {
            [view removeFromSuperview];
        }
    }
    
    [self clearFilter];
    
    selectPDZ = NO;
    [self setBarButton:selectPDZBtn highlighted:NO];
    
    if (!visitPlan) {
        visitPlan = YES;
        [self setBarButton:visitPlanBtn highlighted:YES];
    } else {
        visitPlan = NO;
        [self setBarButton:visitPlanBtn highlighted:YES];
    }
    [self loadView];
}

-(IBAction)toggleSelectPDZ:(id)sender {
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        if (view.tag == 1) {
            [view removeFromSuperview];
            [self addCustTotalLabel];
        }
    }

    if (!selectPDZ) {
        selectPDZ = YES;
        [self setBarButton:selectPDZBtn highlighted:YES];
    } else {
        selectPDZ = NO;
        [self setBarButton:selectPDZBtn highlighted:NO];
    }
   
    [self selectWithFilters];
    [self populateSelectedArray];
    [myTableView reloadData];
    [myTableView setContentOffset:CGPointZero animated:YES];
    
}

-(IBAction)toggleSelectSalesDateSort:(id)sender {
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        if (view.tag == 1) {
            [view removeFromSuperview];
            [self addCustTotalLabel];
        }
    }
    
    if (! selectSalesDateSort) {
        selectSalesDateSort = YES;
        [self setBarButton:selectSalesDateSortBtn highlighted:YES];
    } else {
        selectSalesDateSort = NO;
        [self setBarButton:selectSalesDateSortBtn highlighted:NO];
    }
    
    [self selectWithFilters];
    [self populateSelectedArray];
    [myTableView reloadData];
    [myTableView setContentOffset:CGPointZero animated:YES];
}

-(IBAction)togglePseudoEditMode:(id)sender {
    if (!inPseudoEditMode) {
        [self setBarButton:mButton highlighted:YES];

        // Andrey
        if ([custForRoute count] > 0)
            aButton.enabled = YES;
    } else {
        [self setBarButton:mButton highlighted:NO];
        // Andrey
        aButton.enabled = false;

    }
    
    self.inPseudoEditMode = !inPseudoEditMode;
	toolbar.hidden = !inPseudoEditMode;
	
	[myTableView reloadData];
	
}
- (void)populateSelectedArray{
	NSDictionary *dictCustAcc  = [custAccList objectAtIndex:0];
    NSArray      *arrayCustAcc = [dictCustAcc objectForKey:@"CustAcc"];
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[arrayCustAcc count]];
	for (int y=0; y < [arrayCustAcc count]; y++)
		[array addObject:[NSNumber numberWithBool:NO]];
	self.selectedArray = array;
}

#pragma mark - View lifecycle
#define TableViewTag 8888
- (instancetype)init {
    self = [super init];
    if (self) {
        _checkboxSelections = 0;
        _cellForRow = 0;
    }
    
    return self;
}

- (void)loadView{
    [super loadView];
    //NavBar Setup
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height)];
    [self.view addSubview:backgroundView];
    self.view.backgroundColor = UIColor.clearColor;

    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width,1.f/UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];

    [self.navigationController.navigationBar addSubview:titleView];

    UIImageView *bgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameGrayBackground]];
    [backgroundView addSubview:bgImage];
    
    bgImage.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[bgImage.leadingAnchor constraintEqualToAnchor:backgroundView.leadingAnchor],
       [bgImage.trailingAnchor constraintEqualToAnchor:backgroundView.trailingAnchor],
       [bgImage.topAnchor constraintEqualToAnchor:backgroundView.topAnchor],
       [bgImage.bottomAnchor constraintEqualToAnchor:backgroundView.bottomAnchor]]];

    custForRoute = [NSMutableArray new];
    
    [self selectAllCustomers];
    
    if (visitPlan)
        self.navigationItem.title = @"План посещений";
    else if (additionalCusts)
        self.navigationItem.title = @"Дополнительные клиенты";
    else
        self.navigationItem.title = @"Список клиентов";

    RWBorderedButton *visitPlanButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,160,30) title:@"План посещений"];
    [visitPlanButton addTarget:self
                          action:@selector(toggleVisitPlan:)
                forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *visit = [[UIBarButtonItem alloc] initWithCustomView:visitPlanButton];
    
    if (visitPlan) {
        [self setBarButton:visit highlighted:YES];
    } else {
        [self setBarButton:visit highlighted:NO];
    }
    
    if (additionalCusts) {
        visit.style = UIBarButtonItemStylePlain;
        visit.enabled = false;
        visit.image = nil;
        visit.customView.frame = CGRectZero;
        visit.tintColor = [UIColor redColor];
        [visit setBackgroundImage:[UIImage new] forState:UIControlStateDisabled barMetrics:UIBarMetricsDefault];
    }
    visitPlanBtn = visit;
    
    self.navigationItem.rightBarButtonItem = visitPlanBtn;

    if (! visitPlan && additionalCusts) {
        UIToolbar* toolsLeft = [[UIToolbar alloc] initWithFrame:CGRectMake (0, 2, 210, 40)];
        toolsLeft.barTintColor = [UIColor colorNamed:ACColorNameGrayNavBarBackground];
        toolsLeft.translucent = NO;
        toolsLeft.layer.borderWidth = 0.f;

        NSMutableArray* buttonsLeft = [[NSMutableArray alloc] initWithCapacity:3];

        UIBarButtonItem *biLeft = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        biLeft.width = 10;

        RWBorderedButton *addCustomerButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,90,30) title:@"Загрузить"];
        [addCustomerButton addTarget:self
                           action:@selector(requestCustomer:)
                 forControlEvents:UIControlEventTouchUpInside];

        UIBarButtonItem *addCustomerBarButton = [[UIBarButtonItem alloc] initWithCustomView:addCustomerButton];
        [buttonsLeft addObject:addCustomerBarButton];

        [buttonsLeft addObject:biLeft];

        RWBorderedButton *deleteCustomerButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Очистить"];
        [deleteCustomerButton addTarget:self
                              action:@selector(customerDelete:)
                    forControlEvents:UIControlEventTouchUpInside];

        UIBarButtonItem *delCustomerBarButton = [[UIBarButtonItem alloc] initWithCustomView:deleteCustomerButton];

        [buttonsLeft addObject:delCustomerBarButton];


        [toolsLeft setItems:buttonsLeft animated:NO];

        //self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolsLeft];
        self.navigationItem.leftBarButtonItems = buttonsLeft;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refresh) name:@"updateParent" object:nil];
    }
    
    //SearchBar
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 44.0, CGRectGetWidth(self.navigationController.navigationBar.frame), 50.0)];
    searchBar.barTintColor = [UIColor colorWithRed:62.0/255.0 green:63.0/255.0 blue:64.0/255.0 alpha:1];
    searchBar.delegate = self;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.placeholder = @"Поиск";
    searchBar.tintColor = UIColor.lightGrayColor;
    searchBar.searchTextField.backgroundColor = UIColor.whiteColor;
    
    searching        = NO;
	letUserSelectRow = YES;

    searchBar.layer.borderWidth = 1;

    searchBar.layer.borderColor = [[UIColor colorWithRed:62.0/255.0 green:63.0/255.0 blue:64.0/255.0 alpha:1] CGColor];
    
    UIView *sectionHeadView = [[UIView alloc] initWithFrame:CGRectMake(0, 2, CGRectGetWidth(searchBar.frame),2.f)];
    [sectionHeadView setBackgroundColor:[UIColor colorWithRed:63.0/255.0 green:64.0/255.0 blue:65.0/255.0 alpha:1]];

    UIView *top_sectionHeadView = [[UIView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(searchBar.frame),1.f/UIScreen.mainScreen.scale)];
    [top_sectionHeadView setBackgroundColor:[UIColor blackColor]];
    [sectionHeadView addSubview:top_sectionHeadView];

    UIView *bot_sectionHeadView = [[UIView alloc] initWithFrame:CGRectMake(0,1,CGRectGetWidth(searchBar.frame),1.f/UIScreen.mainScreen.scale)];
    [bot_sectionHeadView setBackgroundColor:[UIColor blackColor]];
    [sectionHeadView addSubview:bot_sectionHeadView];

    UIView *light_sectionHeadView = [[UIView alloc] initWithFrame:CGRectMake(0,1.5f,CGRectGetWidth(searchBar.frame),1.f/UIScreen.mainScreen.scale)];
    [light_sectionHeadView setBackgroundColor:[UIColor colorWithRed:109.0/255.0 green:112.0/255.0 blue:120.0/255.0 alpha:1]];
    [sectionHeadView addSubview:light_sectionHeadView];

    [searchBar addSubview:sectionHeadView];

    [self.view addSubview:searchBar];
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
    myTableView = [[UITableView alloc]initWithFrame:CGRectMake(0.0, 94.0, CGRectGetWidth(self.navigationController.navigationBar.frame), 580.0)];
    
    myTableView.delegate = self;
    myTableView.dataSource = self;
    
    myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [myTableView setBackgroundColor:UIColor.clearColor];
    [self.view addSubview:myTableView];
    
    self.inPseudoEditMode = NO;
	
	self.selectedImage = [UIImage imageNamed:ACImageNameSelected];
	self.unselectedImage = [UIImage imageNamed:ACImageNameCheckmarkGray];
	
    deleteButton.target = self;
	deleteButton.action = @selector(doDelete);
    
	[self populateSelectedArray];
    
    UIToolbar *sectionHead = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.navigationController.navigationBar.frame), 44)];
    sectionHead.barTintColor = [UIColor colorWithRed:62.0/255.0 green:63.0/255.0 blue:64.0/255.0 alpha:1];
    sectionHead.translucent = NO;

    sectionHead.layer.borderWidth = 1;

    sectionHead.layer.borderColor = [[UIColor colorWithRed:62.0/255.0 green:63.0/255.0 blue:64.0/255.0 alpha:1] CGColor];

    NSMutableArray* btns = [NSMutableArray new];
    
    // create a spacer
    UIBarButtonItem *bit = [[UIBarButtonItem alloc]
                           initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [btns addObject:bit];


    // create a standard "refresh" button
    RWBorderedButton *showCityButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Регион"];
    [showCityButton addTarget:self
                          action:@selector(showCity:)
                forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *city = [[UIBarButtonItem alloc] initWithCustomView:showCityButton];
    self.cityBtn = city;
    [btns addObject:city];
    [btns addObject:[self spacerButton]];

    RWBorderedButton *showDreamButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Статус"];
    [showDreamButton addTarget:self
                       action:@selector(showDream:)
             forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *custkey = [[UIBarButtonItem alloc] initWithCustomView:showDreamButton];
    self.keyBtn = custkey;
    [btns addObject:custkey];
    [btns addObject:[self spacerButton]];
    
    RWBorderedButton *showBrandButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Марка"];
    [showBrandButton addTarget:self
                       action:@selector(showBrand:)
             forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *mark = [[UIBarButtonItem alloc] initWithCustomView:showBrandButton];
    self.markBtn = mark;
    [btns addObject:mark];
    [btns addObject:[self spacerButton]];
    
    RWBorderedButton *showStatusDNButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,100,30) title:@"Статус DN"];
    [showStatusDNButton addTarget:self
                        action:@selector(showStatusDN:)
              forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *statusDN = [[UIBarButtonItem alloc] initWithCustomView:showStatusDNButton];
    self.statusDNBtn = statusDN;
    [self setEnabled:NO forButton:statusDNBtn];
    [btns addObject:statusDN];
    [btns addObject:[self spacerButton]];
    
    RWBorderedButton *showCustTypeButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,100,30) title:@"Тип клиента"];
    [showCustTypeButton addTarget:self
                           action:@selector(showCustomerTypes:)
                 forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *typeBarButton = [[UIBarButtonItem alloc] initWithCustomView:showCustTypeButton];
    self.typeBtn = typeBarButton;
    [btns addObject:typeBarButton];
    [btns addObject:[self spacerButton]];
    
    RWBorderedButton *showCustPDZButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,60,30) title:@"ПДЗ"];
    
    [showCustPDZButton addTarget:self
                          action:@selector(toggleSelectPDZ:)
                     forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *pdzBarButton = [[UIBarButtonItem alloc] initWithCustomView:showCustPDZButton];
    
    if (selectPDZ) {
        [self setBarButton:pdzBarButton highlighted:YES];
    } else {
        [self setBarButton:pdzBarButton highlighted:NO];
    }
    
    selectPDZBtn = pdzBarButton;
    
    [btns addObject:selectPDZBtn];
    
    UIBarButtonItem *bit2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [btns addObject:bit2];
    
    RWBorderedButton *selectSalesDateSortButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,100,30) title:@"Заказ \u21C5"];
    
    [selectSalesDateSortButton addTarget:self
                          action:@selector(toggleSelectSalesDateSort:)
                forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *salesDateBarButton = [[UIBarButtonItem alloc] initWithCustomView:selectSalesDateSortButton];
    
    if (selectSalesDateSort)
        [self setBarButton:salesDateBarButton highlighted:YES];
    else
        [self setBarButton:salesDateBarButton highlighted:NO];
    
    selectSalesDateSortBtn = salesDateBarButton;
    
    [btns addObject:selectSalesDateSortBtn];
    
    /*if (! visitPlan && ! additionalCusts) {
        //UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc]
        //        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        //[btns addObject:flexSpace];
        
        RWBorderedButton *addCustomerButton  = [RWBorderedButton buttonWithFrame:CGRectMake(90, 7, 80, 30) title:@"Новый"];
        [addCustomerButton addTarget:self
                              action:@selector(createCustomer:)
                    forControlEvents:UIControlEventTouchUpInside];
        //UIBarButtonItem *addCustomerBarButton = [[UIBarButtonItem alloc] initWithCustomView:addCustomerButton];
        //[btns addObject:addCustomerBarButton];
        [self.navigationController.navigationBar addSubview:addCustomerButton];
    }*/


    [sectionHead setItems:btns animated:NO];

    sectionHead.tintColor = [UIColor blackColor];
    
    [self.view addSubview:sectionHead];

    if (visitPlan || (! visitPlan && ! additionalCusts)) {
        [self addCustTotalLabel];
    }
    
    //Constraints
    sectionHead.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    myTableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        //Section Header
        [sectionHead.heightAnchor constraintEqualToConstant:sectionHead.bounds.size.height],
        [sectionHead.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [sectionHead.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [sectionHead.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [sectionHead.bottomAnchor constraintEqualToAnchor:searchBar.topAnchor],
        
        //SearchBar
        [searchBar.leadingAnchor constraintEqualToAnchor:sectionHead.leadingAnchor],
        [searchBar.trailingAnchor constraintEqualToAnchor:sectionHead.trailingAnchor],
        [searchBar.bottomAnchor constraintEqualToAnchor:myTableView.topAnchor],
        
        //TableView
        [myTableView.leadingAnchor constraintEqualToAnchor:sectionHead.leadingAnchor],
        [myTableView.trailingAnchor constraintEqualToAnchor:sectionHead.trailingAnchor],
        [myTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]
    ];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                             selector:@selector(didSendNewCustomerNotification:)
                                                 name:@"SendNewCustomerNotification"
                                               object:nil];
}

- (void)didSendNewCustomerNotification:(NSNotification *)notification {
    //[self refresh];
    [self performSelector:@selector(refresh) withObject:nil afterDelay:1.0];
    [SVProgressHUD dismiss];
}


- (void)addCustTotalLabel {
    labelCustTotal                           = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 80, 20)];
    labelCustTotal.tag                       = 1;
    labelCustTotal.backgroundColor           = UIColor.clearColor;
    labelCustTotal.font                      = [UIFont systemFontOfSize:16];
    labelCustTotal.adjustsFontSizeToFitWidth = NO;
    labelCustTotal.textAlignment             = NSTextAlignmentLeft;
    labelCustTotal.textColor                 = UIColor.whiteColor;
    labelCustTotal.text                      = [self totalCustSum];
    labelCustTotal.highlightedTextColor      = [UIColor blackColor];
    
    [self.navigationController.navigationBar addSubview:labelCustTotal];
    
    if (! visitPlan && ! additionalCusts) {
        for (UIView *view in self.navigationController.navigationBar.subviews) {
            if (view.tag == 2)
                [view removeFromSuperview];
        }
        
        RWBorderedButton *addCustomerButton  = [RWBorderedButton buttonWithFrame:CGRectMake(90, 7, 80, 30) title:@"Новый"];
        [addCustomerButton addTarget:self
                              action:@selector(createCustomer:)
                    forControlEvents:UIControlEventTouchUpInside];
        
        addCustomerButton.tag = 2;
        
        [self.navigationController.navigationBar addSubview:addCustomerButton];
    }
}

-(NSString*)totalCustSum{
    //NSLog(@"meth333");
    NSDictionary     *cDict     = [custAccList objectAtIndex:0];
    NSArray          *cArray    = [cDict objectForKey:@"CustAcc"];
    
    NSCalendar       *calendar  = [NSCalendar autoupdatingCurrentCalendar];
    NSDate           *currDate  = NSDate.date;
    NSDateComponents *dComp     = [calendar components:( NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay )
                                              fromDate:currDate];
    
    NSUInteger month = [dComp month];
    NSUInteger year  = [dComp year];
    
    int visited = 0;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
        
        NSString *squl;

        NSString *selectPart = @"", *fromPart = @"", *leftJoinPart = @"",*wherePart = @"";

        selectPart      = @"select LastVisitDate\n";
        fromPart        = @"from CustTable custTbl\n";
        leftJoinPart    = @"Left Join CustStatusDN custStatus on custTbl.CustAccount = custStatus.CustAccount\n";
        wherePart       = @"where 1=1 and (StatusDN = '1' or StatusDN = '2') and LastVisitDate <> ''\n";

        if (fkey) {
            //NSLog(@"fkey1");
            wherePart = [NSString stringWithFormat:@"%@ and %@",wherePart,fkey];
        }
        if (fcity) {
            wherePart = [NSString stringWithFormat:@"%@ and %@",wherePart,fcity];
        }
        if (fday) {
            wherePart = [NSString stringWithFormat:@"%@ and LVDateComp > '%@'",wherePart,fday];
        }
        if (fmark) {
            //NSLog(@"fmark");
            leftJoinPart  = [NSString stringWithFormat:@"%@ Left Join PersonalPriceList priceList on custTbl.CustAccount = priceList.CustAccount\n",leftJoinPart];
            wherePart = [NSString stringWithFormat:@"%@ and priceList.Active = '1' and %@",wherePart,fmark];
        }
        
        squl = [NSString stringWithFormat:@"%@ %@ %@ %@ order by Name",selectPart,fromPart,leftJoinPart,wherePart];
        //NSLog(@"skul - %@",squl);
        sql  = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
			while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
            	NSString *lvDate   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                {
                    lvDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                    NSDate *dateFromString = [dateFormatter dateFromString:lvDate];

                    if (dateFromString)
                    {
                        NSCalendar       *cal = [NSCalendar autoupdatingCurrentCalendar];
                        NSDateComponents *dC  = [cal components:( NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay )
                                                          fromDate:dateFromString];
                    
                        //NSLog(@"%@", [NSString stringWithFormat:@"%ld %ld", (long)[dC month], (long)[dC year]]);
                        if ([dC month] == month && [dC year] == year)
                            visited = visited + 1;
                    }
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    return [NSString stringWithFormat:@"%d/%lu", visited, (unsigned long)[cArray count]];
}


- (void)selectAllCustomers {
    NSMutableArray *custsToLiveInArray          = [NSMutableArray array];
    NSMutableArray *custDetToLiveInArray        = [NSMutableArray array];
    NSMutableArray *custAccToLiveInArray        = [NSMutableArray array];
    NSMutableArray *custSendStatusToLiveInArray = [NSMutableArray array];
    NSMutableArray *custPDZToLiveInArray        = [NSMutableArray array];
    
    custList            = [NSMutableArray new];
    custDetList         = [NSMutableArray new];
    custAccList         = [NSMutableArray new];
    custSendStatusList  = [NSMutableArray new];
    custPDZList         = [NSMutableArray new];
    
    copyCustList            = [NSMutableArray new];
    copyCustDetList         = [NSMutableArray new];
    copyCustAccList         = [NSMutableArray new];
    copyCustSendStatusList  = [NSMutableArray new];
    copyCustPDZList         = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        if (visitPlan) {
            sql = "select CustTable.CustAccount, Name, FactAddress, SendStatus, PDZAmount, Phone \n"
                    "from CustTable \n"
                    "LEFT JOIN CustStatusDN on CustTable.CustAccount = CustStatusDN.CustAccount\n"
                    "where CustStatusDN.StatusDN = '1' or CustStatusDN.StatusDN = '2'\n"
                    "order by Name asc;";
        }
        else if (additionalCusts)
            sql = "select CustAccount, Name, FactAddress, SendStatus, PDZAmount, Phone from CustTable where AdditionalCust = 1 order by Name asc";
        else
            sql = "select CustAccount, Name, FactAddress, SendStatus, PDZAmount, Phone, AdditionalCust from CustTable order by Name asc";
		
        sqlite3_stmt *selectstmt;
		
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
			while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
            	NSString *custAcc        = @"null";
                NSString *custName       = @"null";
                NSString *custAddr       = @"null";
                NSString *custSendStatus = @"null";
                NSString *pdzAmount      = @"0";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    custAddr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    custSendStatus  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    pdzAmount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                
                [custsToLiveInArray   addObject:custName];
                custName = nil;
                
                [custDetToLiveInArray addObject:custAddr];
                custAddr = nil;
                
                [custAccToLiveInArray addObject:custAcc];
                
                //if (! isNotFirstLaunch)
                //    [self updateLastSalesTPDate:custAcc];
                
                custAcc = nil;
                
                [custSendStatusToLiveInArray addObject:custSendStatus];
                custSendStatus = nil;
                
                [custPDZToLiveInArray addObject:pdzAmount];
                pdzAmount = nil;
                
                
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);

    
    NSDictionary *custsToLiveInDict             = [NSDictionary dictionaryWithObject:custsToLiveInArray forKey:@"CustName"];
    NSDictionary *custsDetToLiveInDict          = [NSDictionary dictionaryWithObject:custDetToLiveInArray forKey:@"CustAddr"];
    NSDictionary *custsAccToLiveInDict          = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    NSDictionary *custsSendStatusToLiveInDict   = [NSDictionary dictionaryWithObject:custSendStatusToLiveInArray forKey:@"CustSendStatus"];
    NSDictionary *custsPDZToLiveInDict          = [NSDictionary dictionaryWithObject:custPDZToLiveInArray forKey:@"PDZ"];
    
    [custList           addObject:custsToLiveInDict];
    [custDetList        addObject:custsDetToLiveInDict];
    [custAccList        addObject:custsAccToLiveInDict];
    [custSendStatusList addObject:custsSendStatusToLiveInDict];
    [custPDZList        addObject:custsPDZToLiveInDict];
}

- (void)userDidSelectCities:(NSMutableArray *)cities {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    cityArray = [cities copy];
    
    NSString *squl;
    for (NSString *city in cityArray) {
        if ([city isEqualToString:cityArray.firstObject]) {
            squl = [NSString stringWithFormat:@"City = '%@'", city];
        } else {
            squl = [NSString stringWithFormat:@"%@ or City = '%@'", squl, city];
        }
    }
    
    fcity = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;
    
    [self selectWithFilters];
    [self populateSelectedArray];
    [myTableView reloadData];

    [self setBarButton:cityBtn highlighted:fcity != nil];
}

- (void)userDidSelectBrand:(NSMutableArray *)brandArray{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    markArray = [brandArray copy];
    
    NSString *squl;
    for (NSString *mark in markArray) {
        if ([mark isEqualToString:markArray.firstObject]) {
            squl = [NSString stringWithFormat:@"priceList.BrandId = '%@'", mark];
        } else {
            squl = [NSString stringWithFormat:@"%@ or priceList.BrandId = '%@'", squl, mark];
        }
    }
    
    fmark = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;
    
    if (markArray.count == 1) {
        [self setEnabled:YES forButton:statusDNBtn];
    } else {
        statusDNArray = nil;
        self.fstatusDN = nil;
        [self setBarButton:statusDNBtn highlighted:NO];
        [self setEnabled:NO forButton:statusDNBtn];
    }

    [self selectWithFilters];
    [self populateSelectedArray];
    [myTableView reloadData];

    [self setBarButton:markBtn highlighted:fmark != nil];
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
    
    [self selectWithFilters];
    [self populateSelectedArray];
    [myTableView reloadData];
    
    [self setBarButton:statusDNBtn highlighted:self.fstatusDN != nil];
}

#pragma mark - CustomerTypesTableViewControllerDelegate
- (void)userDidSelectCustomerTypes:(NSArray *)selectedTypes {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    typesArray = [selectedTypes copy];

    NSString *squl;
    for (NSDictionary *type in typesArray) {
        if ([type isEqual:typesArray.firstObject]) {
            squl = [NSString stringWithFormat:@"Property6 = '%@'", type[@"property6"]];
        } else {
            squl = [NSString stringWithFormat:@"%@ or Property6 = '%@'", squl, type[@"property6"]];
        }
    }
    
    fType = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;
    
    [self selectWithFilters];
    [self populateSelectedArray];
    [myTableView reloadData];

    [self setBarButton:typeBtn highlighted:fType != nil];
}

- (void)userDidSelectDream:(NSMutableArray *)dreamArray{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    keyArray = [dreamArray copy];
    
    NSString *squl;
    for (NSString *dream in dreamArray) {
        if ([dream isEqualToString:dreamArray.firstObject]) {
            squl = [NSString stringWithFormat:@"StatusDN = '%@'", dream];
        } else {
            squl = [NSString stringWithFormat:@"%@ or StatusDN = '%@'", squl, dream];
        }
    }
    
    fkey = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;
    
    [self selectWithFilters];
    [self populateSelectedArray];
    [myTableView reloadData];

    [self setBarButton:keyBtn highlighted:fkey != nil];
}

- (void)selectWithFilters {
    NSMutableArray *custsToLiveInArray          = [NSMutableArray array];
    NSMutableArray *custDetToLiveInArray        = [NSMutableArray array];
    NSMutableArray *custAccToLiveInArray        = [NSMutableArray array];
    NSMutableArray *custSendStatusToLiveInArray = [NSMutableArray array];
    NSMutableArray *custPDZToLiveInArray        = [NSMutableArray array];
    
    custList            = [NSMutableArray new];
    custDetList         = [NSMutableArray new];
    custAccList         = [NSMutableArray new];
    custSendStatusList  = [NSMutableArray new];
    custPDZList         = [NSMutableArray new];
    
    copyCustList            = [NSMutableArray new];
    copyCustDetList         = [NSMutableArray new];
    copyCustAccList         = [NSMutableArray new];
    copyCustSendStatusList  = [NSMutableArray new];
    copyCustPDZList         = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        NSString *squl;
        
        //NSLog(@"w fil");
        NSString *selectPart = @"", *fromPart = @"", *leftJoinPart = @"", *wherePart = @"";
        if (visitPlan) {
            selectPart      = @"select distinct custTbl.CustAccount, custTbl.Name, custTbl.FactAddress, custTbl.SendStatus, custTbl.PDZAmount, custTbl.Phone\n";
            fromPart        = @"from CustTable custTbl\n";
            leftJoinPart    = @"Left Join CustStatusDN custStatus on custTbl.CustAccount = custStatus.CustAccount\n";
            wherePart       = @"Where (StatusDN = '1' or StatusDN = '2')";
        }
        else if (additionalCusts) {
            selectPart  = @"select distinct custTbl.CustAccount, custTbl.Name, custTbl.FactAddress, custTbl.SendStatus, custTbl.PDZAmount, custTbl.Phone\n";
            fromPart    = @"from CustTable custTbl\n";
            wherePart   = @"where 1=1 and AdditionalCust = '1'";
        } else {
            selectPart  = @"select distinct custTbl.CustAccount, custTbl.Name, custTbl.FactAddress, custTbl.SendStatus, custTbl.PDZAmount, custTbl.Phone\n";
            fromPart    = @"from CustTable custTbl\n";
            wherePart   = @"where 1=1";
        }

        if (fkey && !visitPlan) {
            //NSLog(@"select");
            
            leftJoinPart    = [NSString stringWithFormat:@"%@ Left Join CustStatusDN custStatus on custTbl.CustAccount = custStatus.CustAccount\n",leftJoinPart];
            wherePart       = [NSString stringWithFormat:@"%@ and %@",wherePart,fkey];
        }
        if (fcity) {
            wherePart = [NSString stringWithFormat:@"%@ and %@",wherePart,fcity];
        }
        if (fday) {
            wherePart = [NSString stringWithFormat:@"%@ and LVDateComp > '%@'",wherePart,fday];
        }
        if (fmark) {
            leftJoinPart  = [NSString stringWithFormat:@"%@ Left Join PersonalPriceList priceList on custTbl.CustAccount = priceList.CustAccount\n",leftJoinPart];
            
            if (self.fstatusDN) {
                leftJoinPart = [NSString stringWithFormat:@"%@ Join CustStatusDNBrand sDNBrand on (custTbl.CustAccount = sDNBrand.CustAccount and priceList.BrandId = sDNBrand.BrandId)\n", leftJoinPart];
            }
            wherePart = [NSString stringWithFormat:@"%@ and priceList.Active = '1' and %@",wherePart,fmark];
            
            if (self.fstatusDN) {
                wherePart = [NSString stringWithFormat:@"%@ and %@",wherePart,self.fstatusDN];
            }
        }

        if (fType) {
            wherePart = [NSString stringWithFormat:@"%@ and %@", wherePart, fType];
        }
        
        if (selectPDZ)
            wherePart = [NSString stringWithFormat:@"%@ and PDZAmount != '0'",wherePart];
        
        if (!selectSalesDateSort)
            squl = [NSString stringWithFormat:@"%@ %@ %@ %@ order by Name",selectPart,fromPart,leftJoinPart,wherePart];
        else
            squl = [NSString stringWithFormat:@"%@ %@ %@ %@ order by SalesDateSort desc",selectPart,fromPart,leftJoinPart,wherePart];
        
        sql = [squl UTF8String];
        
        //NSLog(@"%@", squl);
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
		    while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *custAcc        = @"null";
                NSString *custName       = @"null";
                NSString *custAddr       = @"null";
                NSString *custSendStatus = @"null";
                NSString *pdzAmount      = @"0";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    custAddr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    custSendStatus  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    pdzAmount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                [custsToLiveInArray          addObject:custName];
                [custDetToLiveInArray        addObject:custAddr];
                [custAccToLiveInArray        addObject:custAcc];
                [custSendStatusToLiveInArray addObject:custSendStatus];
                [custPDZToLiveInArray        addObject:pdzAmount];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *custsToLiveInDict             = [NSDictionary dictionaryWithObject:custsToLiveInArray forKey:@"CustName"];
    NSDictionary *custsDetToLiveInDict          = [NSDictionary dictionaryWithObject:custDetToLiveInArray forKey:@"CustAddr"];
    NSDictionary *custsAccToLiveInDict          = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    NSDictionary *custsSendStatusToLiveInDict   = [NSDictionary dictionaryWithObject:custSendStatusToLiveInArray forKey:@"CustSendStatus"];
    NSDictionary *custsPDZToLiveInDict          = [NSDictionary dictionaryWithObject:custPDZToLiveInArray forKey:@"PDZ"];
    
    [custList           addObject:custsToLiveInDict];
    [custDetList        addObject:custsDetToLiveInDict];
    [custAccList        addObject:custsAccToLiveInDict];
    [custSendStatusList addObject:custsSendStatusToLiveInDict];
    [custPDZList        addObject:custsPDZToLiveInDict];
    

    for (UIView *view in self.navigationController.navigationBar.subviews) {
        if (view.tag == 1) {
            [view removeFromSuperview];
            [self addCustTotalLabel];
        }
    }
}

- (void)showCity:(id)sender {
    [myTableView reloadData];
    
    if (self.presentedViewController) { return; }
    CustCity *custCity = [[CustCity alloc] init];
    custCity.delegate = self;
    custCity.visitPlan = visitPlan;
    custCity.addCust = additionalCusts;
    custCity.selected = cityArray;
    
    custCity.modalPresentationStyle = UIModalPresentationPopover;
    custCity.popoverPresentationController.barButtonItem = self.cityBtn;
    
    [self presentViewController:custCity animated:YES completion:nil];
}

- (void)showBrand:(id)sender {
    [myTableView reloadData];
    
    if (self.presentedViewController) { return; }
    CustBrand *custBrand = [CustBrand new];
    custBrand.delegate = self;
    custBrand.visitPlan = visitPlan;
    custBrand.addCust = additionalCusts;
    custBrand.selected = markArray;
    
    custBrand.modalPresentationStyle = UIModalPresentationPopover;
    custBrand.popoverPresentationController.barButtonItem = self.markBtn;
    
    [self presentViewController:custBrand animated:YES completion:nil];
}

- (void)showStatusDN:(id)sender {
    [myTableView reloadData];
    
    if (self.presentedViewController) { return; }
    CustStatusDN *custStatusDN = [CustStatusDN new];
    custStatusDN.delegate = self;
    custStatusDN.visitPlan = visitPlan;
    custStatusDN.addCust = additionalCusts;
    custStatusDN.selected = statusDNArray;
    
    custStatusDN.modalPresentationStyle = UIModalPresentationPopover;
    custStatusDN.popoverPresentationController.barButtonItem = self.statusDNBtn;
    
    [self presentViewController:custStatusDN animated:YES completion:nil];
}

- (void)showCustomerTypes:(id)sender {
    [myTableView reloadData];

    if (self.presentedViewController) { return; }
    CustomerTypesTableViewController *customerTypesVC = [CustomerTypesTableViewController new];
    customerTypesVC.delegate = self;
    customerTypesVC.selectedTypesArray = typesArray.mutableCopy;
    
    customerTypesVC.modalPresentationStyle = UIModalPresentationPopover;
    customerTypesVC.popoverPresentationController.barButtonItem = typeBtn;
    [self presentViewController:customerTypesVC animated:YES completion:nil];
}

- (void)showDream:(id)sender {
    [myTableView reloadData];
    
    if (self.presentedViewController) { return; }
    CustDream *custDream = [CustDream new];
    custDream.delegate = self;
    custDream.visitPlan = visitPlan;
    custDream.addCust = additionalCusts;
    custDream.selected = keyArray;
    
    custDream.modalPresentationStyle = UIModalPresentationPopover;
    custDream.popoverPresentationController.barButtonItem = self.keyBtn;
    
    [self presentViewController:custDream animated:YES completion:nil];
}

- (void)selectDay:(id)sender {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self visitDay:sender];
    
    dayBtn = sender;
    
    UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
    [dayBtn setTintColor:color];
}

-(IBAction)visitDay:(id)sender {
    [myTableView reloadData];
    
    [AlertWorkerObjc actionSheetWithTitle:nil message:nil sourceView:sender buttons:@[@"Неделя", @"Месяц",  @"Квартал", @"Полугодие", @"Задать", @"Убрать фильтр"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if ([action.title isEqual:@"Убрать фильтр"]) {
            self->fday = nil;
            [self selectWithFilters];
            [self->myTableView reloadData];
            
            [self->dayBtn setTintColor:UIColor.clearColor];
        } else {
            if ([action.title isEqual:@"Неделя"]) {
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*7];
                
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                self->fday = [dateFormatter stringFromDate:dateY];
                
                [self selectWithFilters];
                [self->myTableView reloadData];
            }
            
            if ([action.title isEqual:@"Месяц"]) {
                
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*30];
                
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                self->fday = [dateFormatter stringFromDate:dateY];
                
                [self selectWithFilters];
                [self->myTableView reloadData];
            }
            
            if ([action.title isEqual:@"Квартал"]) {
                
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*90];
                
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                self->fday = [dateFormatter stringFromDate:dateY];
                
                [self selectWithFilters];
                [self->myTableView reloadData];
            }
            
            if ([action.title isEqual:@"Полугодие"]) {
                
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*180];
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                self->fday = [dateFormatter stringFromDate:dateY];
                
                [self selectWithFilters];
                [self->myTableView reloadData];
            }
            
            if ([action.title isEqual:@"Задать"]) {
                UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"Введите кол-во дней"  message:@"дни визита" preferredStyle:UIAlertControllerStyleAlert];
                
                
                [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.keyboardType = UIKeyboardTypePhonePad;
                    [textField becomeFirstResponder];
                }];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*[alertVC.textFields.firstObject.text doubleValue]];
                    
                    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                    
                    self->fday = [dateFormatter stringFromDate:dateY];
                    
                    [self selectWithFilters];
                    [self populateSelectedArray];
                    [self->myTableView reloadData];
                }];
                
                [alertVC addAction:okAction];
                
                [self presentViewController:alertVC animated:YES completion:nil];
            }
        }
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (void)clearFilter {
    NSString *searchText = searchBar.text;

    fcity = nil;
    fkey  = nil;
    fmark = nil;
    fType = nil;
    fday  = nil;
    
    cityArray = nil;
    markArray = nil;
    typesArray = nil;
    keyArray = nil;
    statusDNArray = nil;
    
    [self selectAllCustomers];
    [self populateSelectedArray];
    [myTableView reloadData];
    
    searchBar.text = searchText;
}

- (void)selectDate:(id)sender {
    // Andrey +
    BOOL isStop = [self IsStop];
    
    if (isStop==YES) {
        [AlertWorkerObjc alertWithTitle:@"Маршрут закончен"];
        return;
    }
    // Andrey -
    
    if (inPseudoEditMode) {
        if (self.presentedViewController) { return; }
        ASPDatePickerViewController *datePickerVC = [ASPDatePickerViewController new];
        datePickerVC.delegate = self;
        datePickerVC.modalPresentationStyle = UIModalPresentationPopover;
        datePickerVC.popoverPresentationController.barButtonItem = aButton;
        [self presentViewController:datePickerVC animated:YES completion:nil];
    }
}

#pragma mark - ASPDatePickerViewControllerDelegate
- (void)datePickerDidCancel {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)datePickerDidPickDate:(NSDate *)date {
    [self datePickerDidCancel];
    
    self.selectedDate = date;
    
    buttonTapped        = FALSE;
    _checkboxSelections = 0;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat_dd_MM_YYYY];
    NSString *strDate = [formatter stringFromDate:self.selectedDate];
    
    if (!self.selectedDate) {
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;
        
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        strDate = [dateFormatter stringFromDate:date];
    }
    
    for (int y = 0; y < [custForRoute count]; y++) {
        NSString *custAccount = [custForRoute objectAtIndex:y];
        NSString *custName    = @"null";
        NSString *custAddr    = @"null";
        
        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            const char *sql = "select Name, FactAddress from CustTable where CustAccount = ?";
           
            sqlite3_stmt *selectstmt;
            
            if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
                if (sqlite3_step(selectstmt) == SQLITE_ROW )
                {
                    if (sqlite3_column_text(selectstmt, 0))
                        custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                        
                    if (sqlite3_column_text(selectstmt, 1))
                        custAddr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                }
            }
            sqlite3_finalize(selectstmt);
            sqlite3_close(database);
        }
        else
            sqlite3_close(database);
        
        [self addCustomersToRoute:custAccount custName:custName custAddr:custAddr strDate:strDate];
    }
    [self populateSelectedArray];
    [myTableView reloadData];
    
    [self togglePseudoEditMode:mButton];
}

-(int)getCustInRouteCount:(NSString *)strDate {
    int custInRout = 0;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select count(*) from CustForRoute where DateOfRoute = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW )
                custInRout  = sqlite3_column_int(statement, 0); 
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);

    
    return custInRout;
}

- (void)addCustomerToRouteDB:(NSString *)custAccount custName:(NSString *)custName custAddr:(NSString *)custAddress strDate:(NSString *)strDate {
    int lineNum = [self getCustInRouteCount:strDate];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "replace into CustForRoute (CustAccount, DateOfRoute, RegularRoute, CustName, GPSPoint, lineNum, GPSRequest, isSended) Values(?, ?, ?, ?, ?, ?, ?, ?)";
        sqlite3_stmt *addStmt;

        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(addStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [@"No" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [custName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [custAddress UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [strLineNum UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(addStmt, 8, 0);
            
            sqlite3_step(addStmt);
            sqlite3_finalize(addStmt);
        }
    }
    sqlite3_close(database);
}

- (void)addCustomersToRoute:(NSString *)custAccount custName:(NSString *)custName custAddr:(NSString *)custAddress strDate:(NSString *)strDate {
    if (lastSend) {
        lastSend = nil;
    }
    
    lastSend = [[PutClientForRouteRequest alloc] init];
    lastSend.custAccount = custAccount;
    lastSend.date = strDate;
    lastSend.custAddress = custAddress;
    lastSend.custName = custName;
    lastSend.forDelete = NO;
    lastSend.delegate = self;
    lastSend.notShowProgress = YES;
    [self addCustomerToRouteDB:custAccount custName:custName custAddr:custAddress strDate:strDate];
    [lastSend sendCust];
}

- (void)isSended:(NSString *)custAccount custName:(NSString *)custName custAddr:(NSString *)custAddress strDate:(NSString *)strDate {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        
        const char *sql = "update CustForRoute Set isSended = ? where CustAccount = ? and DateOfRoute = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_int(updateStmt, 1, 1);
        sqlite3_bind_text(updateStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(updateStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        
        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

- (void)removeCustomersFromRoute:(NSString *)custAccount {
    if (lastSend) {
        lastSend = nil;
    }
    
    lastSend = [[PutClientForRouteRequest alloc] init];
    lastSend.custAccount = custAccount;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat_dd_MM_YYYY];
    NSString *strDate = [formatter stringFromDate:self.selectedDate];
    lastSend.date = strDate;
    lastSend.forDelete = YES;
    lastSend.notShowProgress = YES;
    lastSend.delegate = self;
    [self removeCustomerFromRouteDB:custAccount];
    [lastSend sendCust];
}

- (void)removeCustomerFromRouteDB:(NSString *)custAccount {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *deleteStmt;
        
        const char *sql = "update CustForRoute Set isSended = ?, IsDeleted = ? where CustAccount = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        //When binding parameters, index starts from 1 and not zero.
        sqlite3_bind_int(deleteStmt, 1, 0);
        sqlite3_bind_int(deleteStmt, 2, 1);
        sqlite3_bind_text(deleteStmt, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

- (void)isSendedForDelete:(NSString *)custAccount {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *deleteStmt;
        
        const char *sql = "delete from CustForRoute where CustAccount = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        //When binding parameters, index starts from 1 and not zero.
        sqlite3_bind_text(deleteStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
    }
    
    sqlite3_close(database);
}


- (void)selectForMark{
    if (buttonTapped) {
        buttonTapped        = FALSE;
        _checkboxSelections = 0;
    } else {
        buttonTapped = YES;
    }
    
    [custForRoute removeAllObjects];
    [myTableView reloadData];
}

- (void)dealloc {
    lastSend.delegate = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"SendNewCustomerNotification" object:nil];
}

#pragma mark -
#pragma mark Managing the popover

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    if (searching)
	{
		return 1;
	}
	else
	{
		if ([custList count] == 0)
            return 1;
        else
            return [custList count];
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (searching)
	{
		return [copyCustList count];
	}
	else 
	{
		//Number of rows it should expect should be based on the section
		NSDictionary *dictionary = [custList objectAtIndex:section];
		NSArray		 *array = [dictionary objectForKey:@"CustName"];
		
		return [array count];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (searching)
	{
		return @"Результаты поиска";
	}
	else
	{
		return @"Клиенты";	
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
		UILabel *label = [[UILabel alloc] initWithFrame:kLabelRect]; //CGRectMake(15.0, 0.0, 500.0, 20.0)
		label.tag = kCellLabelTag; //1001
		[cell.contentView addSubview:label];

        UILabel *detailLabel = [[UILabel alloc] initWithFrame:kDetailLabelRect]; //CGRectMake(15.0, 20.0, 500.0, 20.0)
		detailLabel.tag = kCellDetailLabelTag; //1002
        detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        detailLabel.numberOfLines = 0;
		[cell.contentView addSubview:detailLabel];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:unselectedImage];
		imageView.frame = CGRectMake(5.0, 0.0, 23.0, 23.0);
		[cell.contentView addSubview:imageView];
		imageView.hidden = !inPseudoEditMode;
		imageView.tag = kCellImageViewTag; //1000

        /*UILabel *tasksCount = [[UILabel alloc]initWithFrame:CGRectMake(10, 15, 20, 20)];
        tasksCount.backgroundColor = UIColor.clearColor;
        tasksCount.textColor = [ASPFunctions colorFromHex:@"d1d1d1"];
        tasksCount.tag = 2001;
        [tasksCount setTextAlignment:NSTextAlignmentCenter];
        tasksCount.font = [UIFont boldSystemFontOfSize:14];
        //tasksCount.text = @"";
        tasksCount.hidden = YES;
        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(640, 0, 40, 50)];
        container.tag = 2002;
        [container addSubview:tasksCount];
        [cell.contentView addSubview:container];*/

        RWBorderedButton *taskCount      = [RWBorderedButton buttonWithFrame:CGRectMake(650, 7, 40, 35) title:@""];
        [taskCount setBackgroundColor:[UIColor darkGrayColor]];
        taskCount.tag                    = 2001;
        taskCount.layer.cornerRadius     = 5;
        taskCount.clipsToBounds          = YES;
        taskCount.titleLabel.textColor   = UIColor.whiteColor;
        taskCount.userInteractionEnabled = NO;
        [cell.contentView addSubview:taskCount];
        
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0,50.f-1.f/UIScreen.mainScreen.scale,CGRectGetWidth(tableView.frame),1.f/UIScreen.mainScreen.scale)];
        [separator setBackgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground]];
        [cell.contentView addSubview:separator];
        
        RWBorderedButton* sendStatusButton = [RWBorderedButton buttonWithFrame:CGRectMake(520.0, 7.0, 125.0, 35.0) title:@""];
        sendStatusButton.tag = 150;
        [sendStatusButton setBackgroundColor:[UIColor redColor]];
        sendStatusButton.layer.cornerRadius = 5;
        sendStatusButton.clipsToBounds = YES;
        [sendStatusButton addTarget:self action:@selector(showAlertAboutNotSendedNewCusts) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:sendStatusButton];
        
        //UILabel *dateOfSales = [[UILabel alloc] initWithFrame:kDateOfSaleRect];
        //dateOfSales.tag = kCellDateOfSaleTag; //1003
        //[cell.contentView addSubview:dateOfSales];
        
        RWBorderedButton *dateOfSalesButton = [RWBorderedButton buttonWithFrame:kDateOfSaleRect title:@""];
        dateOfSalesButton.tag = kCellDateOfSaleTag;
        //[dateOfSalesButton setBackgroundColor:[UIColor colorWithRed:213.0/255.0 green:83.0/255.0 blue:83.0/255.0 alpha:1]];
        dateOfSalesButton.layer.cornerRadius = 5;
        dateOfSalesButton.clipsToBounds = YES;
        dateOfSalesButton.titleLabel.textColor = UIColor.whiteColor;
        dateOfSalesButton.userInteractionEnabled = NO;
        [cell.contentView addSubview:dateOfSalesButton];
    }
    
    [cell setBackgroundView:nil];
    [cell setBackgroundColor:UIColor.clearColor];

    UILabel *label = (UILabel *)[cell.contentView viewWithTag:kCellLabelTag];
    UILabel *detailLabel = (UILabel *)[cell.contentView viewWithTag:kCellDetailLabelTag];
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kCellImageViewTag];
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        label.frame = (self->inPseudoEditMode) ? kLabelIndentedRect : kLabelRect;
        label.opaque = NO;
        
        detailLabel.textColor = UIColor.lightGrayColor;
        detailLabel.frame = (self->inPseudoEditMode) ? kDetailLabelIndentedRect : kDetailLabelRect;
        detailLabel.opaque = NO;
        
        NSNumber *selected = [self->selectedArray objectAtIndex:[indexPath row]];
        imageView.image = ([selected boolValue]) ? self->selectedImage : self->unselectedImage;
        imageView.hidden = !self->inPseudoEditMode;
        
    } completion:nil];
    
    RWBorderedButton *sendStatusButton  = (RWBorderedButton *)[cell.contentView viewWithTag:150];
    RWBorderedButton *dateOfSalesButton = (RWBorderedButton *)[cell.contentView viewWithTag:kCellDateOfSaleTag];
    RWBorderedButton *taskCount         = (RWBorderedButton *)[cell.contentView viewWithTag:2001];
    
    if (searching) {
        if ([copyCustList count] > 0) {
            NSString *cellValue	   = [copyCustList objectAtIndex:indexPath.row];
        
            NSString *cellValueDet = [copyCustDetList objectAtIndex:indexPath.row];
            
            NSString		*custSendStatusValue = [copyCustSendStatusList objectAtIndex:indexPath.row];
        
            label.text = cellValue;
            detailLabel.text = cellValueDet;
            
            NSString *cellCustAcc = [copyCustAccList objectAtIndex:indexPath.row];

            NSString *lastSalesDate = [self getLastSalesDate:cellCustAcc];
            
            NSString *pdzValue = [copyCustPDZList objectAtIndex:indexPath.row];
            
            if (! [pdzValue isEqualToString:@"0"])
                label.text = [NSString stringWithFormat:@"\u2757 %@", cellValue];
            
            NSInteger count = [self custTasksCount:[copyCustAccList objectAtIndex:indexPath.row]];
            
            if (count > 0) {
                //UIView *container = (UIView *)[cell.contentView viewWithTag:2002];
                //UILabel *tasksCount = (UILabel *)[container viewWithTag:2001];
                //tasksCount.text = [NSString stringWithFormat:@"%d", count];
                //tasksCount.hidden = NO;
                [taskCount setTitle:[NSString stringWithFormat:@"%ld", (long)count] forState:UIControlStateNormal];
                taskCount.hidden = NO;
            } else {
                //UIView *container = (UIView *)[cell.contentView viewWithTag:2002];
                //UILabel *tasksCount = (UILabel *)[container viewWithTag:2001];
                //tasksCount.text = @"";
                //tasksCount.hidden = YES;
                [taskCount setTitle:@"" forState:UIControlStateNormal];
                taskCount.hidden = YES;
            }
            
            if (visitPlan) {
                if ([self custWasVisited:[copyCustAccList objectAtIndex:indexPath.row]])
                {
                    UIColor *mycolor= [UIColor colorWithRed:109.0/255.0 green:236.0/255.0 blue:143.0/255.0 alpha:1.0];
                    cell.backgroundColor        = mycolor;
                    label.backgroundColor       = mycolor;
                    detailLabel.backgroundColor = mycolor;
                } else {
                    cell.backgroundColor = UIColor.clearColor;
                    // Andrey
                    label.backgroundColor = UIColor.clearColor;
                    detailLabel.backgroundColor = UIColor.clearColor;
                }
            }
            
            if (custSendStatusValue != nil && ![custSendStatusValue isEqualToString:@"null"]) {
                NSString* title = @"Не отправлен";
                UIColor* color = [UIColor redColor];
                BOOL isUserInteractionEnabled = YES;
                
                if ([custSendStatusValue isEqualToString:@"Sended"])
                {
                    title = @"Отправлен";
                    color = [ASPFunctions colorFromHex:@"7de77a"];
                    isUserInteractionEnabled = NO;
                    
                }
                [sendStatusButton setTitle:title forState:UIControlStateNormal];
                [sendStatusButton setBackgroundColor:color];
                [sendStatusButton setUserInteractionEnabled:isUserInteractionEnabled];
                [sendStatusButton setHidden:NO];
                [dateOfSalesButton setHidden:YES];
                //dateOfSales.hidden = YES;
            } else {
                [sendStatusButton setHidden:YES];
                [dateOfSalesButton setHidden:NO];
                //dateOfSales.hidden = NO;
            }
            
            if ([lastSalesDate isEqualToString:@"null"])
                [dateOfSalesButton setHidden:YES];
            else
            {
                if (! [self isLastSalesTP:cellCustAcc])
                    dateOfSalesButton.backgroundColor = UIColor.clearColor;
                else
                    [dateOfSalesButton setBackgroundColor:[UIColor colorWithRed:213.0/255.0 green:83.0/255.0 blue:83.0/255.0 alpha:1]];
                
                [dateOfSalesButton setTitle:lastSalesDate forState:UIControlStateNormal];
            }
        }
    } else {
        NSDictionary	*dictionary = [custList objectAtIndex:indexPath.section];
        NSArray			*array		= [dictionary objectForKey:@"CustName"];
        NSString		*cellValue	= [array objectAtIndex:indexPath.row];
        
        NSDictionary	*dictionaryDet  = [custDetList objectAtIndex:indexPath.section];
        NSArray			*arrayDet		= [dictionaryDet objectForKey:@"CustAddr"];
        NSString		*cellValueDet	= [arrayDet objectAtIndex:indexPath.row];
        
        NSDictionary	*dictCustAcc    = [custAccList objectAtIndex:indexPath.section];
        NSArray			*arrayCustAcc	= [dictCustAcc objectForKey:@"CustAcc"];
        NSString		*cellCustAcc	= [arrayCustAcc objectAtIndex:indexPath.row];
        
        label.text = cellValue;
        detailLabel.text = cellValueDet;
        
        NSDictionary	*custPDZDict  = [custPDZList objectAtIndex:0];
        NSArray			*custPDZArray = [custPDZDict objectForKey:@"PDZ"];
        NSString		*custPDZValue = [custPDZArray objectAtIndex:indexPath.row];

        if (! [custPDZValue isEqualToString:@"0"])
            label.text = [NSString stringWithFormat:@"\u2757 %@", cellValue];
        
        NSDictionary	*custDict  = [custAccList objectAtIndex:0];
        NSArray			*custArray = [custDict objectForKey:@"CustAcc"];
        NSString		*custValue = [custArray objectAtIndex:indexPath.row];
        
        NSDictionary	*custSendStatusDict  = [custSendStatusList objectAtIndex:0];
        NSArray			*custSendStatusArray = [custSendStatusDict objectForKey:@"CustSendStatus"];
        NSString		*custSendStatusValue = [custSendStatusArray objectAtIndex:indexPath.row];

        NSString        *lastSalesDate = [self getLastSalesDate:cellCustAcc];
        
        if (custSendStatusValue != nil && ![custSendStatusValue isEqualToString:@"null"]) {
            NSString* title = @"Не отправлен";
            UIColor* color = [UIColor redColor];
            BOOL isUserInteractionEnabled = YES;
            
            if ([custSendStatusValue isEqualToString:@"Sended"]) {
                title = @"Отправлен";
                color = [ASPFunctions colorFromHex:@"7de77a"];
                isUserInteractionEnabled = NO;
                
            }
            [sendStatusButton setTitle:title forState:UIControlStateNormal];
            [sendStatusButton setBackgroundColor:color];
            [sendStatusButton setUserInteractionEnabled:isUserInteractionEnabled];
            [sendStatusButton setHidden:NO];
            [dateOfSalesButton setHidden:YES];
            //dateOfSales.hidden = YES;
        } else {
            [sendStatusButton setHidden:YES];
            [dateOfSalesButton setHidden:NO];
            //dateOfSales.hidden = NO;
        }
        
        NSInteger count = [self custTasksCount:custValue];
        if (count > 0) {
            //UIView *container = (UIView *)[cell.contentView viewWithTag:2002];
            //UILabel *tasksCount = (UILabel *)[container viewWithTag:2001];
            //tasksCount.text = [NSString stringWithFormat:@"%d", count];
            //tasksCount.hidden = NO;
            [taskCount setTitle:[NSString stringWithFormat:@"%ld", (long)count] forState:UIControlStateNormal];
            taskCount.hidden = NO;
        } else {
            //UIView *container = (UIView *)[cell.contentView viewWithTag:2002];
            //UILabel *tasksCount = (UILabel *)[container viewWithTag:2001];
            //tasksCount.text = @"";
            //tasksCount.hidden = YES;
            [taskCount setTitle:@"" forState:UIControlStateNormal];
            taskCount.hidden = YES;
        }
        
        if (visitPlan) {
            NSDictionary	*custDict  = [custAccList objectAtIndex:0];
            NSArray			*custArray = [custDict objectForKey:@"CustAcc"];
            NSString		*custValue = [custArray objectAtIndex:indexPath.row];
            
            if ([self custWasVisited:custValue]) {
                UIColor *mycolor = [UIColor colorWithRed:109.0/255.0 green:236.0/255.0 blue:143.0/255.0 alpha:1.0];
                cell.backgroundColor        = mycolor;
                label.backgroundColor       = mycolor;
                detailLabel.backgroundColor = mycolor;
            } else {
                cell.backgroundColor = UIColor.clearColor;
                // Andrey
                label.backgroundColor       = UIColor.clearColor;
                detailLabel.backgroundColor = UIColor.clearColor;
            }
        }
        
        if ([lastSalesDate isEqualToString:@"null"])
            [dateOfSalesButton setHidden:YES];
        else
        {
            if (! [self isLastSalesTP:cellCustAcc])
                dateOfSalesButton.backgroundColor = UIColor.clearColor;
            else
                [dateOfSalesButton setBackgroundColor:[UIColor colorWithRed:213.0/255.0 green:83.0/255.0 blue:83.0/255.0 alpha:1]];
        
            [dateOfSalesButton setTitle:lastSalesDate forState:UIControlStateNormal];
        }
    }
    
    return cell;
}

- (NSInteger)custTasksCount:(NSString*)custAccount {
    NSInteger countTasks = 0;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        sql = "select count(TaskId) from TaskTable where CustAccount = ? and (Status = 'Открытая' or Status = 'В работе')";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
			sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                if (sqlite3_column_text(selectstmt, 0))
                {
                    countTasks = sqlite3_column_int(selectstmt, 0);
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    return countTasks;
}

-(BOOL)custWasVisited:(NSString*)custAcc {
    NSCalendar       *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate           *currDate = NSDate.date;
    NSDateComponents *dComp = [calendar components:( NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay )
                                          fromDate:currDate];
    
    NSUInteger month = [dComp month];
    NSUInteger year  = [dComp year];
    
    BOOL visited = FALSE;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        NSString *squl;
//        sql = "select LastVisitDate from CustTable where CustAccount = ? and exists(select * from CustStatusDN where CustTable.CustAccount == CustStatusDN.CustAccount and (StatusDN = '1' or StatusDN = '2')) order by Name asc";
        squl = @"select LastVisitDate \n"
                "from CustTable custTbl\n"
                "Left Join CustStatusDN custStatus on custTbl.CustAccount = custStatus.CustAccount\n"
                "where custTbl.CustAccount = ? and (StatusDN = '1' or StatusDN = '2')\n"
                "order by Name asc";
        sql  = [squl UTF8String];
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
			sqlite3_bind_text(selectstmt, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
            	NSString *lvDate   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                {
                    lvDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                    NSDate *dateFromString = [dateFormatter dateFromString:lvDate];

                    NSCalendar       *cal = [NSCalendar autoupdatingCurrentCalendar];
                    NSDateComponents *dC  = [cal components:( NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay )
                                                   fromDate:dateFromString];
                    
                    if ([dC month] == month && [dC year] == year)
                        visited = YES;
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    return visited;
}

- (void) showAlertAboutNotSendedNewCusts {
    [AlertWorkerObjc alertWithTitle:@"Переотправить всех не отправленных клиентов?" message:nil buttons:@[@"Да", @"Отменить"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            [self sendNewCustomer];
        }
    }];
}


#pragma mark -
#pragma mark Search Bar 

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
	//This method is called again when the user clicks back from teh detail view.
	//So the overlay is displayed on the results, which is something we do not want to happen.
    if (searching)
		return;
	
	//Add the overlay view.
	if (ovController == nil)
		ovController = [[OverlayCustView alloc] initWithNibName:@"OverlayCustView" bundle:NSBundle.mainBundle];
	
	CGFloat width = 703;
	CGFloat height = 65000;
	
	//Parameters x = origion on x-axis, y = origon on y-axis.
	CGRect frame = CGRectMake(0, 0, width, height);
	ovController.view.frame = frame;	
	ovController.view.backgroundColor = [UIColor grayColor];
	ovController.view.alpha = 0.5;
	
	ovController.rvController = self;
	
	[myTableView insertSubview:ovController.view aboveSubview:self.parentViewController.view];
	
	searching = YES;
	letUserSelectRow = NO;
	myTableView.scrollEnabled = NO;
	
	//Add the done button.
	/*self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
											   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
											   target:self action:@selector(doneSearching_Clicked:)];*/
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
	
	//Remove all objects first.
	[copyCustList           removeAllObjects];
    [copyCustAccList        removeAllObjects];
    [copyCustDetList        removeAllObjects];
    [copyCustSendStatusList removeAllObjects];
    [copyCustPDZList        removeAllObjects];

	if ([searchText length] > 0) {
		[ovController.view removeFromSuperview];
		searching = YES;
		letUserSelectRow = YES;
		myTableView.scrollEnabled = YES;
		[self searchTableView];
	}
	else 
	{
		CGFloat width = 703;
        CGFloat height = 65000;
        
        //Parameters x = origion on x-axis, y = origon on y-axis.
        CGRect frame = CGRectMake(0, 94, width, height);
        
        ovController.view.frame = frame;
        
        [self.view insertSubview:ovController.view aboveSubview:self.parentViewController.view];
		
		searching = NO;
		letUserSelectRow = NO;
		myTableView.scrollEnabled = NO;
	}
	
	[myTableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)sBar {
    [searchBar resignFirstResponder];
    [self doneSearching_Clicked:nil];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
	[self searchTableView];
}



- (void)searchTableView {
    NSString       *searchText                  = searchBar.text;
	NSMutableArray *searchArray                 = [NSMutableArray new];
    NSMutableArray *searchArrayDet              = [NSMutableArray new];
    NSMutableArray *searchArrayCustAcc          = [NSMutableArray new];
    NSMutableArray *searchArrayCustSendStatus   = [NSMutableArray new];
    NSMutableArray *searchArrayCustPDZ          = [NSMutableArray new];
    
    //custSendStatusList;
	
	for (NSDictionary *dictionary in custList)
	{
		NSArray *array = [dictionary objectForKey:@"CustName"];
		[searchArray addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictDetail in custDetList)
	{
		NSArray *array = [dictDetail objectForKey:@"CustAddr"];
		[searchArrayDet addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictCustAcc in custAccList)
	{
		NSArray *array = [dictCustAcc objectForKey:@"CustAcc"];
		[searchArrayCustAcc addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictCustSendStatus in custSendStatusList) {
        NSArray *array = [dictCustSendStatus objectForKey:@"CustSendStatus"];
        [searchArrayCustSendStatus addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictCustPDZ in custPDZList) {
        NSArray *array = [dictCustPDZ objectForKey:@"PDZ"];
        [searchArrayCustPDZ addObjectsFromArray:array];
    }
    
    for(unsigned long y=0; y<[searchArray count];y++) {
        NSRange titleResultsRange  = [[searchArray objectAtIndex:y] rangeOfString:searchText options:NSCaseInsensitiveSearch];
        NSRange detailResultsRange = [[searchArrayDet objectAtIndex:y] rangeOfString:searchText options:NSCaseInsensitiveSearch];
        
        if (titleResultsRange.length > 0 || detailResultsRange.length > 0) {
            [copyCustDetList        addObject:[searchArrayDet objectAtIndex:y]];
            [copyCustList           addObject:[searchArray objectAtIndex:y]];
            [copyCustAccList        addObject:[searchArrayCustAcc objectAtIndex:y]];
            [copyCustSendStatusList addObject:[searchArrayCustSendStatus objectAtIndex:y]];
            [copyCustPDZList        addObject:[searchArrayCustPDZ objectAtIndex:y]];
        }
    }

    searchArray                 = nil;
    searchArrayDet              = nil;
    searchArrayCustAcc          = nil;
    searchArrayCustSendStatus   = nil;
    searchArrayCustPDZ          = nil;
}

- (void)doneSearching_Clicked:(id)sender {
    searchBar.text = @"";

    [searchBar resignFirstResponder];

    letUserSelectRow          = YES;
	searching                 = NO;
	myTableView.scrollEnabled = YES;
	
	[ovController.view removeFromSuperview];
    ovController = nil;

    [myTableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.f;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (inPseudoEditMode) {
        NSDictionary *dictCustAcc  = [custAccList objectAtIndex:indexPath.section];
        NSArray      *arrayCustAcc = [dictCustAcc objectForKey:@"CustAcc"];
        NSString     *custAccout;
        
        if (searching)
            custAccout = [copyCustAccList objectAtIndex:indexPath.row];
        else
            custAccout = [arrayCustAcc objectAtIndex:indexPath.row];
        
        BOOL selected = [[selectedArray objectAtIndex:[indexPath row]] boolValue];
        [selectedArray replaceObjectAtIndex:[indexPath row] withObject:[NSNumber numberWithBool:!selected]];
        
        if (!selected) {
            [custForRoute addObject:custAccout];
        } else {
            [custForRoute removeObject:custAccout];
        }
            
        [myTableView reloadData];
        
        if ([custForRoute count] > 0)
            aButton.enabled = YES;
        else
            aButton.enabled = FALSE;
    } else {
        NSString *custAccout;
        NSString *custName;
        NSString *custAddr;
        
        if (searching) {
            custName    = [copyCustList objectAtIndex:indexPath.row];
            custAccout  = [copyCustAccList objectAtIndex:indexPath.row];
            custAddr    = [copyCustDetList objectAtIndex:indexPath.row];
        } else {
            NSDictionary *dictionary  = [custList objectAtIndex:indexPath.section];
            NSArray      *array       = [dictionary objectForKey:@"CustName"];
            
            custName                         = [array objectAtIndex:indexPath.row];
            
            NSDictionary *dictCustAcc  = [custAccList objectAtIndex:indexPath.section];
            NSArray      *arrayCustAcc = [dictCustAcc objectForKey:@"CustAcc"];
            
            custAccout                 = [arrayCustAcc objectAtIndex:indexPath.row];
        
            NSDictionary	*dictionaryDet  = [custDetList objectAtIndex:indexPath.section];
            NSArray			*arrayDet		= [dictionaryDet objectForKey:@"CustAddr"];
            
            custAddr = [arrayDet objectAtIndex:indexPath.row];
        }
        
        [self.view endEditing:YES];
        custAddToRouteController                = [[CustAddToRouteController alloc] init];
        custAddToRouteController.custAcc        = custAccout;
        custAddToRouteController.custName       = custName;
        custAddToRouteController.custAddress    = custAddr;
        custAddToRouteController.countTasks     = [NSString stringWithFormat:@"%ld", (long)[self custTasksCount:custAccout]];
        custAddToRouteController.delegate       = self;

        if (infoNavController == nil)
            infoNavController = [[UINavigationController alloc] initWithRootViewController:custAddToRouteController];
        
        infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
        infoNavController.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
        
        [self.navigationController presentViewController:infoNavController animated:YES completion:nil];
        infoNavController.preferredContentSize = CGSizeMake(400,300);
        infoNavController.view.superview.bounds = CGRectMake(0,0,400,300);

        custAddToRouteController = nil;
        infoNavController = nil;
        
    }
}

- (void)hideCustActionListAndShow:(UIViewController *)vcToShow{
    [self dismissViewControllerAnimated:NO completion:^() {
        [self.navigationController presentViewController:vcToShow animated:NO completion:nil];
    }];
    vcToShow = nil;
}


- (void)finalizeStatements {
	if (database)sqlite3_close(database);
}

- (void)scrollToTop{
    NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [myTableView selectRowAtIndexPath:topIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

-(NSString *)visitStatus:(NSString *)custAccount {
    NSString *status = @"null";
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from CustForRoute where DateOfRoute = ? and CustAccount = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW ) {
                if (sqlite3_column_text(statement, 0))
                    status  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return status;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (visitPlan) {
        NSDictionary	*custDict  = [custAccList objectAtIndex:0];
        NSArray			*custArray = [custDict objectForKey:@"CustAcc"];
        NSString		*custValue = [custArray objectAtIndex:indexPath.row];
        
        NSString *statusValue = [self visitStatus:custValue];
        
        if ([statusValue isEqual:@"visited"]) {
            UIColor *mycolor = [UIColor colorWithRed:109.0/255.0 green:236.0/255.0 blue:143.0/255.0 alpha:1.0];
            cell.backgroundColor        = mycolor;
            // Andrey +
            UIView *textlabel = (UILabel *)[cell.contentView viewWithTag:kCellLabelTag];
            textlabel.backgroundColor = mycolor;
            UIView *detailTextLabel = (UILabel *)[cell.contentView viewWithTag:kCellDetailLabelTag];
            detailTextLabel.backgroundColor = mycolor;
            // Andrey -
        } else if ([statusValue isEqual:@"visit"]) {
            UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
            cell.backgroundColor        = color;
            // Andrey +
            UIView *textlabel = (UILabel *)[cell.contentView viewWithTag:kCellLabelTag];
            textlabel.backgroundColor = color;
            UIView *detailTextLabel = (UILabel *)[cell.contentView viewWithTag:kCellDetailLabelTag];
            detailTextLabel.backgroundColor = color;
            // Andrey -
        } else {
            //cell.backgroundColor = UIColor.clearColor;
            // Andrey +
            UIView *textlabel = (UILabel *)[cell.contentView viewWithTag:kCellLabelTag];
            cell.backgroundColor = textlabel.backgroundColor;
            //textlabel.backgroundColor = UIColor.clearColor;
            //UIView *detailTextLabel = (UILabel *)[cell.contentView viewWithTag:kCellDetailLabelTag];
            //detailTextLabel.backgroundColor = UIColor.clearColor;
            // Andrey -
        }
    }
    
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

// Andrey +
-(BOOL)IsStart {
    BOOL isStart = false;
    
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *routeDate = [dateFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from StartStop where Date = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"START" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                isStart = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return isStart;
}

-(BOOL)IsStop{
    BOOL isStop = false;
    
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *routeDate = [dateFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from StartStop where Date = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"STOP" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                isStop = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return isStop;
}

- (void)createCustomer:(id)sender {
    NewCustomerViewController *newCustomerVC = [[UIStoryboard storyboardWithName:@"NewCustomer" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(NewCustomerViewController.class)];
    
    UINavigationController *newCustomerNavVC = [[UINavigationController alloc] initWithRootViewController:newCustomerVC];
    newCustomerNavVC.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self.navigationController presentViewController:newCustomerNavVC animated:YES completion:nil];
}

- (void)requestCustomer:(id)sender {
    MoreCustViewController *fvController = [[MoreCustViewController alloc] initWithNibName: @"MoreCustViewController" bundle: nil];
    
    //fvController.delegate = self;
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];

    fvController = nil;
    infoNavController = nil;
}


- (void)customerDelete:(id)sender {
    [AlertWorkerObjc alertWithTitle:@"Вы уверены, что хотите удалить временных клиентов?" message:nil buttons:@[@"Да", @"Отменить"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
                static sqlite3_stmt *compiledStatement;
                
                sqlite3_exec(database, [[NSString stringWithFormat:
                                         @"delete from CustTable where AdditionalCust = '1'"] UTF8String], NULL, NULL, NULL);
                
                sqlite3_finalize(compiledStatement);
                sqlite3_close(database);
            }
            else
                sqlite3_close(database);
            
            [self refresh];
        }
    }];
}

- (void)refresh{
    if (searching) {
        [self searchBar:searchBar textDidChange:searchBar.text];
    } else {
        [self customerAdded];
    }
}

- (void)customerAdded {
    [self selectWithFilters];
    [self populateSelectedArray];
    [myTableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (visitPlan || (! visitPlan && ! additionalCusts)) {
        labelCustTotal = [self.navigationController.navigationBar viewWithTag:1];
        if (labelCustTotal)
            [self.navigationController.navigationBar bringSubviewToFront:labelCustTotal];
        else
            [self addCustTotalLabel];
        
    }
    myTableView.contentInset = UIEdgeInsetsMake(0,0,30,0);
}

- (void)setEnabled:(BOOL)value forButton:(UIBarButtonItem *)button {
    RWBorderedButton *customViewButton = button.customView;
    [customViewButton setEnabled:value];
}

#pragma mark - request
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
                
                
                [SVProgressHUD showWithStatus:@"Отправка..."];
                PutNewCustomerRequest    *sendNewCustomer = [PutNewCustomerRequest new];
                
                sendNewCustomer.custAccount = custAcc;
                
                [sendNewCustomer sendCustomer:xml];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
}

-(NSString *)getLastSalesDate:(NSString *)custAcc {
    NSString *salesDate = @"null";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select SalesDate from CustTable where CustAccount = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW ) {
                if (sqlite3_column_text(statement, 0))
                    salesDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return salesDate;
}

-(BOOL)isLastSalesTP:(NSString *)custAcc {
    NSString *channel   = @"null";
    NSString *salesDate = @"null";
    BOOL     ret        = NO;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select ChannelTypeId, SalesDate from CustTable where CustAccount = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW ) {
                if (sqlite3_column_text(statement, 0))
                    channel  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                
                if (sqlite3_column_text(statement, 1))
                    salesDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    
    NSCalendar       *myCalendar    = [NSCalendar currentCalendar];
    NSDateFormatter  *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate           *currDate  = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSDate *myDate = [dateFormatter dateFromString: salesDate];
    
    NSDateComponents *dateComponents = [myCalendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:myDate];
    
    if ([self isDateFalls:currDate withYourYear:[dateComponents year] andYourMonth:[dateComponents month]] && [channel isEqualToString:@"ТП"])
        ret = YES;
    else
        ret = false;
    
    return ret;
}

-(BOOL)isDateFalls:(NSDate *)date withYourYear:(NSInteger)year andYourMonth:(NSInteger)month{
    BOOL ret = NO;
    
    NSCalendar       *gregorian      = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [gregorian components:(NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    
    if (dateComponents.year == year && dateComponents.month == month)
        ret = YES;
    else
        ret = NO;
    
    return ret;
    
}

- (void)updateLastSalesTPDate:(NSString *)custAcc {
    const char *sql_2;
    
    sql_2 = "select SalesDate, SalesDateSort, ChannelTypeId from SalesTable where CustAccount = ? order by SalesDateSort desc limit 1";
    
    sqlite3_stmt *selstmt_2;
    
    if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selstmt_2, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
            NSString *salesDate        = @"null";
            NSString *salesDateSort    = @"null";
            NSString *channel          = @"null";
            
            if (sqlite3_column_text(selstmt_2, 0))
                salesDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
            
            if (sqlite3_column_text(selstmt_2, 1))
                salesDateSort  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 1)];
            
            if (sqlite3_column_text(selstmt_2, 2))
                channel  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 2)];
            
            const char *sql_3 = "update CustTable Set SalesDate = ?, SalesDateSort = ?, ChannelTypeId = ? where CustAccount = ?";
            
            sqlite3_stmt *updateStmt;
            
            if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(updateStmt, 1, [salesDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 2, [salesDateSort UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 3, [channel UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 4, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_step(updateStmt);
                sqlite3_finalize(updateStmt);
                
                NSLog(@"%@", salesDate);
                
            }
        }
        sqlite3_finalize(selstmt_2);
    }
}

#pragma mark - Button styling methods && Helpers
- (UIBarButtonItem *)spacerButton {
    UIBarButtonItem *spacerButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacerButton.width = 5.0;
    return spacerButton;
}
- (void)setBarButton:(UIBarButtonItem *)button highlighted:(BOOL)highlighted {
    [(RWBorderedButton *)button.customView setHighlightedState:highlighted];
}

@end
