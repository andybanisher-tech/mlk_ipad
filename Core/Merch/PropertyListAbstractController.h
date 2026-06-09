#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol PropertyListDelegate
- (void)elementIsSelected:(NSString *)listElement propId:(NSString *)propId propElementId:(NSString *)propElementId;
@optional
- (void)multipleSelect:(NSMutableDictionary *)selectedCollection propId:(NSString *)propId;
@end

@interface PropertyListAbstractController : UITableViewController {
    NSMutableArray	*propIdList;
    NSMutableArray	*propIdToLiveInArray;
    
    NSMutableArray	*elementIdList;
    NSMutableArray	*elementIdToLiveInArray;
    
    NSMutableArray	*elementNameList;
    NSMutableArray	*elementNameToLiveInArray;
    
    NSString        *propertyId;
    
    NSMutableDictionary *savedCollection;
}

@property(nonatomic,assign)id<PropertyListDelegate> delegate;
@property(nonatomic,retain)NSMutableArray *propIdList;
@property(nonatomic,retain)NSMutableArray *elementIdList;
@property(nonatomic,retain)NSMutableArray *elementNameList;
@property(nonatomic,retain)NSString *propertyId;
@property(nonatomic,retain)NSMutableDictionary *savedCollection;

@end
