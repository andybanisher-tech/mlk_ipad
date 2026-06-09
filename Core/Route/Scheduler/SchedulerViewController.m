//
//  SchedulerViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 18.12.2021.
//

#import "SchedulerViewController.h"

//DataWorkers
#import "sqlite3.h"
#import "XMLWriter.h"

//VCs
#import "ChooseManagersViewController.h"
#import "CustomersViewController.h"
#import "PutClientForRouteRequest.h"
#import "TasksViewController.h"
#import "RouteMapViewController.h"

//Custom Objects
#import "SchedulerDay.h"

//Cells
#import "SchedulerAddCustomerCollectionReusableView.h"
#import "CustomerInRouteCollectionViewCell.h"
#import "SchedulerDayCollectionViewCell.h"

//Views
#import "SchedulerAccManagementView.h"

//Requests
#import "GetCustTableRequest.h"

#import "GeneratedAssetSymbols.h"

//UI Constants
static const NSInteger kNumberOfDaysInWeek = 7;
static const NSInteger kNumberOfWeeks = 6;

@interface SchedulerViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate, SchedulerAccManagementViewDelegate, ChooseManagersViewControllerDelegate, CustomerInRouteCollectionViewCellDelegate, PutClientForRouteRequestDelegate, CustomersViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblRouteDate;
@property (nonatomic, weak) IBOutlet UIButton *showOnMapButton;

@property (nonatomic, weak) IBOutlet UILabel *lblNoCustomers;

@property (nonatomic, weak) IBOutlet UICollectionView *customersCollectionView;
@property (nonatomic, weak) IBOutlet UICollectionView *daysCollectionView;

@property (nonatomic, strong) SchedulerAccManagementView *accManagementView;
@property (nonatomic, strong) UIStackView *monthNavigationStackView;
@property (nonatomic, strong) UILabel *monthLabel;

@property (nonatomic, strong) NSCalendar *mainCalendar;
@property (nonatomic, strong) NSDateFormatter *mainDateFormatter;
@property (nonatomic, strong) NSDate *currentDate;
@property (nonatomic, strong) SchedulerDay *selectedDay;
@property (nonatomic, strong) NSIndexPath *dropDestinationIndexPath;

@property (nonatomic, strong) NSArray *schedulerDays;

@property (nonatomic, copy) NSString *mainAcc;
@property (nonatomic, copy) NSString *currentAcc;
@property (nonatomic, strong) NSDictionary *selectedManager;

@end

static sqlite3 *database = nil;

@implementation SchedulerViewController

#pragma mark - Life Cycle
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.accManagementView.userInteractionEnabled = YES;
    self.accManagementView.alpha = 1.0;
    self.monthNavigationStackView.hidden = NO;
    
    if ([self.presentedViewController isKindOfClass:UINavigationController.class]) {
        if ([[(UINavigationController *)self.presentedViewController viewControllers].firstObject isKindOfClass:RouteMapViewController.class]) {
            self.selectedDay.customers = [self getCustomersForDate:self.selectedDay.date];
            
            NSInteger selectedDayCellIndex = [self.schedulerDays indexOfObject:self.selectedDay];
            [self.daysCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:selectedDayCellIndex inSection:0]]];
            
            [self.customersCollectionView reloadData];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.accManagementView.userInteractionEnabled = NO;
    self.accManagementView.alpha = 0.7;
    self.monthNavigationStackView.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self setupUI];
    
    [self prepareInitialData];
}

#pragma mark - UI
- (void)setupNavBar {
    //NavBar Setup
    self.navigationItem.title = @"Планировщик";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:UIColor.whiteColor tintColor:[UIColor colorNamed:ACColorNameMLKLightBlue]];
    
    UIBarButtonItem *btnDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self  action:@selector(btnDoneTapped)];
    self.navigationItem.rightBarButtonItem = btnDone;
    
    UIView *statusBarUnderlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, -ASPFunctions.statusBarHeight, self.navigationController.navigationBar.frame.size.width, ASPFunctions.statusBarHeight)];
    statusBarUnderlayView.backgroundColor = [UIColor blackColor];
    [self.navigationController.navigationBar addSubview:statusBarUnderlayView];
    
    //AccManagementView
    NSArray *iPadsArray = [PersistenceWorker load:@"iPadsArray"];
    self.accManagementView = [NSBundle.mainBundle loadNibNamed:NSStringFromClass(SchedulerAccManagementView.class) owner:self options:nil].firstObject;
    self.accManagementView.delegate = self;
    self.accManagementView.hidden = iPadsArray.count < 1;
    [self.navigationController.navigationBar addSubview:self.accManagementView];
    
    //MonthNavigationView
    UIButton *previousMonthButton = [self monthButton:@selector(previousMonthButtonTapped) title:@"<"];
    
    self.monthLabel = [UILabel new];
    self.monthLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    self.monthLabel.textAlignment = NSTextAlignmentCenter;
    self.monthLabel.textColor = [UIColor colorNamed:ACColorNameMLKBlue];
    UIButton *nextMonthButton = [self monthButton:@selector(nextMonthButtonTapped) title:@">"];
    
    self.monthNavigationStackView = [[UIStackView alloc] initWithArrangedSubviews:@[previousMonthButton, self.monthLabel, nextMonthButton]];
    self.monthNavigationStackView.alignment = UIStackViewAlignmentCenter;
    self.monthNavigationStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.navigationController.navigationBar addSubview:self.monthNavigationStackView];
    
    //Constants
    CGFloat monthButtonSide = 40.0;
    [NSLayoutConstraint activateConstraints:@[
        //AccManagementView
        [NSLayoutConstraint constraintWithItem:self.accManagementView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeCenterX multiplier:0.55 constant:1.0],
        [self.accManagementView.centerYAnchor constraintEqualToAnchor:self.navigationController.navigationBar.centerYAnchor],
        
        //PreviousMonthButton
        [previousMonthButton.widthAnchor constraintEqualToConstant:monthButtonSide],
        [previousMonthButton.heightAnchor constraintEqualToAnchor:previousMonthButton.widthAnchor multiplier:1.0],
        
        //NextMonthButton
        [nextMonthButton.widthAnchor constraintEqualToAnchor:previousMonthButton.widthAnchor multiplier:1.0],
        [nextMonthButton.heightAnchor constraintEqualToAnchor:previousMonthButton.heightAnchor multiplier:1.0],
        
        [NSLayoutConstraint constraintWithItem:self.monthNavigationStackView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeCenterX multiplier:1.5 constant:1.0],
        [self.monthNavigationStackView.centerYAnchor constraintEqualToAnchor:self.accManagementView.centerYAnchor]
    ]];
}

