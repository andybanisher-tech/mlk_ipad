//
//  TaskTransViewController.h
//  MLK
//
//  Created by garu on 12/4/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "TaskListView.h"
#import "PutTasksRequest.h"

@interface TaskTransViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, SendTaskDelegate> {
    UIButton             *addBtn;
    UIButton             *cancelBtn;
    UIButton             *doneBtn;
    
    IBOutlet UILabel     *labelTaskName;
    IBOutlet UILabel     *labelTaskStatus;
    
    IBOutlet UITableView *taskTransTable;
    
    BOOL isViewPushed;
    NSString *needPhoto;
    
    NSString *taskId;
    NSString *taskName;
    NSString *custAccount;
    NSString *custName;
    
    NSString *status;
    NSString *typeOfResult;
    NSString *result;
    NSString *dateEnd;
    
    UINavigationController *infoNavController;
    
    NSString             *doneReason;
    NSString             *cancelReason;
}
@property(nonatomic,retain)IBOutlet UIButton *addBtn;
@property(nonatomic,retain)UILabel *labelTaskName;
@property(nonatomic,retain)UILabel *labelTaskStatus;
@property(nonatomic,retain)UITableView *taskTransTable;
@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic,retain)NSString *taskId;
@property(nonatomic,retain)NSString *taskName;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)NSString *custName;
@property(nonatomic,retain)NSString *status;
@property(nonatomic,retain)NSString *typeOfResult;
@property(nonatomic,retain)NSString *result;
@property(nonatomic,retain)NSString *dateEnd;
@property(nonatomic,retain)NSString *doneReason;
@property(nonatomic,retain)NSString *cancelReason;
@property(nonatomic,retain)NSString *needPhoto;

@end
