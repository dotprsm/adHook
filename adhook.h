#if defined(__APPLE__)
#import <TargetConditionals.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

FOUNDATION_EXPORT BOOL ShowBanner(NSURL *url,
                                  CGFloat height,
                                  NSError **error);

FOUNDATION_EXPORT void HideBanner(void);

#ifdef __cplusplus
}
#endif
