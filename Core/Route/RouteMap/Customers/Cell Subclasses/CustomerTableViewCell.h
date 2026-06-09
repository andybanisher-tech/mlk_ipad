//
//  CustomerTableViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 20.04.2022.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomerTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblName;
@property (nonatomic, weak) IBOutlet UILabel *lblAddress;

@property (weak, nonatomic) IBOutlet UIImageView *managerInfoImageView;

@property (nonatomic, weak) IBOutlet UILabel *lblLastVisitDate;
@property (nonatomic, weak) IBOutlet UILabel *lblLastOrderDate;
@property (nonatomic, weak) IBOutlet UILabel *lblTasksCount;

- (void)setCustomerInRouteStatus:(NSString *)status;

@end

NS_ASSUME_NONNULL_END
