//
//  OverlaySelectCustAcc.h
//  MLK
//
//  Created by Rustem Galyamov on 27.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import "UIKit/UIKit.h"

@class SelectCustAcc;

@interface OverlaySelectCustAcc : UIViewController {
	SelectCustAcc *rvController;
}

@property (nonatomic, retain) SelectCustAcc *rvController;

@end
