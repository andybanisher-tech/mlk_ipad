//
//  CDSecondaryPPLCollectionViewCell.m
//  MLK
//
//  Created by Alexandr Polienko on 27.03.2025.
//

#import "CDSecondaryPPLCollectionViewCell.h"

#import "GeneratedAssetSymbols.h"

@interface CDSecondaryPPLCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *markLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusDNLabel;
@property (weak, nonatomic) IBOutlet UILabel *delayLabel;
@property (weak, nonatomic) IBOutlet UILabel *discountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

@end

@implementation CDSecondaryPPLCollectionViewCell

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
- (void)setPPL:(NSDictionary *)ppl {
    self.markLabel.text = ppl[@"BrandName"];
    self.statusDNLabel.text = ppl[@"Status"];
    self.delayLabel.text = [NSString stringWithFormat:@"%@ дн.", ppl[@"Delay"]];
    self.discountLabel.text = [NSString stringWithFormat:@"%@ %%", ppl[@"ComDiscount"]];
    
    self.photoImageView.image = [ppl[@"imageExists"] boolValue] ? [UIImage imageNamed:ACImageNamePhotoAdded] : [UIImage imageNamed:ACImageNamePhotoMissing];
}

@end
