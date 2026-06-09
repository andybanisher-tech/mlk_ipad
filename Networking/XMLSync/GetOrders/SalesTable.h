//
//  SalesTable.h
//  MLK
//
//  Created by Rustem Galyamov on 24.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SalesTable: NSObject {
    NSString    *SalesNum;
    NSString    *SalesDate;
    NSString    *DeliveryDate;
    NSString    *CustAccount;
    NSString    *ContractID;
    NSString    *AmountSum;
    NSString    *ChannelTypeID;
    NSString    *SalesStatus;
    NSString    *Comment;
    NSString    *SalesNum1c;
    NSString    *SalesUUID;
    NSString    *ActionID;
    NSString    *ActionType;
}

@property(nonatomic,retain)NSString *SalesNum;
@property(nonatomic,retain)NSString *SalesDate;
@property(nonatomic,retain)NSString *DeliveryDate;
@property(nonatomic,retain)NSString *CustAccount;
@property(nonatomic,retain)NSString *ContractID;
@property(nonatomic,retain)NSString *AmountSum;
@property(nonatomic,retain)NSString *ChannelTypeID;
@property(nonatomic,retain)NSString *SalesStatus;
@property(nonatomic,retain)NSString *Comment;
@property(nonatomic,retain)NSString *SalesNum1c;
@property(nonatomic,retain)NSString *SalesUUID;
@property(nonatomic,retain)NSString *ActionID;
@property(nonatomic,retain)NSString *ActionType; 

@end
