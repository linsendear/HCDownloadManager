//
//  ViewController.m
//  HCDownloadTest
//
//  Created by linyoulu on 2020/5/29.
//  Copyright © 2020 linyoulu. All rights reserved.
//

#import "ViewController.h"
#import "SDAutoLayout.h"

#import "HCDownloadManager.h"
#import "DLTableviewCell.h"
@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) HCDownloadManager *dlMgr;
@property (nonatomic) NSMutableArray *modelArray;
@property (nonatomic) UITableView *listTV;

@property (nonatomic) UITextField *urlTF;

@property (nonatomic) UILabel *mgrStateLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _modelArray = [NSMutableArray new];
    
    [self createSubviews];
    [self configDLManager];
//    [self testDownload];
    
}

- (void)createSubviews
{
    UIView *topView = [UIView new];
    topView.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:topView];
    topView.sd_layout.topEqualToView(self.view)
    .leftEqualToView(self.view)
    .rightEqualToView(self.view)
    .heightIs(150);
    
    
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [addBtn setTitle:@"添加" forState:UIControlStateNormal];
    [addBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(addBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:addBtn];
    addBtn.sd_layout
    .topSpaceToView(topView, 34)
    .rightSpaceToView(topView, 20)
    .widthIs(50)
    .heightIs(40);
    
    UITextField *tf = [UITextField new];
    tf.returnKeyType = UIReturnKeyDone;
    tf.clearButtonMode = UITextFieldViewModeAlways;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.text = @"";
//    [tf addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventValueChanged];
    _urlTF = tf;
    [topView addSubview:tf];
    tf.sd_layout
    .leftSpaceToView(topView, 20)
    .topEqualToView(addBtn)
    .heightIs(40)
    .rightSpaceToView(addBtn, 10);
    
    _mgrStateLabel = [UILabel new];
    _mgrStateLabel.textAlignment = NSTextAlignmentCenter;
    [topView addSubview:_mgrStateLabel];
    _mgrStateLabel.sd_layout
    .topSpaceToView(addBtn, 0)
    .leftEqualToView(topView)
    .rightEqualToView(topView)
    .heightIs(30);
    
    _mgrStateLabel.text = @"下载器速度";
    
    UIButton *pauseAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [pauseAllBtn setTitle:@"全部暂停" forState:UIControlStateNormal];
    [pauseAllBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [pauseAllBtn addTarget:self action:@selector(pauseAllClicked) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:pauseAllBtn];
    pauseAllBtn.sd_layout
    .topSpaceToView(_mgrStateLabel, 0)
    .rightSpaceToView(topView, 20)
    .heightIs(40)
    .widthIs(100);
    
    UIButton *startAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [startAllBtn setTitle:@"全部开始" forState:UIControlStateNormal];
    [startAllBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [startAllBtn addTarget:self action:@selector(startAllClicked) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:startAllBtn];
    startAllBtn.sd_layout
    .topSpaceToView(_mgrStateLabel, 0)
    .leftSpaceToView(topView, 20)
    .heightIs(40)
    .widthIs(100);
    
    UIButton *delAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [delAllBtn setTitle:@"全部删除" forState:UIControlStateNormal];
    [delAllBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [delAllBtn addTarget:self action:@selector(delAllClidked) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:delAllBtn];
    delAllBtn.sd_layout
    .topSpaceToView(_mgrStateLabel, 0)
    .leftSpaceToView(startAllBtn, 5)
    .heightIs(40)
    .rightSpaceToView(pauseAllBtn, 5);
    
    
    
    _listTV = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _listTV.delegate = self;
    _listTV.dataSource = self;
    _listTV.rowHeight = 80;
    [_listTV registerClass:[DLTableviewCell class] forCellReuseIdentifier:@"cell"];
    
    [self.view addSubview:_listTV];
    _listTV.sd_layout.topSpaceToView(topView, 0)
    .leftEqualToView(self.view)
    .rightEqualToView(self.view)
    .bottomEqualToView(self.view);
}

- (void)getDLManagerState
{
    CGFloat speed = [_dlMgr totalSpeed];
    
    if (speed > 1000)
    {
        speed = speed/1000.0;
        _mgrStateLabel.text = [NSString stringWithFormat:@"下载器速度 %.1fMB", speed];
    }
    else
    {
        _mgrStateLabel.text = [NSString stringWithFormat:@"下载器速度 %.1fKB", speed];
    }
    
}

- (void)pauseAllClicked
{
    [_dlMgr suspendAllTasks];
}

- (void)startAllClicked
{
    [_dlMgr resumeAllTasks];
}

-(void)delAllClidked
{
    NSArray *tempArray = [_dlMgr getTaskWithState:HCDownloadStateALL];
    for (HCDownloadTask *task in tempArray)
    {
        [_dlMgr deleteTaskWith:task.url description:nil deleteFile:YES];
    }
    
    [_modelArray removeAllObjects];
    [_listTV reloadData];
}

- (void)addBtnClick:(UIButton*)btn
{
    if (_urlTF.text.length > 0)
    {
        HCDownloadTask *task = [_dlMgr addTaskWith:_urlTF.text saveName:@"" description:@"" info:@""];
        if (task)
        {
            [_dlMgr resumeTaskWith:task.url description:@""];
            
            DownloadModel *model = [DownloadModel new];
            [model setInfoWithTask:task];
            [_modelArray addObject:model];
            [_listTV reloadData];
        }
        
    }
    else
    {
        NSArray *testArray = @[@"https://vd1.bdstatic.com/mda-hiqmm8s10vww26sx/mda-hiqmm8s10vww26sx.mp4?playlist=%5B%22hd%22%5D&auth_key=1506158514-0-0-6cde713ec6e6a15bd856fbb4f2564658&bcevod_channel=searchbox_feed",
                               @"https://vd1.bdstatic.com/mda-hez17qvhyauh9ybf/mda-hez17qvhyauh9ybf.mp4?auth_key=1506158741-0-0-d0a39ee4b472f0af492fed6d20396697&bcevod_channel=searchbox_feed",
                               @"https://vd1.bdstatic.com/mda-hiwgyhhpzdscwkyu/mda-hiwgyhhpzdscwkyu.mp4?playlist=%5B%22hd%22%5D&auth_key=1506159218-0-0-02860d7d3bad11758b123c96aa7271ec&bcevod_channel=searchbox_feed",
                               @"http://vd1.bdstatic.com/mda-hifgbu4tm1a1qzeu/mda-hifgbu4tm1a1qzeu.mp4?playlist=%5B%22hd%22%2C%22sc%22%5D&auth_key=1506244843-0-0-ecdd91d0d43be82b39bfb7ec3419e6b3&bcevod_channel=pae_search",
                               @"http://vd1.bdstatic.com/mda-hhmf74humzsjh5vu/mda-hhmf74humzsjh5vu.mp4?playlist=%5B%22hd%22%5D&auth_key=1506244931-0-0-e44269ae5ad22c5727c790735a4493dc&bcevod_channel=pae_search",
                               @"http://vd1.bdstatic.com/mda-hippg2tb6m76yzn5/mda-hippg2tb6m76yzn5.mp4?playlist=%5B%22hd%22%2C%22sc%22%5D&auth_key=1506245036-0-0-ad4426cc88fef724b489fd33f2346aef&bcevod_channel=pae_search",
                               @"http://vd1.bdstatic.com/mda-hhbh2uf27n6a060c/mda-hhbh2uf27n6a060c.mp4?playlist=%5B%22hd%22%5D&auth_key=1506245100-0-0-6c6524317d829e486630aa35da9df353&bcevod_channel=pae_search",
                               @"http://vd1.bdstatic.com/mda-hirsd45wk2zkeder/mda-hirsd45wk2zkeder.mp4?playlist=%5B%22hd%22%5D&auth_key=1506245547-0-0-3de0aa3b920536e751b8c2e21b8f449f&bcevod_channel=pae_search",
                               @"http://vd1.bdstatic.com/mda-hihm59tq2dpzsai2/mda-hihm59tq2dpzsai2.mp4?playlist=%5B%22hd%22%5D&auth_key=1506245685-0-0-66217496c6306e00677b6b7f511581de&bcevod_channel=pae_search",
                               @"http://vd1.bdstatic.com/mda-hd0tzu0gfwgcx5rr/mda-hd0tzu0gfwgcx5rr.mp4?playlist=%5B%22hd%22%2C%22sc%22%5D&auth_key=1506245859-0-0-29f6ba3f0df614f61fe6f63093378ac5&bcevod_channel=pae_search",
                               @"http://vd1.bdstatic.com/mda-hig01fitvbhmne29/mda-hig01fitvbhmne29.mp4?playlist=%5B%22hd%22%2C%22sc%22%5D&auth_key=1506245874-0-0-55657c86fa3761c70e20b387a9484086&bcevod_channel=pae_search",
                               @"http://vd1.bdstatic.com/mda-hiti1y2h7ujkruk7/mda-hiti1y2h7ujkruk7.mp4?playlist=%5B%22hd%22%5D&auth_key=1506245981-0-0-8df55a1752262f8ca985389c69687bc5&bcevod_channel=pae_search",
                               @"https://vd1.bdstatic.com/mda-hekxfmvyjyh6ju0m/mda-hekxfmvyjyh6ju0m.mp4?playlist=%5B%22hd%22%2C%22sc%22%5D&auth_key=1506158510-0-0-2843ff6bdc744d9f7f96ae0ca91bbee1&bcevod_channel=searchbox_feed",
                               @"http://vd1.bdstatic.com/mda-hhztvi8vq14feyvn/mda-hhztvi8vq14feyvn.mp4?playlist=%5B%22hd%22%5D&auth_key=1506246097-0-0-6505e29c0fe37fdebcf061e016d05020&bcevod_channel=pae_search",
                               @"http://vd1.bdstatic.com/mda-hc6mrcmk0s5ej4ed/mda-hc6mrcmk0s5ej4ed.mp4?playlist=%5B%22hd%22%2C%22sc%22%5D&auth_key=1506246036-0-0-2afa15ce89cfe65b0dcfe5cbcc91ab3f&bcevod_channel=pae_search"
        ];
        
        for (NSString *testUrl in testArray)
        {
            HCDownloadTask *task = [_dlMgr addTaskWith:testUrl saveName:@"" description:@"" info:@""];
            if (task)
            {
                [_dlMgr resumeTaskWith:task.url description:@""];
                
                DownloadModel *model = [DownloadModel new];
                [model setInfoWithTask:task];
                [_modelArray addObject:model];
                [_listTV reloadData];
            }
        }
    }
}

//-(void)textChanged:(UITextField*)tf
//{
//    _downloadUrl = tf.text;
//}

- (void)configDLManager
{
    _dlMgr = [HCDownloadManager sharedManager];
    _dlMgr.maxDownloadingTasks = 5;
    NSLog(@"download path:%@", [HCDownloadManager managerPath]);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DLProgressChanged:) name:HCDownloadNotifationProgressChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DLStateChanged:) name:HCDownloadNotifationStateChanged object:nil];
    
    
    NSArray *tempArray = [_dlMgr getTaskWithState:HCDownloadStateALL];
    
    for (HCDownloadTask *task in tempArray)
    {
        if (task.url.length > 0)
        {
            DownloadModel *model = [DownloadModel new];
            
            [model setInfoWithTask:task];
           
            [_modelArray addObject:model];
        }
    }
    
    [_listTV reloadData];
        
}

- (void)DLProgressChanged:(NSNotification*)notification
{
    HCDownloadTask *dlTask = notification.object;
    [self getDLManagerState];
    [self updateModelWithTask:dlTask];
    
}

- (void)DLStateChanged:(NSNotification*)notification
{
    HCDownloadTask *dlTask = notification.object;
    [self updateModelWithTask:dlTask];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _modelArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLTableviewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    DownloadModel *model = [_modelArray objectAtIndex:indexPath.row];
    
    cell.model = model;
    
    return cell;
}

- (void)updateModelWithTask:(HCDownloadTask*)task
{
    for (int i = 0; i < _modelArray.count; i ++)
    {
        DownloadModel *model = [_modelArray objectAtIndex:i];
        if (model.strUrl.length > 0 && [model.strUrl isEqualToString:task.url])
        {
            [model setInfoWithTask:task];
            [_listTV reloadData];
            
            break;
        }
    }
}


- (void)testDownload
{
    
}

@end
