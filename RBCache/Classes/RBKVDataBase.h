//
//  RBKVDataBase.h
//  Pods
//
//  Created by baxiang on 2017/1/19.
//
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@class RBKVItem;
@interface RBKVDataBase : NSObject


@property (nonatomic, assign) BOOL errorLogsSwitch; // Default is YES.

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;


- (instancetype)initWithDirectory:(NSString *)directory NS_DESIGNATED_INITIALIZER;

- (BOOL)dbReset;

- (BOOL)dbExecute:(NSString *)sqlStr;

- (BOOL)dbCheck;

- (void)dbCheckpoint;

- (nullable RBKVItem *)dbGetItemForKey:(NSString *)key;

- (BOOL)dbSaveItemWithKey:(NSString *)key value:(NSData *)value filename:(nullable NSString *)filename;
- (BOOL)dbSaveItemWithKey:(NSString *)key
                    value:(NSData *)value
                 filename:(nullable NSString *)filename
                 lifetime:(NSTimeInterval)lifetime
             extendedData:(nullable NSData *)extendedData;

- (nullable NSString *)dbGetFilenameWithKey:(NSString *)key;
- (nullable NSArray<NSString *> *)dbGetFilenamesWithExpireDateEarlierThan:(NSInteger)date;
- (nullable NSArray<RBKVItem *> *)dbGetItemsOrderByExpireDateAscWithLimit:(NSInteger)rowNum;

- (BOOL)dbDeleteItemWithKey:(NSString *)key;
- (BOOL)dbDeleteItemsWithExpireDateEarlierThan:(NSInteger)time;

- (NSInteger)dbGetTotalItemSize;
- (NSInteger)dbGetTotalItemCount;

@end
NS_ASSUME_NONNULL_END
