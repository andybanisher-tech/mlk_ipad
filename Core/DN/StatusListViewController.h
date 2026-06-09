//
//  StatusListViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 27.11.12.
//
//

#import "UIKit/UIKit.h"

@protocol StatusListDelegate
- (void)elementIsSelected:(NSString *)listElement;
@end

@interface StatusListViewController : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
    NSMutableArray	*elementNameList;
    NSMutableArray	*elementNameToLiveInArray;
}

@property(nonatomic,assign)id<StatusListDelegate> delegate;
@property(nonatomic,retain)NSMutableArray *elementNameList;

- (void)createList;
- (void)refreshData;

@end
