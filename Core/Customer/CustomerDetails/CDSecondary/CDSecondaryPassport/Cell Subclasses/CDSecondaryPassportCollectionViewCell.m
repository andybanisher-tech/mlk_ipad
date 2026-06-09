//
//  CDSecondaryPassportCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 28.03.2025.
//

#import "CDSecondaryPassportCollectionViewCell.h"

#import "GeneratedAssetSymbols.h"

@interface CDSecondaryPassportCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UIImageView *indicatorImageView;

@end

@implementation CDSecondaryPassportCollectionViewCell

#pragma mark - Life Cycle
- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.contentView.backgroundColor = highlighted ? UIColor.systemGray4Color : UIColor.whiteColor;
    } completion:nil];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.contentView.backgroundColor = selected ? UIColor.systemGray4Color : UIColor.whiteColor;
}

#pragma mark - Setters
- (void)setData:(NSDictionary *)data {
    self.nameLabel.text = data[@"PropertyName"];
    
    NSString *type = data[@"PropertyType"];
    NSString *value = data[@"Value"];
    
    if ([type localizedStandardContainsString:@"bool"]) {
        self.valueLabel.text = nil;
        
        BOOL isYES = [value localizedStandardContainsString:@"yes"];
        self.indicatorImageView.image = isYES ? [self circleCheckmarkImage] : [self circleImage];
    } else if ([type localizedStandardContainsString:@"photo"]) {
        self.valueLabel.text = nil;
        
        self.indicatorImageView.image = [data[@"imageExists"] boolValue] ? [UIImage imageNamed:ACImageNamePhotoAdded] : [UIImage imageNamed:ACImageNamePhotoMissing];
    } else {
        NSInteger valuesCount = [value componentsSeparatedByString:@","].count;
        self.valueLabel.text = valuesCount > 1 ? [NSString stringWithFormat:@"(%ld)", (long)valuesCount] : value;
        
        self.indicatorImageView.image = [UIImage imageNamed:ACImageNameRightArrow];
    }
}

#pragma mark - Helpers
- (UIImage *)circleImage {
    return [[UIImage systemImageNamed:@"circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30.0]] imageWithTintColor:[ASPFunctions colorFromHex:@"BDBDBD"] renderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIImage *)circleCheckmarkImage {
    return [[UIImage systemImageNamed:@"checkmark.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30.0 weight:UIImageSymbolWeightMedium]] imageWithTintColor:[UIColor colorNamed:ACColorNameMLKBlue]];
}

@end
