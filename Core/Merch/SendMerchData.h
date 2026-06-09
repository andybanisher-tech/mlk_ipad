//
//  SendMerchData.h
//  MLK
//
//  Created by Rustem Galyamov on 28.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"
#import "PutGroupPropertiesValueRequest.h"
#import "PutTTPropertiesValueRequest.h"
#import "PutCommentsRequest.h"
#import "PutPhotosRequest.h"

@interface SendMerchData: NSObject {
    NSString *custAccount;
    
    PutGroupPropertiesValueRequest *putGroupPropertiesValue;
    PutTTPropertiesValueRequest    *putTTPropertiesValue;
    PutCommentsRequest             *putComments;
    PutPhotosRequest          *putGroupPhotos;
}

@property (nonatomic,retain) NSString *custAccount;

- (void)sendGroupPropertiesValue;
- (void)sendTTPropertiesValue;
- (void)sendComments;
- (void)sendGroupPhotos;

@end
