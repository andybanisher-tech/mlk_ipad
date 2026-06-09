//
//  CustDream.h
//  MLK
//
//  Created by Rustem Galyamov on 06.12.13.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol CustDreamDelegate <NSObject>

- (void)userDidSelectDream:(NSMutableArray *)dreamArray;
@end

@interface CustDream : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
	NSMutableArray       *dreamList;
	NSMutableArray       *dreamToLiveInArray;
    
    BOOL visitPlan;
    BOOL addCust;
    BOOL fromTask;
    BOOL fromCustTask;
    
    NSString *custAcccount;
    id              setBtn;
    NSMutableArray *dreamSelected;
    NSMutableArray          *selected;
}

@property(nonatomic,retain)NSMutableArray  *dreamList;
@property(assign, nonatomic) id<CustDreamDelegate> delegate;
@property(nonatomic,readwrite)BOOL visitPlan;
@property(nonatomic,readwrite)BOOL addCust;
@property(nonatomic,readwrite)BOOL fromCustTask;
@property(nonatomic,readwrite)BOOL fromTask;
@property(nonatomic,retain)NSString *custAcccount;
@property(nonatomic,retain)NSMutableArray *dreamSelected;
@property(nonatomic,retain)NSMutableArray *selected;
@property(nonatomic,retain)id setBtn;

- (void)dreamListCreate;

+ (void)finalizeStatements;

@end
