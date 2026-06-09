//
//  CustForTaskView.h
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import "UIKit/UIKit.h"
#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "CustCity.h"
#import "CustBrand.h"
#import "CustDream.h"

@protocol CustForTaskDelegate
- (void)selectCustAcc:(NSString *)custAccount custName:(NSString *)custName;
@end

@interface CustForTaskView : UITableViewController <UITableViewDelegate,UITableViewDataSource, CustCityDelegate, CustBrandDelegate, UISearchBarDelegate, CustDreamDelegate> {
	NSMutableArray       *custAccList;
	NSMutableArray       *custAccToLiveInArray;
    NSMutableArray		 *arrayByCopyCustAccList;
    
    NSMutableArray       *custNameList;
	NSMutableArray       *custNameToLiveInArray;
    NSMutableArray		 *arrayByCopyCustNameList;
    
    NSString    *taskId;
    IBOutlet UISearchBar *searchBar;
    
    NSString *fcity;
    NSMutableArray *cityArray;
    NSString *fkey;
    NSMutableArray *keyArray;
    NSString *fmark;
    NSMutableArray *markArray;
    
    id cityBtn;
    id markBtn;
    id keyBtn;
    
    NSMutableArray *selectedArray;
}
@property(nonatomic,retain)NSMutableArray  *custAccList;
@property(nonatomic,retain)NSMutableArray  *custNameList;
@property(nonatomic,retain)NSString *taskId;
@property(nonatomic,retain)NSString *fcity;
@property(nonatomic,retain)NSMutableArray *cityArray;
@property(nonatomic,retain)NSString *fkey;
@property(nonatomic,retain)NSMutableArray *keyArray;
@property(nonatomic,retain)NSString *fmark;
@property(nonatomic,retain)NSMutableArray *markArray;
@property(nonatomic,retain)id cityBtn;
@property(nonatomic,retain)id markBtn;
@property(nonatomic,retain)id keyBtn;
@property(nonatomic,retain)NSMutableArray *arrayByCopyCustAccList;
@property(nonatomic,retain)NSMutableArray *arrayByCopyCustNameList;
@property(nonatomic,retain)NSMutableArray *selectedArray;

@property(nonatomic,assign) id<CustForTaskDelegate> delegate;

+ (void)finalizeStatements;

@end
