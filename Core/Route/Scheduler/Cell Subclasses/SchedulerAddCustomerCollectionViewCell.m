//
//  SchedulerAddCustomerCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 20.04.2022.
//

#import "SchedulerAddCustomerCollectionViewCell.h"

@implementation SchedulerAddCustomerCollectionViewCell

- (void)awakeFromNib{
    [super awakeFromNib];
    [ASPFunctions addLineLayerForView:self lineColor:[ASPFunctions colorFromHex:@"BDBDBD"] lineWidth:2.0 cornerRadius:20.0];
}

@end
