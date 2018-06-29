//
//  LMCoreDataRepairManage.m
//  MOA
//
//  Created by Limo on 2018/6/14.
//  Copyright © 2018年 moa. All rights reserved.
//

#import "LMCoreDataRepairManage.h"
#import "WCRepairKitManage.h"
#include <stdlib.h>
#import <UIKit/UIKit.h>

DidFinishLaunchingBlock didFinishLaunchingBlock;

@interface LMCoreDataRepairAlert:NSObject

- (void)showPromptView;
@property (nonatomic, copy) void(^repairBlock)();

@end

LMCoreDataRepairAlert * alert;

@implementation LMCoreDataRepairAlert

- (void)showPromptView {
    UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"检测到数据库可能已损坏，是否尝试修复？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"修复", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *btnTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([btnTitle isEqualToString:@"取消"]) {
        if (didFinishLaunchingBlock) {
            didFinishLaunchingBlock();
        }
    } else if ([btnTitle isEqualToString:@"修复"]) {
        if (self.repairBlock) {
            self.repairBlock();
        }
    }
}
@end

@interface LMCoreDataRepairManage()<UIAlertViewDelegate>

@end

@implementation LMCoreDataRepairManage


+ (void)repairKitStartWithDB:(NSString *)corruptedDBPath storeIdentifiers:(NSString *)storeIdentifiers{
    
    if (storeIdentifiers == nil || [storeIdentifiers isKindOfClass:[NSString class]]==NO) {
        return;
    }
    
    
    if ([[WCRepairKitManage shareManage] repairKitCheckIntegrityDB:corruptedDBPath corruptedDBCipher:nil error:nil]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *key = [NSString stringWithFormat:@"WCRepairKitStoreIdentifiers+%@",corruptedDBPath];
            
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:key] isEqualToString:storeIdentifiers] == NO) {
                [[WCRepairKitManage shareManage] backupDBPath:corruptedDBPath backupCipher:nil];
                [[NSUserDefaults standardUserDefaults] setObject:storeIdentifiers forKey:key];
            }
            
        });
    } else {
        
        [[WCRepairKitManage shareManage] recoveryDBPath:corruptedDBPath DBPageSize:4096 corruptedDBCipher:nil backupCipher:nil isOverwriteFile:YES error:nil];
    }
    
    
    
    
    //    NSArray *dbPathArr = [NSArray arrayWithArray:[self allDefaultDBNameFilesAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]]];
    //
    //    NSMutableArray *backupDBPathArr = [NSMutableArray array];
    //    NSMutableArray *recoveryDBPathArr = [NSMutableArray array];
    //
    //    for (NSString *dbPath in dbPathArr) {
    //        if ([[WCRepairKitManage shareManage] repairKitCheckIntegrityDB:dbPath corruptedDBCipher:nil error:nil]) {
    //            [backupDBPathArr addObject:dbPath];
    //        } else {
    //            if ([[WCRepairKitManage shareManage] backupExistsAtDBPath:dbPath error:nil]) {
    //                [recoveryDBPathArr addObject:dbPath];
    //            }
    //        }
    //    }
    //
    //
    //    if (recoveryDBPathArr.count > 0) {
    //
    //        alert = [[LMCoreDataRepairAlert alloc] init];
    //        alert.repairBlock = ^(){
    //            [self recoveryDB:[NSArray arrayWithArray:recoveryDBPathArr]];
    //        };
    //        [alert showPromptView];
    //        return;
    //    }
    //
    //    if (didFinishLaunchingBlock) {
    //        didFinishLaunchingBlock();
    //    }
    //
    //
    //    if (backupDBPathArr.count <= 0) {
    //        return;
    //    }
    //
    //    for (NSString *dbPath in backupDBPathArr) {
    //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //            [[WCRepairKitManage shareManage] backupDBPath:dbPath backupCipher:nil];
    //        });
    //    }hbjngm
}


+ (void)setDidFinishLaunchingBlock:(DidFinishLaunchingBlock)block {
    
    didFinishLaunchingBlock = block;
    
}




