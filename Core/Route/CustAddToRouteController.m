//
//  CustAddToRouteController.m
//  MLK
//
//  Created by Nikita on 09/04/15.
//
//

#import "CustAddToRouteController.h"
#import "Base64Class.h"
#import "CustViewController.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

@implementation CustAddToRouteController {
    RWBorderedButton *chooseDateButton;
}

static sqlite3 *database = nil;

@synthesize custAcc, custName;
@synthesize labelCustName;
@synthesize dateLabel, custAddress;
@synthesize addBtn;
@synthesize countTasks;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.delegate refresh];
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //NavBar Setup
    self.navigationItem.title = custName;
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    RWBorderedButton *closeButton  = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
    [closeButton addTarget:self
                    action:@selector(cancel_Clicked:)
          forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *closeBarButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    
    self.navigationItem.rightBarButtonItem = closeBarButton;
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.frame];
    
    [self.view addSubview:backgroundView];
    [self.view setBackgroundColor:UIColor.clearColor];
    
    UIImageView *bgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameGrayBackground]];
    [backgroundView addSubview:bgImage];
    bgImage.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[bgImage.leadingAnchor constraintEqualToAnchor:backgroundView.leadingAnchor],
       [bgImage.trailingAnchor constraintEqualToAnchor:backgroundView.trailingAnchor],
       [bgImage.topAnchor constraintEqualToAnchor:backgroundView.topAnchor],
       [bgImage.bottomAnchor constraintEqualToAnchor:backgroundView.bottomAnchor]]];
    
    UILabel *lblRoute = [UILabel new];
    lblRoute.tag = 1;
    lblRoute.backgroundColor = UIColor.clearColor;
    lblRoute.font = [UIFont systemFontOfSize:16];
    lblRoute.adjustsFontSizeToFitWidth = NO;
    lblRoute.textAlignment = NSTextAlignmentLeft;
    lblRoute.textColor = UIColor.whiteColor;
    lblRoute.text = @"Маршрут на";
    lblRoute.highlightedTextColor = [UIColor blackColor];
    [self.view addSubview:lblRoute];
    
    lblRoute.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[lblRoute.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10.0],
       [lblRoute.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10.0]]];
    
    RWBorderedButton *chooseDate = [RWBorderedButton buttonWithFrame:CGRectMake(125.0, 5.0, 150.0, 30.0) title:@"Дата"];
    [chooseDate addTarget:self
                   action:@selector(btnSelectDateTapped:)
         forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:chooseDate];
    
    chooseDate.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[chooseDate.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:125.0],
       [chooseDate.centerYAnchor constraintEqualToAnchor:lblRoute.centerYAnchor],
       [chooseDate.widthAnchor constraintEqualToConstant:150.0],
       [chooseDate.heightAnchor constraintEqualToConstant:30.0]]];
    
    UILabel *lblDate = [UILabel new];
    lblDate.tag = 2;
    lblDate.backgroundColor = UIColor.clearColor;
    lblDate.font = [UIFont systemFontOfSize:16];
    lblDate.adjustsFontSizeToFitWidth = NO;
    lblDate.textAlignment = NSTextAlignmentCenter;
    lblDate.textColor = UIColor.whiteColor;
    lblDate.text = @"Дата";
    lblDate.highlightedTextColor = [UIColor blackColor];
    lblDate.hidden = YES;
    [self.view addSubview:lblDate];
    
    lblDate.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[lblDate.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:135.0],
       [lblDate.centerYAnchor constraintEqualToAnchor:lblRoute.centerYAnchor],
       [lblDate.widthAnchor constraintEqualToConstant:175.0],
       [lblDate.heightAnchor constraintEqualToConstant:30.0]]];
    
    
    dateLabel = lblDate;
    chooseDateButton = chooseDate;
    
    
    // -->
    RWBorderedButton *addToRouteBnt = [RWBorderedButton buttonWithFrame:CGRectMake(75.0, 60.0, 250.0, 50.0)
                                                                  title:@"Добавить в маршрут"];
    [NSLayoutConstraint activateConstraints:
     @[[addToRouteBnt.widthAnchor constraintEqualToConstant:250.0],
       [addToRouteBnt.heightAnchor constraintEqualToConstant:50.0]]];
    
    [addToRouteBnt addTarget:self
                      action:@selector(addToRoute)
            forControlEvents:UIControlEventTouchUpInside];
    
    [addToRouteBnt setEnabled:NO];
    
    addBtn = addToRouteBnt;
    
    RWBorderedButton *openCust = [RWBorderedButton buttonWithFrame:CGRectMake(75, 130.0, 250, 50)
                                                             title:@"Карточка клиента"];
    [openCust addTarget:self
                 action:@selector(openCust)
       forControlEvents:UIControlEventTouchUpInside];
    
    RWBorderedButton *showOnMap = [RWBorderedButton buttonWithFrame:CGRectMake(75, 200.0, 250, 50)
                                                              title:@"Показать на карте"];
    [showOnMap addTarget:self
                  action:@selector(onMap)
        forControlEvents:UIControlEventTouchUpInside];
    
    UIStackView *buttonsStackView = [[UIStackView alloc] initWithArrangedSubviews:@[addToRouteBnt, openCust, showOnMap]];
    buttonsStackView.distribution = UIStackViewDistributionFillEqually;
    buttonsStackView.axis = UILayoutConstraintAxisVertical;
    buttonsStackView.spacing = 20.0;
    [self.view addSubview:buttonsStackView];
    
    buttonsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[buttonsStackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
       [buttonsStackView.topAnchor constraintEqualToAnchor:chooseDate.bottomAnchor constant:20.0]]];
    
    // <--
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(cancel_Clicked:) name:@"closeCustAddToRouteController" object:nil];
    
    //
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *curDate           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:curDate];
    
    self.dateLabel.text = strDate;
    
    [chooseDateButton setTitle:strDate forState:UIControlStateNormal];
    
    self.selectedDate = curDate;
    
    [addBtn setEnabled:YES];
}

