//
//  GlobalSettingsView.h
//  MLK
//
//  Created by Rustem Galyamov on 15.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"

@interface GlobalSettingsView : UIViewController {
    BOOL isViewPushed;
    IBOutlet UILabel *udidLabel;
    
    UITextField *tfUsername;
    UITextField *tfUserpass;
    UITextField *tfEmple;
}
@property(nonatomic,readwrite) BOOL isViewPushed;
@property(nonatomic,retain) UILabel *udidLabel;

@property(nonatomic, retain) IBOutlet UITextField *tfUsername;
@property(nonatomic, retain) IBOutlet UITextField *tfUserpass;
@property(nonatomic, retain) IBOutlet UITextField *tfEmple;

@property (nonatomic, weak) IBOutlet UIButton *btnServerAddress;

-(IBAction)userFieldDoneEditing:(id)sender;
-(IBAction)passFieldDoneEditing:(id)sender;
-(IBAction)empleFieldDoneEditing:(id)sender;

@end
