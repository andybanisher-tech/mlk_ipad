//
//  BrandDop.h
//  MLK
//
//  Created by garu on 11/12/14.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol BrandDopDelegate
- (void)selectBrand:(NSString *)brand;
- (void)selectBrandArray:(NSMutableArray *)brand brandString:(NSString *)brandString;
@end

@interface BrandDop : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
	NSMutableArray       *brandList;
	NSMutableArray       *brandToLiveInArray;
    
    NSMutableArray       *brandIdList;
	NSMutableArray       *brandIdToLiveInArray;
    
    id                      setBtn;
    NSMutableArray          *brandSelected;
    NSMutableArray          *selected;
    NSString                *brandString;
    
}
@property(nonatomic,retain)NSMutableArray  *brandList;
@property(nonatomic,retain)NSMutableArray  *brandIdList;

@property(nonatomic,assign) id<BrandDopDelegate> delegate;

@property(nonatomic,retain)NSMutableArray *brandSelected;
@property(nonatomic,retain)NSMutableArray *selected;
@property(nonatomic,retain)id setBtn;
@property(nonatomic,retain)NSString *brandString;

+ (void)finalizeStatements;

@end
