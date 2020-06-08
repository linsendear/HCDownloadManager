//
//  HCDownloadManager.m
//  wisdom
//
//  Created by linyoulu on 2018/1/24.
//  Copyright © 2018年 hc. All rights reserved.
//

#import "HCDownloadManager.h"
#import <CommonCrypto/CommonDigest.h>

#define HCDownloadPlistFile @"HCDownloadManagerId.plist"

//计算速度和进度的定时器
#define TimerInterval 1


@interface HCDownloadManager()<NSURLSessionDelegate, NSURLSessionDownloadDelegate>

//任务字典，包含所有任务,加快查找速度
@property (nonatomic) NSMutableDictionary *allTasksDic;
//任务的id数组，保留顺序
@property (nonatomic) NSMutableArray *identifierArray;
//下载中的任务数组
@property (nonatomic) NSMutableArray *downloadingIdentifierArray;
//存储任务id的plist文件
@property (nonatomic) NSString *identifierPlist;
//定时器，计算速度用
@property (nonatomic) NSTimer *timer;
//当前下载的字节数KB
@property (nonatomic) CGFloat currentSize;


@end

@implementation HCDownloadManager

+ (HCDownloadManager *)sharedManager
{
    static HCDownloadManager *sharedInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}



//初始化数据
- (instancetype)init
{
    if (self = [super init])
    {
        self.maxDownloadingTasks = 1;
        self.totalSpeed = 0;
        self.currentSize = 0;
        self.canCellularAccess = NO;
        self.canBackground = NO;
        self.downloadingIdentifierArray = [NSMutableArray new];
        self.allTasksDic = [NSMutableDictionary new];
        self.identifierArray = [NSMutableArray new];
        self.identifierPlist = [NSString stringWithFormat:@"%@%@",[HCDownloadManager managerPath], HCDownloadPlistFile];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:TimerInterval target:self selector:@selector(OnTimer) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
        [self loadIdentifierFromPlist];
    }
    
    return self;
}
//- (void)setCanCellularAccess:(BOOL)canCellularAccess{
//   [[NSUserDefaults standardUserDefaults] setBool:canCellularAccess forKey:@"HCDownloadManager_canCellularAccess"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}
//-(BOOL)canCellularAccess{
//    BOOL result = [[NSUserDefaults standardUserDefaults] boolForKey:@"HCDownloadManager_canCellularAccess"];
//
//    return result;
//}
//同时下载的数量
- (void)setMaxDownloadingTasks:(NSInteger)maxDownloadingTasks
{
    if (maxDownloadingTasks >= 5)
    {
        _maxDownloadingTasks = 5;
    }
    else if(maxDownloadingTasks <= 1)
    {
        _maxDownloadingTasks = 1;
    }
    else
    {
        _maxDownloadingTasks = maxDownloadingTasks;
    }
}

//获取指定的task
- (HCDownloadTask*)getTaskWithURL:(NSString*)url description:(NSString*)description
{
    HCDownloadTask *task = nil;
    if (url.length > 0)
    {
        NSString *identifier = [self taskIdentifierWith:url description:description];
        task = [self.allTasksDic objectForKey:identifier];
    }

    return task;
}
//获取指定状态的task
- (NSArray*)getTaskWithState:(HCDownloadState)state
{
    NSMutableArray *taskArray = [NSMutableArray new];
    for (NSString *identifier in self.identifierArray)
    {
        HCDownloadTask *task = [self.allTasksDic objectForKey:identifier];
        if (state == HCDownloadStateALL)
        {
            [taskArray addObject:task];
        }
        else
        {
            if (state == task.state)
            {
                [taskArray addObject:task];
            }
        }
    }
    
    return [taskArray copy];
}
//返回task
- (HCDownloadTask*)getTaskWithidentifier:(NSString*)identifier
{
    HCDownloadTask *task = nil;
    
    if (identifier.length > 0)
    {
        task = [self.allTasksDic objectForKey:identifier];
    }
    return task;
}

