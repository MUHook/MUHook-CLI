//
//  CLLoading+Tools.m
//  MUHookTools
//
//  Created by 吴双 on 2020/2/23.
//  Copyright © 2020 Magic-Unique. All rights reserved.
//

#import "CLLoading+Tools.h"

@implementation CLLoading (Tools)

+ (instancetype)sharedInstance {
    static CLLoading *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [CLLoading loading];
        _shared.text = @"Waiting...";
    });
    return _shared;
}

+ (void)start {
    [[self sharedInstance] start];
}

+ (void)stop {
    [[self sharedInstance] stop];
}

@end
