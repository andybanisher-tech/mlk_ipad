//
//  CustomerInRouteDetailsSectionHeaderView.m
//  MLK
//
//  Created by Alexandr Polienko on 20.06.2024.
//

#import "CustomerInRouteDetailsSectionHeaderView.h"

//Constants
static const float kRadiusSliderMinValue = 0.5;
static const float kRadiusSliderMaxValue = 3.0;

@interface CustomerInRouteDetailsSectionHeaderView ()

@property (nonatomic, weak) IBOutlet UILabel *radiusLabel;
@property (nonatomic, weak) IBOutlet UISlider *radiusSlider;

@end

@implementation CustomerInRouteDetailsSectionHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];    
    self.radiusSlider.minimumValue = kRadiusSliderMinValue;
    self.radiusSlider.maximumValue = kRadiusSliderMaxValue;
}

- (void)setSearchRadius:(double)radius {
    self.radiusLabel.text = [NSString stringWithFormat:@"Радиус поиска: %.1f km", radius];
    self.radiusSlider.value = radius;
}

#pragma mark - Button Actions
- (IBAction)customerCardButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(headerCustomerCardButtonTapped)]) {
        [self.delegate headerCustomerCardButtonTapped];
    }
}

- (IBAction)addToRouteButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(headerAddToRouteButtonTapped)]) {
        [self.delegate headerAddToRouteButtonTapped];
    }
}

- (IBAction)radiusSliderChangedValue:(UISlider *)sender {
    self.radiusLabel.text = [NSString stringWithFormat:@"Радиус поиска: %.1f km", sender.value];
    
    if (!self.radiusSlider.isTracking && [self.delegate respondsToSelector:@selector(headerRadiusSliderChangedValue:)]) {
        [self.delegate headerRadiusSliderChangedValue:sender.value];
    }
}

@end