- (void)setupUI {
    //Register Cells
    [self.customersCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass(CustomerInRouteCollectionViewCell.class) bundle:nil] forCellWithReuseIdentifier:NSStringFromClass(CustomerInRouteCollectionViewCell.class)];
    
    self.daysCollectionView.collectionViewLayout = [self getDaysLayout];
}

- (void)prepareInitialData {
    self.mainAcc = LocalAuthWorker.login;
    self.currentAcc = self.mainAcc;
    
    self.mainCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    self.mainDateFormatter = NSDateFormatter.new;
    self.mainDateFormatter.defaultDate = NSDate.date;
    
    self.currentDate = NSDate.date;
    
    [self createDaysForBaseDate:self.currentDate];
    
    //Observers
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(routeRefreshed:) name:@"routeRefreshed" object:nil];
}

#pragma mark - Data Setters
- (void)setSelectedDay:(SchedulerDay *)selectedDay{
    if (_selectedDay == selectedDay) {
        return;
    }
    
    //Removing previous selected Day cell border
    if (_selectedDay) {
        NSInteger previousSelectedDayCellIndex = [self.schedulerDays indexOfObject:_selectedDay];
        SchedulerDayCollectionViewCell *cell = (SchedulerDayCollectionViewCell *)[self.daysCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:previousSelectedDayCellIndex inSection:0]];
        [cell setCellSelected:NO];
    }
    
    _selectedDay = selectedDay;
    
    if (_selectedDay) {
        self.mainDateFormatter.dateFormat = @"E, dd MMMM yyyy";
        NSString *selectedDateString = [self.mainDateFormatter stringFromDate:_selectedDay.date].uppercaseString;
        
        NSString *routeDate = [NSString stringWithFormat:@"Маршрут на: %@", selectedDateString];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: routeDate];
        [attributedString setAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:self.lblRouteDate.font.pointSize], NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameGrayNavBarBackground]} range:[routeDate rangeOfString:selectedDateString]];
        
        self.lblRouteDate.attributedText = attributedString;
    } else {
        self.lblRouteDate.attributedText = nil;
    }
    
    self.lblNoCustomers.hidden = _selectedDay.customers.count > 0;
    
    self.showOnMapButton.hidden = ![self.mainCalendar isDateInToday:_selectedDay.date];
    self.customersCollectionView.dragInteractionEnabled = !_selectedDay.isInPast;
    [self.customersCollectionView reloadData];
}

- (void)setDropDestinationIndexPath:(NSIndexPath *)dropDestinationIndexPath {
    if (_dropDestinationIndexPath == dropDestinationIndexPath) {
        return;
    }
    
    NSMutableArray *indexPathsToReload = [NSMutableArray new];
    //Removing previous destination cell border
    if (_dropDestinationIndexPath) {
        [indexPathsToReload addObject:_dropDestinationIndexPath];
    }
    
    _dropDestinationIndexPath = dropDestinationIndexPath;
    
    //Adding new destination cell border
    if (_dropDestinationIndexPath) {
        [indexPathsToReload addObject:_dropDestinationIndexPath];
    }
    
    [self.daysCollectionView reloadItemsAtIndexPaths:indexPathsToReload];
}

#pragma mark - Button Actions
- (void)previousMonthButtonTapped {
    if (!self.customersCollectionView.hasActiveDrag) {
        NSDateComponents *dateComponents = [NSDateComponents new];
        dateComponents.month = -1;
        self.currentDate = [self.mainCalendar dateByAddingComponents:dateComponents toDate:self.currentDate options:kNilOptions];
        
        [self createDaysForBaseDate:self.currentDate];
    }
}

