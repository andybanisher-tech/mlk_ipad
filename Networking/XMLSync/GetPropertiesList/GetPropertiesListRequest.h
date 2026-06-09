//
//  GetPropertiesList.h
//  MLK
//
//  Created by Rustem Galyamov on 02.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetPropertiesListRequest: NSObject

@property (nonatomic, assign) BOOL syncTTPropertiesOnly;

- (void)propListReq;

@end

