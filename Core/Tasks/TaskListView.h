//
//  TaskListView.h
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol TaskListDelegate
- (void)selectListId:(NSString *)listId listName:(NSString *)listName;
@end

@interface TaskListView : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
	NSMutableArray       *listIdList;
	NSMutableArray       *listIdToLiveInArray;
    
    NSMutableArray       *listNameList;
	NSMutableArray       *listNameToLiveInArray;
    
    NSString    *taskId;
}
@property(nonatomic,retain)NSMutableArray  *listIdList;
@property(nonatomic,retain)NSMutableArray  *listNameList;
@property(nonatomic,retain)NSString *taskId;

@property(nonatomic,assign) id<TaskListDelegate> delegate;

+ (void)finalizeStatements;

@end
