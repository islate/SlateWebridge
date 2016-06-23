//
//  NSObject+webridge.m
//  SlateCore
//
//  Created by linyize on 16/5/27.
//  Copyright © 2016年 Modern Mobile Digital Media Company Limited. All rights reserved.
//

#import "NSObject+webridge.h"

@implementation NSObject (webridge)

- (NSString *)stringForJavascript
{
    if ([self isKindOfClass:[NSString class]])
    {
        return [NSString stringWithFormat:@"'%@'", self];
    }
    else if ([self isKindOfClass:[NSNumber class]])
    {
        return [NSString stringWithFormat:@"%@", self];
    }
    else {
        @try {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:nil];
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            return jsonString;
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
        return nil;
    }
}

@end
