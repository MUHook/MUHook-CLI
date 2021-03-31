//
//  MUHookTools.h
//  MUHookTools
//
//  Created by 吴双 on 2020/2/22.
//  Copyright © 2020 Magic-Unique. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MUHookTools : NSObject

+ (NSString *)templateUrlWithGitee:(BOOL)gitee ssh:(BOOL)ssh;

+ (MUPath *)cli_rootDirectory;

+ (MUPath *)cli_cacheDirectory;

@end