//新建下载任务，并未开启下载,任务存在时，返回NO
- (HCDownloadTask *)addTaskWith:(NSString*)url saveName:(NSString *)saveName description:(NSString*)description info:(NSString*)info
{
    HCDownloadTask *task = nil;
    
    NSString *identifier = [self taskIdentifierWith:url description:description];
    
    task = [self getTaskWithidentifier:identifier];
    
    if (task == nil)
    {
        task = [[HCDownloadTask alloc] init];
        if (info)
        {
            task.infoString = info;
        }
        task.url = url;
        task.desp = description;
        task.identifier = identifier;
        
        //暂时认为不会有重定向
//        task.fileName = [NSString stringWithFormat:@"%@/%@.%@",identifier,identifier, [url pathExtension]];
        
        if (saveName.length > 0)
        {
            task.fileName = [NSString stringWithFormat:@"%@/%@",identifier, saveName];
        }
        else
        {
            task.fileName = [NSString stringWithFormat:@"%@/%@.%@",identifier,identifier, [url pathExtension]];
        }

        
        
        if ([[[url pathExtension] lowercaseString] isEqualToString:@"m3u8"])
        {
            task.isM3U8 = YES;
            task.tsIndex = -1;
            task.tsCount = 0;
        }
        
        //设置状态
        [self taskStateChanged:task state:HCDownloadStatePause];
        //添加到队列
        [self.identifierArray addObject:identifier];
        //添加到任务字典
        [self.allTasksDic setObject:task forKey:task.identifier];
        //存储plist
        [self saveIdentifierToPlist];
    }
    
    return task;
}
//删除任务
- (void)deleteTaskWith:(NSString*)url description:(NSString*)description deleteFile:(BOOL)deleteFile;
{
    NSString *identifier = [self taskIdentifierWith:url description:description];
    
    HCDownloadTask *task = [self getTaskWithidentifier:identifier];
    
    //删除任务
    [self.downloadingIdentifierArray removeObject:task.identifier];
    [self.identifierArray removeObject:task.identifier];
    //删除任务
    [self.allTasksDic removeObjectForKey:identifier];
    
    //保存plist
    [self saveIdentifierToPlist];
    
    //取消下载
    [self cancelTask:task];
    
    //删除文件
    if (deleteFile)
    {
        NSString *path = [NSString stringWithFormat:@"%@%@", [HCDownloadManager managerPath], identifier];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

//释放NSURLSession NSURLSessionDownloadTask
- (void)cancelTask:(HCDownloadTask *)task
{
    if (task)
    {
        if (task.downloadTask)
        {
            [task.downloadTask cancel];
            task.downloadTask = nil;
        }
        
        if (task.session)
        {
            [task.session invalidateAndCancel];
            task.session = nil;
        }
    }
}
//开始/恢复下载
- (void)resumeTaskWith:(NSString*)url description:(NSString*)description
{
    NSString *identifier = [self taskIdentifierWith:url description:description];
    HCDownloadTask *task = [self getTaskWithidentifier:identifier];
    if (task)
    {
        if (task.state == HCDownloadStatePause || task.state == HCDownloadStateFail)
        {
            [self taskStateChanged:task state:HCDownloadStateWaiting];
            
            [self resumeNextTask];
        }
    }
}

//查看下载队列，少于max时，开始下载
- (void)resumeNextTask
{
    for (NSString *identifier in self.identifierArray)
    {
        if (self.downloadingIdentifierArray.count < self.maxDownloadingTasks)
        {
            HCDownloadTask *task = [self.allTasksDic objectForKey:identifier];
            if (task.state == HCDownloadStateWaiting)
            {
                //添加任务到下载中数组
                [self.downloadingIdentifierArray addObject:task.identifier];
                
                [self taskStateChanged:task state:HCDownloadStateWorking];
                
                
                //初始化session
                if (task.session == nil)
                {
                    NSURLSessionConfiguration *configure = nil;
                    
                    //后台下载
                    if (self.canBackground == YES)
                    {
                        configure = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[self backgroundSessionIdentifier:task.identifier]];
                    }
                    else
                    {
                        configure = [NSURLSessionConfiguration defaultSessionConfiguration];
                    }
                    
                    //允许蜂窝数据
                    if (self.canCellularAccess)
                    {
                        configure.allowsCellularAccess = YES;
                    }
                    else
                    {
                        configure.allowsCellularAccess = NO;
                    }
                    
                    task.session = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:[NSOperationQueue mainQueue]];

                }
                
                //m3u8文件，配置ts信息
                if (task.isM3U8 && task.tsCount == 0)
                {
                    [task configTSArray];
                }
                
                //初始化downloadtask
                
                NSString *dataFile = [NSString stringWithFormat:@"%@%@/hc.data",[HCDownloadManager managerPath], identifier];
                NSData *resumeData = [[NSData alloc] initWithContentsOfFile:dataFile];
                if (resumeData)
                {
                    //恢复后删除data文件
                    [[NSFileManager defaultManager] removeItemAtPath:dataFile error:nil];
                    
                    NSString *tmpFile = [NSString stringWithFormat:@"%@/%@",[HCDownloadManager tmpPath], task.tmpFile];
                    NSString *taskTmpFile = [NSString stringWithFormat:@"%@%@/hc.tmp",[HCDownloadManager managerPath], identifier];
                    
                    if (tmpFile.length > 0 && taskTmpFile.length > 0)
                    {
                        [[NSFileManager defaultManager] moveItemAtPath:taskTmpFile toPath:tmpFile error:nil];
                        
                        task.downloadTask = [task.session downloadTaskWithResumeData:resumeData];
                    }
                }
                
                
                //数据无法恢复task时
                if (task.downloadTask == nil)
                {
                    if (task.isM3U8)
                    {
                        if (task.tsIndex < 0 || task.tsCount == 0)
                        {
                            task.downloadTask = [task.session downloadTaskWithURL:[NSURL URLWithString:task.url]];
                        }
                        else
                        {
                            NSString *tsUrl = [task.tsUrlArray objectAtIndex:task.tsIndex];
                            task.downloadTask = [task.session downloadTaskWithURL:[NSURL URLWithString:tsUrl]];
                        }
                    }
                    else
                    {
                        task.downloadTask = [task.session downloadTaskWithURL:[NSURL URLWithString:task.url]];
                    }
                    
                }
                
                //生成task标识
                if (task.identifier.length == 0)
                {
                    task.identifier = [self taskIdentifierWith:task.url description:task.description];
                }
                
                //把标识赋值给downloadtask
                if (task.downloadTask.taskDescription.length == 0)
                {
                    task.downloadTask.taskDescription = task.identifier;
                }
                
                [task.downloadTask resume];
            }
        }
        else
        {
            break;
        }
    }
}
//暂停
- (void)suspendTaskWith:(NSString*)url description:(NSString*)description
{
    NSString *identifier = [self taskIdentifierWith:url description:description];
    HCDownloadTask *task = [self getTaskWithidentifier:identifier];
    if (task)
    {
        if (task.state == HCDownloadStateWorking )
        {
            //从下载中数组移除
            [self.downloadingIdentifierArray removeObject:task.identifier];
            
            [task.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {

            }];
        
            task.speed = 0;
            
            [self taskStateChanged:task state:HCDownloadStatePause];
            
            [self resumeNextTask];
        }
        else if(task.state == HCDownloadStateWaiting)
        {
            [self taskStateChanged:task state:HCDownloadStatePause];
            
            [self resumeNextTask];
        }
    }
}

