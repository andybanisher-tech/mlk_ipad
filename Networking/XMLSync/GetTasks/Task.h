//
//  Task.h
//  MLK
//
//  Created by garu on 11/25/14.
//
//

#import <Foundation/Foundation.h>

@interface Task: NSObject {
    NSString    *TaskID;
    NSString    *TaskName;
    NSString    *DateStart;
    NSString    *DateEnd;
    NSString    *TypeOfResult;
    NSString    *Result;
    NSString    *ClientCode;
    NSString    *Status;
    NSString    *Source;
    NSString    *Author;
    NSString    *Comment;
    NSString    *Setted;
    NSString    *Visit;
    NSString    *From1C;
    NSString    *Photo;
}

@property(nonatomic,retain)NSString    *TaskID;
@property(nonatomic,retain)NSString    *TaskName;
@property(nonatomic,retain)NSString    *DateStart;
@property(nonatomic,retain)NSString    *DateEnd;
@property(nonatomic,retain)NSString    *TypeOfResult;
@property(nonatomic,retain)NSString    *Result;
@property(nonatomic,retain)NSString    *ClientCode;
@property(nonatomic,retain)NSString    *Status;
@property(nonatomic,retain)NSString    *Source;
@property(nonatomic,retain)NSString    *Author;
@property(nonatomic,retain)NSString    *Comment;
@property(nonatomic,retain)NSString    *Setted;
@property(nonatomic,retain)NSString    *Visit;
@property(nonatomic,retain)NSString    *From1C;
@property(nonatomic,retain)NSString    *Photo;

@end
