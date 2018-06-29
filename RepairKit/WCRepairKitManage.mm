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


@implementation WCRepairKitManage

- (BOOL)backupDBPath:(NSString *)corruptedDBPath{
    return [self backupDBPath:corruptedDBPath backupCipher:nil error:nil]?YES:NO;
}

- (BOOL)backupDBPath:(NSString *)corruptedDBPath backupCipher:(NSString *)backupCipherStr {
    return [self backupDBPath:corruptedDBPath  backupCipher:backupCipherStr error:nil]?YES:NO;
}

- (NSString *)backupDBPath:(NSString *)corruptedDBPath backupCipher:(NSString *)backupCipherStr error:(NSError **)error{
    
    [self fixPath:corruptedDBPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([corruptedDBPath isEqualToString:@""] || ![fileManager fileExistsAtPath:corruptedDBPath]) {
        if (error) {
            *error = [NSError errorWithDomain:@"数据库文件路径错误" code:0 userInfo:nil];
            NSLog( @"%@",*error);
        }
        return nil;
    }
    
    NSString *backupPath = [corruptedDBPath stringByAppendingString:@"-backup"];
    NSString *oldBackupPath = [corruptedDBPath stringByAppendingString:@"-oldBackup"];
    
    if ([fileManager fileExistsAtPath:backupPath]) {
        // 已有文件旧备份文件 需要移动备份文件
        if ([[fileManager attributesOfItemAtPath:backupPath error:nil] fileSize]>1024) {
            if ([fileManager fileExistsAtPath:oldBackupPath]) {
                [fileManager removeItemAtPath:oldBackupPath error:nil];
            }
            [fileManager copyItemAtPath:backupPath toPath:oldBackupPath error:nil];
        }
        [fileManager removeItemAtPath:backupPath error:nil];
    }
    
    
    const void *backupCipherBytes;
    unsigned int backupCipherLength;
    if (backupCipherStr == nil || [backupCipherStr isKindOfClass:[NSString class]] == NO) {
        backupCipherBytes = 0;
        backupCipherLength = 0;
    } else {
        NSData *backupCipher = [NSData dataWithBytes:[backupCipherStr UTF8String] length:(NSUInteger)strlen([backupCipherStr UTF8String])];
        backupCipherBytes = backupCipher.bytes;
        backupCipherLength = (unsigned int)backupCipher.length;
    }
    
    
    const char *backupPathCStr = backupPath.fileSystemRepresentation;
    
    
    sqlite3 *corruptedDB = NULL;
    int result = sqlite3_open([corruptedDBPath fileSystemRepresentation], &corruptedDB);
    if (result != SQLITERK_OK) {
        
        sqlite3_close(corruptedDB);
        if (error) {
            *error = [NSError errorWithDomain:@"打开待备份数据库失败" code:result userInfo:@{ @"Path":corruptedDBPath, }];
            NSLog( @"%@",*error);
        }
        return nil;
    }
    
    int rc = sqliterk_save_master(corruptedDB, backupPathCStr, backupCipherBytes,
                                  backupCipherLength);
    if (rc == SQLITERK_OK) {
        rc = sqlite3_close(corruptedDB);
        if (rc != SQLITE_OK) {
            if (error) {
                *error = [NSError errorWithDomain:@"待备份数据库关闭失败" code:result userInfo:@{ @"Path":corruptedDBPath, }];
                NSLog( @"%@",*error);
            }
            
        }
        return backupPath;
    }
    
    if (error) {
        *error = [NSError errorWithDomain:@"数据库文件备份失败" code:rc userInfo:@{ @"Path":[NSString stringWithUTF8String:backupPathCStr], }];
        NSLog( @"%@",*error);
    }
    
    // 备份数据库文件失败 删除临时生成的备份文件
    if ([fileManager fileExistsAtPath:backupPath]) {
        [fileManager removeItemAtPath:backupPath error:nil];
        if ([fileManager fileExistsAtPath:oldBackupPath] && [[fileManager attributesOfItemAtPath:oldBackupPath error:nil] fileSize]>1024) {
            [fileManager copyItemAtPath:oldBackupPath toPath:backupPath error:nil];
            [fileManager removeItemAtPath:oldBackupPath error:nil];
        }
    }
    
    return nil;
}

- (BOOL)recoveryDBPath:(NSString *)corruptedDBPath {
    return [self recoveryDBPath:corruptedDBPath DBPageSize:4096 corruptedDBCipher:nil backupCipher:nil isOverwriteFile:YES error:nil]?YES:NO;
}

- (BOOL)recoveryDBPath:(NSString *)corruptedDBPath backupCipher:(NSString *)backupCipherStr{
    return [self recoveryDBPath:corruptedDBPath DBPageSize:4096 corruptedDBCipher:nil backupCipher:backupCipherStr isOverwriteFile:YES error:nil]?YES:NO;
}

- (NSString *)recoveryDBPath:(NSString *)corruptedDBPath DBPageSize:(int)pageSize corruptedDBCipher:(NSString *)corruptedDBCipherStr backupCipher:(NSString *)backupCipherStr isOverwriteFile:(BOOL)isOverwriteFile error:(NSError **)error{
    
    corruptedDBPath = [self fixPath:corruptedDBPath];
    
    if (corruptedDBPath == nil || [corruptedDBPath isKindOfClass:[NSString class]] == NO) {
        if (error) {
            *error = [NSError errorWithDomain:@"数据库文件路径错误" code:0 userInfo:nil];
            NSLog( @"%@",*error);
        }
        return nil;
    }
    
    if (pageSize <= 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"数据库页大小有误" code:0 userInfo:nil];
            NSLog( @"%@",*error);
        }
        return nil;
    }
    
    NSString *backupPath = [corruptedDBPath stringByAppendingString:@"-backup"];
    NSString *oldBackupPath = [corruptedDBPath stringByAppendingString:@"-oldBackup"];
    
    NSFileManager* fileManager=[NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:backupPath]) {
        // 如果备份1不存在 则使用备份2 如果备份文件都不存在 则return
        if ([fileManager fileExistsAtPath:oldBackupPath]) {
            backupPath = oldBackupPath;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:@"备份文件不存在" code:0 userInfo:nil];
                NSLog( @"%@",*error);
            }
            return nil;
        }
    }
    
    
    const void *backupCipherBytes;
    unsigned int backupCipherLength;
    if (backupCipherStr == nil || [backupCipherStr isKindOfClass:[NSString class]] == NO) {
        backupCipherBytes = 0;
        backupCipherLength = 0;
    } else {
        NSData *backupCipher = [NSData dataWithBytes:[backupCipherStr UTF8String] length:(NSUInteger)strlen([backupCipherStr UTF8String])];
        backupCipherBytes = backupCipher.bytes;
        backupCipherLength = (unsigned int)backupCipher.length;
    }
    
    const void *corruptedDBCipherBytes;
    unsigned int corruptedDBCipherLength;
    if (corruptedDBCipherStr == nil || [corruptedDBCipherStr isKindOfClass:[NSString class]] == NO) {
        corruptedDBCipherBytes = 0;
        corruptedDBCipherLength = 0;
    } else {
        NSData *corruptedDBCipher = [NSData dataWithBytes:[corruptedDBCipherStr UTF8String] length:(NSUInteger)strlen([corruptedDBCipherStr UTF8String])];
        corruptedDBCipherBytes = corruptedDBCipher.bytes;
        corruptedDBCipherLength = (unsigned int)corruptedDBCipher.length;
    }
    
    NSString *recoveryPath = [NSString stringWithFormat:@"%@%@",corruptedDBPath,@"-recovery"];
    
    const char *corruptedDBPathCStr = corruptedDBPath.fileSystemRepresentation;
    const char *backupPathCStr = backupPath.fileSystemRepresentation;
    const char *recoveryPathCStr = recoveryPath.fileSystemRepresentation;
    
    sqliterk_master_info *info;
    unsigned char kdfSalt[16];
    memset(kdfSalt, 0, 16);
    int rc = sqliterk_load_master(backupPathCStr, backupCipherBytes,
                                  backupCipherLength, nullptr, 0, &info, kdfSalt);
    
    if (rc != SQLITERK_OK) {
        if (error) {
            *error = [NSError errorWithDomain:@"读取数据库备份文件失败" code:rc userInfo:@{ @"Path":[NSString stringWithUTF8String:backupPathCStr], }];
            NSLog( @"%@",*error);
        }
        
        return nil;
    }
    
    sqliterk_cipher_conf conf;
    memset(&conf, 0, sizeof(sqliterk_cipher_conf));
    conf.key = corruptedDBCipherBytes;
    conf.key_len = corruptedDBCipherLength;
    conf.page_size = pageSize;
    conf.kdf_salt = kdfSalt;
    conf.use_hmac = true;
    
    sqliterk *rk;
    rc = sqliterk_open(corruptedDBPathCStr, corruptedDBCipherLength?&conf:NULL, &rk);
    if (rc != SQLITERK_OK) {
        if (error) {
            *error = [NSError errorWithDomain:@"读取已损坏数据库失败" code:rc userInfo:@{ @"Path":corruptedDBPath, }];
            NSLog( @"%@",*error);
        }
        
        return nil;
    }
    
    sqlite3 *recoveryDB = NULL;
    rc = sqlite3_open(recoveryPathCStr, &recoveryDB);
    if (rc != SQLITERK_OK) {
        sqlite3_close(recoveryDB);
        if (error) {
            *error = [NSError errorWithDomain:@"创建数据库备份失败" code:rc userInfo:@{ @"Path":recoveryPath, }];
            NSLog( @"%@",*error);
        }
        
        return nil;
    }
    
    rc = sqliterk_output(rk, recoveryDB, info,
                         SQLITERK_OUTPUT_ALL_TABLES);
    if (rc != SQLITERK_OK) {
        if (error) {
            *error = [NSError errorWithDomain:@"还原数据库文件失败" code:rc userInfo:@{ @"Path":recoveryPath, }];
            NSLog( @"%@",*error);
        }
        return nil;
    }
    
    rc = sqlite3_close(recoveryDB);
    if (rc != SQLITE_OK) {
        if (error) {
            *error = [NSError errorWithDomain:@"待备份数据库关闭失败" code:rc userInfo:@{ @"Path":recoveryPath, }];
            NSLog( @"%@",*error);
        }
        
    }
    
    // 修复完成，是否覆盖已损坏文件
    if (isOverwriteFile == NO) {
        return recoveryPath;
    }
    
    if (![fileManager fileExistsAtPath:corruptedDBPath]) {
        if (error) {
            *error = [NSError errorWithDomain:@"已损坏数据库文件不存在" code:0 userInfo:@{ @"Path":corruptedDBPath, }];
            NSLog( @"%@",*error);
        }
        return nil;
    }
    
    if (![fileManager removeItemAtPath:corruptedDBPath error:nil]) {
        if (error) {
            *error = [NSError errorWithDomain:@"删除已损坏数据库文件失败" code:0 userInfo:@{ @"Path":corruptedDBPath, }];
            NSLog( @"%@",*error);
        }
        return nil;
    }
    
    if (![fileManager copyItemAtPath:recoveryPath toPath:corruptedDBPath error:nil]) {
        if (error) {
            *error = [NSError errorWithDomain:@"删除已损坏数据库文件失败" code:0 userInfo:@{ @"Path":recoveryPath, }];
            NSLog( @"%@",*error);
        }
        return nil;
    }
    
    if (![fileManager removeItemAtPath:recoveryPath error:nil]) {
        if (error) {
            *error = [NSError errorWithDomain:@"删除冗余的修复数据库文件失败" code:0 userInfo:@{ @"Path":recoveryPath, }];
            NSLog( @"%@",*error);
        }
        return nil;
    }
    
    
    return corruptedDBPath;
}


