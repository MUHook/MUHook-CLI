//
//  MUHReplaceMap.h
//  MUHookTools
//
//  Created by 吴双 on 2020/2/23.
//  Copyright © 2020 Magic-Unique. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MUHReplaceItem : NSObject

@property (nonatomic, copy, readonly) NSString *key;

@property (nonatomic, copy, readonly) NSString *value;

@end

@interface MUHReplaceMap : NSObject

@property (nonatomic, strong, readonly) NSArray<MUHReplaceItem *> *items;

- (void)addKey:(NSString *)key value:(NSString *)value;

- (void)setObject:(NSString *)obj forKeyedSubscript:(NSString *)key;

@end
