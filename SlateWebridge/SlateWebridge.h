//
//  SlateWebridge.h
//  Slate
//
//  Created by yize lin on 13-8-5.
//  Copyright (c) 2012年 Modern Mobile Digital Media Company Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^SlateWebridgeCompletionBlock)(id result, NSError *error);

@protocol SlateWebridgeHandler;

/**
 *  webView与原生代码的通信封装
 */
@interface SlateWebridge : NSObject

+ (instancetype)sharedBridge;

- (void)addHandlers:(NSArray<id<SlateWebridgeHandler>>*)handlers;
- (void)setPriorHandler:(id<SlateWebridgeHandler>)handler;

// 网页调用原生功能 或者 js回调
- (BOOL)isWebridgeMessage:(NSURL *)URL;
- (void)handleWebridgeMessage:(NSURL *)URL webView:(UIWebView *)webView;

// 原生调用网页JS
- (void)evalJSCommand:(NSString *)jsCommand jsParams:(id)jsParams completionHandler:(void (^)(id, NSError *))completionHandler webView:(UIWebView *)webView;

@end

@protocol SlateWebridgeHandler <NSObject>

@end
