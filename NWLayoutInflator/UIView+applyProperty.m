//
//  UIView+applyProperty.m
//  NWLayoutInflator
//
//  Created by Nicholas White on 8/1/15.
//  Copyright (c) 2015 Nicholas White. All rights reserved.
//

#import "UIView+applyProperty.h"
#import "UIColor+hexString.h"
#import "NWLayoutView.h"
#import "UIGestureRecognizer+Blocks.h"

@implementation UIView (applyProperty)

- (void)applyProperty:(NSString*)name value:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    SEL s = NSSelectorFromString([NSString stringWithFormat:@"apply_%@:layoutView:", name]);
    if ([self respondsToSelector:s]) {
        IMP imp = [self methodForSelector:s];
        void (*func)(id, SEL, NSString*, NWLayoutView*) = (void *)imp;
        func(self, s, value, layoutView);
    } else {
        SEL s = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [[name substringToIndex:1] uppercaseString], [name substringFromIndex:1]]);
        if ([self respondsToSelector:s]) {
            IMP imp = [self methodForSelector:s];
            void (*func)(id, SEL, NSString*) = (void *)imp;
            @try {
                func(self, s, value);
            }
            @catch (NSException *exception) {
                NSLog(@"Exception encountered applying property %@ with value %@\n%@", name, value, exception);
            }
            @finally {
                // ?
            }
        }
    }
}

- (UIColor *)colorNamed:(NSString*)name {
    if ([name hasPrefix:@"#"]) {
        return [UIColor colorFromHex:name];
    } else {
        return [NWLayoutView namedColor:name];
    }
}

- (void)apply_font:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    UIFont *font;
    if ([value rangeOfString:@":"].location == NSNotFound) {
        font = [UIFont systemFontOfSize:[value floatValue]];
    } else {
        NSString *valueFromColon = [value substringFromIndex:[value rangeOfString:@":"].location + 1];
        if ([value hasPrefix:@"fontWithName:'"]) {
            NSString *sizeText = [valueFromColon substringFromIndex:[valueFromColon rangeOfString:@":"].location + 1];
            NSString *nameText = [valueFromColon substringWithRange:NSMakeRange(1, [valueFromColon rangeOfString:@"'" options:0 range:NSMakeRange(1, valueFromColon.length - 1)].location - 1)];
            font = [UIFont fontWithName:nameText size:[sizeText floatValue]];
        } else if ([value hasPrefix:@"bold"]) {
            font = [UIFont boldSystemFontOfSize:[valueFromColon floatValue]];
        } else if ([value hasPrefix:@"italic"]) {
            font = [UIFont italicSystemFontOfSize:[valueFromColon floatValue]];
        } else {
            font = [UIFont systemFontOfSize:[valueFromColon floatValue]];
        }
    }
    if (font) {
        if ([self respondsToSelector:@selector(titleLabel)]) {
            ((UIButton*)self).titleLabel.font = font;
        } else if ([self respondsToSelector:@selector(setFont:)]) {
            ((UILabel*)self).font = font;
        }
    }
}

- (void)apply_text:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if ([self respondsToSelector:@selector(setText:)]) {
        [(UILabel*)self setText:value];
    } else if ([self respondsToSelector:@selector(setTitle:forState:)]) {
        [(UIButton*)self setTitle:value forState:UIControlStateNormal];
    }
}

- (void)apply_textColor:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    UIColor *color = [self colorNamed:value];
    if ([self respondsToSelector:@selector(setTextColor:)]) {
        [(UILabel*)self setTextColor:color];
    } else if ([self respondsToSelector:@selector(setTitleColor:forState:)]) {
        [(UIButton*)self setTitleColor:color forState:UIControlStateNormal];
        [(UIButton*)self setTitleColor:color forState:UIControlStateHighlighted];
    }
}

- (void)apply_textAlignment:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if ([self respondsToSelector:@selector(setTextAlignment:)]) {
        NSTextAlignment alignment;
        if ([value isEqualToString:@"left"]) alignment = NSTextAlignmentLeft;
        else if ([value isEqualToString:@"center"]) alignment = NSTextAlignmentCenter;
        else if ([value isEqualToString:@"right"]) alignment = NSTextAlignmentRight;
        ((UILabel*)self).textAlignment = alignment;
    } else if ([self respondsToSelector:@selector(setContentHorizontalAlignment:)]) {
        UIControlContentHorizontalAlignment alignment;
        if ([value isEqualToString:@"left"]) alignment = UIControlContentHorizontalAlignmentLeft;
        else if ([value isEqualToString:@"center"]) alignment = UIControlContentHorizontalAlignmentCenter;
        else if ([value isEqualToString:@"right"]) alignment = UIControlContentHorizontalAlignmentRight;
        ((UIButton*)self).contentHorizontalAlignment = alignment;
    }
}

- (void)apply_cornerRadius:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = [value floatValue];
}

