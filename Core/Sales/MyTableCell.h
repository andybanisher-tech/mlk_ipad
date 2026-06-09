//
//  MyTableCell.h
//  Grids
//
//  Created by Tracy Snell on 10/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"


@interface MyTableCell : UITableViewCell {

	NSMutableArray *columns;
	CGRect savedFrame;
}

@property(nonatomic, weak) UILabel *viewToHideOnDeleteState;

- (void)addColumn:(CGFloat)position;

@end
