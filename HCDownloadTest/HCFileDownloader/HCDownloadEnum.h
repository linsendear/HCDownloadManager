//
//  HCDownloadEnum.h
//  wisdom
//
//  Created by linyoulu on 2018/1/24.
//  Copyright © 2018年 hc. All rights reserved.
//

#ifndef HCDownloadEnum_h
#define HCDownloadEnum_h

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, HCDownloadState)
{
    HCDownloadStateALL,
    //新建后就是等待状态，可切换至下载状态，暂停状态
    HCDownloadStateWaiting,
    //下载状态，可切换至完成，失败，暂停状态
    HCDownloadStateWorking,
    //暂停状态，可切换至等待状态
    HCDownloadStatePause,
    //完成，最终状态
    HCDownloadStateFinished,
    //失败，最终状态
    HCDownloadStateFail,
    
};

#endif /* HCDownloadEnum_h */
