//
//  FirmViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 21.01.13.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol FirmDelegate
- (void)selectFirm:(NSString *)firmId firmName:(NSString *)firmName firmMarkup:(NSString *)firmMarkup;
@end

@interface FirmViewController : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
	NSMutableArray       *firmIdList;
    NSMutableArray       *firmNameList;
    NSMutableArray       *firmMarkupList;
}

@property(nonatomic,retain)NSMutableArray  *firmIdList;
@property(nonatomic,retain)NSMutableArray  *firmNameList;
@property(nonatomic,retain)NSMutableArray  *firmMarkupList;

@property(nonatomic,assign) id<FirmDelegate> delegate;

+(void)finalizeStatements;
- (void)firmListCreate;

@end
