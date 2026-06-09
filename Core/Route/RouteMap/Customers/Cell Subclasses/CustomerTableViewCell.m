//
//  CustomerTableViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 20.04.2022.
//

#import "CustomerTableViewCell.h"

@interface CustomerTableViewCell ()
@property (nonatomic, weak) IBOutlet UIImageView *actionsImageView;


@end

@implementation CustomerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.lblLastVisitDate.font = [UIFont monospacedDigitSystemFontOfSize:16.0 weight:UIFontWeightSemibold];
    self.lblLastOrderDate.font = [UIFont monospacedDigitSystemFontOfSize:16.0 weight:UIFontWeightSemibold];
    self.lblTasksCount.font = [UIFont monospacedDigitSystemFontOfSize:16.0 weight:UIFontWeightSemibold];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCustomerInRouteStatus:(NSString *)status {
    self.actionsImageView.tintColor = UIColor.whiteColor;
    if ([status isEqual:@"visited"]) {
        self.backgroundColor = [ASPFunctions colorFromHex:@"7DE779"];
    } else if ([status isEqual:@"visit"]) {
        self.backgroundColor = [ASPFunctions colorFromHex:@"6395EC"];
    } else if (status) {
        self.backgroundColor = [ASPFunctions colorFromHex:@"BDBDBD"];
    } else {
        self.backgroundColor = UIColor.whiteColor;
        self.actionsImageView.tintColor = [ASPFunctions colorFromHex:@"A6A6A6"];
    }
}

@end
