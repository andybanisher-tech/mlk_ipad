//
//  SalesDetailViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"


@interface SalesDetailViewController : UIViewController <UISplitViewControllerDelegate> {
    
	UIToolbar *toolbar;
	UIViewController *mainController;	
}

@property(retain,nonatomic) UIToolbar *toolbar;


@end

