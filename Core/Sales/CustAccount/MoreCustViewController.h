//
//  MoreCustViewController.h
//  MLK
//
//  Created by garu on 11/7/14.
//
//

#import "UIKit/UIKit.h"
#import "BrandDop.h"
#import "TwoRegions.h"
#import "sqlite3.h"

@protocol MoreCustomerDelegate
- (void)customerAdded;
@end

@interface MoreCustViewController : UIViewController <UITextFieldDelegate, BrandDopDelegate, TwoRegionsDelegate> {
    UIButton    *chooseRegionBtn;
    UIButton    *chooseBrandBtn;
    UIButton    *loadBtn;
    UIButton    *cancelBtn;
    
    IBOutlet UITextField *regionValue;
    IBOutlet UITextField *brandValue;
    
    BrandDop            *brandDop;

    TwoRegions           *twoRegions;

    NSString    *propertyValueId;
    NSString    *brandId;
    
    NSMutableArray *cityArray;
    NSMutableArray *markArray;
}
@property(nonatomic,assign)id<MoreCustomerDelegate> delegate;
@property(nonatomic,retain)IBOutlet UIButton *chooseRegionBtn;
@property(nonatomic,retain)IBOutlet UIButton *chooseBrandBtn;
@property(nonatomic,retain)IBOutlet UIButton *loadBtn;
@property(nonatomic,retain)IBOutlet UIButton *cancelBtn;
@property(nonatomic,retain)UITextField *regionValue;
@property(nonatomic,retain)UITextField *brandValue;
@property(nonatomic,retain)NSString *propertyValueId;
@property(nonatomic,retain)NSString *brandId;
@property(nonatomic,retain)BrandDop            *brandDop;

@property(nonatomic,retain)TwoRegions   *twoRegions;

@property(nonatomic,retain)NSMutableArray *cityArray;
@property(nonatomic,retain)NSMutableArray *markArray;

-(IBAction)loadCustomer;
-(IBAction)cancel;
-(IBAction)chooseRegion;
-(IBAction)chooseBrand:(id)sender;
- (void)selectBrand:(NSString *)brand;
- (void)selectRegions:(NSString *)region regionName:(NSString *)regionName;

@end
