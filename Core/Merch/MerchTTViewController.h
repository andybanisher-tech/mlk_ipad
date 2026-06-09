//
//  MerchTTViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 14.06.12.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "PropertyListViewController.h"
#import "PropertyMultipleListViewController.h"
#import "CameraViewController.h"

@class CameraViewController;

@interface MerchTTViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, PropertyListDelegate> {
    BOOL isViewPushed;
    BOOL inVisit;
    
    NSMutableArray  *propIdList;
    NSMutableArray  *propNameList;
    NSMutableArray  *propTypeList;
    NSMutableArray  *propValueList;
    NSMutableArray  *propSendStatusList;
    NSMutableArray  *propMultiple;
	
    NSString *selectedForPropId;
    NSString *valueForProperty;
    NSString *propElementListId;
    NSString *custAccount;
    NSString *selectedDate;
    
    UITextField *alertTextField;
    
    PropertyListAbstractController *propertyListViewController;
}
@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic,readwrite)BOOL inVisit;
@property(nonatomic,retain)NSMutableArray  *propIdList;
@property(nonatomic,retain)NSMutableArray  *propNameList;
@property(nonatomic,retain)NSMutableArray  *propTypeList;
@property(nonatomic,retain)NSMutableArray  *propValueList;
@property(nonatomic,retain)NSString *selectedForPropId;
@property(nonatomic,retain)NSString *valueForProperty;
@property(nonatomic,retain)NSString *propElementListId;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)NSString *selectedDate;
@property(nonatomic,retain)PropertyListAbstractController *propertyListViewController;
@property(nonatomic,retain)NSMutableArray  *propSendStatusList;
@property(nonatomic,retain)NSMutableArray *propMultiple;

- (void)finalizeStatements;
- (void)refreshData;
- (void)propListCreate;
- (void)addPropValue:(NSString*)valueDate property:(NSString*)property value:(NSString*)value;
- (void)alertViewTextFieldDidChanged;
- (void)readValue;
- (void)showList:(UITableViewCell*)cell rowNum:(NSInteger)rowNum propId:(NSString *)propId multiple:(NSString *)multiple;
- (void)makePhoto:(NSString *)property;
- (void)elementIsSelected:(NSString *)listElement propId:(NSString *)propId propElementId:(NSString *)propElementId;
-(BOOL)custInVisit:(NSString *)custAcc;
-(BOOL)custInVisitPhoto:(NSString *)custAcc;
- (void)createTodayPropValue;
- (void)addTodayPropValue:(NSString*)valueDate property:(NSString*)property value:(NSString*)value;
- (void)multipleSelect:(NSMutableDictionary *)selectedCollection propId:(NSString *)propId;

@end
