//
//  SetTaskToCustViewController.h
//  MLK
//
//  Created by garu on 12/12/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "TaskForCustView.h"
#import "PutTasksRequest.h"

@interface SetTaskToCustViewController : UIViewController <UITextFieldDelegate, TaskForCustDelegate, SendTaskDelegate> {
    BOOL isViewPushed;
    
    NSString *custAcc;
    NSString *custNameStr;
    NSString *taskId;
    NSString *dateEnd;
    NSString *taskName;
    NSString *dateStart;
    NSString *typeOfResult;
    NSString *taskSet;
    NSString *taskVisit;
    NSString *taskSource;
    NSString *from1C;
    NSString *photo;
    
    UIButton             *saveTask;
    IBOutlet UILabel     *labelCustName;
    IBOutlet UILabel     *labelTaskEndDate;
}

@property (nonatomic, readwrite) BOOL isViewPushed;
@property (nonatomic, retain) NSString *custAcc;
@property (nonatomic, retain) NSString *custNameStr;
@property (nonatomic, retain) NSString *taskId;
@property (nonatomic, retain) NSString *typeOfResult;
@property (nonatomic, retain) NSString *result;
@property (nonatomic, retain) NSString *dateEnd;
@property (nonatomic, retain) NSString *taskName;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) NSString *taskSet;
@property (nonatomic, retain) NSString *taskVisit;
@property (nonatomic, retain) NSString *taskSource;
@property (nonatomic, retain) IBOutlet UIButton *saveTask;
@property (nonatomic, retain) UILabel *labelCustName;
@property (nonatomic, retain) UILabel *labelTaskEndDate;
@property (nonatomic, retain) NSString *dateStart;
@property (nonatomic, retain) NSString *from1C;
@property (nonatomic, retain) NSString *photo;

- (void)cancel_Clicked:(id)sender;
- (void)selectTask:(NSString *)taskId taskName:(NSString *)taskName;

@end
