//
//  TwoRegions.h
//  MLK
//
//  Created by garu on 11/7/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol TwoRegionsDelegate
- (void)selectRegions:(NSString *)region regionName:(NSString *)regionName;
- (void)selectCityArray:(NSMutableArray *)city cityString:(NSString *)cityString;
@end

@interface TwoRegions : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
	NSMutableArray       *regionValueIdList;
	NSMutableArray       *regionValueIdToLiveInArray;
    
    NSMutableArray       *regionValueNameList;
	NSMutableArray       *regionValueNameToLiveInArray;
    
    NSMutableArray *citySelected;
    NSMutableArray *selected;
    id              setBtn;
    NSString        *cityString;
}
@property(nonatomic,retain)NSMutableArray  *regionValueIdList;
@property(nonatomic,retain)NSMutableArray  *regionValueNameList;
@property(nonatomic,retain)NSMutableArray *citySelected;
@property(nonatomic,retain)NSMutableArray *selected;
@property(nonatomic,retain)id setBtn;
@property(nonatomic,retain)NSString *cityString;

@property(nonatomic,assign) id<TwoRegionsDelegate> delegate;

+ (void)finalizeStatements;

@end
