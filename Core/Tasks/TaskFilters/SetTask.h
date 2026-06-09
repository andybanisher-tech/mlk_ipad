//
//  SetTask.h
//  MLK
//
//  Created by garu on 12/11/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol SetTaskDelegate
- (void)selectSetTask:(NSString *)setValue;
@end

@interface SetTask : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
	NSMutableArray       *setList;
    NSMutableArray       *setToLiveInArray;
    
    BOOL                fromCust;
    NSString            *custAccount;
}
@property(nonatomic,retain)NSMutableArray  *setList;
@property(nonatomic,retain)NSMutableArray  *setToLiveInArray;
@property(nonatomic,assign) id<SetTaskDelegate> delegate;
@property(nonatomic,readwrite)BOOL fromCust;
@property(nonatomic,retain)NSString *custAccount;
+ (void)finalizeStatements;

@end