- (BOOL)sqliteCheckIntegrityDB:(NSString *)dbPath isQuick:(BOOL)isQuick error:(NSError **)error{
    
    dbPath = [self fixPath:dbPath];
    
    // File not exists = okay
    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:dbPath] ) {
        if (error) {
            *error = [NSError errorWithDomain:@"数据库文件路径错误" code:0 userInfo:nil];
            NSLog( @"%@",*error);
        }
        
        return NO;
    }
    
    const char *filename = [dbPath fileSystemRepresentation];
    sqlite3 *database = NULL;
    
    int result = 0;
    
    result = sqlite3_open( filename, &database );
    if (result != SQLITE_OK ) {
        sqlite3_close( database );
        if (error) {
            *error = [NSError errorWithDomain:@"打开数据库失败" code:result userInfo:@{@"Path":dbPath,}];
            NSLog( @"%@",*error);
        }
        
        return NO;
    }
    
    BOOL integrityVerified = NO;
    sqlite3_stmt *integrity = NULL;
    NSString *columnResult = @"";
    
    sqlite3_prepare_v2( database, isQuick?"PRAGMA quick_check;":"PRAGMA integrity_check;", -1, &integrity, NULL );
    if (result  == SQLITE_OK ) {
        while ( sqlite3_step( integrity ) == SQLITE_ROW ) {
            const  unsigned  char * result = sqlite3_column_text( integrity, 0 );
            if ( result && strcmp( ( const char * )result, (const char *)"ok" ) == 0 ) {
                integrityVerified = YES;
                break;
            } else {
                if (result) {
                    columnResult = [NSString stringWithUTF8String:( const char * )result];
                }
            }
        }
        sqlite3_finalize( integrity );
    }
    
    sqlite3_close( database );
    
    if (integrityVerified == NO) {
        if (error) {
            *error = [NSError errorWithDomain:@"数据库校验失败" code:result userInfo:@{@"Path":dbPath,@"ColumnResult":columnResult?columnResult:@""}];
            NSLog( @"%@",*error);
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)repairKitCheckIntegrityDB:(NSString *)dbPath corruptedDBCipher:(NSString *)corruptedDBCipherStr error:(NSError **)error{
    
    dbPath = [self fixPath:dbPath];
    const char *correntDBPathCStr = dbPath.fileSystemRepresentation;
    
    const void *corruptedDBCipherBytes;
    unsigned int corruptedDBCipherLength;
    if (corruptedDBCipherStr == nil || [corruptedDBCipherStr isKindOfClass:[NSString class]] == NO) {
        corruptedDBCipherBytes = 0;
        corruptedDBCipherLength = 0;
    } else {
        NSData *corruptedDBCipher = [NSData dataWithBytes:[corruptedDBCipherStr UTF8String] length:(NSUInteger)strlen([corruptedDBCipherStr UTF8String])];
        corruptedDBCipherBytes = corruptedDBCipher.bytes;
        corruptedDBCipherLength = (unsigned int)corruptedDBCipher.length;
    }
    
    // 加密的Salt 这里默认数据库未加密 所以Salt填0
    unsigned char kdfSalt[16];
    memset(kdfSalt, 0, 16);
    
    sqliterk_cipher_conf conf;
    memset(&conf, 0, sizeof(sqliterk_cipher_conf));
    conf.key = corruptedDBCipherBytes;
    conf.key_len = corruptedDBCipherLength;
    conf.page_size = 4096;
    conf.kdf_salt = kdfSalt;
    conf.use_hmac = true;
    
    sqliterk *rk;
    int rc = sqliterk_open(correntDBPathCStr, corruptedDBCipherLength?&conf:NULL, &rk);
    if (rc != SQLITERK_OK) {
        if (error) {
            *error = [NSError errorWithDomain:@"读取数据库失败，已损坏" code:rc userInfo:@{ @"Path":dbPath, }];
            NSLog( @"%@",*error);
        }
        
        return NO;
    }
    
    unsigned int integrity = sqliterk_integrity(rk);
    if ((integrity & SQLITERK_INTEGRITY_HEADER) == 0) {
        
        if (error) {
            *error = [NSError errorWithDomain:@"检查数据库已损坏，完整性flag有误" code:rc userInfo:@{ @"Path":dbPath, @"integrity flag":[NSString stringWithFormat:@"%d",rc]}];
            NSLog( @"%@",*error);
        }
        return NO;
    }
    return YES;
}


- (BOOL)backupExistsAtDBPath:(NSString *)corruptedDBPath error:(NSError **)error{
    
    corruptedDBPath = [self fixPath:corruptedDBPath];
    
    if (corruptedDBPath == nil || [corruptedDBPath isKindOfClass:[NSString class]] == NO) {
        if (error) {
            *error = [NSError errorWithDomain:@"数据库文件路径错误" code:0 userInfo:nil];
            NSLog( @"%@",*error);
        }
        return NO;
    }
    
    NSString *backupPath = [corruptedDBPath stringByAppendingString:@"-backup"];
    NSString *oldBackupPath = [corruptedDBPath stringByAppendingString:@"-oldBackup"];
    
    NSFileManager* fileManager=[NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:backupPath]) {
        // 如果备份1不存在 则使用备份2 如果备份文件都不存在 则return
        if ([fileManager fileExistsAtPath:oldBackupPath]) {
            backupPath = oldBackupPath;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:@"备份文件不存在" code:0 userInfo:nil];
                NSLog( @"%@",*error);
            }
            return NO;
        }
    }
    return YES;
}
#pragma mark - fixPath
- (NSString *)fixPath:(NSString *)path  {
    
    if (path == nil || [path isKindOfClass:[NSString class]] == NO) {
        return @"";
    }
    
    if ([path hasPrefix:@"file://"]) {
        path = [path substringFromIndex:7];
    }
    return path;
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
