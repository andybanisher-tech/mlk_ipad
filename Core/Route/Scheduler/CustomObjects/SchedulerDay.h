//
//  SchedulerDay.h
//  MLK
//
//  Created by Alexandr Polienko on 15.01.2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SchedulerDay: NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, copy) NSString *number;

@property (nonatomic, strong) NSMutableArray *customers;

@property (nonatomic, assign) BOOL isWithinDisplayedMonth;
@property (nonatomic, assign) BOOL isInPast;

@end

NS_ASSUME_NONNULL_END
