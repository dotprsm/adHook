# adHook

A small dylib that displays an HTML page as a banner overlay in a or selected current window.

Works on iOS, iPadOS, tvOS & macOS

## Build

On macOS with Xcode Command Line Tools installed, run:

```sh
clang -dynamiclib -fobjc-arc -framework AppKit -framework WebKit \
  -install_name @rpath/libadhook.dylib adhook.m -o libadhook.dylib
```

## Usage

Import `adhook.h` in the host app. Pass an HTTP, HTTPS, or local file URL and the banner heigh you want in points:

```objc
#import "adhook.h"

NSError *error = nil;
NSURL *url = [NSURL URLWithString:@"https://example.com/banner.html"];

if (!ShowBanner(url, 90.0, &error)) {
    NSLog(@"Could not show banner: %@", error.localizedDescription);
}
```

To remove the banner:

```objc
HideBanner();
```

`ShowBanner` returns `YES` if the banner was added and `NO` if it could not be shown. The supplied page is loaded in the app's WKWebView, so its content and network access are subject to change from WebKit and the host app
