//
//  TaskTableViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 12.08.2021.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@class TaskTableViewCell;

@protocol TaskTableViewCellDelegate <NSObject>

@optional
- (void)cellBtnAssignTapped:(TaskTableViewCell *)cell;
@end

@interface TaskTableViewCell : UITableViewCell

@property (nonatomic, weak) id <TaskTableViewCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *lblTaskName;
@property (nonatomic, weak) IBOutlet UILabel *lblTaskPeriod;
@property (nonatomic, weak) IBOutlet UIButton *btnAssign;

@end

NS_ASSUME_NONNULL_END
