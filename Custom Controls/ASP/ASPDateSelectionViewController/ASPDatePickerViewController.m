//
//  ASPDatePickerViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 06.04.2021.
//

#import "ASPDatePickerViewController.h"

#import "GeneratedAssetSymbols.h"

//Constants
static const CGFloat kPickerViewWidth = 300.0;

@interface ASPDatePickerViewController ()
@property (nonatomic, strong) UIDatePicker *mainDatePicker;

@end

@implementation ASPDatePickerViewController

- (void)viewIsAppearing:(BOOL)animated {
    [super viewIsAppearing:animated];
    CGFloat pickerViewHeight = ceil([self.view systemLayoutSizeFittingSize: UILayoutFittingCompressedSize].height);
    self.preferredContentSize = CGSizeMake(kPickerViewWidth, pickerViewHeight);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    //UI Setup
    UIToolbar *datePickerToolbar = [[UIToolbar alloc] initWithFrame:self.view.bounds];
    [datePickerToolbar sizeToFit];
    datePickerToolbar.clipsToBounds = YES;
    
    UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *btnDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];
    datePickerToolbar.items = @[btnCancel, flexSpace, btnDone];
    datePickerToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:datePickerToolbar];

    UIView *bottomLineView = [[UIView alloc] initWithFrame:datePickerToolbar.frame];
    bottomLineView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    bottomLineView.translatesAutoresizingMaskIntoConstraints = NO;
    [datePickerToolbar addSubview:bottomLineView];
    
    self.mainDatePicker = [UIDatePicker new];
    self.mainDatePicker.tintColor = [UIColor colorNamed:ACColorNameMLKBlue];
    self.mainDatePicker.date = NSDate.date;
    self.mainDatePicker.datePickerMode = UIDatePickerModeDate;
    self.mainDatePicker.preferredDatePickerStyle = UIDatePickerStyleInline;
    self.mainDatePicker.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview: self.mainDatePicker];
    
    [NSLayoutConstraint activateConstraints:@[
        //DatePickerToolbar
        [datePickerToolbar.heightAnchor constraintEqualToConstant:datePickerToolbar.bounds.size.height],
        [datePickerToolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [datePickerToolbar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [datePickerToolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        
        //BottomLineView
        [bottomLineView.heightAnchor constraintEqualToConstant:0.5],
        [bottomLineView.leadingAnchor constraintEqualToAnchor:datePickerToolbar.leadingAnchor],
        [bottomLineView.trailingAnchor constraintEqualToAnchor:datePickerToolbar.trailingAnchor],
        [bottomLineView.bottomAnchor constraintEqualToAnchor:datePickerToolbar.bottomAnchor],
        
        //MainDatePicker
        [self.mainDatePicker.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mainDatePicker.topAnchor constraintEqualToAnchor:datePickerToolbar.bottomAnchor],
        [self.mainDatePicker.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mainDatePicker.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]
    ];
}

- (void)setDatePickerMode:(UIDatePickerMode)datePickerMode {
    self.mainDatePicker.datePickerMode = datePickerMode;
}

- (void)setDatePickerStyle:(UIDatePickerStyle)datePickerStyle {
    self.mainDatePicker.preferredDatePickerStyle = datePickerStyle;
}

- (void)setCurrentDate:(NSDate *)currentDate {
    self.mainDatePicker.date = currentDate;
}

- (void)setMaximumDate:(NSDate *)maximumDate {
    self.mainDatePicker.maximumDate = maximumDate;
}

- (void)setMinimumDate:(NSDate *)minimumDate {
    self.mainDatePicker.minimumDate = minimumDate;
}

#pragma mark - Delegate
- (void)cancelButtonTapped {
    if ([self.delegate respondsToSelector:@selector(datePickerDidCancel)]) {
        [self.delegate datePickerDidCancel];
    }
}

- (void)doneButtonTapped {
    if ([self.delegate respondsToSelector:@selector(datePickerDidPickDate:)]) {
        [self.delegate datePickerDidPickDate:self.mainDatePicker.date];
    }
}

@end
