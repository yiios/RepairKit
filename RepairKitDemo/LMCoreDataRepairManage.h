//
//  LMCoreDataRepairManage.h
//  MOA
//
//  Created by Limo on 2018/6/14.
//  Copyright © 2018年 moa. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DidFinishLaunchingBlock)(void);

@interface LMCoreDataRepairManage : NSObject

+ (void)setDidFinishLaunchingBlock:(DidFinishLaunchingBlock)block;

+ (void)repairKitStartWithDB:(NSString *)corruptedDBPath storeIdentifiers:(NSString *)storeIdentifiers;


#warning 下面是损坏数据的测试代码 不要主动调用！！！！
+ (void)testCorruptDB;

@end
