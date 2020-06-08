//
//  HCDownloadTask.h
//  wisdom
//
//  Created by linyoulu on 2018/1/24.
//  Copyright © 2018年 hc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HCDownloadEnum.h"


@interface HCDownloadTask : NSObject
//业务用model
@property (nonatomic,copy) NSString * infoString;
//下载状态
@property (nonatomic, assign) HCDownloadState state;
//下载进度
@property (nonatomic, assign) CGFloat progress;
//已下载大小KB
@property (nonatomic, assign) CGFloat downloadSize;
//总大小KB
@property (nonatomic, assign) CGFloat totalSize;
//当前计算周期内下载的字节数
@property (nonatomic, assign) CGFloat currentSize;
//速度KB/s
@property (nonatomic, assign) CGFloat speed;
//上一周期速度，减少通知用
@property (nonatomic, assign) CGFloat lastSpeed;

//文件名，使用时需拼接路径[HCDownloadManager ]
@property (nonatomic) NSString *fileName;
//下载地址
@property (nonatomic) NSString *url;
//描述,可为空
@property (nonatomic) NSString *desp;
//urlsession
@property (strong,nonatomic) NSURLSession *session;
//下载任务
@property (strong,nonatomic) NSURLSessionDownloadTask *downloadTask;
//缓存数据
//@property (nonatomic) NSData *resumeData;
//标识，url与description做md5后的值
@property (nonatomic) NSString *identifier;
//缓存文件,移动文件用
@property (nonatomic) NSString *tmpFile;

//MARK:M3U8属性
//是否是m3u8
@property (nonatomic, assign) BOOL isM3U8;
//ts文件数组
@property (nonatomic) NSMutableArray *tsFileArray;
//ts对应url数组
@property (nonatomic) NSMutableArray *tsUrlArray;
//m3u8文件中的ts文件数量
@property (nonatomic, assign) NSInteger tsCount;
//当前已下载的ts文件索引,从0开始 -1标识当前下载的是m3u8文件
@property (nonatomic, assign) NSInteger tsIndex;
//当前ts文件的下载大小
@property (nonatomic, assign) NSInteger tsDownloadSize;

/**
 当前任务显示的cell 可以是空
 */
@property (nonatomic, weak ) UITableViewCell *tableViewCell;

//配置ts数据，包含ts的url数组，和ts本地存储位置
- (BOOL)configTSArray;
//归档task
+ (void)archive:(HCDownloadTask*)task;
//解档task
+ (HCDownloadTask*)unarchive:(NSString*)identifier;

@end