-(void)apply_backgroundColor:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    self.backgroundColor = [self colorNamed:value];
}
- (void)apply_borderColor:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    self.layer.borderColor = [[self colorNamed:value] CGColor];
}
- (void)apply_borderWidth:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    self.layer.borderWidth = [value floatValue];
}

- (void)apply_imageNamed:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if ([self respondsToSelector:@selector(setImage:)]) {
        [((UIImageView*)self) setImage:[UIImage imageNamed:value]];
    }
}

- (void)apply_imageWithURL:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if ([self respondsToSelector:@selector(setImageWithURL:)]) {
        if ([value hasPrefix:@"//"]) {
            value = [NSString stringWithFormat:@"http:%@", value];
        }
        [self performSelector:@selector(setImageWithURL:) withObject:[NSURL URLWithString:value]];
    }
}

- (void)apply_numberOfLines:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if ([self respondsToSelector:@selector(setNumberOfLines:)]) {
        [((UILabel*)self) setNumberOfLines:[value intValue]];
    }
}

- (void)apply_tintColor:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if ([self respondsToSelector:@selector(setTintColor:)]) {
        [((UIImageView*)self) setTintColor:[self colorNamed:value]];
    }
}

- (void)apply_onclick:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    NSString *param = nil;
    NSString *method = value;
    BOOL includeView = NO;
    NSRange colon = [value rangeOfString:@":"];
    if ([value rangeOfString:@"//"].location != NSNotFound) {
        // It's a url
        param = value;
        method = @"openUrl:";
    } else if (colon.location != NSNotFound && colon.location < value.length - 1) {
        method = [value substringToIndex:colon.location + 1];
        param = [value substringFromIndex:colon.location + 1];
        if ([param hasSuffix:@" view:"]) {
            method = [NSString stringWithFormat:@"%@view:", method];
            param = [param substringToIndex:[param rangeOfString:@" "].location];
            includeView = YES;
        }
    }
    NSCharacterSet *nonSelectorChars = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMONPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_:"] invertedSet];
    if ([method rangeOfCharacterFromSet:nonSelectorChars].location == NSNotFound && [layoutView.delegate respondsToSelector:NSSelectorFromString(method)]) {
        if (param && param.length) {
            self.userInteractionEnabled = YES;
            __weak id weakDelegate = layoutView.delegate;
            __weak typeof(layoutView)weakLayoutView = layoutView;
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithActionBlock:^(UIGestureRecognizer *gesture) {
                if (!weakDelegate) return;
                SEL selector = NSSelectorFromString(method);
                IMP imp = [weakDelegate methodForSelector:selector];
                if (includeView) {
                    void (*func)(id, SEL, NSString*, NWLayoutView*view) = (void *)imp;
                    func(weakDelegate, selector, param, weakLayoutView);
                } else {
                    void (*func)(id, SEL, NSString*) = (void *)imp;
                    func(weakDelegate, selector, param);
                }
            }];
            [self addGestureRecognizer:tapRecognizer];
        } else {
            if ([self respondsToSelector:@selector(addTarget:action:forControlEvents:)]) {
                [((UIButton*)self) addTarget:layoutView.delegate action:NSSelectorFromString(value) forControlEvents:UIControlEventTouchUpInside];
            } else {
                self.userInteractionEnabled = YES;
                UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:layoutView.delegate action:NSSelectorFromString(value)];
                [self addGestureRecognizer:tapRecognizer];
            }
        }
    } else if ([layoutView.delegate respondsToSelector:@selector(onclick:)]) {
        self.userInteractionEnabled = YES;
        __weak id weakDelegate = layoutView.delegate;
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithActionBlock:^(UIGestureRecognizer *gesture) {
            if (!weakDelegate) return;
            [weakDelegate performSelector:@selector(onclick:) withObject:value];
        }];
        [self addGestureRecognizer:tapRecognizer];
    } else {
        NSLog(@"ERROR: delegate does not respond to %@ -- %@", value, layoutView.delegate);
        return;
    }
}

- (void)apply_activityIndicatorViewStyle:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if ([self respondsToSelector:@selector(setActivityIndicatorViewStyle:)]) {
        UIActivityIndicatorViewStyle style;
        if ([value isEqualToString:@"white"]) style = UIActivityIndicatorViewStyleWhite;
        else if ([value isEqualToString:@"whitelarge"]) style = UIActivityIndicatorViewStyleWhiteLarge;
        else if ([value isEqualToString:@"gray"]) style = UIActivityIndicatorViewStyleGray;
        ((UIActivityIndicatorView*)self).activityIndicatorViewStyle = style;
    }
}

- (void)apply_tag:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    self.tag = [value intValue];
}

- (void)apply_scrollEnabled:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if ([self respondsToSelector:@selector(setScrollEnabled:)]) {
        ((UIScrollView*)self).scrollEnabled = [value intValue] ? YES : NO;
    }
}

