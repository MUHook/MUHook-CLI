//
//  main.m
//  MUHookTools
//
//  Created by 吴双 on 2020/2/22.
//  Copyright © 2020 Magic-Unique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MUHookTools.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        CLMainExplain = @"MUHook 工具";
        CLMakeSubcommand(MUHookTools, __init_);
        CLCommandMain();
    }
    return 0;
}
