//
//  CDPrimaryHeaderCollectionViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 27.09.2024.
//

#import <UIKit/UIKit.h>

#import "CDPrimarySectionItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CDPrimaryHeaderCollectionViewCell : UICollectionViewCell

#pragma mark - Setters
- (void)setItem:(CDPrimarySectionItem *)item;

@end

NS_ASSUME_NONNULL_END
