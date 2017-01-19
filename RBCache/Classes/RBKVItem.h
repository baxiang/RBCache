//
//  RBKVItem.h
//  Pods
//
//  Created by baxiang on 2017/1/19.
//
//

#import <Foundation/Foundation.h>

@interface RBKVItem : NSObject

@property (nonatomic, strong) NSString *key;

@property (nonatomic, strong) NSData *value;

@property (nonatomic, strong, nullable) NSString *filename;

@property (nonatomic, assign) int size;

@property (nonatomic, assign) long expireDate;

@property (nonatomic, strong, nullable) NSData *extendedData;

- (BOOL)isValid;

- (NSTimeInterval)remainLife;
@end