+ (void)presentAlertViewController:(UIAlertController *)alertController {
    if ([[UIApplication sharedApplication]keyWindow].rootViewController == nil) {
        [[UIApplication sharedApplication]keyWindow].rootViewController = [[UIViewController alloc] init];
    }
    [[[UIApplication sharedApplication]keyWindow].rootViewController presentViewController:alertController animated:YES completion:nil];
}


+ (void)recoveryDB:(NSArray *)recoveryDBPathArr {
    
    if (recoveryDBPathArr.count > 0) {
        for (NSString *dbPath in recoveryDBPathArr) {
            // 唤起修复
            [[WCRepairKitManage shareManage] recoveryDBPath:dbPath DBPageSize:4096 corruptedDBCipher:nil backupCipher:nil isOverwriteFile:YES error:nil];
        }
    }
    
    NSLog(@"Recovery success");
    if (didFinishLaunchingBlock) {
        didFinishLaunchingBlock();
    }
}



+ (NSMutableArray *)allDefaultDBNameFilesAtPath:(NSString *)direString{
    NSString *defaultDBName = @".db";
    
    NSMutableArray *pathArray = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *tempArray = [fileManager contentsOfDirectoryAtPath:direString error:nil];
    for (NSString *fileName in tempArray) {
        BOOL flag = YES;
        NSString *fullPath = [direString stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&flag]) {
            if (!flag) {
                if ([fileName isEqualToString:defaultDBName]) {
                    [pathArray addObject:fullPath];
                }
            } else {
                if ([fileName rangeOfString:@"_incompatible"].location != NSNotFound) {
                    continue;
                }
                NSString *dbPath = [fullPath stringByAppendingPathComponent:defaultDBName];
                if ([fileManager fileExistsAtPath:dbPath]) {
                    [pathArray addObject:dbPath];
                }
            }
        }
    }
    
    return pathArray;
}


#warning 下面是损坏数据的测试代码 务必不要主动调用！！！！
+ (void)testCorruptDB {
#if DEBUG
    
    NSArray *dbPathArr = [NSArray arrayWithArray:[self allDefaultDBNameFilesAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]]];
    
    NSMutableArray *backupDBPathArr = [NSMutableArray array];
    NSMutableArray *recoveryDBPathArr = [NSMutableArray array];
    
    for (NSString *dbPath in dbPathArr) {
        if ([[WCRepairKitManage shareManage] repairKitCheckIntegrityDB:dbPath corruptedDBCipher:nil error:nil]) {
            [backupDBPathArr addObject:dbPath];
            
        } else {
            [recoveryDBPathArr addObject:dbPath];
        }
    }
    
    
    if (backupDBPathArr.count == 0) {
        UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"无可用数据库" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alertView show];
        return;
    }
    
    NSString *message = @"已损坏以下数据库：\n";
    for (NSString *dbPath in backupDBPathArr) {
        NSString *storeURLStr = dbPath;
        if ([storeURLStr hasPrefix:@"file://"]) {
            storeURLStr = [storeURLStr substringFromIndex:7];
        }
        
        // OC API
        NSData *data = [self create1KbRandomNSData];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:storeURLStr];
        [fileHandle seekToFileOffset:0];  //将节点跳到文件的头部
        [fileHandle writeData:data]; //追加写入数据
        [fileHandle closeFile];
        
        message = [NSString stringWithFormat:@"%@ %@ \n",message,dbPath];
        //    // C API
        //    FILE *file = fopen(storeURLStr.UTF8String, "rb+");
        //    unsigned char *zeroPage = new unsigned char[100];
        //    memset(zeroPage, 0, 100);
        //    fwrite(zeroPage, 100, 1, file);
        //    fclose(file);
        
    }
    
    UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alertView show];
    
#endif
    
}

/**
 生成1Kb的随机data数据
 
 @return 1Kb的随机data数据
 */
+ (NSData *)create1KbRandomNSData {
    int oneKb           = 1024;
    NSMutableData* theData = [NSMutableData dataWithCapacity:oneKb];
    for( unsigned int i = 0 ; i < oneKb/4 ; ++i ) {
        u_int32_t randomBits = arc4random();
        [theData appendBytes:(void*)&randomBits length:4];
    }
    return theData;
}

@end