- (void) apply_segments:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if (![self isKindOfClass:[UISegmentedControl class]]) return;
    UISegmentedControl *control = (UISegmentedControl*)self;
    NSArray *items = [value componentsSeparatedByString:@"|"];
    [control removeAllSegments];
    for (NSString *segment in items) {
        [control insertSegmentWithTitle:segment atIndex:control.numberOfSegments animated:NO];
    }
    [control addTarget:layoutView action:@selector(chooseSegment:) forControlEvents:UIControlEventValueChanged];
    control.selectedSegmentIndex = 0;
}

- (void)apply_placeholder:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if ([self respondsToSelector:@selector(setPlaceholder:)]) {
        ((UITextField*)self).placeholder = value;
    }
}

- (void)apply_keyboardType:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if ([self respondsToSelector:@selector(setKeyboardType:)]) {
        UIKeyboardType keyboardType = ((UITextField*)self).keyboardType;
        value = [value lowercaseString];
        if ([value isEqualToString:@"alphabet"]) {
            keyboardType = UIKeyboardTypeAlphabet;
        } else if ([value isEqualToString:@"decimalpad"]) {
            keyboardType = UIKeyboardTypeDecimalPad;
        } else if ([value isEqualToString:@"emailaddress"]) {
            keyboardType = UIKeyboardTypeEmailAddress;
        } else if ([value isEqualToString:@"namephonepad"]) {
            keyboardType = UIKeyboardTypeNamePhonePad;
        } else if ([value isEqualToString:@"numberpad"]) {
            keyboardType = UIKeyboardTypeNumberPad;
        } else if ([value isEqualToString:@"numbersandpunctuation"]) {
            keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        } else if ([value isEqualToString:@"phonepad"]) {
            keyboardType = UIKeyboardTypePhonePad;
        } else if ([value isEqualToString:@"twitter"]) {
            keyboardType = UIKeyboardTypeTwitter;
        } else if ([value isEqualToString:@"url"]) {
            keyboardType = UIKeyboardTypeURL;
        } else if ([value isEqualToString:@"websearch"]) {
            keyboardType = UIKeyboardTypeWebSearch;
        }
        ((UITextField*)self).keyboardType = keyboardType;
    }
}

- (void)apply_transform:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    CGAffineTransform transform = CGAffineTransformIdentity;
    NSArray *parts = [value componentsSeparatedByString:@" "];
    for (NSString *part in parts) {
        NSArray *keyValue = [part componentsSeparatedByString:@":"];
        if (keyValue.count < 2) continue;
        NSString *key = keyValue[0];
        NSString *valueStr = keyValue[1];
        NSArray *values = [valueStr componentsSeparatedByString:@","];
        if ([key isEqualToString:@"scale"] && values.count == 2) {
            transform = CGAffineTransformScale(transform, [values[0] floatValue], [values[1] floatValue]);
        } else if ([key isEqualToString:@"rotate"]) {
            transform = CGAffineTransformRotate(transform, [values[0] floatValue]);
        } else if ([key isEqualToString:@"translate"] && values.count == 2) {
            transform = CGAffineTransformTranslate(transform, [values[0] floatValue], [values[1] floatValue]);
        }
    }
    self.transform = transform;
}

- (void)apply_minimumDate:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if (![self respondsToSelector:@selector(setMinimumDate:)]) return;
    UIDatePicker *dp = (UIDatePicker*)self;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [formatter dateFromString:value];
    [dp setMinimumDate:date];
}

- (void)apply_maximumDate:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if (![self respondsToSelector:@selector(setMaximumDate:)]) return;
    UIDatePicker *dp = (UIDatePicker*)self;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [formatter dateFromString:value];
    [dp setMaximumDate:date];
}

- (void)apply_date:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if (![self respondsToSelector:@selector(setDate:)]) return;
    UIDatePicker *dp = (UIDatePicker*)self;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [formatter dateFromString:value];
    [dp setDate:date];
}

- (void)apply_datePickerMode:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    if (![self respondsToSelector:@selector(setDatePickerMode:)]) return;
    UIDatePickerMode mode = ((UIDatePicker*)self).datePickerMode;
    if ([value isEqualToString:@"date"]) {
        mode = UIDatePickerModeDate;
    } else if ([value isEqualToString:@"dateAndTime"]) {
        mode = UIDatePickerModeDateAndTime;
    } else if ([value isEqualToString:@"countDownTimer"]) {
        mode = UIDatePickerModeCountDownTimer;
    } else if ([value isEqualToString:@"time"]) {
        mode = UIDatePickerModeTime;
    }
    ((UIDatePicker*)self).datePickerMode = mode;
}

- (void)apply_formValue:(NSString*)value layoutView:(NWLayoutView*)layoutView {
    // TODO: this is unnecessary; the generic set* in applyProperty should cover it
    if (![self respondsToSelector:@selector(setFormValue:)]) return;
    [self performSelector:@selector(setFormValue:) withObject:value];
}

@end
