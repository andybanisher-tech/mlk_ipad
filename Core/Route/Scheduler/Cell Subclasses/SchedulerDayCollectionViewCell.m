//
//  SchedulerDayCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 18.12.2021.
//

#import "SchedulerDayCollectionViewCell.h"

#import "GeneratedAssetSymbols.h"

@interface SchedulerDayCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *connectedManagerImageView;
@property (nonatomic, weak) IBOutlet UIImageView *commonCustomerImageView;

@property (nonatomic, strong) IBOutletCollection(UILabel) NSArray *customerNameLabels;

@property (nonatomic, weak) IBOutlet UILabel *lblCustomersCount;

@end

@implementation SchedulerDayCollectionViewCell

- (void)awakeFromNib{
    [super awakeFromNib];
    [ASPFunctions addLineLayerForView:self lineColor:UIColor.clearColor lineWidth:4.0 cornerRadius:0.0];
    [ASPFunctions addLineLayerForView:self.contentView lineColor:[ASPFunctions colorFromHex:@"9D9D9D"] lineWidth:1.0 cornerRadius:0.0];
}

#pragma mark - Setters
- (void)setCustomers:(NSArray *)customers mainAcc:(NSString *)mainAcc {
    NSUInteger subAccCustomerIndex = [customers indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return ![obj[@"managerIDs"] containsObject:mainAcc];
    }];
    
    self.connectedManagerImageView.hidden = subAccCustomerIndex == NSNotFound;
    
    NSUInteger commonCustomerIndex = [customers indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj[@"managerIDs"] count] > 1;
    }];
    
    self.commonCustomerImageView.hidden = commonCustomerIndex == NSNotFound;
    
    for (int i = 0; i < self.customerNameLabels.count; i++) {
        UILabel *lblCustomer = self.customerNameLabels[i];
        if (customers.count > i) {
            lblCustomer.text = customers[i][@"custName"];
            lblCustomer.superview.hidden = NO;
            if ([customers[i][@"status"] isEqual:@"visited"]) {
                lblCustomer.superview.backgroundColor = [ASPFunctions colorFromHex:@"7DE779"];
            } else if ([customers[i][@"status"] isEqual:@"visit"]) {
                lblCustomer.superview.backgroundColor = [ASPFunctions colorFromHex:@"6395EC"];
            } else {
                lblCustomer.superview.backgroundColor = [ASPFunctions colorFromHex:@"BDBDBD"];
            }
        } else {
            lblCustomer.superview.hidden = YES;
        }
    }
    
    if (customers.count > self.customerNameLabels.count) {
        self.lblCustomersCount.text = [NSString stringWithFormat:@"ещё %lu... (%lu)", customers.count - self.customerNameLabels.count, customers.count];
    } else {
        self.lblCustomersCount.text = nil;
    }
}

- (void)setCellSelected:(BOOL)selected {
    if (selected) {
        self.contentView.layer.borderWidth = 3.0;
        self.contentView.layer.borderColor = [UIColor colorNamed:ACColorNameMLKBlue].CGColor;
        
        self.lblDayNumber.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        self.lblDayNumber.textColor = [UIColor colorNamed:ACColorNameMLKBlue];
    } else {
        self.contentView.layer.borderWidth = 1.0;
        self.contentView.layer.borderColor = [ASPFunctions colorFromHex:@"9D9D9D"].CGColor;
        
        self.lblDayNumber.font = [UIFont systemFontOfSize:14.0];
        self.lblDayNumber.textColor = [UIColor blackColor];
    }
}

- (void)setDropDestinationColor:(UIColor *)color {
    self.layer.borderColor = color.CGColor;
}

@end
