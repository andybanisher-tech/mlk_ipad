//
//  ASPPDFReaderViewController.h
//  MLK
//
//  Created by Alexandr Polienko on 11.11.2023.
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface ASPPDFReaderViewController : UIViewController

+ (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithPdfData:(NSData *)pdfData;
- (instancetype)initWithPdfPath:(NSString *)pdfPath;

@end

NS_ASSUME_NONNULL_END