- (void)nextMonthButtonTapped {
    if (!self.customersCollectionView.hasActiveDrag) {
        NSDateComponents *dateComponents = [NSDateComponents new];
        dateComponents.month = 1;
        self.currentDate = [self.mainCalendar dateByAddingComponents:dateComponents toDate:self.currentDate options:kNilOptions];
        
        [self createDaysForBaseDate:self.currentDate];
    }
}

- (void)btnDoneTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)showOnMapButtonTapped:(id)sender {
    RouteMapViewController *routeMapVC = [[UIStoryboard storyboardWithName:@"RouteMap" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(RouteMapViewController.class)];
    routeMapVC.currentDate = self.currentDate;
    
    UINavigationController *routeMapNavVC = [[UINavigationController alloc] initWithRootViewController:routeMapVC];
    routeMapNavVC.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self.navigationController presentViewController:routeMapNavVC animated:YES completion:nil];
}

- (IBAction)btnAddCustomerTapped:(id)sender {
    CustomersViewController *customersVC = [[UIStoryboard storyboardWithName:@"Customers" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([CustomersViewController class])];
    customersVC.delegate = self;
    customersVC.customersInRoute = [NSMutableArray arrayWithArray:self.selectedDay.customers];
    customersVC.selectedDate = self.selectedDay.date;
    customersVC.mainAcc = self.mainAcc;
    customersVC.currentAcc = self.currentAcc;
    customersVC.selectedManager = self.selectedManager;
    
    [self.navigationController pushViewController:customersVC animated:YES];
}

- (IBAction)addCustomerFromTaskButtonTapped:(id)sender {
    TasksViewController *tasksVC = [[UIStoryboard storyboardWithName:@"Tasks" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(TasksViewController.class)];
    tasksVC.delegate = self;
    
    UINavigationController *tasksNavVC = [[UINavigationController alloc] initWithRootViewController:tasksVC];
    tasksNavVC.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:tasksNavVC animated:YES completion:nil];
}

#pragma mark - Notifications
- (void)routeRefreshed:(NSNotification *)notification {
    if (![ASPFunctions isViewControllerVisible:self]) { return; }
    
//    NSDictionary *object = notification.object;
    
    for (SchedulerDay *day in self.schedulerDays) {
        day.customers = [self getCustomersForDate:day.date];
    }
    
    [self.customersCollectionView reloadData];
    self.lblNoCustomers.hidden = self.selectedDay.customers.count > 0;
    
    [self.daysCollectionView reloadData];
}

#pragma mark - SchedulerAccManagementViewDelegate
- (void)userDidTapChooseManagerButton:(UIButton *)sender {
    NSArray *iPadsArray = [PersistenceWorker load:@"iPadsArray"];
    
    ChooseManagersViewController *chooseManagersVC = [[UIStoryboard storyboardWithName:@"ChooseManagers" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(ChooseManagersViewController.class)];
    chooseManagersVC.delegate = self;
    chooseManagersVC.iPadsArray = iPadsArray;
    if (self.selectedManager) {
        chooseManagersVC.selectedIPadsSet = [NSMutableSet setWithObject:self.selectedManager];
    }
    chooseManagersVC.isSchedulerMode = YES;
    
    chooseManagersVC.modalPresentationStyle = UIModalPresentationPopover;
    chooseManagersVC.popoverPresentationController.sourceView = sender;
    chooseManagersVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    
    [self presentViewController:chooseManagersVC animated:YES completion:nil];
}

- (void)userDidTapChangeAccButton {
    NSString *accToSelect;
    
    BOOL isMainAcc;
    UIColor *navBarBackgroundColor;
    
    NSString *title;
    NSString *message;
    if ([self.currentAcc isEqualToString:self.mainAcc]) {
        accToSelect = self.selectedManager[@"id"];
        
        isMainAcc = YES;
        navBarBackgroundColor = [UIColor colorNamed:ACColorNameBlueNavBarBackground];
        
        title = @"Маршрут менеджера";
        message = @"Перейти в режим редактирования маршрута от лица выбранного менеджера?";
    } else {
        accToSelect = self.mainAcc;
        
        isMainAcc = NO;
        navBarBackgroundColor = UIColor.whiteColor;
        
        title = @"Обычный режим";
        message = @"Завершить редактирование маршрута от лица выбранного менеджера?";
    }
    
    [AlertWorkerObjc alertWithTitle:title message:message buttons:@[@"Да", @"Отменить"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            self.currentAcc = accToSelect;
            [self.accManagementView setIsMainAcc: isMainAcc];
            [ASPFunctions setNavigationBar:self.navigationController.navigationBar backgroundColor:navBarBackgroundColor];
            
            [self.customersCollectionView reloadData];
            [self.daysCollectionView reloadData];
        }
    }];
}

#pragma mark - ChooseManagersViewControllerDelegate
- (void)userDidChooseManagers:(NSSet *)managers {
    [self dismissViewControllerAnimated:YES completion:^{
        NSDictionary *manager = managers.anyObject;
        if (![self.selectedManager isEqualToDictionary:manager]) {
            self.selectedManager = manager;
            [self.accManagementView setManager:manager];
            [self loadRouteForManager:manager[@"id"]];
        }
    }];
}

#pragma mark - CustomerInRouteCollectionViewCellDelegate
- (void)cellBtnRemoveCustomerTapped:(CustomerInRouteCollectionViewCell *)sender {
    NSIndexPath *indexPath = [self.customersCollectionView indexPathForCell:sender];
    [self removeCustomers:@[self.selectedDay.customers[indexPath.item]]];
}

#pragma mark - CustomersViewControllerDelegate
- (void)userDidAddCustomersToRoute:(NSArray *)customers date:(NSDate *)date {
    if (!self.presentedViewController) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    [self addCustomers:customers toDate:date];
}

- (void)userDidRemoveCustomersFromRoute:(NSArray *)customers {
    [self.navigationController popViewControllerAnimated:YES];
    
    [self removeCustomers:customers];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.customersCollectionView) {
        return self.selectedDay.customers.count;
    } else {
        return self.schedulerDays.count;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.customersCollectionView && [kind isEqualToString:UICollectionElementKindSectionFooter]) {
        SchedulerAddCustomerCollectionReusableView *footerView = (SchedulerAddCustomerCollectionReusableView *)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:NSStringFromClass([SchedulerAddCustomerCollectionReusableView class]) forIndexPath:indexPath];
        footerView.addCustomerFromTaskButton.hidden = ![self.currentAcc isEqualToString:self.mainAcc];
        
        return footerView;
    }
    
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.customersCollectionView) {
        CustomerInRouteCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CustomerInRouteCollectionViewCell.class) forIndexPath:indexPath];
        
        NSDictionary *object = self.selectedDay.customers[indexPath.item];
        cell.lblName.text = object[@"custName"];
        
        if (![object[@"regularRoute"] isEqual:@"Yes"] && ![object[@"status"] isEqual:@"visited"] && !self.selectedDay.isInPast) {
            cell.btnRemove.hidden = NO;
        } else {
            cell.btnRemove.hidden = YES;
        }
        
        if ([object[@"managerIDs"] containsObject:self.currentAcc]) {
            cell.contentView.alpha = 1.0;
        } else {
            cell.contentView.alpha = 0.5;
            cell.btnRemove.hidden = YES;
        }
        
        if ([object[@"managerIDs"] containsObject:self.mainAcc]) {
            cell.managerInfoImageView.image = [UIImage imageNamed:ACImageNameCommonCustomerInRoute];
            cell.managerInfoImageView.hidden = [object[@"managerIDs"] count] < 2;
        } else {
            cell.managerInfoImageView.image = [UIImage imageNamed:ACImageNameConnectedManager];
            cell.managerInfoImageView.hidden = NO;
        }
        
        if ([object[@"status"] isEqual:@"visited"]) {
            cell.backgroundColor = [ASPFunctions colorFromHex:@"7DE779"];
        } else if ([object[@"status"] isEqual:@"visit"]) {
            cell.backgroundColor = [ASPFunctions colorFromHex:@"6395EC"];
        } else {
            cell.backgroundColor = [ASPFunctions colorFromHex:@"BDBDBD"];
        }
        
        cell.delegate = self;
        
        return cell;
    } else {
        SchedulerDayCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SchedulerDayCollectionViewCell class]) forIndexPath:indexPath];
        SchedulerDay *day = self.schedulerDays[indexPath.item];
        cell.lblDayNumber.text = day.number;
        [cell setCustomers:day.customers mainAcc:self.mainAcc];
        [cell setCellSelected:day == self.selectedDay];
        
        if (!day.isWithinDisplayedMonth) {
            cell.contentView.backgroundColor = [ASPFunctions colorFromHex:@"B7B7B7"];
        } else {
            NSInteger remainder = indexPath.item % 7;
            if (remainder != 0 && (remainder % 5 == 0 || remainder % 6 == 0)) {
                cell.contentView.backgroundColor = [ASPFunctions colorFromHex:@"DADADA"];
            } else {
                cell.contentView.backgroundColor = UIColor.whiteColor;
            }
        }
        
        if (self.dropDestinationIndexPath && self.dropDestinationIndexPath.item == indexPath.item) {
            SchedulerDay *destinationDay = self.schedulerDays[indexPath.item];
            if (self.selectedDay != destinationDay && !destinationDay.isInPast) {
                [cell setDropDestinationColor:[UIColor greenColor]];
            } else {
                [cell setDropDestinationColor:[UIColor redColor]];
            }
        } else {
            [cell setDropDestinationColor:UIColor.clearColor];
        }
        
        return cell;
    }
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if (collectionView == self.daysCollectionView) {
        SchedulerDay *day = self.schedulerDays[indexPath.item];
        if (self.selectedDay != day) {
            self.selectedDay = day;
            
            SchedulerDayCollectionViewCell *cell = (SchedulerDayCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            [cell setCellSelected:YES];
        }
    } else if (!self.customersCollectionView.hasActiveDrag) {
        [self showCustomerInfo:self.selectedDay.customers[indexPath.item]];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (collectionView == self.customersCollectionView && self.selectedDay && !self.selectedDay.isInPast) {
        return [(UICollectionViewFlowLayout *)collectionViewLayout footerReferenceSize];
    }
    return CGSizeZero;
}

#pragma mark - UICollectionViewDragDelegate
- (BOOL)collectionView:(UICollectionView *)collectionView dragSessionIsRestrictedToDraggingApplication:(id<UIDragSession>)session {
    return YES;
}

- (NSArray<UIDragItem *> *)collectionView:(UICollectionView *)collectionView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.selectedDay.customers[indexPath.item];
    
    if ([object[@"managerIDs"] containsObject:self.currentAcc]) {
        return @[[self dragItemForIndexPath:indexPath]];
    }

    return @[];
}

