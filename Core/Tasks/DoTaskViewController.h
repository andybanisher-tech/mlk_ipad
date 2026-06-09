//
//  DoTaskViewController.h
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "TaskListView.h"
#import "PutTasksRequest.h"

@interface DoTaskViewController : UIViewController <UITextFieldDelegate, TaskListDelegate, SendTaskDelegate> {
    BOOL isViewPushed;
    
    NSString *custAccount;
    NSString *custName;
    NSString *taskId;
    NSString *typeOfResult;
    NSString *result;
    NSString *dateEnd;
    NSString *taskName;
    NSString *status;
    NSString *needPhoto;
    
    UIButton    *boolValueBtn;
    BOOL        boolValue;
    
    TaskListView         *taskListView;
    
}
@property(nonatomic,readwrite) BOOL isViewPushed;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)NSString *custName;
@property(nonatomic,retain)NSString *taskId;
@property(nonatomic,retain)NSString *typeOfResult;
@property(nonatomic,retain)NSString *result;
@property(nonatomic,retain)NSString *dateEnd;
@property(nonatomic,retain)NSString *taskName;
@property(nonatomic,retain)NSString *status;
@property(nonatomic,retain)NSString *needPhoto;
@property(nonatomic,readwrite)BOOL boolValue;
@property(nonatomic,retain)UIButton *boolValueBtn;
@property(nonatomic,retain)TaskListView        *taskListView;

@property (nonatomic, strong) NSDictionary *taskTransData;

@end