//全部开始
- (void)resumeAllTasks
{
    for (NSString *identifier in self.identifierArray)
    {
        HCDownloadTask *task = [self.allTasksDic objectForKey:identifier];
        if (task.state == HCDownloadStatePause)
        {
            [self taskStateChanged:task state:HCDownloadStateWaiting];
        }
    }
    
    for (NSInteger i = self.downloadingIdentifierArray.count; i < self.maxDownloadingTasks; i++)
    {
        [self resumeNextTask];
    }
}
//全部暂停
- (void)suspendAllTasks
{
    //清理下载中的数组
    [self.downloadingIdentifierArray removeAllObjects];
    
    for (NSString *identifier in self.identifierArray)
    {
        HCDownloadTask *task = [self.allTasksDic objectForKey:identifier];
        if (task.state == HCDownloadStateWaiting)
        {
            [self taskStateChanged:task state:HCDownloadStatePause];
        }
        else if(task.state == HCDownloadStateWorking)
        {
            [task.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                
            }];
            
            [self taskStateChanged:task state:HCDownloadStatePause];
        }
    }
}

//设置状态，然后发送通知或调用代理
- (void)taskStateChanged:(HCDownloadTask*)task state:(HCDownloadState)state
{
    task.state = state;
    if (state != HCDownloadStateWorking)
    {
        task.speed = 0;
    }
        //归档至文件
    [HCDownloadTask archive:task];
    
    //通知
    [[NSNotificationCenter defaultCenter] postNotificationName:HCDownloadNotifationStateChanged object:task];
}


