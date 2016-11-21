//
//  SlateWebridge.m
//  Slate
//
//  Created by yize lin on 16-6-23.
//  Copyright (c) 2016年 islate. All rights reserved.
//

#import "SlateWebridge.h"

#import "NSInvocation+Extensions.h"
#import "NSString+json.h"
#import "NSString+urlencode.h"
#import "NSObject+webridge.h"

#define WEBVIEW_DELEGATE_COMMAND @"domReady"

@interface SlateScriptMessage : NSObject

@property (nonatomic, strong) id body;
@property (nonatomic, weak) UIWebView *webView;

@end

@interface SlateWebridge ()

@property (nonatomic, strong) NSMutableArray<id<SlateWebridgeHandler>> *handlers;
@property (nonatomic, assign) int sequence;
@property (nonatomic, strong) NSMutableDictionary *callbackDict;

// 注册回调block，并获得序号
- (NSNumber *)sequenceOfNativeToJSCallback:(SlateWebridgeCompletionBlock)callback;

// 移除序号对应的回调block
- (void)removeSequence:(NSNumber *)sequence;

// 处理webView得到的message
// 1、执行函数 或 2、得到返回值
- (void)handleMessage:(SlateScriptMessage *)message;

- (id<SlateWebridgeHandler>)targetWithSelector:(SEL)selector;
- (void)nativeToJSCallback:(NSDictionary *)returnDict;
- (void)jsToNative:(NSDictionary *)evalDict webView:(UIWebView *)webView;
- (BOOL)asyncExecuteForCommand:(NSString *)command params:(id)params sequence:(NSNumber *)sequence webView:(UIWebView *)webView;
- (void)executeForCommand:(NSString *)command params:(id)params sequence:(NSNumber *)sequence webView:(UIWebView *)webView;
- (void)callbackWithResult:(id)result error:(NSString *)error sequence:(NSNumber *)sequence webView:(UIWebView *)webView;

@end

@implementation SlateWebridge

+ (instancetype)sharedBridge
{
    static id _sharedInstance = nil;
    static dispatch_once_t  once = 0;
    
    dispatch_once(&once, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sequence = 0;
        _callbackDict = [NSMutableDictionary new];
        _handlers = [NSMutableArray new];
    }
    return self;
}

- (void)addHandlers:(NSArray<id<SlateWebridgeHandler>>*)handlers
{
    [_handlers addObjectsFromArray:handlers];
}

- (void)setPriorHandler:(id<SlateWebridgeHandler>)handler
{
    [_handlers insertObject:handler atIndex:0];
}

- (id<SlateWebridgeHandler>)targetWithSelector:(SEL)selector
{
    id target = nil;
    for (id handler in _handlers) {
        if ([handler respondsToSelector:selector]) {
            target = handler;
            break;
        }
    }
    return target;
}

- (BOOL)isWebridgeMessage:(NSURL *)URL
{
    if ([URL.scheme.lowercaseString isEqualToString:@"webridge"]) {
        return YES;
    }
    return NO;
}

- (void)handleWebridgeMessage:(NSURL *)URL webView:(UIWebView *)webView
{
    NSString *urlString = URL.absoluteString;
    NSString *messageString = [urlString stringByReplacingOccurrencesOfString:@"webridge://" withString:@""];
    messageString = [messageString stringUnescapedAsURIComponent];
    
    if (messageString.length == 0) {
        return;
    }
    
    SlateScriptMessage *message = [SlateScriptMessage new];
    message.body = [messageString JSONObject];
    message.webView = webView;
    
    [self handleMessage:message];
}

- (void)evalJSCommand:(NSString *)jsCommand jsParams:(id)jsParams completionHandler:(void (^)(id, NSError *))completionHandler webView:(UIWebView *)webView
{
    if (![NSThread isMainThread])
    {
        // 非主线程不允许调用
        return;
    }
    
    NSString *jsParamsString = @"''";
    if (jsParams)
    {
        jsParamsString = [jsParams stringForJavascript];
    }
    
    NSNumber *sequence = [self sequenceOfNativeToJSCallback:completionHandler];
    NSString *javaScriptString = [NSString stringWithFormat:@"webridge.nativeToJS('%@', %@, %@)", jsCommand, jsParamsString, sequence];
    
    [webView stringByEvaluatingJavaScriptFromString:javaScriptString];
}

