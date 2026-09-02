#import "CCAppsIconLoader.h"

#import <UIKit/UIImage+Private.h>

UIImage *CCAppsFallbackGlyph(void) {
    static UIImage *glyph = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc]
            initWithSize:CGSizeMake(29.0, 29.0)];
        glyph = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [[UIColor blackColor] setFill];
            CGFloat side = 8.0;
            for (NSUInteger row = 0; row < 2; row++) {
                for (NSUInteger column = 0; column < 2; column++) {
                    CGRect rect = CGRectMake(5.0 + column * 11.0, 5.0 + row * 11.0, side, side);
                    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:2.0] fill];
                }
            }
            (void)context;
        }];
    });
    return glyph;
}

UIImage *CCAppsIconForBundleIdentifier(NSString *bundleIdentifier) {
    static NSCache<NSString *, UIImage *> *iconCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iconCache = [[NSCache alloc] init];
        iconCache.countLimit = 256;
    });

    if (bundleIdentifier.length == 0) return CCAppsFallbackGlyph();
    UIImage *cachedIcon = [iconCache objectForKey:bundleIdentifier];
    if (cachedIcon) return cachedIcon;

    UIImage *icon = nil;
    @try {
        if ([UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
            icon = [UIImage _applicationIconImageForBundleIdentifier:bundleIdentifier
                                                               format:MIIconVariantSpotlight
                                                                scale:UIScreen.mainScreen.scale];
        }
    } @catch (NSException *exception) {
        NSLog(@"[CCApps] Icon lookup for %@ raised %@: %@",
              bundleIdentifier, exception.name, exception.reason);
    }

    if (!icon) icon = CCAppsFallbackGlyph();
    [iconCache setObject:icon forKey:bundleIdentifier];
    return icon;
}
