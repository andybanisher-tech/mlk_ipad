//
//  TaskList.h
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import <Foundation/Foundation.h>

@interface TaskList: NSObject {
    NSString    *TaskID;
    NSString    *LineID;
    NSString    *LineDescription;
}

@property(nonatomic,retain)NSString    *TaskID;
@property(nonatomic,retain)NSString    *LineID;
@property(nonatomic,retain)NSString    *LineDescription;
@end