- (NSNumber *)sequenceOfNativeToJSCallback:(SlateWebridgeCompletionBlock)callback
{
    if (!callback)
    {
        return @(0);
    }
    
    @synchronized(self)
    {
        _sequence += 1;
        [_callbackDict setObject:callback forKey:@(_sequence)];
        return @(_sequence);
    }
}

- (void)removeSequence:(NSNumber *)sequence
{
    if (!sequence)
    {
        return;
    }
    
    @synchronized(self)
    {
        [_callbackDict removeObjectForKey:sequence];
    }
}

// 为了以后兼容WKWebView的WKScriptMessage
- (void)handleMessage:(SlateScriptMessage *)message
{
    if (![message.body isKindOfClass:[NSDictionary class]])
    {
        return;
    }
    
    id returnDict = [message.body objectForKey:@"return"];
    if ([returnDict isKindOfClass:[NSDictionary class]])
    {
        // js返回值
        [self nativeToJSCallback:returnDict];
        return;
    }
    
    id evalDict = [message.body objectForKey:@"eval"];
    if ([evalDict isKindOfClass:[NSDictionary class]])
    {
        // 执行原生方法
        [self jsToNative:evalDict webView:message.webView];
        return;
    }
}

- (void)nativeToJSCallback:(NSDictionary *)returnDict
{
    NSNumber *sequence = [returnDict objectForKey:@"sequence"];
    id result = [returnDict objectForKey:@"result"];
    
    if (!sequence || !result || sequence.integerValue == 0)
    {
        return;
    }
    
    SlateWebridgeCompletionBlock callback = nil;
    @synchronized(self)
    {
        callback = [_callbackDict objectForKey:sequence];
        [_callbackDict removeObjectForKey:sequence];
    }
    
    if (callback)
    {
        callback(result, nil);
    }
}

- (void)jsToNative:(NSDictionary *)evalDict webView:(UIWebView *)webView
{
    NSString *command = [evalDict objectForKey:@"command"];
    id params = [evalDict objectForKey:@"params"];
    NSNumber *sequence = [evalDict objectForKey:@"sequence"];
    
    if (!command || !params)
    {
        return;
    }
    
    if (![self asyncExecuteForCommand:command params:params sequence:sequence webView:webView])
    {
        // 异步调用失败，尝试同步调用
        [self executeForCommand:command params:params sequence:sequence webView:webView];
    }
}

- (BOOL)asyncExecuteForCommand:(NSString *)command params:(id)params sequence:(NSNumber *)sequence webView:(UIWebView *)webView
{
    if ([command isEqualToString:WEBVIEW_DELEGATE_COMMAND])
    {
        return NO;
    }
    
    NSInvocation *invocation = nil;
    
    NSString *methodName = [NSString stringWithFormat:@"%@:completion:webView:", command];
    SEL selector = NSSelectorFromString(methodName);
    
    id target = [self targetWithSelector:selector];
    if (!target)
    {
        return NO;
    }
    
    NSMethodSignature *signature = [[target class] instanceMethodSignatureForSelector:selector];
    if (!signature)
    {
        return NO;
    }
    
    __weak typeof(self) weakSelf = self;
    __weak UIWebView *weakWebView = webView;
    SlateWebridgeCompletionBlock block = ^(id result, NSError *error) {
        __strong UIWebView *strongWebView = weakWebView;
        [weakSelf callbackWithResult:result error:error.localizedDescription sequence:sequence webView:strongWebView];
    };
    
    invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation retainArguments];
    invocation.selector = selector;
    invocation.target = target;
    [invocation setArgument:&params atIndex:2];
    [invocation setArgument:&block atIndex:3];
    [invocation setArgument:&webView atIndex:4];
    
    if (invocation == nil || ![target respondsToSelector:selector])
    {
        return NO;
    }
    
    @try {
        [invocation invoke];
        NSLog(@"Webridge: %@ %@ %@", target, methodName, params);
    }
    @catch(NSException *exception) {
        NSLog (@"WebBridge exception on %@ %@", target, methodName);
        NSLog (@"%@ %@", [exception name], [exception reason]);
        NSLog (@"%@", [[exception callStackSymbols] componentsJoinedByString:@"\n"]);
        
        if (target)
        {
            NSString *error = [NSString stringWithFormat:@"%@ exception on method: %@",
                               NSStringFromClass([target class]),
                               methodName];
            error = [error stringByAppendingFormat:@"\nexception name:%@ reason:%@",
                     [exception name],
                     [exception reason]];
            
            [self callbackWithResult:nil error:error sequence:sequence webView:webView];
        }
    }
    
    return YES;
}

