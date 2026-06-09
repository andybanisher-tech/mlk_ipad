//
//  DNGrid.h
//  MLK
//
//  Created by Rustem Galyamov on 20.11.12.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol DNGridDelegate
- (void)gridIsUpdated;
-(IBAction)showDNActionSheet:(id)sender title:(NSString *)titleTxt custAccount:(NSString *)custAccountLoc brandId:(NSString *)brandId;
@end

@interface DNGrid : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray		 *brandIdList;
    NSMutableArray		 *brandNameList;
    NSMutableArray		 *monthList;
	NSMutableArray		 *sysStatusList;
	NSMutableArray		 *managerStatusList;
	NSMutableArray		 *commentList;
    NSMutableArray       *sendStatusList;
    
    NSString             *custAccount;
}

@property(nonatomic,assign) id<DNGridDelegate> delegate;
@property(nonatomic,retain)NSMutableArray *brandIdList;
@property(nonatomic,retain)NSMutableArray *brandNameList;
@property(nonatomic,retain)NSMutableArray *monthList;
@property(nonatomic,retain)NSMutableArray *sysStatusList;
@property(nonatomic,retain)NSMutableArray *managerStatusList;
@property(nonatomic,retain)NSMutableArray *commentList;
@property(nonatomic,retain)NSMutableArray *sendStatusList;
@property(nonatomic,retain)NSString       *custAccount;

- (void)createLineList;

- (void)finalizeStatements;
- (void)refreshData;

@end
