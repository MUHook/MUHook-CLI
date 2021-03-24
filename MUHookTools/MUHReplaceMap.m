//
//  MUHReplaceMap.m
//  MUHookTools
//
//  Created by 吴双 on 2020/2/23.
//  Copyright © 2020 Magic-Unique. All rights reserved.
//

#import "MUHReplaceMap.h"

@implementation MUHReplaceItem

- (void)setKey:(NSString *)key {
    _key = key;
}

- (void)setValue:(NSString *)value {
    _value = value;
}

@end

@interface MUHReplaceMap ()

@property (nonatomic, strong, readonly) NSMutableArray *mItems;

@end

@implementation MUHReplaceMap

- (instancetype)init {
    self = [super init];
    if (self) {
        _mItems = [NSMutableArray array];
    }
    return self;
}

- (void)addKey:(NSString *)key value:(NSString *)value {
    MUHReplaceItem *item = [MUHReplaceItem new];
    item.key = key;
    item.value = value;
    [self.mItems addObject:item];
}

- (void)setObject:(NSString *)obj forKeyedSubscript:(NSString *)key {
    [self addKey:key value:obj];
}

- (NSArray *)items {
    return [self.mItems copy];
}

@end
