//
//  TaskSource.h
//  MLK
//
//  Created by garu on 12/11/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol TaskSourceDelegate <NSObject>

- (void)userDidSelectTaskSources:(NSMutableArray *)taskSources;
@end

@interface TaskSource : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
    NSMutableArray       *sourceList;
    NSMutableArray       *sourceToLiveInArray;
    
    BOOL                fromCust;
    NSString            *custAccount;
    
    id setBtn;
    NSMutableArray      *selected;
}
@property(nonatomic,retain)NSMutableArray  *sourceList;
@property(nonatomic,retain)NSMutableArray  *sourceToLiveInArray;
@property(nonatomic,assign) id<TaskSourceDelegate> delegate;
@property(nonatomic,readwrite)BOOL fromCust;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)NSMutableArray *sourceSelected;
@property(nonatomic,retain)NSMutableArray *selected;
@property(nonatomic,retain)id setBtn;
+ (void)finalizeStatements;

@end
