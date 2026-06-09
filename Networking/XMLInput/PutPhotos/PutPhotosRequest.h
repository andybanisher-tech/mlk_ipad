//
//  PutPhotosRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 28.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PutPhotosRequest: NSObject {

    NSString        *custAccount;
    
    BOOL notShowProgress;
}

@property(nonatomic,retain)NSString     *custAccount;

@property(nonatomic,readwrite)BOOL notShowProgress;

- (void)sendGroupPhotos;
- (void)sendMsg:(NSString *)msg;

@end