//加载任务列表(全部)
- (void)loadIdentifierFromPlist
{
    NSArray *identifierArray = [NSArray arrayWithContentsOfFile:self.identifierPlist];
    if (identifierArray.count > 0)
    {
        self.identifierArray = [identifierArray mutableCopy];
        for (NSString *identifier in identifierArray)
        {
            HCDownloadTask *task = [HCDownloadTask unarchive:identifier];
            if (task)
            {
                //异常退出时，状态重置
                if (task.state == HCDownloadStateWorking || task.state == HCDownloadStateWaiting)
                {
                    task.state = HCDownloadStatePause;
                }
                                
                [self.allTasksDic setObject:task forKey:identifier];
            }
        }
    }
}
//保存任务列表(全部)
- (void)saveIdentifierToPlist
{
    if (self.identifierArray.count > 0)
    {
        if (![[NSFileManager defaultManager] fileExistsAtPath:[HCDownloadManager managerPath]])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:[HCDownloadManager managerPath] withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        [self.identifierArray writeToFile:self.identifierPlist atomically:YES];
    }
    else
    {
        [[NSFileManager defaultManager] removeItemAtPath:self.identifierPlist error:nil];
    }
}


//MARK:NSURLSessionDelegate
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    if (self.completedHandler)
    {
        BOOL finishedAll = YES;
        for (NSString *identifier in self.identifierArray)
        {
            HCDownloadTask *task = [self.allTasksDic objectForKey:identifier];
            if (task.state == HCDownloadStateWaiting || task.state == HCDownloadStateWorking)
            {
                finishedAll = NO;
                break;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (finishedAll)
            {
                self.completedHandler();
            }
        });
        
    }
}
//MARK:NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    NSString *identifier = task.taskDescription;
    HCDownloadTask *hctask = [self.allTasksDic objectForKey:identifier];
    if (hctask == nil)
    {
        return;
    }
    
    if (error)
    {
        
        //暂停
        NSData *data = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        
        //有种情况，还没下载到数据，就被暂停了，这时应该是暂停，不能是下载失败
        if (data || (hctask.isM3U8 && hctask.tsDownloadSize == 0) || (!hctask.isM3U8 && hctask.downloadSize == 0))
        {
            //取消下载，保存已下载数据
            if (data)
            {
                NSData *resumeData = [self getCorrectResumeData:data];
                if (resumeData)
                {
                    //保存data文件
                    NSString *dataFile = [NSString stringWithFormat:@"%@%@/hc.data",[HCDownloadManager managerPath], identifier];
                    [resumeData writeToFile:dataFile atomically:YES];
                    
                    //保存临时文件路径
                    hctask.tmpFile = [self getTempFilePath:data];
                    
                    [HCDownloadTask archive:hctask];
                    //保存临时文件
                    
                    NSString *tmpFile = [NSString stringWithFormat:@"%@/%@",[HCDownloadManager tmpPath], hctask.tmpFile];
                    NSString *taskTmpFile = [NSString stringWithFormat:@"%@%@/hc.tmp",[HCDownloadManager managerPath], identifier];
                    
                    if (tmpFile.length > 0 && taskTmpFile.length > 0)
                    {
                        [[NSFileManager defaultManager] moveItemAtPath:tmpFile toPath:taskTmpFile error:nil];
                    }
                }
            }
            
            [self cancelTask:hctask];
            
            
            //切换网络时,正在下载中的任务要暂停
            if (hctask.state != HCDownloadStatePause)
            {
                [self.downloadingIdentifierArray removeObject:hctask.identifier];
                [self taskStateChanged:hctask state:HCDownloadStatePause];
            }
        }
        else
        {
            //真的失败了
            [self taskStateChanged:hctask state:HCDownloadStateFail];
            //释放
            [self cancelTask:hctask];
            //从下载中移除
            [self.downloadingIdentifierArray removeObject:hctask.identifier];
            //开始下一个
            [self resumeNextTask];
        }
    }
    else
    {
        //任务完成
        if (hctask.isM3U8)
        {
            if(hctask.tsCount > 0 && hctask.tsIndex == hctask.tsCount - 1)
            {
                //ts全部完成
                hctask.progress = 1.0f;
                hctask.speed = 0;
                hctask.currentSize = 0;
                //下载完成
                [self taskStateChanged:hctask state:HCDownloadStateFinished];
                //释放
                [self cancelTask:hctask];
                //从下载中移除
                [self.downloadingIdentifierArray removeObject:hctask.identifier];
                //开始下一个
                [self resumeNextTask];
            }
            else
            {
                hctask.tsIndex++;
                //记录index
                [HCDownloadTask archive:hctask];
                //下载下一个ts文件
                if([self downloadNextTS:hctask] == NO)
                {
                    [self taskStateChanged:hctask state:HCDownloadStateFail];
                    //释放
                    [self cancelTask:hctask];
                    //从下载中移除
                    [self.downloadingIdentifierArray removeObject:hctask.identifier];
                    //开始下一个
                    [self resumeNextTask];
                }
            }
        }
        else
        {
            hctask.progress = 1.0f;
            hctask.speed = 0;
            hctask.currentSize = 0;
            //下载完成
            [self taskStateChanged:hctask state:HCDownloadStateFinished];
            //释放
            [self cancelTask:hctask];
            //从下载中移除
            [self.downloadingIdentifierArray removeObject:hctask.identifier];
            //开始下一个
            [self resumeNextTask];
        }
    }
}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSString *identifier = downloadTask.taskDescription;
    HCDownloadTask *task = [self.allTasksDic objectForKey:identifier];
    if (task)
    {
        if (task.isM3U8)
        {
            if (task.tsIndex < 0)
            {
                //m3u8文件下载完成
                NSString *saveFile = [NSString stringWithFormat:@"%@/%@",[HCDownloadManager managerPath], task.fileName];
                NSURL *toUrl = [NSURL fileURLWithPath:saveFile];
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:toUrl error:nil];
                
            }
            else
            {
                //ts文件下载完成
                if(task.tsIndex < task.tsFileArray.count)
                {
                    NSString *tsLocal = [task.tsFileArray objectAtIndex:task.tsIndex];
                    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:tsLocal] error:nil];
                }
            }
        }
        else
        {
            NSString *saveFile = [NSString stringWithFormat:@"%@/%@",[HCDownloadManager managerPath], task.fileName];
            NSURL *toUrl = [NSURL fileURLWithPath:saveFile];
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:toUrl error:nil];
        }
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    //下载器速度
    self.currentSize =  self.currentSize + bytesWritten/1000.0;
    
    NSString *identifier = downloadTask.taskDescription;
    HCDownloadTask *task = [self.allTasksDic objectForKey:identifier];
    if (task)
    {
        
        
        task.currentSize = task.currentSize + bytesWritten/1000.0;
        
        if (task.isM3U8)
        {
            //m3u8按照文件数量计算进度
            NSInteger i = task.tsIndex + 1;
            task.progress = i*1.0/(task.tsCount + 1);
            
//            task.totalSize += totalBytesExpectedToWrite/1000.0;
            task.downloadSize += bytesWritten/1000.0;
            task.totalSize = task.downloadSize;
//            NSLog(@"downloading--- %f", task.downloadSize);
            task.tsDownloadSize = totalBytesWritten;
            
        }
        else
        {
            task.totalSize = totalBytesExpectedToWrite/1000.0;
            task.downloadSize = totalBytesWritten/1000.0;
            
            //按照实际下载字节计算速度
            task.progress = totalBytesWritten*1.0/totalBytesExpectedToWrite;
        }
    }
}

