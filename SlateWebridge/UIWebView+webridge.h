//
//  UIWebView+webridge.h
//  SlateCore
//
//  Created by linyize on 16/6/24.
//  Copyright © 2016年 islate. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SlateWebridge;

@interface UIWebView (webridge)

// 设置webridge指针
- (void)setBridge:(SlateWebridge *)bridge;
- (SlateWebridge *)bridge;

// 原生调用网页JS
- (void)evalJSCommand:(NSString *)jsCommand jsParams:(id)jsParams completionHandler:(void (^)(id, NSError *))completionHandler;

// 处理webridge调用或者回调消息
- (BOOL)handleWebridgeMessage:(NSURL *)url;

@end
