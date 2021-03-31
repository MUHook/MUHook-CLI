//
//  MUHookTools.m
//  MUHookTools
//
//  Created by 吴双 on 2020/2/22.
//  Copyright © 2020 Magic-Unique. All rights reserved.
//

#import "MUHookTools.h"

@implementation MUHookTools

+ (NSString *)templateUrlWithGitee:(BOOL)gitee ssh:(BOOL)ssh {
    NSString *scheme = ssh ? @"git@" : @"https://";
    NSString *domain = gitee ? @"gitee.com" : @"github.com";
    NSString *userSep = ssh ? @":" : @"/";
    NSString *url = [NSString stringWithFormat:@"%@%@%@MUHook/Template.git", scheme, domain, userSep];
    return url;
}

+ (MUPath *)cli_rootDirectory {
    return [[MUPath homePath] subpathWithComponent:@".muhook"];
}

+ (MUPath *)cli_cacheDirectory {
    return [[self cli_rootDirectory] subpathWithComponent:@"caches"];
}

@end
