#import "adhook.h"
#import <WebKit/WebKit.h>

static const NSInteger ADHookBannerTag = 0xADB44;

#if TARGET_OS_OSX
static __weak NSWindow *ADHookWindow;
#else
static __weak UIWindow *ADHookWindow;
#endif

static NSError *ADHookError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:@"com.adhook.error"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

static BOOL AllowedURL(NSURL *url) {
    NSString *scheme = url.scheme.lowercaseString;
    return [scheme isEqualToString:@"https"] ||
           [scheme isEqualToString:@"http"] ||
           [scheme isEqualToString:@"file"];
}

#if TARGET_OS_OSX
static NSWindow *CurrentWindow(void) {
    return NSApp.keyWindow;
}
#else
static UIWindow *CurrentWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]] ||
            scene.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) return window;
        }
    }
    return nil;
}
#endif

BOOL ShowBanner(NSURL *url, CGFloat height, NSError **error) {
    if (![NSThread isMainThread]) {
        if (error) *error = ADHookError(1, @"Call ShowBanner on the main thread.");
        return NO;
    }

    if (![url isKindOfClass:[NSURL class]] || !AllowedURL(url)) {
        if (error) *error = ADHookError(2, @"A valid http, https, or file URL is required.");
        return NO;
    }

#if TARGET_OS_OSX
    NSWindow *window = CurrentWindow();
    NSView *container = window.contentView;
    if (!window || !container) {
        if (error) *error = ADHookError(3, @"There is no key window to attach the banner to.");
        return NO;
    }
    CGFloat bannerHeight = MIN(MAX(height, 40.0), container.bounds.size.height);
    NSView *previous = [container viewWithTag:ADHookBannerTag];
    [previous removeFromSuperview];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:NSMakeRect(
        0, 0, container.bounds.size.width, bannerHeight)
                                             configuration:[WKWebViewConfiguration new]];
    webView.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
    webView.wantsLayer = YES;
    webView.layer.borderWidth = 0.5;
    webView.layer.borderColor = NSColor.separatorColor.CGColor;
    webView.tag = ADHookBannerTag;
    [container addSubview:webView positioned:NSWindowAbove relativeTo:nil];
#else
    UIWindow *window = CurrentWindow();
    UIView *container = window.rootViewController.view;
    if (!window || !container) {
        if (error) *error = ADHookError(3, @"There is no active key window to attach the banner to.");
        return NO;
    }
    CGFloat bannerHeight = MIN(MAX(height, 40.0), container.bounds.size.height);
    UIView *previous = [container viewWithTag:ADHookBannerTag];
    [previous removeFromSuperview];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(
        0, CGRectGetHeight(container.bounds) - bannerHeight,
        CGRectGetWidth(container.bounds), bannerHeight)
                                             configuration:[WKWebViewConfiguration new]];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    webView.layer.borderWidth = 0.5;
    webView.layer.borderColor = UIColor.separatorColor.CGColor;
    webView.tag = ADHookBannerTag;
    [container addSubview:webView];
#endif

    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    ADHookWindow = window;
    return YES;
}

void HideBanner(void) {
    void (^removeBanner)(void) = ^{
#if TARGET_OS_OSX
        NSView *container = ADHookWindow.contentView;
#else
        UIView *container = ADHookWindow.rootViewController.view;
#endif
        [[container viewWithTag:ADHookBannerTag] removeFromSuperview];
        ADHookWindow = nil;
    };
    if ([NSThread isMainThread]) removeBanner();
    else dispatch_async(dispatch_get_main_queue(), removeBanner);
}
