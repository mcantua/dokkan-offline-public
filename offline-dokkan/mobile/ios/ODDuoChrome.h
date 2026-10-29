#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

/* Shared Unit Creator colors and bundled display fonts. Missing font files
 * fall back to the system font so the launcher still draws. */
static inline UIColor *ODDuoColor(unsigned hex) {
    return [UIColor colorWithRed:((hex >> 16) & 255) / 255.0 green:((hex >> 8) & 255) / 255.0 blue:(hex & 255) / 255.0 alpha:1];
}
static inline void ODDuoRegisterFonts(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSBundle *bundle = NSBundle.mainBundle;
        for (NSString *file in @[@"Bangers-Regular.ttf", @"RussoOne-Regular.ttf"]) {
            NSString *base = file.stringByDeletingPathExtension;
            NSURL *url = [bundle URLForResource:base withExtension:@"ttf" subdirectory:@"site/fonts"];
            if (!url) url = [bundle URLForResource:base withExtension:@"ttf" subdirectory:@"fonts"];
            if (!url) {
                for (NSString *root in @[@"site/fonts", @"fonts"]) {
                    NSString *path = [bundle.resourcePath stringByAppendingPathComponent:[root stringByAppendingPathComponent:file]];
                    if ([NSFileManager.defaultManager fileExistsAtPath:path]) { url = [NSURL fileURLWithPath:path]; break; }
                }
            }
            if (url) CTFontManagerRegisterFontsForURL((__bridge CFURLRef)url, kCTFontManagerScopeProcess, NULL);
        }
    });
}
static inline UIFont *ODDuoDisplayFont(CGFloat size) {
    ODDuoRegisterFonts();
    return [UIFont fontWithName:@"Bangers-Regular" size:size] ?: [UIFont fontWithName:@"Bangers" size:size] ?: [UIFont systemFontOfSize:size weight:UIFontWeightHeavy];
}
static inline UIFont *ODDuoTextFont(CGFloat size) {
    ODDuoRegisterFonts();
    return [UIFont fontWithName:@"RussoOne-Regular" size:size] ?: [UIFont fontWithName:@"Russo One" size:size] ?: [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
}
static inline UIButton *ODDuoChoiceButton(NSString *title, NSString *subtitle, NSString *identifier) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.accessibilityIdentifier = identifier;
    button.accessibilityLabel = [NSString stringWithFormat:@"%@. %@", title, subtitle];
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.title = title;
    config.subtitle = subtitle;
    config.titleAlignment = UIButtonConfigurationTitleAlignmentCenter;
    config.baseForegroundColor = ODDuoColor(0x1d0f00);
    UIBackgroundConfiguration *background = config.background;
    background.backgroundColor = ODDuoColor(0xff8c1a);
    background.cornerRadius = 16;
    background.strokeWidth = 2;
    background.strokeColor = ODDuoColor(0x7a3500);
    config.background = background;
    config.contentInsets = NSDirectionalEdgeInsetsMake(20, 18, 20, 18);
    config.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *incoming) {
        NSMutableDictionary *next = [incoming mutableCopy];
        next[NSFontAttributeName] = ODDuoTextFont(22);
        return next;
    };
    config.subtitleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *incoming) {
        NSMutableDictionary *next = [incoming mutableCopy];
        next[NSFontAttributeName] = ODDuoTextFont(13);
        next[NSForegroundColorAttributeName] = ODDuoColor(0x1d0f00);
        return next;
    };
    button.configuration = config;
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:92].active = YES;
    return button;
}
static inline UILabel *ODDuoLabel(NSString *text, UIFont *font, UIColor *color) {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}
