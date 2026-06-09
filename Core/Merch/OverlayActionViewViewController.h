//
//  OverlayActionViewViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 09.04.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"

@class MerchActionViewController;

@interface OverlayActionViewViewController : UIViewController {
	MerchActionViewController *rvController;
}

@property (nonatomic, retain) MerchActionViewController *rvController;

@end
