//
//  WCRepairKitManage.m
//  RepairKitDemo
//
//  Created by Limo on 2018/6/12.
//  Copyright © 2018年 Limo. All rights reserved.
//

#import "WCRepairKitManage.h"
#include "SQLiteRepairKit.h"
#import <sqlite3.h>


static sqlite3 *db = nil;


@implementation WCRepairKitManage

- (BOOL)backupDBPath:(NSString *)corruptedDBPath{
    return [self backupDBPath:corruptedDBPath backupCipher:nil];
}

- (BOOL)backupDBPath:(NSString *)corruptedDBPath backupCipher:(NSString *)backupCipherStr{
    
    if (corruptedDBPath == nil || [corruptedDBPath isKindOfClass:[NSString class]] == NO) {
        NSError *error = [NSError errorWithDomain:@"数据库文件路径错误"
                                             code:0
                                         userInfo:nil];
        NSLog(@"%@",error);
        return NO;
    }
    
    const void *backupCipherBytes;
    unsigned int backupCipherLength;
    
    if (backupCipherStr == nil || [backupCipherStr isKindOfClass:[NSString class]] == NO) {
        backupCipherBytes = 0;
        backupCipherLength = 0;
    } else {
        NSData *backupCipher = [backupCipherStr dataUsingEncoding:NSASCIIStringEncoding];
        backupCipherBytes = backupCipher.bytes;
        backupCipherLength = (unsigned int)backupCipher.length;
    }
    
    const char *backupPathCStr = [NSString stringWithFormat:@"%@%@",corruptedDBPath,@"-backup"].UTF8String;
    
    int rc = sqliterk_save_master([self openDB:corruptedDBPath], backupPathCStr, backupCipherBytes,
                                  backupCipherLength);
    if (rc == SQLITERK_OK) {
        [self closeDB:corruptedDBPath];
        return YES;
    }
    
    NSError *error = [NSError errorWithDomain:@"数据库文件备份失败"
                                         code:rc
                                     userInfo:@{
                                                @"Path":[NSString stringWithUTF8String:backupPathCStr],
                                                }];
    NSLog(@"%@",error);
    return NO;
}

- (BOOL)recoveryDBPath:(NSString *)corruptedDBPath DBPageSize:(int)pageSize{
    
    return [self recoveryDBPath:corruptedDBPath DBPageSize:pageSize backupCipher:nil];
}
- (BOOL)recoveryDBPath:(NSString *)corruptedDBPath DBPageSize:(int)pageSize backupCipher:(NSString *)backupCipherStr{
    
    if (corruptedDBPath == nil || [corruptedDBPath isKindOfClass:[NSString class]] == NO) {
        NSError *error = [NSError errorWithDomain:@"数据库文件路径错误"
                                             code:0
                                         userInfo:nil];
        NSLog(@"%@",error);
        return NO;
    }
    
    if (pageSize <= 0) {
        NSError *error = [NSError errorWithDomain:@"数据库页大小有误"
                                             code:0
                                         userInfo:nil];
        NSLog(@"%@",error);
        return NO;
    }
    
    const void *backupCipherBytes;
    unsigned int backupCipherLength;
    
    if (backupCipherStr == nil || [backupCipherStr isKindOfClass:[NSString class]] == NO) {
        backupCipherBytes = 0;
        backupCipherLength = 0;
    } else {
        NSData *backupCipher = [backupCipherStr dataUsingEncoding:NSASCIIStringEncoding];
        backupCipherBytes = backupCipher.bytes;
        backupCipherLength = (unsigned int)backupCipher.length;
    }

    const char *corruptedDBPathCStr = corruptedDBPath.UTF8String;
    const char *backupPathCStr = [NSString stringWithFormat:@"%@%@",corruptedDBPath,@"-backup"].UTF8String;
    const char *recoveryPathCStr = [NSString stringWithFormat:@"%@%@",corruptedDBPath,@"-recovery"].UTF8String;
    
    sqliterk_master_info *info;
    unsigned char kdfSalt[16];
    memset(kdfSalt, 0, 16);
    int rc = sqliterk_load_master(backupPathCStr, backupCipherBytes,
                                  backupCipherLength, nullptr, 0, &info, kdfSalt);
    
    if (rc != SQLITERK_OK) {
        NSError *error = [NSError errorWithDomain:@"读取数据库备份文件失败"
                                             code:rc
                                         userInfo:@{
                                                    @"Path":[NSString stringWithUTF8String:backupPathCStr],
                                                    }];
        NSLog(@"%@",error);
        return NO;
    }
    
    sqliterk_cipher_conf conf;
    memset(&conf, 0, sizeof(sqliterk_cipher_conf));
    conf.key = 0;
    conf.key_len = 0;
    conf.page_size = pageSize;
    conf.kdf_salt = kdfSalt;
    conf.use_hmac = true;
    
    sqliterk *rk;
    rc = sqliterk_open(corruptedDBPathCStr, &conf, &rk);
    if (rc != SQLITERK_OK) {
        NSError *error = [NSError errorWithDomain:@"读取损坏数据库失败"
                                             code:rc
                                         userInfo:@{
                                                    @"Path":[NSString stringWithUTF8String:corruptedDBPathCStr],
                                                    }];
        NSLog(@"%@",error);
        return NO;
    }
    
    [self openDB:[NSString stringWithUTF8String:recoveryPathCStr]];
    rc = sqliterk_output(rk, db, info,
                         SQLITERK_OUTPUT_ALL_TABLES);
    if (rc != SQLITERK_OK) {
        NSError *error = [NSError errorWithDomain:@"还原数据库文件失败"
                                             code:rc
                                         userInfo:@{
                                                    @"Path":[NSString stringWithUTF8String:recoveryPathCStr],
                                                    }];
        NSLog(@"%@",error);
        return NO;
    }
    [self closeDB:[NSString stringWithUTF8String:recoveryPathCStr]];
    return YES;
}



#pragma mark 打开或者创建数据库
- (sqlite3 *)openDB:(NSString *)dbPath {
    if (!db) {
        NSLog(@"%@",dbPath);
        //判断dbPath中是否有sqlite文件
        int result = sqlite3_open([dbPath UTF8String], &db);
        if (result == SQLITERK_OK) {
            NSLog(@"打开数据库成功！");
        }else{
            [self closeDB:dbPath];
            NSError *error = [NSError errorWithDomain:@"打开数据库失败"
                                                 code:result
                                             userInfo:@{
                                                        @"Path":dbPath,
                                                        }];
            NSLog(@"%@",error);
        }
    }
    return db;
}

#pragma mark 关闭数据库
- (void)closeDB:(NSString *)dbPath {
    int result = sqlite3_close(db);
    if (result == SQLITE_OK) {
        NSLog(@"数据库关闭成功！");
        db = nil;
    } else {
        NSError *error = [NSError errorWithDomain:@"数据库关闭失败"
                                             code:result
                                         userInfo:@{
                                                    @"Path":dbPath,
                                                    }];
        NSLog(@"%@",error);
    }
}

#pragma mark - LifeCycle
static WCRepairKitManage *_manage;

+ (instancetype)shareManage {
    return [[self alloc]init];
}


+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_manage == nil) {
            _manage = [super allocWithZone:zone];
        }
    });
    return _manage;
}

- (id)copyWithZone:(NSZone *)zone {
    return _manage;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _manage;
}

@end
