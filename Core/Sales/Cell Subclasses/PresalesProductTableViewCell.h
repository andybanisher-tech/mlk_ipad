//
//  PresalesProductTableViewCell.h
//  MLK
//
//  Created by Alexandr Polienko on 08.09.2022.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface PresalesProductTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblNumber;
@property (nonatomic, weak) IBOutlet UILabel *lblProductCode;
@property (nonatomic, weak) IBOutlet UILabel *lblBrand;
@property (nonatomic, weak) IBOutlet UILabel *lblName;

@property (nonatomic, weak) IBOutlet UILabel *lblBadProduct;

@property (nonatomic, weak) IBOutlet UITextField *txtQtyField;

@property (nonatomic, weak) IBOutlet UILabel *lblSum;
@property (nonatomic, weak) IBOutlet UILabel *lblAvailableQty;

#pragma mark - Setters
- (void)setPrice:(NSNumber *)price discount:(NSNumber *)discount;

@end

NS_ASSUME_NONNULL_END
