//
//  HCDownloadManager.h
//  wisdom
//
//  Created by linyoulu on 2018/1/24.
//  Copyright © 2018年 hc. All rights reserved.
//

//使用NSArray存储key值，保证有序 使用NSDictionary保存key与task，快速查找

#import <Foundation/Foundation.h>
#import "HCDownloadTask.h"

//状态变化通知
#define HCDownloadNotifationStateChanged @"HCDownloadNotifationStateChanged"
//进度，速度变化通知
#define HCDownloadNotifationProgressChanged @"HCDownloadNotifationProgressChanged"

//后台完成的回调
typedef void (^BackgroundDownloadCompletedHandler)(void);

@interface HCDownloadManager : NSObject
//同时下载的task最大值，默认1，最大5
@property (nonatomic, assign) NSInteger maxDownloadingTasks;
//下载器的总速度
@property (nonatomic, assign) CGFloat totalSpeed;
//是否使用蜂窝数据,默认为不使用
@property (nonatomic, assign) BOOL canCellularAccess;
//是否启用后台下载(后台模式只能处理当前正在下载的任务，无法开启新任务，即m3u8类型文件无法继续下载ts文件)
@property (nonatomic, assign) BOOL canBackground;

//单例
+ (HCDownloadManager *)sharedManager;
//下载器的路径，用来拼接，并获取文件位置
+ (NSString*)managerPath;


//获取指定的task
- (HCDownloadTask*)getTaskWithURL:(NSString*)url description:(NSString*)description;
//获取指定状态的task
- (NSArray*)getTaskWithState:(HCDownloadState)state;

//新建下载任务，并未开启下载,任务存在时，返回NO，info为业务用model，
- (HCDownloadTask *)addTaskWith:(NSString*)url saveName:(NSString *)saveName description:(NSString*)description info:(NSString*)info;
//删除任务，可选是否删除文件
- (void)deleteTaskWith:(NSString*)url description:(NSString*)description deleteFile:(BOOL)deleteFile;
//开始/恢复下载
- (void)resumeTaskWith:(NSString*)url description:(NSString*)description;
//暂停
- (void)suspendTaskWith:(NSString*)url description:(NSString*)description;
//全部开始
- (void)resumeAllTasks;
//全部暂停
- (void)suspendAllTasks;




//后台下载用
@property (nonatomic, copy) BackgroundDownloadCompletedHandler completedHandler;

-(void)addCompletionHandler:(BackgroundDownloadCompletedHandler)handler identifier:(NSString *)identifier;

@end
