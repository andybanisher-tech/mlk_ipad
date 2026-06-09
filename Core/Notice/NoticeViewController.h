//
//  NoticeViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 17.12.12.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "NoticeDescrViewController.h"

@interface NoticeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NoticeDelegate> {
    BOOL isViewPushed;
    
    NSMutableArray  *idListNew;
    NSMutableArray  *nameListNew;
    NSMutableArray  *descrListNew;
    //NSMutableArray  *statusListNew;
    
    NSMutableArray  *idList;
    NSMutableArray  *nameList;
    NSMutableArray  *descrList;
    //NSMutableArray  *statusList;
}

@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic,retain)NSMutableArray  *idListNew;
@property(nonatomic,retain)NSMutableArray  *nameListNew;
@property(nonatomic,retain)NSMutableArray  *descrListNew;
//@property(nonatomic,retain)NSMutableArray  *statusListNew;

@property(nonatomic,retain)NSMutableArray  *idList;
@property(nonatomic,retain)NSMutableArray  *nameList;
@property(nonatomic,retain)NSMutableArray  *descrList;
//@property(nonatomic,retain)NSMutableArray  *statusList;

@property (nonatomic, strong) IBOutlet UITableView *tableView;

- (void)cancel_Clicked:(id)sender;
- (void)createNoticeList;
- (void)createNotice;
- (void)gridIsUpdated;
-(BOOL)checkForNotice;

@end