//MARK:OnTimer 计算速度,然后通知
- (void)OnTimer
{
    self.totalSpeed = self.currentSize*1.0/TimerInterval;
    self.currentSize = 0;
    
    for (NSString *identifier in self.downloadingIdentifierArray)
    {
        HCDownloadTask *task = [self.allTasksDic objectForKey:identifier];
        
        task.lastSpeed = task.speed;
        task.speed = task.currentSize*1.0/TimerInterval;
        task.currentSize = 0;
        
        if (task.lastSpeed != task.speed)
        {
            //更新进度
            [HCDownloadTask archive:task];
            [[NSNotificationCenter defaultCenter] postNotificationName:HCDownloadNotifationProgressChanged object:task];
        }
    }
}

//MARK:BackgroundSession

- (NSString *)backgroundSessionIdentifier:(NSString*)taskIdentifier
{
    NSString *sessionIdentifier = [NSString stringWithFormat:@"%@.%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"], taskIdentifier];
    return sessionIdentifier;
}

-(void)addCompletionHandler:(BackgroundDownloadCompletedHandler)handler identifier:(NSString *)identifier
{
    if ([identifier containsString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]])
    {
        self.completedHandler = handler;
    }
}

//MARK:TOOLS

- (NSString*)taskIdentifierWith:(NSString*)url description:(NSString*)description
{
    NSString *identifier = @"";
    if (url.length > 0)
    {
        NSString *desp = @"";
        if (description.length > 0)
        {
            desp = description;
        }
        
        identifier = [self md5With16:[NSString stringWithFormat:@"%@%@",url,desp]];
    }
    
    return identifier;
}

