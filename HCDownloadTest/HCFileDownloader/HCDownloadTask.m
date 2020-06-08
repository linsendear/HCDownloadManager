//
//  HCDownloadTask.m
//  wisdom
//
//  Created by linyoulu on 2018/1/24.
//  Copyright © 2018年 hc. All rights reserved.
//

#import "HCDownloadTask.h"
#import "HCDownloadManager.h"

@implementation HCDownloadTask


//归档task
+ (void)archive:(HCDownloadTask*)task
{
    NSString *filePath = [NSString stringWithFormat:@"%@%@/", [HCDownloadManager managerPath], task.identifier];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@%@.task", filePath, task.identifier];
    
    [NSKeyedArchiver archiveRootObject:task toFile:fileName];
}
//解档task
+ (HCDownloadTask*)unarchive:(NSString*)identifier
{
    NSString *fileName = [NSString stringWithFormat:@"%@%@/%@.task", [HCDownloadManager managerPath], identifier, identifier];
    
    HCDownloadTask* task = [NSKeyedUnarchiver unarchiveObjectWithFile:fileName];
    
    return task;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:_state forKey:@"state"];
    [aCoder encodeFloat:_progress forKey:@"progress"];
    
    [aCoder encodeObject:_url forKey:@"url"];
    [aCoder encodeObject:_desp forKey:@"desp"];
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_fileName forKey:@"fileName"];
    [aCoder encodeObject:_tmpFile forKey:@"tmpFile"];
    
    if (_infoString.length > 0)
    {
        [aCoder encodeObject:_infoString forKey:@"infoString"];
    }
    
    [aCoder encodeBool:_isM3U8 forKey:@"isM3U8"];
    
    if (_isM3U8)
    {
//        [aCoder encodeInteger:_tsCount forKey:@"tsCount"];
        [aCoder encodeInteger:_tsIndex forKey:@"tsIndex"];
        [aCoder encodeFloat:_downloadSize forKey:@"downloadSize"];
    }
    
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _state = [aDecoder decodeIntegerForKey:@"state"];
        _progress = [aDecoder decodeFloatForKey:@"progress"];
        
        _url = [aDecoder decodeObjectForKey:@"url"];
        _desp = [aDecoder decodeObjectForKey:@"desp"];
        _identifier = [aDecoder decodeObjectForKey:@"identifier"];
        _fileName = [aDecoder decodeObjectForKey:@"fileName"];
        _tmpFile = [aDecoder decodeObjectForKey:@"tmpFile"];
        
        _infoString = [aDecoder decodeObjectForKey:@"infoString"];
        
        _isM3U8 = [aDecoder decodeBoolForKey:@"isM3U8"];
        
        if(_isM3U8)
        {
//            _tsCount = [aDecoder decodeIntegerForKey:@"tsCount"];
            _tsIndex = [aDecoder decodeIntegerForKey:@"tsIndex"];
            _downloadSize = [aDecoder decodeFloatForKey:@"downloadSize"];
        }
    }
    
    return self;
}

- (BOOL)configTSArray
{
    self.tsUrlArray = [NSMutableArray new];
    self.tsFileArray = [NSMutableArray new];
    
    NSString *m3u8File = [NSString stringWithFormat:@"%@%@",[HCDownloadManager managerPath],self.fileName];
    NSString *content = [NSString stringWithContentsOfFile:m3u8File encoding:NSUTF8StringEncoding error:nil];
    
    if (content.length > 0)
    {
        NSString *strUrlPrfix = [self.url stringByDeletingLastPathComponent];
        NSString *strNo0d = [content stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        NSArray *tempArray = [strNo0d componentsSeparatedByString:@"#EXTINF:"];
        
        if (tempArray.count > 1)
        {
            
            for (int i = 1; i < tempArray.count; i ++)
            {
                NSString *strInfo = [tempArray objectAtIndex:i];
                
                if (strInfo.length > 0)
                {
                    NSArray *tempInfoArray = [strInfo componentsSeparatedByString:@"\n"];
                    if (tempInfoArray.count > 1)
                    {
                        NSString *tsFile = [tempInfoArray objectAtIndex:1];
                        NSString *strTSUrl = [NSString stringWithFormat:@"%@/%@", strUrlPrfix, tsFile];
                        
                        NSRange range = [tsFile rangeOfString:@"?"];
                        if (range.location != NSNotFound)
                        {
                            tsFile = [tsFile substringToIndex:range.location];
                        }
                        
                        NSString *strTSLocal = [NSString stringWithFormat:@"%@%@/%@", [HCDownloadManager managerPath], self.identifier, tsFile];
                        
                        [self.tsUrlArray addObject:strTSUrl];
                        [self.tsFileArray addObject:strTSLocal];
                    }
                }
            }
        }
        
        if (self.tsUrlArray.count > 0)
        {
            self.tsCount = self.tsUrlArray.count;
        }
    }

    
    return self.tsCount > 0;
    
}


@end
