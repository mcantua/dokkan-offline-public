#import <UIKit/UIKit.h>
void AppInstallerTraitAPIProbe(UIWindow *window, UIButton *button) {
    if (@available(iOS 17.0, *)) {
        id<UITraitOverrides> overrides = window.traitOverrides;
        BOOL hadCategory = [overrides containsTrait:UITraitPreferredContentSizeCategory.class];
        UIContentSizeCategory savedCategory = overrides.preferredContentSizeCategory;
        overrides.preferredContentSizeCategory = UIContentSizeCategoryAccessibilityExtraExtraExtraLarge;
        if (hadCategory) overrides.preferredContentSizeCategory = savedCategory;
        else [overrides removeTrait:UITraitPreferredContentSizeCategory.class];
    }
    UIImageSymbolConfiguration *symbol = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular];
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.preferredSymbolConfigurationForImage = symbol;
    button.configuration = configuration;
}
