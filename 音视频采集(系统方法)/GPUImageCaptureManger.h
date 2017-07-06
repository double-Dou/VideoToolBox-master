//
//  GPUImageCaptureManger.h
//  音视频采集(系统方法)
//
//  Created by 赵旭鹏 on 2017/6/28.
//  Copyright © 2017年 赵旭鹏. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GPUImage/GPUImage.h>
@interface GPUImageCaptureManger : NSObject
@property (nonatomic, strong)UIView *backView;
//摄像头
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
//对音视频采集管理类进行初始化
-(instancetype)initGPUImageCaptureManagerWithViewController:(UIViewController *)viewController;
//切换摄像头
-(void)changeCamera;
@end
