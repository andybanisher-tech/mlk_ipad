//
//  SchedulerAccManagementView.h
//  MLK
//
//  Created by Alexandr Polienko on 09.07.2024.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@class SchedulerAccManagementView;

@protocol SchedulerAccManagementViewDelegate <NSObject>

- (void)userDidTapChooseManagerButton:(UIButton *)sender;
- (void)userDidTapChangeAccButton;

@end

@interface SchedulerAccManagementView : UIView

@property (nonatomic, weak) id <SchedulerAccManagementViewDelegate> delegate;

#pragma mark - Setters
- (void)setManager:(NSDictionary *)manager;
- (void)setIsMainAcc:(BOOL)isMainAcc;

@end

NS_ASSUME_NONNULL_END
