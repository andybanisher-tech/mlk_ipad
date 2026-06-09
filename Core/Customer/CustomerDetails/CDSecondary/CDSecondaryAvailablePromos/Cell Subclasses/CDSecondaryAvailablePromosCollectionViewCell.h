//
//  CDSecondaryAvailablePromosCollectionViewCell.h
//  MLK
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CDSecondaryAvailablePromosCollectionViewCell;

@protocol CDSecondaryAvailablePromosCollectionViewCellDelegate <NSObject>
- (void)availablePromosCellDidTapDetails:(CDSecondaryAvailablePromosCollectionViewCell *)cell;
@end

@interface CDSecondaryAvailablePromosCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id<CDSecondaryAvailablePromosCollectionViewCellDelegate> delegate;

- (void)setPromo:(NSDictionary *)promo;

@end

NS_ASSUME_NONNULL_END
