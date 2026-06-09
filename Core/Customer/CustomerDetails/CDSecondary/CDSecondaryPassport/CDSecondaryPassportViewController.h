//
//  CDSecondaryPassportViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 28.03.2025.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CDSecondaryPassportViewController : UIViewController

@property (nonatomic, copy) NSString *custAccount;
@property (nonatomic, copy) NSString *ttID;
@property (nonatomic, assign) BOOL isCustInVisit;

@end

NS_ASSUME_NONNULL_END
