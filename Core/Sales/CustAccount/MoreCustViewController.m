//
//  MoreCustViewController.m
//  MLK
//
//  Created by garu on 11/7/14.
//
//

#import "MoreCustViewController.h"
#import "MoreCustRequest.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@interface MoreCustViewController ()

@end

@implementation MoreCustViewController

@synthesize chooseBrandBtn, chooseRegionBtn, loadBtn, cancelBtn, regionValue, brandValue;
@synthesize brandDop, twoRegions;
@synthesize propertyValueId, brandId;
@synthesize cityArray, markArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Загрузка временных клиентов";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    self.navigationController.navigationBar.tintColor = UIColor.whiteColor;

    propertyValueId = @"";
    brandId         = @"";
}

- (BOOL)shouldAutorotate {
    return YES;
}

-(IBAction)chooseBrand:(id)sender {
    if (!brandDop) {
        brandDop              = [[BrandDop alloc] init];
        brandDop.delegate     = self;
        brandDop.selected     = markArray;
        
        brandDop.modalPresentationStyle = UIModalPresentationPopover;
        brandDop.popoverPresentationController.sourceView = chooseBrandBtn;
        
        [self presentViewController:brandDop animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        brandDop = nil;
    }
}

- (void)selectBrand:(NSString *)brand {
    if (brandDop.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        brandDop = nil;
    }
    
    if (brand == nil)
        markArray = nil;
    
    brandValue.text = [self getBrandName:brand];
    
    brandId = brand;
}

- (void)selectBrandArray:(NSMutableArray *)brand brandString:(NSString *)brandString {
    if (brandDop.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        brandDop = nil;
    }
    
    markArray = [brand copy];
    
    brandValue.text = brandString;
    
    NSArray *array = [brand copy];
    int counter;
    
    for(counter = 0; counter < [array count]; counter++) {
        if (counter == 0) {
            brandId = [NSString stringWithFormat:@"%@", [array objectAtIndex:counter]];
        } else {
            brandId = [NSString stringWithFormat:@"%@,%@", brandId, [array objectAtIndex:counter]];
        }
    }
}

- (void)selectCityArray:(NSMutableArray *)city cityString:(NSString *)cityString {
    if (twoRegions.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        twoRegions = nil;
    }
    
    cityArray = [city copy];
    
    regionValue.text = cityString;
    
    NSArray *array = [city copy];
    int counter;
    
    for(counter = 0; counter < [array count]; counter++) {
        if (counter == 0) {
            propertyValueId = [NSString stringWithFormat:@"%@", [array objectAtIndex:counter]];
        } else {
            propertyValueId = [NSString stringWithFormat:@"%@,%@", propertyValueId, [array objectAtIndex:counter]];
        }
    }
}

-(IBAction)chooseRegion {
    if (!twoRegions) {
        twoRegions              = [[TwoRegions alloc] init];
        twoRegions.delegate     = self;
        twoRegions.selected     = cityArray;
        
        twoRegions.modalPresentationStyle = UIModalPresentationPopover;
        twoRegions.popoverPresentationController.sourceView = chooseRegionBtn;
        
        [self presentViewController:twoRegions animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        twoRegions = nil;
    }
}

- (void)selectRegions:(NSString *)region regionName:(NSString *)regionName {
    if (twoRegions.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        twoRegions = nil;
    }
    
    if (region == nil)
        cityArray = nil;
    
    regionValue.text = regionName;
    
    propertyValueId = region;
}
-(IBAction)loadCustomer {
    if ([propertyValueId isEqualToString:@""]) {
        [AlertWorkerObjc alertWithTitle:@"Ошибка" message: @"Необходимо заполнить поле 'Регион'."];
    } else {
        [self dismissViewControllerAnimated:NO completion:nil];
    
        MoreCustRequest *moreCustRequest = [MoreCustRequest new];
    
        moreCustRequest.propertyValueId = propertyValueId;
        moreCustRequest.brandId         = brandId;
        moreCustRequest.isCustContactRequest = NO;
        [moreCustRequest moreCustReq];
    }
}

-(IBAction)cancel {
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(NSString *)getBrandName:(NSString *)brand {
    NSString *brandName = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select BrandName from BrandDop where BrandId = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [brand UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                if (sqlite3_column_text(selectstmt, 0))
                    brandName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }

    return brandName;
}

@end
