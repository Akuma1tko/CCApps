#import "CCAppsModule.h"

#import "CCAppsContentModuleContext.h"
#import "CCAppsModuleViewController.h"

@interface CCAppsModule ()
@property (nonatomic, strong, readwrite) CCAppsModuleViewController *contentViewController;
@property (nonatomic, strong) CCUIContentModuleContext *contentModuleContext;
@end

@implementation CCAppsModule

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                              displayName:(NSString *)displayName {
    self = [super init];
    if (self) {
        _contentViewController = [[CCAppsModuleViewController alloc]
            initWithBundleIdentifier:bundleIdentifier
                         displayName:displayName];
    }
    return self;
}

- (UIViewController *)backgroundViewController {
    return nil;
}

- (void)setContentModuleContext:(CCUIContentModuleContext *)contentModuleContext {
    _contentModuleContext = contentModuleContext;
    self.contentViewController.contentModuleContext = contentModuleContext;
}

@end
