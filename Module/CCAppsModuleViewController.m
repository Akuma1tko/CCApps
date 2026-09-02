#import "CCAppsModuleViewController.h"

#import "CCAppsContentModuleContext.h"
#import "../Shared/CCAppsIconLoader.h"
#import "../Shared/CCAppsLauncher.h"

static const CGFloat CCAppsIconNormalAlpha = 0.65;
static const CGFloat CCAppsIconPressedAlpha = 0.40;

@interface CCAppsModuleViewController ()
@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, strong) UIImageView *iconView;
@end

@implementation CCAppsModuleViewController

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                              displayName:(NSString *)displayName {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _bundleIdentifier = [bundleIdentifier copy];
        _displayName = [displayName copy];
    }
    return self;
}

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = UIColor.clearColor;
    view.clipsToBounds = YES;
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImage *icon = [CCAppsIconForBundleIdentifier(self.bundleIdentifier)
        imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.userInteractionEnabled = NO;
    // Full-color app artwork needs a slightly larger frame than a monochrome
    // glyph to have the same apparent visual weight in a compact CC module.
    iconView.layer.cornerRadius = 13.33;
    iconView.layer.masksToBounds = YES;
    iconView.alpha = CCAppsIconNormalAlpha;
    [self.view addSubview:iconView];
    self.iconView = iconView;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = UIColor.clearColor;
    button.accessibilityLabel = self.displayName;
    button.accessibilityHint = @"Opens application";
    [button addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(buttonTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    [NSLayoutConstraint activateConstraints:@[
        [iconView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [iconView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [iconView.widthAnchor constraintEqualToConstant:60.0],
        [iconView.heightAnchor constraintEqualToConstant:60.0],
        [button.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [button.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [button.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [button.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)buttonTouchDown:(__unused UIButton *)button {
    self.iconView.alpha = CCAppsIconPressedAlpha;
}

- (void)buttonTouchEnded:(__unused UIButton *)button {
    self.iconView.alpha = CCAppsIconNormalAlpha;
}

- (void)buttonTapped:(__unused UIButton *)button {
    NSString *bundleIdentifier = self.bundleIdentifier;
    if (bundleIdentifier.length == 0) {
        NSLog(@"[CCApps] Tap ignored because the module has no bundle identifier");
        return;
    }

    CCUIContentModuleContext *context = self.contentModuleContext;
    if (!context ||
        ![context respondsToSelector:@selector(requestAuthenticationWithCompletionHandler:)]) {
        NSLog(@"[CCApps] No Control Center authentication context for %@; using direct launch fallback",
              bundleIdentifier);
        CCAppsLaunchApplication(bundleIdentifier);
        return;
    }

    NSLog(@"[CCApps] Authentication requested for %@", bundleIdentifier);
    __weak typeof(self) weakSelf = self;
    [context requestAuthenticationWithCompletionHandler:^(BOOL authenticated) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || !authenticated) {
                NSLog(@"[CCApps] Authentication did not authorize %@", bundleIdentifier);
                return;
            }

            CCUIContentModuleContext *currentContext = strongSelf.contentModuleContext;
            if ([currentContext respondsToSelector:@selector(openApplication:completionHandler:)]) {
                NSLog(@"[CCApps] Authenticated system launch requested for %@", bundleIdentifier);
                [currentContext openApplication:bundleIdentifier completionHandler:^{
                    NSLog(@"[CCApps] Authenticated system launch completed for %@", bundleIdentifier);
                }];
            } else {
                NSLog(@"[CCApps] Authenticated direct launch fallback for %@", bundleIdentifier);
                CCAppsLaunchApplication(bundleIdentifier);
            }
        });
    }];
}

- (CGFloat)preferredExpandedContentHeight {
    return 0.0;
}

- (CGFloat)preferredExpandedContentWidth {
    return 0.0;
}

- (BOOL)providesOwnPlatter {
    return NO;
}

- (BOOL)shouldBeginTransitionToExpandedContentModule {
    return NO;
}

- (BOOL)_canShowWhileLocked {
    return YES;
}

@end
