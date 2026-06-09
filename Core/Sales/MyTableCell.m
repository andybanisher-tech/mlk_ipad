//
//  MyTableCell.m
//  Grids
//
//  Created by Tracy Snell on 10/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MyTableCell.h"

#define cell1Width 80
#define cell2Width 80
#define cellHeight 44

@implementation MyTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // Initialization code
        columns = [NSMutableArray arrayWithCapacity:5];
    }
    return self;
}

- (void)addColumn:(CGFloat)position {
	[columns addObject:[NSNumber numberWithFloat:position]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}

- (void)setViewToHideOnDeleteState:(UILabel *)viewToHideOnDeleteState {
	_viewToHideOnDeleteState = viewToHideOnDeleteState;
	savedFrame = viewToHideOnDeleteState.frame;
}

- (void)willTransitionToState:(UITableViewCellStateMask)state {
	[super willTransitionToState:state];
	/*if (self.viewToHideOnDeleteState)
		self.viewToHideOnDeleteState.hidden = state == 3;*/
	if (self.viewToHideOnDeleteState) {
		if (state == 3)
			[self.viewToHideOnDeleteState setFrame:CGRectOffset(savedFrame,-25,0)];
		else
			[self.viewToHideOnDeleteState setFrame:savedFrame];
	}
}
/*
- (void)drawRect:(CGRect)rect { 
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	// just match the color and size of the horizontal line
	CGContextSetRGBStrokeColor(ctx, 0.5, 0.5, 0.5, 1.0); 
	CGContextSetLineWidth(ctx, 0.25);

	for (int i = 0; i < [columns count]; i++) {
		// get the position for the vertical line
		CGFloat f = [((NSNumber*) [columns objectAtIndex:i]) floatValue];
		CGContextMoveToPoint(ctx, f, 0);
		CGContextAddLineToPoint(ctx, f, self.bounds.size.height);
	}
	
	CGContextStrokePath(ctx);
	
	[super drawRect:rect];
}*/

/*- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);       
    
	// CGContextSetLineWidth: The default line width is 1 unit. When stroked, the line straddles the path, with half of the total width on either side.
	// Therefore, a 1 pixel vertical line will not draw crisply unless it is offest by 0.5. This problem does not seem to affect horizontal lines.
	CGContextSetLineWidth(context, 1.0);
	
	// If this is the topmost cell in the table, draw the line on top
	for (int i = 0; i < [columns count]; i++) {
		// get the position for the vertical line
		CGFloat f = [((NSNumber*) [columns objectAtIndex:i]) floatValue];
		CGContextMoveToPoint(context, f, 0);
		CGContextAddLineToPoint(context, f, self.bounds.size.height);
	}
	
	// Draw the lines
	CGContextStrokePath(context); 
}*/

@end
