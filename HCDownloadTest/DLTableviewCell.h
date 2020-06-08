//
//  DLTableviewCell.h
//  HCDownloadTest
//
//  Created by linyoulu on 2020/5/29.
//  Copyright © 2020 linyoulu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCDownloadManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface DownloadModel : NSObject

@property (nonatomic) NSString *strUrl;
@property (nonatomic) NSString *progress;
@property (nonatomic) NSString *state;
@property (nonatomic) NSString *speed;

- (void)setInfoWithTask:(HCDownloadTask*)task;

@end




@interface DLTableviewCell : UITableViewCell

@property (nonatomic) DownloadModel *model;


@end

NS_ASSUME_NONNULL_END
