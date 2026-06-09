//
//  TaskCustomerTableViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 12.08.2021.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface TaskCustomerTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblCustomerName;
@property (nonatomic, weak) IBOutlet UILabel *lblStartDate;
@property (nonatomic, weak) IBOutlet UILabel *lblSource;
@property (nonatomic, weak) IBOutlet UILabel *lblResult;
@property (nonatomic, weak) IBOutlet UILabel *lblStatus;
@property (nonatomic, weak) IBOutlet UILabel *lblLastActionDate;

@end

NS_ASSUME_NONNULL_END
