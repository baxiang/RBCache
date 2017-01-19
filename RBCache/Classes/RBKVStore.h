//
//  RBKVStore.h
//  Pods
//
//  Created by baxiang on 2017/1/19.
//
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@class RBKVItem;
@interface RBKVStore : NSObject

- (instancetype)initWithDirectory:(NSString *)directory;

- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value;
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value filename:(nullable NSString *)filename;
- (BOOL)saveItemWithKey:(NSString *)key
                  value:(NSData *)value
               filename:(nullable NSString *)filename
               lifetime:(NSTimeInterval)lifetime
           extendedData:(nullable NSData *)extendedData;

- (nullable NSData *)getItemValueForKey:(NSString *)key;
- (nullable RBKVItem *)getItemForKey:(NSString *)key;

- (BOOL)removeItemForKey:(NSString *)key;
- (BOOL)removeItemsWithSizeLimit:(NSInteger)size;
- (BOOL)removeItemsWithCountLimit:(NSInteger)count;
- (BOOL)removeItemsEarlierThanDate:(NSInteger)date;
- (BOOL)removeAllItems;

- (NSInteger)totalItemsSize;
- (NSInteger)totalItemsCount;
@end
NS_ASSUME_NONNULL_END
