//
//  CustomerInRouteCollectionViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 18.06.2024.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@class CustomerInRouteCollectionViewCell;

@protocol CustomerInRouteCollectionViewCellDelegate <NSObject>

@optional
- (void)cellBtnRemoveCustomerTapped:(CustomerInRouteCollectionViewCell *)sender;

@end

@interface CustomerInRouteCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id <CustomerInRouteCollectionViewCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *lblName;

@property (weak, nonatomic) IBOutlet UIImageView *managerInfoImageView;

@property (nonatomic, weak) IBOutlet UIButton *btnRemove;

@end

NS_ASSUME_NONNULL_END
