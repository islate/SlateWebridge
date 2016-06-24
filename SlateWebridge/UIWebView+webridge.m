//
//  UIWebView+webridge.m
//  SlateCore
//
//  Created by linyize on 16/6/24.
//  Copyright © 2016年 islate. All rights reserved.
//

#import "UIWebView+webridge.h"

#import "SlateWebridge.h"
#import <objc/runtime.h>

static char UIWebViewBridge;

@interface WebridgeObjectContainer : NSObject
@property (nonatomic, readonly, weak) SlateWebridge *bridge;
@end

@implementation WebridgeObjectContainer
- (instancetype) initWithWebridge:(SlateWebridge *)bridge
{
    if (!(self = [super init]))
    {
        return nil;
    }
    _bridge = bridge;
    return self;
}
@end

@implementation UIWebView (webridge)

- (void)setBridge:(SlateWebridge *)bridge
{
    objc_setAssociatedObject(self, &UIWebViewBridge,
                             [[WebridgeObjectContainer alloc] initWithWebridge:bridge],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SlateWebridge *)bridge
{
    WebridgeObjectContainer *c = objc_getAssociatedObject(self, &UIWebViewBridge);
    return c.bridge;
}

- (void)evalJSCommand:(NSString *)jsCommand jsParams:(id)jsParams completionHandler:(void (^)(id, NSError *))completionHandler
{
    [[self bridge] evalJSCommand:jsCommand jsParams:jsParams completionHandler:completionHandler webView:self];
}

- (BOOL)handleWebridgeMessage:(NSURL *)url
{
    if ([[self bridge] isWebridgeMessage:url])
    {
        [[self bridge] handleWebridgeMessage:url webView:self];
        return YES;
    }
    return NO;
}

@end