- (NSString *)md5With16:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}


+(NSString*)tmpPath
{
    return [NSHomeDirectory() stringByAppendingFormat:@"/tmp"];
}

+ (NSString*)managerPath
{
    static NSString *managerPath = @"";
    if (managerPath.length == 0)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        managerPath =  [[paths objectAtIndex:0] stringByAppendingFormat:@"/Caches/HCDownloadManager/"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:managerPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:managerPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }
    
    return managerPath;
}


//MARK:resumeData



- (NSData *)getCorrectResumeData:(NSData *)resumeData
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0)
    {
        return resumeData;
    }
    
    NSData *cleanedData = resumeData;
    if([[[UIDevice currentDevice] systemVersion] floatValue] >=11.0 && [[[UIDevice currentDevice] systemVersion] floatValue] < 11.2)
    {
        cleanedData = [self cleanResumeData:resumeData];
    }
    
    NSData *newData = nil;
    NSString *kResumeCurrentRequest = @"NSURLSessionResumeCurrentRequest";
    NSString *kResumeOriginalRequest = @"NSURLSessionResumeOriginalRequest";
    //获取继续数据的字典
    NSMutableDictionary* resumeDictionary = [NSPropertyListSerialization propertyListWithData:cleanedData options:NSPropertyListMutableContainers format:NULL error:nil];
    //重新编码原始请求和当前请求
    if (resumeDictionary[kResumeCurrentRequest] == nil
        ||resumeDictionary[kResumeOriginalRequest] == nil) {
        return newData;
    }
    resumeDictionary[kResumeCurrentRequest] = [self correctRequestData:resumeDictionary[kResumeCurrentRequest]];
    resumeDictionary[kResumeOriginalRequest] = [self correctRequestData:resumeDictionary[kResumeOriginalRequest]];
    newData = [NSPropertyListSerialization dataWithPropertyList:resumeDictionary format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListMutableContainers error:nil];
    
    return newData;
}

