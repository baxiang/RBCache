//
//  RBKVItem.m
//  Pods
//
//  Created by baxiang on 2017/1/19.
//
//

#import "RBKVItem.h"

@implementation RBKVItem

- (BOOL)isValid
{
    if (self.expireDate <= 0) return YES;
    return (time(NULL) <= self.expireDate);
}

- (NSTimeInterval)remainLife
{
    if (self.expireDate <= 0) {
        return 0;
    } else {
        NSTimeInterval remainTime = self.expireDate - time(NULL);
        return remainTime > 0 ? remainTime : -1.0;
    }
}

@end
