#import <UIKit/UIKit.h>
#import <ControlCenterUIKit/CCUIContentModuleContentViewController-Protocol.h>

@class CCUIContentModuleContext;

@interface CCAppsModuleViewController : UIViewController <CCUIContentModuleContentViewController>

@property (nonatomic, strong) CCUIContentModuleContext *contentModuleContext;

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                              displayName:(NSString *)displayName NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end
