//
//  VideoEndcoder.h
//  音视频采集(系统方法)
//
//  Created by 赵旭鹏 on 2017/6/29.
//  Copyright © 2017年 赵旭鹏. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface VideoEndcoder : NSObject
-(instancetype)initVideoEndcoder;
- (void) encodeFrame:(CMSampleBufferRef )sampleBuffer;
//停止编码
- (void) stopEncodeSession;
@end
