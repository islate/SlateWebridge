//
//  NSInvocation+Extensions.m
//  SlateCore
//
//  Created by yize lin on 16-6-23.
//  Copyright (c) 2016年 islate. All rights reserved.
//

#import "NSInvocation+Extensions.h"

@implementation NSInvocation (Extensions)

- (id)returnValueAsObject
{
    const char *methodReturnType = [[self methodSignature] methodReturnType];
    switch (*methodReturnType)
    {
        case 'c':
        {
            int8_t value;
            [self getReturnValue:&value];
            return [NSNumber numberWithChar:value];
        }
        case 'C':
        {
            uint8_t value;
            [self getReturnValue:&value];
            return [NSNumber numberWithUnsignedChar:value];
        }
        case 'i':
        {
            int32_t value;
            [self getReturnValue:&value];
            return [NSNumber numberWithInt:value];
        }
        case 'I':
        {
            uint32_t value;
            [self getReturnValue:&value];
            return [NSNumber numberWithUnsignedInt:value];
        }
        case 's':
        {
            int16_t value;
            [self getReturnValue:&value];
            return [NSNumber numberWithShort:value];
        }
        case 'S':
        {
            uint16_t value;
            [self getReturnValue:&value];
            return [NSNumber numberWithUnsignedShort:value];
        }
        case 'f':
        {
            float value;
            [self getReturnValue:&value];
            return [NSNumber numberWithFloat:value];
        }
        case 'd':
        {
            double value;
            [self getReturnValue:&value];
            return [NSNumber numberWithDouble:value];
        }
        case 'B':
        {
            uint8_t value;
            [self getReturnValue:&value];
            return [NSNumber numberWithBool:(BOOL)value];
        }
        case 'l':
        {
            long value;
            [self getReturnValue:&value];
            return [NSNumber numberWithLong:value];
        }
        case 'L':
        {
            unsigned long value;
            [self getReturnValue:&value];
            return [NSNumber numberWithUnsignedLong:value];
        }
        case 'q':
        {
            long long value;
            [self getReturnValue:&value];
            return [NSNumber numberWithLongLong:value];
        }
        case 'Q':
        {
            unsigned long long value;
            [self getReturnValue:&value];
            return [NSNumber numberWithUnsignedLongLong:value];
        }
        case '@':
        {
            __unsafe_unretained id value;
            [self getReturnValue:&value];
            return [value copy];
        }
        case 'v':
        case 'V':
        {
            return nil;
        }
        default:
        {
            return nil;
        }
    }
    return nil;
}

@end

