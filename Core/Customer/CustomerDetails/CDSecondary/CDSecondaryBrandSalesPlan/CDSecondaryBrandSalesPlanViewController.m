//
//  CDSecondaryBrandSalesPlanViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 23.02.2026.
//

#import "CDSecondaryBrandSalesPlanViewController.h"

//VCs
#import "ASPDatePickerViewController.h"

//Cells
#import "CDSecondaryBrandSalesPlanCollectionViewCell.h"

//Custom Objects
#import "Debouncer.h"

#import "GeneratedAssetSymbols.h"

@interface CDSecondaryBrandSalesPlanViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ASPDatePickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *mainCollectionView;

@property (nonatomic, strong) UIButton *selectedDateButton;

@property (nonatomic, strong) NSCalendar *mainCalendar;
@property (nonatomic, strong) NSDateFormatter *mainDateFormatter;
@property (nonatomic, strong) NSDate *selectedDate;

@property (nonatomic, strong) NSArray *dataSource;

@property (nonatomic, strong) Debouncer *debouncer;

@end

@implementation CDSecondaryBrandSalesPlanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self prepareLayout];
    [self prepareInitialData];
    [self getBrandSalesPlan];
}

#pragma mark - Setup UI
- (void)setupNavBar {
    //MonthNavigationView
    UIButton *previousMonthButton = [self monthButton:@selector(previousMonthButtonTapped) title:@"<" fontSize:25.0];
    self.selectedDateButton = [self monthButton:@selector(selectedDateButtonTapped) title:nil fontSize:18.0];
    UIButton *nextMonthButton = [self monthButton:@selector(nextMonthButtonTapped) title:@">" fontSize:25.0];
    
    UIStackView *monthNavigationStackView = [[UIStackView alloc] initWithArrangedSubviews:@[previousMonthButton, self.selectedDateButton, nextMonthButton]];
    monthNavigationStackView.spacing = 3.0;
    monthNavigationStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    //Constants
    CGFloat monthButtonSide = 35.0;
    [NSLayoutConstraint activateConstraints:@[
        //MonthNavigationStackView
        [monthNavigationStackView.heightAnchor constraintEqualToConstant:monthButtonSide],
        
        //PreviousMonthButton
        [previousMonthButton.widthAnchor constraintEqualToAnchor:monthNavigationStackView.heightAnchor multiplier:1.0],
        
        //NextMonthButton
        [nextMonthButton.widthAnchor constraintEqualToAnchor:monthNavigationStackView.heightAnchor multiplier:1.0],
    ]];
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:monthNavigationStackView];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

- (void)prepareLayout {
    UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    configuration.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    configuration.headerMode = UICollectionLayoutListHeaderModeSupplementary;
    configuration.itemSeparatorHandler = ^UIListSeparatorConfiguration * _Nonnull(NSIndexPath * _Nonnull indexPath, UIListSeparatorConfiguration * _Nonnull sectionSeparatorConfiguration) {
        sectionSeparatorConfiguration.bottomSeparatorInsets = NSDirectionalEdgeInsetsZero;
        return sectionSeparatorConfiguration;
    };
    
    UICollectionViewCompositionalLayout *layout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:configuration];
    self.mainCollectionView.collectionViewLayout = layout;
}

- (void)prepareInitialData {
    //Initial setups
    self.debouncer = [[Debouncer alloc] init];
    
    self.mainCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    self.mainDateFormatter = NSDateFormatter.new;
    self.mainDateFormatter.defaultDate = NSDate.date;
    
    self.selectedDate = NSDate.date;
}

#pragma mark - Data Setters
- (void)setSelectedDate:(NSDate *)selectedDate {
    if (_selectedDate == selectedDate) {
        return;
    }
    
    _selectedDate = selectedDate;
    
    self.mainDateFormatter.dateFormat = @"LLLL yyyy";
    NSString *selectedDateString = [self.mainDateFormatter stringFromDate:selectedDate];
    [UIView performWithoutAnimation:^{
        [self.selectedDateButton setTitle:selectedDateString.capitalizedString forState:UIControlStateNormal];
        [self.selectedDateButton.superview layoutIfNeeded];
    }];
}

#pragma mark - Networking
- (void)getBrandSalesPlan {
    self.mainDateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    NSString *dateString = [self.mainDateFormatter stringFromDate:self.selectedDate];
    
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Получаем план по марке за %@...", dateString]];
    
    [APIWorker.sharedInstance getBrandSalesPlan:self.custAccount date:dateString completion:^(id _Nullable data, NSError * _Nullable error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        } else {
            if ([data isKindOfClass:NSArray.class]) {
                self.dataSource = data;
                [self.mainCollectionView reloadData];
            } else if ([data isKindOfClass:NSDictionary.class]) {
                NSString *errorString = [data[@"Errors"] firstObject][@"error_message"];
                [SVProgressHUD showErrorWithStatus:errorString];
            }
            
            [SVProgressHUD dismiss];
        }
    }];
}

#pragma mark - Button Actions
- (void)previousMonthButtonTapped {
    [self changeSelectedDateByMonthOffset:-1];
}

- (void)selectedDateButtonTapped {
    ASPDatePickerViewController *datePickerVC = [ASPDatePickerViewController new];
    datePickerVC.delegate = self;
    datePickerVC.modalPresentationStyle = UIModalPresentationPopover;
    datePickerVC.popoverPresentationController.sourceView = self.selectedDateButton;
    datePickerVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    [self presentViewController:datePickerVC animated:YES completion:nil];
    
    [datePickerVC setDatePickerStyle:UIDatePickerStyleWheels];
    if (@available(iOS 17.4, *)) {
        [datePickerVC setDatePickerMode:UIDatePickerModeYearAndMonth];
    }
    [datePickerVC setCurrentDate:self.selectedDate];
}

- (void)nextMonthButtonTapped {
    [self changeSelectedDateByMonthOffset:1];
}

#pragma mark - ASPDatePickerViewControllerDelegate
- (void)datePickerDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)datePickerDidPickDate:(NSDate *)date {
    if (![self.mainCalendar isDate:self.selectedDate equalToDate:date toUnitGranularity:NSCalendarUnitMonth]) {
        self.selectedDate = date;
        [self getBrandSalesPlan];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CDSecondaryBrandSalesPlanSectionHeaderView" forIndexPath:indexPath];
        return headerView;
    }
    
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDSecondaryBrandSalesPlanCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDSecondaryBrandSalesPlanCollectionViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.dataSource[indexPath.item];
    [cell setBrandSalesPlan:object];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - Helpers
- (UIButton *)monthButton:(SEL)action title:(NSString *)title fontSize:(CGFloat)fontSize {
    UIButton *monthButton = [UIButton buttonWithType:UIButtonTypeSystem];
    monthButton.titleLabel.font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightBold];
    [monthButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [monthButton setTitle:title forState:UIControlStateNormal];
    [monthButton setTitleColor:[UIColor colorNamed:ACColorNameMLKLightBlue] forState:UIControlStateNormal];
    
    return monthButton;
}

- (void)changeSelectedDateByMonthOffset:(NSInteger)offset {
    NSDateComponents *components = NSDateComponents.new;
    components.month = offset;

    self.selectedDate = [self.mainCalendar dateByAddingComponents:components toDate:self.selectedDate options:kNilOptions];

    __weak typeof(self) weakSelf = self;
    [self.debouncer dispatch:^{
        [weakSelf getBrandSalesPlan];
    }];
}

@end
