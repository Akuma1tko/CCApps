#import "CCAppsLauncher.h"

#import <FrontBoardServices/FBSSystemService.h>

BOOL CCAppsLaunchApplication(NSString *bundleIdentifier) {
    if (bundleIdentifier.length == 0) {
        NSLog(@"[CCApps] Cannot launch an empty bundle identifier");
        return NO;
    }

    @try {
        Class serviceClass = NSClassFromString(@"FBSSystemService");
        if (!serviceClass || ![serviceClass respondsToSelector:@selector(sharedService)]) {
            NSLog(@"[CCApps] FBSSystemService is unavailable");
            return NO;
        }

        FBSSystemService *service = [serviceClass sharedService];
        if (!service || ![service respondsToSelector:@selector(openApplication:options:withResult:)]) {
            NSLog(@"[CCApps] FrontBoard app-launch selector is unavailable");
            return NO;
        }

        [service openApplication:bundleIdentifier options:@{} withResult:^{
            NSLog(@"[CCApps] Launch request for %@ completed", bundleIdentifier);
        }];
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"[CCApps] Launch of %@ raised %@: %@",
              bundleIdentifier,
              exception.name,
              exception.reason);
        return NO;
    }
}