- (NSData *)correctRequestData:(NSData *)data {
    NSData *resultData = nil;
    NSData *arData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (arData != nil) {
        return data;
    }
    
    NSMutableDictionary *archiveDict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:nil error:nil];
    
    int k = 0;
    NSMutableDictionary *oneDict = [NSMutableDictionary dictionaryWithDictionary:archiveDict[@"$objects"][1]];
    while (oneDict[[NSString stringWithFormat:@"$%d", k]] != nil) {
        k += 1;
    }
    
    int i = 0;
    while (oneDict[[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]] != nil) {
        NSString *obj = oneDict[[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]];
        if (obj != nil) {
            [oneDict setObject:obj forKey:[NSString stringWithFormat:@"$%d", i + k]];
            [oneDict removeObjectForKey:obj];
            archiveDict[@"$objects"][1] = oneDict;
        }
        i += 1;
    }
    
    if (oneDict[@"__nsurlrequest_proto_props"] != nil) {
        NSString *obj = oneDict[@"__nsurlrequest_proto_props"];
        [oneDict setObject:obj forKey:[NSString stringWithFormat:@"$%d", i + k]];
        [oneDict removeObjectForKey:@"__nsurlrequest_proto_props"];
        archiveDict[@"$objects"][1] = oneDict;
    }
    
    NSMutableDictionary *twoDict = [NSMutableDictionary dictionaryWithDictionary:archiveDict[@"$top"]];
    if (twoDict[@"NSKeyedArchiveRootObjectKey"] != nil) {
        [twoDict setObject:twoDict[@"NSKeyedArchiveRootObjectKey"] forKey:[NSString stringWithFormat:@"%@", NSKeyedArchiveRootObjectKey]];
        [twoDict removeObjectForKey:@"NSKeyedArchiveRootObjectKey"];
        archiveDict[@"$top"] = twoDict;
    }
    
    resultData = [NSPropertyListSerialization dataWithPropertyList:archiveDict format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListMutableContainers error:nil];
    
    return resultData;
}

- (NSData *)cleanResumeData:(NSData *)resumeData
{
    NSString *dataString = [[NSString alloc] initWithData:resumeData encoding:NSUTF8StringEncoding];
    if ([dataString containsString:@"<key>NSURLSessionResumeByteRange</key>"])
    {
        NSRange rangeKey = [dataString rangeOfString:@"<key>NSURLSessionResumeByteRange</key>"];
        NSString *headStr = [dataString substringToIndex:rangeKey.location];
        NSString *backStr = [dataString substringFromIndex:rangeKey.location];
        
        NSRange rangeValue = [backStr rangeOfString:@"</string>\n\t"];
        NSString *tailStr = [backStr substringFromIndex:rangeValue.location + rangeValue.length];
        dataString = [headStr stringByAppendingString:tailStr];
    }
    return [dataString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)getTempFilePath:(NSData *)resumeData
{
    NSString *XMLStr = [[NSString alloc] initWithData:resumeData encoding:NSUTF8StringEncoding];
    NSString *tmpFilename = @"";
    //判断系统，iOS8以前和以后
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0)
    {
        //iOS8包含iOS8以前
        NSRange tmpRange = [XMLStr rangeOfString:@"NSURLSessionResumeInfoLocalPath"];
        NSString *tmpStr = [XMLStr substringFromIndex:tmpRange.location + tmpRange.length];
        NSRange oneStringRange = [tmpStr rangeOfString:@"CFNetworkDownload_"];
        NSRange twoStringRange = [tmpStr rangeOfString:@".tmp"];
        tmpFilename = [tmpStr substringWithRange:NSMakeRange(oneStringRange.location, twoStringRange.location + twoStringRange.length - oneStringRange.location)];
        
    }
    else
    {
        //iOS8以后
        NSRange tmpRange = [XMLStr rangeOfString:@"NSURLSessionResumeInfoTempFileName"];
        NSString *tmpStr = [XMLStr substringFromIndex:tmpRange.location + tmpRange.length];
        NSRange oneStringRange = [tmpStr rangeOfString:@"<string>"];
        NSRange twoStringRange = [tmpStr rangeOfString:@"</string>"];
        //记录tmp文件名
        tmpFilename = [tmpStr substringWithRange:NSMakeRange(oneStringRange.location + oneStringRange.length, twoStringRange.location - oneStringRange.location - oneStringRange.length)];
    }
    
    return tmpFilename;
    
}

//MARK:download ts

- (BOOL)downloadNextTS:(HCDownloadTask*)task
{
    if (task.tsCount == 0)
    {
        if([task configTSArray] == NO)
            return NO;
    }
    
    if (task.tsIndex < task.tsUrlArray.count)
    {
        NSString *tsUrl = [task.tsUrlArray objectAtIndex:task.tsIndex];
        task.downloadTask = [task.session downloadTaskWithURL:[NSURL URLWithString:tsUrl]];
        task.downloadTask.taskDescription = task.identifier;
        task.tsDownloadSize = 0;
        [task.downloadTask resume];
    }
    
    return YES;
}

@end
