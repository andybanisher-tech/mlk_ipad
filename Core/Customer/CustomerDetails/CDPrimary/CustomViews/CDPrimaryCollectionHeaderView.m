//
//  CDPrimaryCollectionHeaderView.m
//  MLK
//
//  Created by Alexandr Polienko on 21.07.2025.
//

#import "CDPrimaryCollectionHeaderView.h"

@interface CDPrimaryCollectionHeaderView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation CDPrimaryCollectionHeaderView

#pragma mark - Setters
- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

@end
