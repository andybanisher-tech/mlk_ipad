//
//  CDSecondaryPPLCollectionHeaderView.h
//  MLK
//
//  Created by Alexandr Polienko on 27.03.2025.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CDSecondaryPPLCollectionHeaderView : UICollectionReusableView

@property (nonatomic, copy) void (^onHeaderSortButtonTapped)(void);

@end

NS_ASSUME_NONNULL_END
