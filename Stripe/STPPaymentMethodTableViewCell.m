//
//  STPPaymentMethodTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 8/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodTableViewCell.h"

#import "STPApplePayPaymentMethod.h"
#import "STPCard.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"

@interface STPPaymentMethodTableViewCell ()

@property (nonatomic) id<STPPaymentMethod> paymentMethod;
@property (nonatomic) STPTheme *theme;
@property (nonatomic) UIImageView *leftIcon;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIImageView *checkmarkIcon;

@end

@implementation STPPaymentMethodTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Left icon
        UIImageView *leftIcon = [[UIImageView alloc] init];
        _leftIcon = leftIcon;
        [self.contentView addSubview:leftIcon];

        // Title label
        UILabel *titleLabel = [UILabel new];
        _titleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];

        // Checkmark icon
        UIImageView *checkmarkIcon = [[UIImageView alloc] initWithImage:[STPImageLibrary checkmarkIcon]];
        _checkmarkIcon = checkmarkIcon;
        [self setAccessoryView:checkmarkIcon];  // Supports UITableViewCellEditingStyle positioning
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat midY = CGRectGetMidY(self.bounds);
    CGFloat padding = 15.0;
    CGFloat iconWidth = 26.0;

    // Left icon
    [self.leftIcon sizeToFit];
    self.leftIcon.center = CGPointMake(padding + iconWidth / 2.0, midY);

    // Title label
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake(padding * 2.0 + iconWidth + CGRectGetMidX(self.titleLabel.bounds), midY);
}

- (void)configureForNewCardRowWithTheme:(STPTheme *)theme {
    self.theme = theme;

    self.backgroundColor = self.theme.secondaryBackgroundColor;

    // Left icon
    self.leftIcon.image = [STPImageLibrary addIcon];
    self.leftIcon.tintColor = self.theme.accentColor;

    // Title label
    self.titleLabel.font = self.theme.font;
    self.titleLabel.textColor = self.theme.accentColor;
    self.titleLabel.text = STPLocalizedString(@"Add New Card…", @"Button to add a new credit card.");

    // Checkmark icon
    self.checkmarkIcon.hidden = YES;

    [self setNeedsLayout];
}

- (void)configureWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod selected:(BOOL)selected theme:(STPTheme *)theme {
    self.paymentMethod = paymentMethod;
    self.theme = theme;

    self.backgroundColor = self.theme.secondaryBackgroundColor;

    // Left icon
    self.leftIcon.image = paymentMethod.templateImage;
    self.leftIcon.tintColor = [self primaryColorForPaymentMethodWithSelectedState:selected];

    // Title label
    self.titleLabel.font = self.theme.font;
    self.titleLabel.attributedText = [self buildAttributedStringForPaymentMethod:self.paymentMethod selected:selected];

    // Checkmark icon
    self.checkmarkIcon.tintColor = self.theme.accentColor;
    self.checkmarkIcon.hidden = !selected;

    [self setNeedsLayout];
}

- (UIColor *)primaryColorForPaymentMethodWithSelectedState:(BOOL)isSelected {
    return isSelected ? self.theme.accentColor : [self.theme.primaryForegroundColor colorWithAlphaComponent:0.6];
}

- (NSAttributedString *)buildAttributedStringForPaymentMethod:(id<STPPaymentMethod>)paymentMethod selected:(BOOL)selected {
    if ([paymentMethod isKindOfClass:[STPCard class]]) {
        return [self buildAttributedStringForCard:(STPCard *)paymentMethod selected:selected];
    }

    if ([paymentMethod isKindOfClass:[STPApplePayPaymentMethod class]]) {
        NSString *label = STPLocalizedString(@"Apple Pay", @"Text for Apple Pay payment method");
        UIColor *primaryColor = [self primaryColorForPaymentMethodWithSelectedState:selected];
        return [[NSAttributedString alloc] initWithString:label attributes:@{NSForegroundColorAttributeName: primaryColor}];
    }

    return nil;
}

- (NSAttributedString *)buildAttributedStringForCard:(STPCard *)card selected:(BOOL)selected {
    NSString *format = STPLocalizedString(@"%@ Ending In %@", @"{card brand} ending in {last4}");
    NSString *brandString = [STPCard stringFromBrand:card.brand];
    NSString *label = [NSString stringWithFormat:format, brandString, card.last4];

    UIColor *primaryColor = selected ? self.theme.accentColor : self.theme.primaryForegroundColor;
    UIColor *secondaryColor = [primaryColor colorWithAlphaComponent:0.6];

    NSDictionary *attributes = @{NSForegroundColorAttributeName: secondaryColor,
                                 NSFontAttributeName: self.theme.font};

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:label attributes:attributes];
    [attributedString addAttribute:NSForegroundColorAttributeName value:primaryColor range:[label rangeOfString:brandString]];
    [attributedString addAttribute:NSForegroundColorAttributeName value:primaryColor range:[label rangeOfString:card.last4]];
    [attributedString addAttribute:NSFontAttributeName value:self.theme.emphasisFont range:[label rangeOfString:brandString]];
    [attributedString addAttribute:NSFontAttributeName value:self.theme.emphasisFont range:[label rangeOfString:card.last4]];

    return [attributedString copy];
}

@end
