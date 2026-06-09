//
//  RouteViewTableSectionHeaderView.h
//  MLK
//
//  Created by Alexandr Polienko on 09.08.2023.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RouteViewTableSectionHeaderViewDelegate <NSObject>

- (void)headerShowButtonTapped:(double)searchRadius;

@end

@interface RouteViewTableSectionHeaderView : UITableViewHeaderFooterView

@property (nonatomic, weak) id <RouteViewTableSectionHeaderViewDelegate> delegate;

@property (nonatomic, weak) IBOutlet UITextField *searchDistanceTextField;

@end

NS_ASSUME_NONNULL_END
