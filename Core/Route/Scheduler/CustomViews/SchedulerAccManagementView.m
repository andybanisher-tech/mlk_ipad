//
//  SchedulerAccManagementView.m
//  MLK
//
//  Created by Alexandr Polienko on 09.07.2024.
//

#import "SchedulerAccManagementView.h"

#import "GeneratedAssetSymbols.h"

@interface SchedulerAccManagementView ()
@property (nonatomic, weak) IBOutlet UIButton *chooseManagerButton;
@property (nonatomic, weak) IBOutlet UIButton *changeAccButton;

@end

@implementation SchedulerAccManagementView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupUI];
}

#pragma mark - Private
- (void)setupUI {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.chooseManagerButton.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    //Constants
    CGFloat rightPadding = 5.0;
    [NSLayoutConstraint activateConstraints:@[
        [self.chooseManagerButton.imageView.centerYAnchor constraintEqualToAnchor:self.chooseManagerButton.centerYAnchor constant:0.0],
        [self.chooseManagerButton.imageView.leadingAnchor constraintEqualToAnchor:self.chooseManagerButton.leadingAnchor constant:rightPadding]
    ]];
}

#pragma mark - Setters
- (void)setManager:(NSDictionary *)manager {
    NSString *name = manager[@"name"] ? manager[@"name"] : @"Выберите менеджера";
    [self.chooseManagerButton setTitle:name forState:UIControlStateNormal];
    self.changeAccButton.hidden = manager == nil;
}

- (void)setIsMainAcc:(BOOL)isMainAcc {
    UIImage *buttonImage = isMainAcc ? [UIImage imageNamed:ACImageNameMainAccRoute] : [UIImage imageNamed:ACImageNameSubAccRoute];
    [self.changeAccButton setImage:buttonImage forState:UIControlStateNormal];
}

#pragma mark - Button Actions
- (IBAction)chooseManagerButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(userDidTapChooseManagerButton:)]) {
        [self.delegate userDidTapChooseManagerButton:sender];
    }
}

- (IBAction)changeAccButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userDidTapChangeAccButton)]) {
        [self.delegate userDidTapChangeAccButton];
    }
}

@end
