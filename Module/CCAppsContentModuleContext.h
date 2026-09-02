#import <Foundation/Foundation.h>

// Minimal declarations for the ControlCenterUIKit context that CCSupport gives
// each provided module. Keeping this local avoids depending on a full set of
// version-specific private headers.
@interface CCUIContentModuleContext : NSObject

- (void)requestAuthenticationWithCompletionHandler:(void (^)(BOOL authenticated))completionHandler;
- (void)openApplication:(NSString *)bundleIdentifier
       completionHandler:(void (^)(void))completionHandler;

@end
