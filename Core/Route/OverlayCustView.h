//
//  OverlayCustView.h
//  MLK
//
//  Created by Rustem Galyamov on 03.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"

@class CustViewController;

@interface OverlayCustView : UIViewController {
	CustViewController *rvController;
}

@property (nonatomic, retain) CustViewController *rvController;

@end
