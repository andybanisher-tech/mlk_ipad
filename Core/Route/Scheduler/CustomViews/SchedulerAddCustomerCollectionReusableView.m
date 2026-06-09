//
//  SchedulerAddCustomerCollectionReusableView.m
//  MLK
//
//  Created by Alexandr Polienko on 20.04.2022.
//

#import "SchedulerAddCustomerCollectionReusableView.h"

@interface SchedulerAddCustomerCollectionReusableView ()
@property (nonatomic, weak) IBOutlet UIButton *btnAddCustomer;

@end

@implementation SchedulerAddCustomerCollectionReusableView

- (void)awakeFromNib{
    [super awakeFromNib];
    [ASPFunctions addLineLayerForView:self.btnAddCustomer lineColor:[ASPFunctions colorFromHex:@"BDBDBD"] lineWidth:2.0 cornerRadius:20.0];
}

@end