- (NSArray<UIDragItem *> *)collectionView:(UICollectionView *)collectionView itemsForAddingToDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    return @[[self dragItemForIndexPath:indexPath]];
}

#pragma mark - UICollectionViewDropDelegate
- (BOOL)collectionView:(UICollectionView *)collectionView canHandleDropSession:(id<UIDropSession>)session {
    return [session canLoadObjectsOfClass:[NSString class]];
}

- (UICollectionViewDropProposal *)collectionView:(UICollectionView *)collectionView dropSessionDidUpdate:(id<UIDropSession>)session withDestinationIndexPath:(NSIndexPath *)destinationIndexPath {
    self.dropDestinationIndexPath = destinationIndexPath;
    
    if (destinationIndexPath) {
        SchedulerDay *destinationDay = self.schedulerDays[destinationIndexPath.item];
        if (self.selectedDay != destinationDay && !destinationDay.isInPast) {
            return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationCopy intent:UICollectionViewDropIntentInsertIntoDestinationIndexPath];
        }
    }
    
    return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationForbidden];
}

- (void)collectionView:(UICollectionView *)collectionView dropSessionDidEnd:(id<UIDropSession>)session {
    self.dropDestinationIndexPath = nil;
}

- (void)collectionView:(UICollectionView *)collectionView dropSessionDidExit:(id<UIDropSession>)session {
    self.dropDestinationIndexPath = nil;
}

