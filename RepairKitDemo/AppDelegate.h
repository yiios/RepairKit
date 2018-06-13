//
//  AppDelegate.h
//  RepairKitDemo
//
//  Created by Limo on 2018/6/12.
//  Copyright © 2018年 Limo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

