//
//  CDSecondaryPassportCollectionHeaderView.m
//  MLK
//
//  Created by Alexandr Polienko on 28.03.2025.
//

#import "CDSecondaryPassportCollectionHeaderView.h"

@interface CDSecondaryPassportCollectionHeaderView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation CDSecondaryPassportCollectionHeaderView

#pragma mark - Setters
- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

@end
