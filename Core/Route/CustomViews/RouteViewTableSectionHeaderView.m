//
//  RouteViewTableSectionHeaderView.m
//  MLK
//
//  Created by Alexandr Polienko on 09.08.2023.
//

#import "RouteViewTableSectionHeaderView.h"

@interface RouteViewTableSectionHeaderView () <UITextFieldDelegate>

@end

@implementation RouteViewTableSectionHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.searchDistanceTextField.delegate = self;
}

#pragma mark - Button Actions
- (IBAction)showButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(headerShowButtonTapped:)]) {
        [self.delegate headerShowButtonTapped:self.searchDistanceTextField.text.doubleValue];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger dotsCount = [textField.text componentsSeparatedByString:@"."].count - 1;
    if (dotsCount > 0 && [string isEqual:@"."]) {
        return NO;
    }
    
    return [string isEqualToString:@""] || [string isEqualToString:@"0"] || [string isEqualToString:@"."] || string.integerValue;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self showButtonTapped:nil];
    return YES;
}

@end
