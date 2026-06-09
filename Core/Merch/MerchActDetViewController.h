//
//  MerchActDetViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 15.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "ActionFileRequest.h"

@protocol ActionDetailDelegate
- (void)closeView:(BOOL)closeAll;
@end

@interface MerchActDetViewController : UIViewController {
    BOOL isViewPushed;
    
    UIButton    *actionBtn;
    UIButton    *getFile;
    UIButton    *addSalesLine;
    
    UINavigationController *infoNavController;
    
    IBOutlet UITextField *brandTxt;
    IBOutlet UITextField *setIdTxt;
    IBOutlet UITextField *nameTxt;
    IBOutlet UITextField *priceTxt;
    IBOutlet UITextField *availQtyTxt;
    IBOutlet UITextField *typeTxt;
    IBOutlet UITextField *amountSumTxt;
    IBOutlet UITextField *amountQtyTxt;
    IBOutlet UITextView  *setDescrTxt;
    IBOutlet UITextField  *salesQtyTxt;
    
    NSString *brand;
    NSString *setId;
    NSString *name;
    NSString *price;
    NSString *availQty;
    NSString *type;
    NSString *amountSum;
    NSString *amountQty;
    NSString *setDescr;
    NSString *actionId;
    NSString *brandId;
    
    ActionFileRequest *actionFileRequest;
    
    NSString *custAccount;
    
    IBOutlet UILabel *labelQty;
    IBOutlet UILabel *labelSum;
    
    BOOL fromMerch;
}

@property(nonatomic,assign)id<ActionDetailDelegate> delegate;

@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic,retain)IBOutlet UIButton *actionBtn;
@property(nonatomic,retain)IBOutlet UIButton *getFile;
@property(nonatomic,retain)IBOutlet UIButton *addSalesLine;
@property(nonatomic,retain)NSString *brand;
@property(nonatomic,retain)NSString *setId;
@property(nonatomic,retain)NSString *name;
@property(nonatomic,retain)NSString *price;
@property(nonatomic,retain)NSString *availQty;
@property(nonatomic,retain)NSString *type;
@property(nonatomic,retain)NSString *amountSum;
@property(nonatomic,retain)NSString *amountQty;
@property(nonatomic,retain)NSString *setDescr;
@property(nonatomic,retain)NSString *actionId;
@property(nonatomic,retain)NSString *brandId;
@property(nonatomic,retain)UITextField *brandTxt;
@property(nonatomic,retain)UITextField *setIdTxt;
@property(nonatomic,retain)UITextField *nameTxt;
@property(nonatomic,retain)UITextField *priceTxt;
@property(nonatomic,retain)UITextField *availQtyTxt;
@property(nonatomic,retain)UITextField *typeTxt;
@property(nonatomic,retain)UITextField *amountSumTxt;
@property(nonatomic,retain)UITextField *amountQtyTxt;
@property(nonatomic,retain)UITextView *setDescrTxt;
@property(nonatomic,retain)UITextField *salesQtyTxt;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)UILabel *labelQty;
@property(nonatomic,retain)UILabel *labelSum;
@property(nonatomic,readwrite)BOOL fromMerch;

-(IBAction)getActionFile;
-(IBAction)prepareSalesLine;
-(NSTimer*)createTimer;
- (void)updateBtn;
- (void)closeView:(BOOL)closeAll;

@end
