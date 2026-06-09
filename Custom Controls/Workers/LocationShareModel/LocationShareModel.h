//
//  LocationShareModel.h
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BackgroundTaskManager.h"

@interface LocationShareModel: NSObject

@property(nonatomic,retain) NSTimer *timer;
@property(nonatomic,retain) BackgroundTaskManager * bgTask;

+(id)sharedModel;

@end
