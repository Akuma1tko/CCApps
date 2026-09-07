#import "CCAppsModuleViewController.h"

#import "CCAppsContentModuleContext.h"
#import "../Shared/CCAppsIconLoader.h"
#import "../Shared/CCAppsLauncher.h"
#import "../Shared/CCAppsQuickActions.h"

static const CGFloat CCAppsIconNormalAlpha = 0.65;
static const CGFloat CCAppsIconPressedScale = 0.92;

@interface CCAppsModuleViewController ()
@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) id pendingQuickAction;
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
    button.accessibilityHint = @"Opens application. Touch and hold for quick actions.";
    [button addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(buttonTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    UIContextMenuInteraction *contextMenu =
        [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [button addInteraction:contextMenu];

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

- (UIContextMenuConfiguration *)contextMenuInteraction:(__unused UIContextMenuInteraction *)interaction
                        configurationForMenuAtLocation:(__unused CGPoint)location {
    NSArray *shortcutItems = CCAppsQuickActionsForBundleIdentifier(self.bundleIdentifier);
    if (shortcutItems.count == 0) return nil;

    NSString *bundleIdentifier = self.bundleIdentifier;
    __weak typeof(self) weakSelf = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                   previewProvider:nil
                                                    actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
        (void)suggestedActions;
        NSMutableArray<UIMenuElement *> *actions =
            [NSMutableArray arrayWithCapacity:shortcutItems.count];
        for (id shortcutItem in shortcutItems) {
            NSString *title = [shortcutItem localizedTitle];
            UIImage *image = CCAppsQuickActionIcon(shortcutItem, bundleIdentifier);
            UIAction *action = [UIAction actionWithTitle:title
                                                   image:image
                                              identifier:nil
                                                 handler:^(__unused UIAction *selectedAction) {
                [weakSelf queueQuickActionUntilMenuDismisses:shortcutItem];
            }];
            [actions addObject:action];
        }
        return [UIMenu menuWithTitle:@"" children:actions];
    }];
}

- (UITargetedPreview *)contextMenuInteraction:(__unused UIContextMenuInteraction *)interaction
   previewForHighlightingMenuWithConfiguration:(__unused UIContextMenuConfiguration *)configuration {
    UIPreviewParameters *parameters = [[UIPreviewParameters alloc] init];
    parameters.backgroundColor = UIColor.clearColor;
    parameters.visiblePath = [UIBezierPath bezierPathWithRoundedRect:self.iconView.bounds
                                                        cornerRadius:self.iconView.layer.cornerRadius];
    return [[UITargetedPreview alloc] initWithView:self.iconView parameters:parameters];
}

- (UITargetedPreview *)contextMenuInteraction:(__unused UIContextMenuInteraction *)interaction
     previewForDismissingMenuWithConfiguration:(UIContextMenuConfiguration *)configuration {
    return [self contextMenuInteraction:interaction
        previewForHighlightingMenuWithConfiguration:configuration];
}

- (void)contextMenuInteraction:(__unused UIContextMenuInteraction *)interaction
       willDisplayMenuForConfiguration:(__unused UIContextMenuConfiguration *)configuration
                              animator:(__unused id<UIContextMenuInteractionAnimating>)animator {
    self.iconView.alpha = CCAppsIconNormalAlpha;
    self.iconView.transform = CGAffineTransformIdentity;
}

- (void)contextMenuInteraction:(__unused UIContextMenuInteraction *)interaction
         willEndForConfiguration:(__unused UIContextMenuConfiguration *)configuration
                         animator:(id<UIContextMenuInteractionAnimating>)animator {
    __weak typeof(self) weakSelf = self;
    [animator addCompletion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        strongSelf.iconView.alpha = CCAppsIconNormalAlpha;
        strongSelf.iconView.transform = CGAffineTransformIdentity;

        id shortcutItem = strongSelf.pendingQuickAction;
        strongSelf.pendingQuickAction = nil;
        if (shortcutItem) {
            // Authentication presentation is ignored if requested while the
            // context menu still owns Control Center's presentation context.
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf performQuickAction:shortcutItem];
            });
        }
    }];
}

- (void)queueQuickActionUntilMenuDismisses:(id)shortcutItem {
    if (!shortcutItem) return;
    self.pendingQuickAction = shortcutItem;

    // Defensive fallback in case UIKit omits the dismissal callback.
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.pendingQuickAction != shortcutItem) return;
        strongSelf.pendingQuickAction = nil;
        [strongSelf performQuickAction:shortcutItem];
    });
}

- (void)performQuickAction:(id)shortcutItem {
    if (!shortcutItem) return;

    CCUIContentModuleContext *context = self.contentModuleContext;
    if (!context ||
        ![context respondsToSelector:@selector(requestAuthenticationWithCompletionHandler:)]) {
        CCAppsLaunchQuickAction(shortcutItem, self.bundleIdentifier);
        return;
    }

    NSString *bundleIdentifier = self.bundleIdentifier;
    __weak typeof(self) weakSelf = self;
    [context requestAuthenticationWithCompletionHandler:^(BOOL authenticated) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || !authenticated) return;
            CCAppsLaunchQuickAction(shortcutItem, bundleIdentifier);
        });
    }];
}

- (void)buttonTouchDown:(__unused UIButton *)button {
    [UIView animateWithDuration:0.16
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState |
                                UIViewAnimationOptionAllowUserInteraction |
                                UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.iconView.transform = CGAffineTransformMakeScale(CCAppsIconPressedScale,
                                                              CCAppsIconPressedScale);
    } completion:nil];
}

- (void)buttonTouchEnded:(__unused UIButton *)button {
    [UIView animateWithDuration:0.20
                          delay:0.0
         usingSpringWithDamping:0.72
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState |
                                UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self.iconView.transform = CGAffineTransformIdentity;
    } completion:nil];
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