- (void)collectionView:(UICollectionView *)collectionView performDropWithCoordinator:(id<UICollectionViewDropCoordinator>)coordinator {
    NSIndexPath *destinationIndexPath = coordinator.destinationIndexPath;
    if (destinationIndexPath) {
        NSMutableArray *customers = [NSMutableArray new];
        for (int i = 0; i < coordinator.items.count; i++) {
            [customers addObject:coordinator.items[i].dragItem.localObject];
        }
        [self removeCustomers:customers];
        [self addCustomers:customers toDate:[self.schedulerDays[destinationIndexPath.item] date]];
    }
    self.dropDestinationIndexPath = nil;
}

#pragma mark - CollectionView Helpers
- (UIDragItem *)dragItemForIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.selectedDay.customers[indexPath.item];
    NSString *custName = object[@"custName"];
    
    NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithObject:custName];
    
    UIDragItem *dragItem = [[UIDragItem alloc] initWithItemProvider:itemProvider];
    dragItem.localObject = object;
    
    return dragItem;
}

#pragma mark - Helpers
- (UIButton *)monthButton:(SEL)action title:(NSString *)title {
    UIButton *monthButton = [UIButton buttonWithType:UIButtonTypeSystem];
    monthButton.titleLabel.font = [UIFont systemFontOfSize:25.0 weight:UIFontWeightSemibold];
    [monthButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [monthButton setTitle:title forState:UIControlStateNormal];
    [monthButton setTitleColor:[UIColor colorNamed:ACColorNameMLKBlue] forState:UIControlStateNormal];
    
    return monthButton;
}

- (UICollectionViewLayout *)getDaysLayout {
    NSCollectionLayoutSize *size = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.0]];
    
    //Item
    NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:size];
    
    //Horizontal Group
    NSCollectionLayoutGroup *horizontalGroup = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:size subitem:item count:kNumberOfDaysInWeek];
    
    //Vertical Group
    NSCollectionLayoutGroup *verticalGroup = [NSCollectionLayoutGroup verticalGroupWithLayoutSize:size subitem:horizontalGroup count:kNumberOfWeeks];
    
    //Section
    NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:verticalGroup];
    
    return [[UICollectionViewCompositionalLayout alloc] initWithSection:section];
}

