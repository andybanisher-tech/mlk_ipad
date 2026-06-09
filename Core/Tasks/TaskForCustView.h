//
//  TaskForCustView.h
//  MLK
//
//  Created by garu on 12/12/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol TaskForCustDelegate
- (void)selectTask:(NSString *)taskNum taskName:(NSString *)taskN;
@end

@interface TaskForCustView : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
	NSMutableArray       *taskList;
	NSMutableArray       *taskToLiveInArray;
    
    NSMutableArray       *taskNameList;
	NSMutableArray       *taskNameToLiveInArray;
    
    NSString    *custAccount;
}
@property(nonatomic,retain)NSMutableArray  *taskList;
@property(nonatomic,retain)NSMutableArray  *taskNameList;
@property(nonatomic,retain)NSString *custAccount;

@property(nonatomic,assign) id<TaskForCustDelegate> delegate;

+ (void)finalizeStatements;

@end
