//
//  MUHCreator.h
//  MUHookTools
//
//  Created by 吴双 on 2020/2/22.
//  Copyright © 2020 Magic-Unique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MUHReplaceMap.h"

@interface MUHCreator : NSObject

@property (nonatomic, strong, readonly) MUHReplaceMap *map;

@property (nonatomic, strong) MUPath *app;

@property (nonatomic, strong) MUPath *distPath;

@property (nonatomic, assign) BOOL open;

- (void)create;

@end
