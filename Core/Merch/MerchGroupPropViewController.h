//
//  MerchGroupPropViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 30.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol GroupPropControllerDelegate
- (void)showList:(UITableViewCell*)cell rowNum:(NSInteger)rowNum propId:(NSString*)propId;
- (void)elementIsSelected:(NSString *)listElement propId:(NSString *)propId propElementId:(NSString *)propElementId;
- (void)brandSelected:(NSString*)brandId;
- (void)makePhoto:(NSString *)property;
@end

@interface MerchGroupPropViewController : UITableViewController <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate, UINavigationControllerDelegate> {    
	NSMutableArray  *propIdList;
    NSMutableArray  *propNameList;
    NSMutableArray  *propTypeList;
    NSMutableArray  *propValueList;
    NSMutableArray  *propSendStatusList;
	
    NSString *groupId;
    NSString *brandId;
    NSString *listElement;
    NSString *propElementListId;
    NSString *selectedForPropId;
    NSString *valueForProperty;
    NSString *custAccount;
    NSString *selectedDate;
    
    UITextField *alertTextField;
    
    BOOL custInVisit;
}

@property(nonatomic,retain)NSMutableArray  *propIdList;
@property(nonatomic,retain)NSMutableArray  *propNameList;
@property(nonatomic,retain)NSMutableArray  *propTypeList;
@property(nonatomic,retain)NSMutableArray  *propValueList;
@property(nonatomic,retain)NSMutableArray  *propSendStatusList;
@property(nonatomic,assign) id<GroupPropControllerDelegate> delegate;
@property(nonatomic,retain)NSString *groupId;
@property(nonatomic,retain)NSString *brandId;
@property(nonatomic,retain)NSString *listElement;
@property(nonatomic,retain)NSString *propElementListId;
@property(nonatomic,retain)NSString *selectedForPropId;
@property(nonatomic,retain)NSString *valueForProperty;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)NSString *selectedDate;
@property(nonatomic,readwrite)BOOL custInVisit;

- (void)finalizeStatements;
- (void)refreshData;
- (void)propListCreate;
- (void)addPropValue:(NSString*)valueDate group:(NSString*)group brandId:(NSString*)brand property:(NSString*)property value:(NSString*)value;
- (void)alertViewTextFieldDidChanged;
- (void)readValue;
- (void)createTodayPropValue;
- (void)addTodayPropValue:(NSString*)valueDate group:(NSString*)group brandId:(NSString*)brand property:(NSString*)property value:(NSString*)value;

@end
