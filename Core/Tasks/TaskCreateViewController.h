//
//  TaskCreateViewController.h
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "CustForTaskView.h"
#import "PutTasksRequest.h"

#import "ASPDatePickerViewController.h"

@class MLKBorderedTextField;

@interface TaskCreateViewController : UIViewController <UITextFieldDelegate, CustForTaskDelegate, SendTaskDelegate, ASPDatePickerViewControllerDelegate> {
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
    NSString *from1C;
    
    IBOutlet MLKBorderedTextField *textTypeField;
    UIButton             *saveTask;
    IBOutlet UILabel     *labelCustName;
    IBOutlet UILabel     *labelTaskEndDate;
    
    UIButton    *custListBtn;
    
    IBOutlet UIButton   *setDeliveryDateBtn;
    
    
    BOOL settingOldTask;
}
@property(nonatomic,readwrite) BOOL isViewPushed;
@property(nonatomic,readwrite) BOOL settingOldTask;
@property(nonatomic,retain)NSString *custAcc;
@property(nonatomic,retain)NSString *custNameStr;
@property(nonatomic,retain)NSString *taskId;
@property(nonatomic,retain)NSString *typeOfResult;
@property(nonatomic,retain)NSString *result;
@property(nonatomic,retain)NSString *dateEnd;
@property(nonatomic,retain)NSString *taskName;
@property(nonatomic,retain)NSString *status;
@property(nonatomic,retain)NSString *taskSet;
@property(nonatomic,retain)NSString *taskVisit;
@property(nonatomic,retain)NSString *from1C;
@property(nonatomic,retain)IBOutlet UIButton *saveTask;
@property(nonatomic,retain)UILabel *labelCustName;
@property(nonatomic,retain)UILabel *labelTaskEndDate;
@property(nonatomic,retain)UITextField *textTypeField;
@property(nonatomic,retain)UIButton *custListBtn;
@property(nonatomic,retain)IBOutlet UIButton *setDeliveryDateBtn;

@property(nonatomic,retain)NSString *dateStart;

- (void)cancel_Clicked:(id)sender;
-(IBAction)listBtn_pressed:(id)sender;
//-(IBAction)openList;
- (void)selectCustAcc:(NSString *)custAccount custName:(NSString *)custName;

@end