- (void)createDaysForBaseDate:(NSDate *)date {
    self.mainDateFormatter.dateFormat = @"LLLL yyyy";
    NSString *monthString = [self.mainDateFormatter stringFromDate:date];
    self.monthLabel.text = monthString.capitalizedString;
    
    NSInteger numberOfDaysInMonth = [self.mainCalendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date].length;
    NSDate *firstDayOfMonth = [self.mainCalendar dateFromComponents:[self.mainCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:date]];
    
    //Small tweaking to make Monday first weekday
    NSCalendarUnit weekdayComponent = [self.mainCalendar component:NSCalendarUnitWeekday fromDate:firstDayOfMonth];
    NSInteger firstDayWeekday = weekdayComponent == 1 ? 7 : weekdayComponent - 1;
    
    self.mainDateFormatter.dateFormat = @"dd";
    
    NSMutableArray *days = [NSMutableArray new];
    NSDate *todayDate = NSDate.date;
    for (int i = 1; i < numberOfDaysInMonth + firstDayWeekday; i++) {
        BOOL isWithinDisplayedMonth = i >= firstDayWeekday;
        NSInteger dayOffset = isWithinDisplayedMonth ? i - firstDayWeekday : -(firstDayWeekday - i);
        
        [days addObject:[self generateDayWithOffset:dayOffset forBaseDate:firstDayOfMonth todayDate:todayDate isWithinDisplayedMonth:isWithinDisplayedMonth]];
    }
    
    [days addObjectsFromArray:[self generateStartOfNextMonthWithFirstDayOfDisplayedMonth:firstDayOfMonth]];
    
    self.schedulerDays = [NSArray arrayWithArray:days];
    for (SchedulerDay *day in self.schedulerDays) {
        day.customers = [self getCustomersForDate:day.date];
    }
    
    self.selectedDay = [ASPFunctions firstObjectInArray:self.schedulerDays where:^BOOL(SchedulerDay *day, NSUInteger idx, BOOL * _Nonnull stop) {
        return [self.mainCalendar isDateInToday:day.date];
    }];
    
    [self.daysCollectionView reloadData];
}

- (NSArray *)generateStartOfNextMonthWithFirstDayOfDisplayedMonth:(NSDate *)firstDay{
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.month = 1;
    dateComponents.day = -1;
    NSDate *lastDayInMonth = [self.mainCalendar dateByAddingComponents:dateComponents toDate:firstDay options:kNilOptions];
    
    //Small tweaking to make Monday first weekday
    NSCalendarUnit weekdayComponent = [self.mainCalendar component:NSCalendarUnitWeekday fromDate:lastDayInMonth];
    weekdayComponent = weekdayComponent == 1 ? 7 : weekdayComponent - 1;
    
    NSInteger additionalDays = kNumberOfDaysInWeek - weekdayComponent;
    
    NSMutableArray *days = [NSMutableArray new];
    NSDate *todayDate = NSDate.date;
    for (int i = 1; i <= additionalDays; i++) {
        BOOL isWithinDisplayedMonth = NO;
        NSInteger dayOffset = i;
        
        [days addObject:[self generateDayWithOffset:dayOffset forBaseDate:lastDayInMonth todayDate:todayDate isWithinDisplayedMonth:isWithinDisplayedMonth]];
    }
    
    return days;
}

- (SchedulerDay *)generateDayWithOffset:(NSInteger)dayOffset forBaseDate:(NSDate *)baseDate todayDate:(NSDate *)todayDate isWithinDisplayedMonth:(BOOL)isWithinDisplayedMonth{
    SchedulerDay *day = [SchedulerDay new];
    day.date = [self.mainCalendar dateByAddingUnit:NSCalendarUnitDay value:dayOffset toDate:baseDate options:kNilOptions];
    day.number = [self.mainDateFormatter stringFromDate:day.date];
    day.isWithinDisplayedMonth = isWithinDisplayedMonth;
    day.isInPast = [self.mainCalendar components:NSCalendarUnitDay fromDate:todayDate toDate:day.date options:kNilOptions].day < 0;
    
    return day;
}

#pragma mark - AccManagement
- (void)loadRouteForManager:(NSString *)managerID {
    if (managerID) {
        GetCustTableRequest *custTableRequest = [GetCustTableRequest new];
        custTableRequest.isSchedulerRequest = YES;
        [custTableRequest requestCustTable:managerID];
    } else {
        [self routeRefreshed:nil];
    }
}

#pragma mark - Working with Data
- (NSMutableArray *)getCustomersForDate:(NSDate *)date {
    NSMutableArray *mainAccCustomers = [self getCustomersForDate:date managerID:self.mainAcc];
    
    if (self.selectedManager) {
        NSArray *subAccCustomers = [self getCustomersForDate:date managerID:self.selectedManager[@"id"]];
        for (NSMutableDictionary *customer in subAccCustomers) {
            NSString *custAccount = customer[@"custAccount"];
            
            NSUInteger searchIndex = [mainAccCustomers indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [obj[@"custAccount"] isEqualToString:custAccount];
            }];
            
            if (searchIndex != NSNotFound) {
                [mainAccCustomers[searchIndex][@"managerIDs"] addObject:self.selectedManager[@"id"]];
            } else {
                [mainAccCustomers addObject:customer];
            }
        }
    }
    
    return mainAccCustomers;
}

