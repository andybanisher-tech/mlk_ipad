//
//  PutCommentsRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 28.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PutCommentsRequest: NSObject

@property(copy, nonatomic) NSString *custAccount;
@property(copy, nonatomic) NSString *commentId;
  
@property(assign, nonatomic) BOOL notShowProgress;
@property(assign, nonatomic) BOOL notShowErrorMessage;

- (void)sendComments;

@end
