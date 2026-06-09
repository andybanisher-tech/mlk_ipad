//
//  CDSecondaryReferralCodeViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 21.07.2025.
//

#import "CDSecondaryReferralCodeViewController.h"

#import "sqlite3.h"

//Constants
static NSString *const kBonusInfoText = @"Ваш персональный бонус от мастера!\nПолучите скидку в магазине Космедэль — просто покажите этот код!\n\n{custAccount}\n\nКак это работает?\n\n- Приходите в розничный магазин Космедэль.\n- На кассе покажите этот флаер с QR-кодом.\n- Получите скидку на покупку — легко и просто!\n\nСкидка действует на ассортимент профессиональной косметики, ухода и расходных материалов.\n\nАдреса магазинов:";

@interface CDSecondaryReferralCodeViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;

@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@property (weak, nonatomic) IBOutlet UIImageView *qrCodeImageView;

@property (weak, nonatomic) IBOutlet UILabel *custAccountLabel;

@end

static sqlite3 *database = nil;

@implementation CDSecondaryReferralCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareData];
}

#pragma mark - Prepare Data
- (void)prepareData {
    NSArray *cosmAddresses;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "SELECT CosmAddressesJSON FROM CustTable WHERE CustAccount = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            
            sqlite3_bind_text(selectstmt, 1, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0)) {
                    NSString *cosmAddressesJSON = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                    
                    NSData *cosmAddressesData = [cosmAddressesJSON dataUsingEncoding:NSUTF8StringEncoding];
                    cosmAddresses = [NSJSONSerialization JSONObjectWithData:cosmAddressesData options:0 error:nil];
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self bindData:cosmAddresses];
}

- (void)bindData:(NSArray *)cosmAddresses {
    NSString *bonusInfoText = [kBonusInfoText stringByReplacingOccurrencesOfString:@"{custAccount}" withString:self.custAccount];
    NSString *addressesString = [cosmAddresses componentsJoinedByString:@"\n"];
    
    self.textLabel.text = [NSString stringWithFormat:@"%@\n%@", bonusInfoText, addressesString];
    
    self.qrCodeImageView.image = [self generateQRCodeWithString:self.custAccount];
    self.custAccountLabel.text = self.custAccount;
}

#pragma mark - Button Actions
- (IBAction)closeButtonTapped:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)shareButtonTapped:(id)sender {
    UIImage *imageToShare = self.qrCodeImageView.image;
    if (!imageToShare) { return; }

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[imageToShare] applicationActivities:nil];
    activityVC.popoverPresentationController.sourceView = sender;
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - UI Helpers
- (UIImage *)generateQRCodeWithString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setValue:data forKey:@"inputMessage"];
    CIImage *qrCIImage = filter.outputImage;

    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
    [colorFilter setValue:qrCIImage forKey:kCIInputImageKey];
    [colorFilter setValue:[CIColor colorWithCGColor:UIColor.blackColor.CGColor] forKey:@"inputColor0"];
    [colorFilter setValue:[CIColor colorWithCGColor:UIColor.clearColor.CGColor] forKey:@"inputColor1"];
    
    CIImage *coloredImage = colorFilter.outputImage;

    CGFloat scaleX = 15.0;
    CGFloat scaleY = 15.0;
    CIImage *scaledImage = [coloredImage imageByApplyingTransform:CGAffineTransformMakeScale(scaleX, scaleY)];

    return [UIImage imageWithCIImage:scaledImage scale:UIScreen.mainScreen.scale orientation:UIImageOrientationUp];
}

@end
