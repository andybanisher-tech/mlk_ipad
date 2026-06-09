//
//  SchedulerDayCollectionViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 18.12.2021.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface SchedulerDayCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblDayNumber;

#pragma mark - Setters
- (void)setCustomers:(NSArray *)customers mainAcc:(NSString *)currentAcc;

- (void)setCellSelected:(BOOL)selected;
- (void)setDropDestinationColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