- (void)executeForCommand:(NSString *)command params:(id)params sequence:(NSNumber *)sequence webView:(UIWebView *)webView
{
    NSInvocation *invocation = nil;
    
    NSString *methodName = [NSString stringWithFormat:@"%@:webView:", command];
    SEL selector = NSSelectorFromString(methodName);
    
    id target = nil;
    if ([command isEqualToString:WEBVIEW_DELEGATE_COMMAND])
    {
        target = webView.delegate;
    }
    else
    {
        target = [self targetWithSelector:selector];
    }
    
    if (!target)
    {
        NSString *error = @"Webridge target is nil.";
        [self callbackWithResult:nil error:error sequence:sequence webView:webView];
        return;
    }

    NSMethodSignature *signature = [[target class] instanceMethodSignatureForSelector:selector];
    
    if (signature)
    {
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation retainArguments];
        invocation.selector = selector;
        invocation.target = target;
        [invocation setArgument:&params atIndex:2];
        [invocation setArgument:&webView atIndex:3];
    }
    
    if (invocation && [target respondsToSelector:selector])
    {
        @try {
            [invocation invoke];
            NSLog(@"Webridge: %@ %@ %@", target, methodName, params);
            
            id result = [invocation returnValueAsObject];
            
            NSLog(@"result: %@", result);
            
            [self callbackWithResult:result error:nil sequence:sequence webView:webView];
        }
        @catch(NSException *exception) {
            NSLog (@"WebBridge exception on %@ %@", target, methodName);
            NSLog (@"%@ %@", [exception name], [exception reason]);
            NSLog (@"%@", [[exception callStackSymbols] componentsJoinedByString:@"\n"]);
            
            if (target)
            {
                NSString *error = [NSString stringWithFormat:@"%@ exception on method: %@",
                                   NSStringFromClass([target class]),
                                   methodName];
                error = [error stringByAppendingFormat:@"\nexception name:%@ reason:%@",
                         [exception name],
                         [exception reason]];
                
                [self callbackWithResult:nil error:error sequence:sequence webView:webView];
            }
        }
    }
    else
    {
        NSLog (@"WebBridge controller doesn't know how to run method: %@ %@", target, methodName);
        
        if (target)
        {
            NSString *error = [NSString stringWithFormat:@"%@ doesn't know method: %@",
                               NSStringFromClass([target class]),
                               methodName];
            [self callbackWithResult:nil error:error sequence:sequence webView:webView];
        }
    }
}

- (void)callbackWithResult:(id)result error:(NSString *)error sequence:(NSNumber *)sequence webView:(UIWebView *)webView
{
    if (!webView || !sequence)
    {
        return;
    }
    NSString *jsonResult = @"''";
    if (result)
    {
        jsonResult = [result stringForJavascript];
    }
    if (!error)
    {
        error = @"";
    }
    NSString *callbackJS = nil;
    @try {
        callbackJS = [NSString stringWithFormat:@"webridge.jsToNativeCallback(%@, %@, '%@')", sequence, jsonResult, error];
    }
    @catch (NSException *exception) {
        NSLog (@"Webridge generate callbackJS exception name:%@ reason:%@", [exception name], [exception reason]);
    }
    @finally {
        if (callbackJS.length > 0)
        {
            NSString *result = [webView stringByEvaluatingJavaScriptFromString:callbackJS];
            NSLog(@"result:%@", result);
        }
    }
}

@end

@implementation SlateScriptMessage

@end
