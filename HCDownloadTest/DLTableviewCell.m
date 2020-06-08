//
//  DLTableviewCell.m
//  HCDownloadTest
//
//  Created by linyoulu on 2020/5/29.
//  Copyright © 2020 linyoulu. All rights reserved.
//

#import "DLTableviewCell.h"
#import "SDAutoLayout.h"

@implementation DownloadModel

- (void)setInfoWithTask:(HCDownloadTask*)task
{
    self.strUrl = task.url;
    
    if (task.speed > 1000)
    {
        self.speed = [NSString stringWithFormat:@"%.2fMB",task.speed/1000];
    }
    else
    {
     
        self.speed = [NSString stringWithFormat:@"%.2fKB",task.speed];
    }
    
    self.progress = [NSString stringWithFormat:@"%.2f",task.progress*100];
    
    NSString *strState = @"未知";
    switch (task.state)
    {
        case HCDownloadStateWaiting:
            strState = @"等待";
            break;
            case HCDownloadStateWorking:
            strState = @"下载中";
            break;
            case HCDownloadStatePause:
            strState = @"暂停";
            break;
            case HCDownloadStateFinished:
            strState = @"完成";
            break;
            case HCDownloadStateFail:
            strState = @"失败";
            break;
            
        default:
            break;
    }
    
    self.state = strState;
}

@end

@interface DLTableviewCell ()

@property (nonatomic) UILabel *urlLabel;
@property (nonatomic) UILabel *progressLabel;
@property (nonatomic) UILabel *stateLabel;
@property (nonatomic) UILabel *speedLabel;

@end

@implementation DLTableviewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self createSubviews];
    }
    
    return self;
}

- (void)createSubviews
{
    _urlLabel = [UILabel new];
    _urlLabel.numberOfLines = 2;
    [self.contentView addSubview:_urlLabel];
    _urlLabel.sd_layout
    .topEqualToView(self.contentView)
    .leftSpaceToView(self.contentView, 10)
    .rightSpaceToView(self.contentView, 10)
    .heightIs(50);
    
    _stateLabel = [UILabel new];
    [self.contentView addSubview:_stateLabel];
    _stateLabel.sd_layout.bottomEqualToView(self.contentView)
    .rightSpaceToView(self.contentView, 10)
    .heightIs(30)
    .widthIs(80);
    
    _speedLabel = [UILabel new];
    [self.contentView addSubview:_speedLabel];
    _speedLabel.sd_layout.bottomEqualToView(_stateLabel)
    .rightSpaceToView(_stateLabel, 5)
    .heightIs(30)
    .widthIs(120);
    
    _progressLabel = [UILabel new];
    [self.contentView addSubview:_progressLabel];
    
    _progressLabel.sd_layout
    .leftSpaceToView(self.contentView, 10)
    .bottomEqualToView(_stateLabel)
    .heightIs(30)
    .widthIs(100);
}

- (void)setModel:(DownloadModel *)model
{
    if (model.strUrl.length > 0)
    {
        _urlLabel.text = model.strUrl;
    }
    if (model.state.length > 0)
    {
        _stateLabel.text = model.state;
    }
    if (model.speed.length > 0)
    {
        _speedLabel.text = [NSString stringWithFormat:@"速度:%@",model.speed];
    }
    if (model.progress.length > 0)
    {
        _progressLabel.text = [NSString stringWithFormat:@"进度:%@",model.progress];
    }
}

@end
