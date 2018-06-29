//
//  AppDelegate.m
//  RepairKitDemo
//
//  Created by Limo on 2018/6/12.
//  Copyright © 2018年 Limo. All rights reserved.
//

#import "AppDelegate.h"
#import "WCRepairKitManage.h"
#import "LMCoreDataRepairManage.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSString *repairDBPath = [self copyFile2Documents:@"test-repair"];
    
    WCRepairKitManage *manage = [WCRepairKitManage shareManage];
    // 备份数据库
    [manage backupDBPath:repairDBPath];
    // 修复数据库
    [manage recoveryDBPath:repairDBPath DBPageSize:4096 corruptedDBCipher:nil backupCipher:nil isOverwriteFile:YES error:nil];
    
    return YES;
}

-(NSString*)copyFile2Documents:(NSString*)fileName {
    NSFileManager*fileManager =[NSFileManager defaultManager];
    NSError*error;
    NSArray*paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString*documentsDirectory =[paths objectAtIndex:0];
    
    NSString*destPath =[documentsDirectory stringByAppendingPathComponent:fileName];
    
    //  如果目标目录也就是(Documents)目录没有数据库文件的时候，才会复制一份，否则不复制
    if(![fileManager fileExistsAtPath:destPath]){
        NSString* sourcePath =[[NSBundle mainBundle] pathForResource:fileName ofType:nil];
        [fileManager copyItemAtPath:sourcePath toPath:destPath error:&error];
    }
    return destPath;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

@end
