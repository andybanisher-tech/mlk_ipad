//
//  ChooseManagersViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 02.09.2021.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@class SyncTypeViewController;

@protocol ChooseManagersViewControllerDelegate <NSObject>
- (void)userDidChooseManagers:(NSSet *)managers;

@end

@interface ChooseManagersViewController : UIViewController

@property (nonatomic, weak) id <ChooseManagersViewControllerDelegate> delegate;

@property (nonatomic, strong) NSArray *iPadsArray;
@property (nonatomic, strong) NSMutableSet *selectedIPadsSet;
@property (nonatomic, assign) BOOL isSchedulerMode;

@end

NS_ASSUME_NONNULL_END
