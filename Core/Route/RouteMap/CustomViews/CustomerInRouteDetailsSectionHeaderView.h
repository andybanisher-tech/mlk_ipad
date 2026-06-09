//
//  CustomerInRouteDetailsSectionHeaderView.h
//  MLK
//
//  Created by Alexandr Polienko on 20.06.2024.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@class CustomerInRouteDetailsSectionHeaderView;

@protocol CustomerInRouteDetailsSectionHeaderViewDelegate <NSObject>

- (void)headerCustomerCardButtonTapped;
- (void)headerAddToRouteButtonTapped;
- (void)headerRadiusSliderChangedValue:(float)value;

@end

@interface CustomerInRouteDetailsSectionHeaderView : UICollectionReusableView

@property (nonatomic, weak) id <CustomerInRouteDetailsSectionHeaderViewDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *codeLabel;
@property (nonatomic, weak) IBOutlet UILabel *typeLabel;
@property (nonatomic, weak) IBOutlet UILabel *factAddressLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel *lastOrderDateLabel;
@property (nonatomic, weak) IBOutlet UILabel *tasksLabel;

@property (nonatomic, weak) IBOutlet UIButton *addToRouteButton;

@property (nonatomic, weak) IBOutlet UIStackView *radiusStackView;

- (void)setSearchRadius:(double)radius;

@end

NS_ASSUME_NONNULL_END