- (NSString *)getCustAddress:(NSString *)custAccountSQL {
    NSString *custAddr = @"null";
    static sqlite3_stmt *selectstmt = nil;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select GPSPoint from CustTable where CustAccount = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccountSQL UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0))
                    custAddr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    NSLog(@"%@", custAddr);
    return custAddr;
}

- (void)onMap{    
    mvControllerToolbar = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:NSBundle.mainBundle];
    
    mvControllerToolbar.isViewPushed = NO;
    
    mvControllerToolbar.custName     = custName;
    mvControllerToolbar.custAddr     = [self getCustAddress:custAcc];
    
    if (mvNavController == nil)
        mvNavController = [[UINavigationController alloc] initWithRootViewController:mvControllerToolbar];
    
    mvNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    //[self.navigationController presentViewController:mvNavController animated:YES completion:nil];
    [self.delegate hideCustActionListAndShow:mvNavController];
    mvControllerToolbar = nil;
    mvNavController     = nil;
}

- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}


- (IBAction)addToRoute {
    if (custViewController == nil)
        custViewController = [[CustViewController alloc] init];
    
    [custViewController addCustomersToRoute:custAcc custName:custName custAddr:[self getCustAddress:custAcc] strDate:self.dateLabel.text];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openCust {
    [NavigationWorker openCustomerDetails:self->custAcc];
}

- (void)btnSelectDateTapped:(id)sender {
    if (!self.datePickerVC) {
        self.datePickerVC = [ASPDatePickerViewController new];
        self.datePickerVC.delegate = self;
        self.datePickerVC.modalPresentationStyle = UIModalPresentationPopover;
    }
    
    if (!self.datePickerVC.presentingViewController) {
        self.datePickerVC.popoverPresentationController.sourceView = sender;
        self.datePickerVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
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
    self.selectedDate = nil;
}

- (void)datePickerDidPickDate:(NSDate *)date {
    [self datePickerDidCancel];
    
    self.selectedDate = date;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat_dd_MM_YYYY];
    NSString *strDate = [formatter stringFromDate:self.selectedDate];
    
    if (!self.selectedDate) {
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;
        
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        strDate = [dateFormatter stringFromDate:date];
        
        self.dateLabel.text = strDate;
        [chooseDateButton setTitle:strDate forState:UIControlStateNormal];
    }
    
    self.dateLabel.text = strDate;
    [chooseDateButton setTitle:strDate forState:UIControlStateNormal];
    [addBtn setEnabled:YES];
    self.selectedDate = nil;
}

@end


