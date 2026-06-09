//
//  CustStatusDN.h
//  mlk
//
//  Created by Nikolya Smolnyakov on 17.10.16.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol CustStatusDNDelegate <NSObject>

- (void)userDidSelectStatusDN:(NSMutableArray *)statusDNArray;

@end

@interface CustStatusDN : UITableViewController<UITableViewDelegate,UITableViewDataSource> {
    NSMutableArray       *statusDNList;
    NSMutableArray       *statusDNToLiveInArray;
    
    BOOL visitPlan;
    BOOL addCust;
    BOOL fromTask;
    BOOL fromCustTask;
    
    NSString *custAcccount;
    id                      setBtn;
    NSMutableArray          *statusDNSelected;
    NSMutableArray          *selected;
    
}
@property(nonatomic,retain)NSMutableArray  *statusDNList;
@property(nonatomic,assign) id<CustStatusDNDelegate> delegate;
@property(nonatomic,readwrite)BOOL visitPlan;
@property(nonatomic,readwrite)BOOL addCust;
@property(nonatomic,readwrite)BOOL fromCustTask;
@property(nonatomic,readwrite)BOOL fromTask;
@property(nonatomic,retain)NSString *custAcccount;
@property(nonatomic,retain)NSMutableArray *statusDNSelected;
@property(nonatomic,retain)NSMutableArray *selected;
@property(nonatomic,retain)id setBtn;

- (void)statusDNCreate;

+ (void)finalizeStatements;


@end
