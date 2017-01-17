//
//  RBCache.m
//  Pods
//
//  Created by baxiang on 2017/1/18.
//
//

#import "RBCache.h"

@implementation RBCache

+(RBCache*)defaultCache{
    static RBCache *_dafaultCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dafaultCache = [[[self class] alloc] init];
    });
    return _dafaultCache;
}

@end
