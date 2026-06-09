//
//  CustomerInRouteCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 18.06.2024.
//

#import "CustomerInRouteCollectionViewCell.h"

@implementation CustomerInRouteCollectionViewCell

#pragma mark - Cell Delegate
- (IBAction)btnRemoveCustomerTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cellBtnRemoveCustomerTapped:)]) {
        [self.delegate cellBtnRemoveCustomerTapped:self];
    }
}

@end
