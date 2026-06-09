//
//  TaskTransTableViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 20.05.2021.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface TaskTransTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblSource;
@property (nonatomic, weak) IBOutlet UILabel *lblAuthor;
@property (nonatomic, weak) IBOutlet UILabel *lblValue;
@property (nonatomic, weak) IBOutlet UILabel *lblStatus;
@property (nonatomic, weak) IBOutlet UILabel *lblDate;

@end

NS_ASSUME_NONNULL_END