- (NSMutableArray *)getCustomersForDate:(NSDate *)date managerID:(NSString *)managerID {
    self.mainDateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    NSString *dateOfRoute = [self.mainDateFormatter stringFromDate:date];
    NSMutableArray *customers = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *custForRoute = [managerID isEqualToString:self.mainAcc] ? @"CustForRoute" : @"tmpCustForRoute";
        NSString *sqlString = [NSString stringWithFormat:@"select CustName, CustAddress, CustAccount, RegularRoute, Status, cast(lineNum as integer) as lnum from %@ where DateOfRoute = ? and IsDeleted Is Not 1 and NearCust is NULL order by lnum", custForRoute];
        
        const char *sql = sqlString.UTF8String;

        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [dateOfRoute UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custName = @"null";
                NSString *custAddress = @"null";
                NSString *custAccount = @"null";
                NSString *regularRoute = @"null";
                NSString *status = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                if (sqlite3_column_text(selectstmt, 1))
                    custAddress = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                if (sqlite3_column_text(selectstmt, 2))
                    custAccount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                if (sqlite3_column_text(selectstmt, 3))
                    regularRoute = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                if (sqlite3_column_text(selectstmt, 4))
                    status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                NSMutableDictionary *customer = [NSMutableDictionary new];
                customer[@"custName"] = custName;
                customer[@"custAddress"] = custAddress;
                customer[@"custAccount"] = custAccount;
                customer[@"regularRoute"] = regularRoute;
                customer[@"status"] = status;
                customer[@"managerIDs"] = @[managerID].mutableCopy;
                
                if ([custName isEqualToString:@"null"] && [custAddress isEqualToString:@"null"]) {
                    [self tryGetNameAndAddress:customer];
                }
                
                [customers addObject:customer];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    return customers;
}

- (void)tryGetNameAndAddress:(NSMutableDictionary *)customer {
    NSString *sqlString = @"select Name, Address from tmpCustTable where CustAccount = ?";
    
    const char *sql = sqlString.UTF8String;
    
    sqlite3_stmt *selectstmt;
    
    if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [customer[@"custAccount"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selectstmt) == SQLITE_ROW) {
            if (sqlite3_column_text(selectstmt, 0)) {
                customer[@"custName"] = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
            
            if (sqlite3_column_text(selectstmt, 1)) {
                customer[@"custAddress"] = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
            }
        }
    }
    sqlite3_finalize(selectstmt);
}

- (void)addCustomers:(NSArray *)customers toDate:(NSDate *)date {
    self.mainDateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    NSString *dateOfRoute = [self.mainDateFormatter stringFromDate:date];
    NSString *errorMessage = @"";
    
    SchedulerDay *destinationDay = [ASPFunctions firstObjectInArray:self.schedulerDays where:^BOOL(SchedulerDay *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [NSCalendar.currentCalendar isDate:obj.date inSameDayAsDate:date];
    }];
    
    for (int i = 0; i < customers.count; i++) {
        NSDictionary *customer = customers[i];
        if (destinationDay) {
            NSUInteger customerIndex = [destinationDay.customers indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [obj[@"custAccount"] isEqual:customer[@"custAccount"]];
            }];

            if (customerIndex != NSNotFound) {
                NSMutableArray *managerIDs = destinationDay.customers[customerIndex][@"managerIDs"];
                if (![managerIDs containsObject:self.currentAcc]) {
                    [managerIDs addObject:self.currentAcc];
                } else {
                    errorMessage = [NSString stringWithFormat:@"%@\n- %@", errorMessage, customer[@"custName"]];
                    continue;
                }
            }
        }
        
#warning - ARRAY HERE!!!!
        PutClientForRouteRequest *sendCustForRoute = [PutClientForRouteRequest new];
        sendCustForRoute.managerID = self.currentAcc;
        sendCustForRoute.custAccount = customer[@"custAccount"];
        sendCustForRoute.custAddress = customer[@"custAddress"];
        sendCustForRoute.custName = customer[@"custName"];
        sendCustForRoute.date = dateOfRoute;
        sendCustForRoute.forDelete = NO;
        sendCustForRoute.notShowProgress = YES;
        sendCustForRoute.delegate = self;
        [sendCustForRoute sendCust];
        
        NSInteger lineNum = destinationDay ? destinationDay.customers.count + i : i;
        NSString *strLineNum = [NSString stringWithFormat:@"%lu", lineNum];

        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            NSString *custForRoute = [self.currentAcc isEqualToString:self.mainAcc] ? @"CustForRoute" : @"tmpCustForRoute";
            NSString *sqlString = [NSString stringWithFormat:@"replace into %@ (CustAccount, DateOfRoute, RegularRoute, CustName, GPSPoint, lineNum, GPSRequest, isSended) Values(?, ?, ?, ?, ?, ?, ?, ?)", custForRoute];
            
            const char *sql = sqlString.UTF8String;
            
            sqlite3_stmt *addStmt;

            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(addStmt, 1, [customer[@"custAccount"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 2, [dateOfRoute UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 3, [@"No" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 4, [customer[@"custName"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 5, [customer[@"custAddress"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 6, [strLineNum UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 7, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_int(addStmt, 8, 0);
                
                sqlite3_step(addStmt);
                sqlite3_finalize(addStmt);
            }
        }
    }
    sqlite3_close(database);
    
    if (destinationDay) {
        NSInteger selectedDayCellIndex = [self.schedulerDays indexOfObject:destinationDay];
        
        destinationDay.customers = [self getCustomersForDate:destinationDay.date];
        [self.daysCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:selectedDayCellIndex inSection:0]]];
    }
    
    [self.customersCollectionView reloadData];
    self.lblNoCustomers.hidden = self.selectedDay.customers.count > 0;
    
    if (errorMessage.length > 2) {
        [AlertWorkerObjc alertWithTitle:@"Невозможно повторно добавить в маршрут:" message:errorMessage];
    }
}

- (void)removeCustomers:(NSArray *)customers {
    self.mainDateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    NSString *dateOfRoute = [self.mainDateFormatter stringFromDate:self.selectedDay.date];
    
    NSMutableIndexSet *indicesToRemove = [NSMutableIndexSet new];
    NSMutableArray *indexPathsToDelete = [NSMutableArray new];
    for (int i = 0; i < customers.count; i++) {
        NSDictionary *customer = customers[i];
        
        NSUInteger customerIndex = [self.selectedDay.customers indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj[@"custAccount"] isEqual:customer[@"custAccount"]];
        }];
        
        if (customerIndex != NSNotFound) {
            NSMutableArray *managerIDs = self.selectedDay.customers[customerIndex][@"managerIDs"];
            [managerIDs removeObject:self.currentAcc];
            if (managerIDs.count == 0) {
                [indicesToRemove addIndex:customerIndex];
                [indexPathsToDelete addObject:[NSIndexPath indexPathForItem:customerIndex inSection:0]];
            }
            
            PutClientForRouteRequest *sendCustForRoute = [PutClientForRouteRequest new];
            sendCustForRoute.managerID = self.currentAcc;
            sendCustForRoute.custAccount = customer[@"custAccount"];
            sendCustForRoute.date = dateOfRoute;
            sendCustForRoute.forDelete = YES;
            sendCustForRoute.notShowProgress = YES;
            sendCustForRoute.delegate = self;
            [sendCustForRoute sendCust];
            
            if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
                NSString *custForRoute = [self.currentAcc isEqualToString:self.mainAcc] ? @"CustForRoute" : @"tmpCustForRoute";
                NSString *sqlString = [NSString stringWithFormat:@"update %@ set isSended = ?, IsDeleted = ? where CustAccount = ? and DateOfRoute = ?", custForRoute];
                
                const char *sql = sqlString.UTF8String;
                
                sqlite3_stmt *deleteStmt;
                
                if (sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL) == SQLITE_OK) {
                    sqlite3_bind_int(deleteStmt, 1, 0);
                    sqlite3_bind_int(deleteStmt, 2, 1);
                    sqlite3_bind_text(deleteStmt, 3, [customer[@"custAccount"] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(deleteStmt, 4, [dateOfRoute UTF8String], -1, SQLITE_TRANSIENT);
                    
                    sqlite3_step(deleteStmt);
                    sqlite3_finalize(deleteStmt);
                }
            }
        }
    }
    sqlite3_close(database);

    if (indexPathsToDelete.count > 0) {
        [self.selectedDay.customers removeObjectsAtIndexes:indicesToRemove];
        [self.customersCollectionView deleteItemsAtIndexPaths:indexPathsToDelete];
    } else {
        [self.customersCollectionView reloadData];
    }
    
    NSInteger selectedDayCellIndex = [self.schedulerDays indexOfObject:self.selectedDay];
    [self.daysCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:selectedDayCellIndex inSection:0]]];

    self.lblNoCustomers.hidden = self.selectedDay.customers.count > 0;
}

- (void)showCustomerInfo:(NSDictionary *)customer {
    if (![customer[@"managerIDs"] containsObject:self.mainAcc]) { return; }
    
    [NavigationWorker openCustomerDetails:customer[@"custAccount"]];
}

#pragma mark - PutClientForRouteDelegate
- (void)isSended:(NSString *)custAccount custName:(NSString *)custName custAddr:(NSString *)custAddress strDate:(NSString *)strDate {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *custForRoute = [self.currentAcc isEqualToString:self.mainAcc] ? @"CustForRoute" : @"tmpCustForRoute";
        NSString *sqlString = [NSString stringWithFormat:@"update %@ Set isSended = ? where CustAccount = ? and DateOfRoute = ?", custForRoute];
        
        const char *sql = sqlString.UTF8String;
        
        sqlite3_stmt *updateStmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_int(updateStmt, 1, 1);
            sqlite3_bind_text(updateStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updateStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_step(updateStmt);
            sqlite3_finalize(updateStmt);
        }
    }
    sqlite3_close(database);
}

- (void)isSendedForDelete:(NSString *)custAccount {
    self.mainDateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    NSString *dateOfRoute = [self.mainDateFormatter stringFromDate:self.selectedDay.date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *custForRoute = [self.currentAcc isEqualToString:self.mainAcc] ? @"CustForRoute" : @"tmpCustForRoute";
        NSString *sqlString = [NSString stringWithFormat:@"delete from %@ where CustAccount = ? and DateOfRoute = ?", custForRoute];
        
        const char *sql = sqlString.UTF8String;
        
        sqlite3_stmt *deleteStmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(deleteStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(deleteStmt, 2, [dateOfRoute UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
    }
    sqlite3_close(database);
}

@end
