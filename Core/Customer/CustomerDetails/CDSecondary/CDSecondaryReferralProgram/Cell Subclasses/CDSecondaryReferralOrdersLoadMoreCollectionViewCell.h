//
//  CDSecondaryReferralOrdersLoadMoreCollectionViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 27.06.2025.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CDSecondaryReferralOrdersLoadMoreCollectionViewCell : UICollectionViewCell

@property (nonatomic, copy) void (^onCellLoadMoreButtonTapped)(void);

@end

NS_ASSUME_NONNULL_END
