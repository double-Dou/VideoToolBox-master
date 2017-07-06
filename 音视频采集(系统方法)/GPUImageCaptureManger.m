//
//  GPUImageCaptureManger.m
//  音视频采集(系统方法)
//
//  Created by 赵旭鹏 on 2017/6/28.
//  Copyright © 2017年 赵旭鹏. All rights reserved.
//

#import "GPUImageCaptureManger.h"

@interface GPUImageCaptureManger()<GPUImageVideoCameraDelegate>
//磨皮美颜
@property (nonatomic, strong) GPUImageBilateralFilter *bilateralFilter;
//亮白美颜
@property (nonatomic, strong) GPUImageBrightnessFilter *brightnessFilter;

@end

@implementation GPUImageCaptureManger

//懒加载
-(UIView *)backView
{
    if (!_backView) {
        _backView = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _backView;
}

//初始化方法
-(instancetype)initGPUImageCaptureManagerWithViewController:(UIViewController*)viewController
{
    if (self == [super init]) {
        // 创建视频源
        // SessionPreset:屏幕分辨率，AVCaptureSessionPresetHigh会自适应高分辨率
        // cameraPosition:摄像头方向
        // 最好使用AVCaptureSessionPresetHigh，会自动识别，如果用太高分辨率，当前设备不支持会直接报错
        self.videoCamera = [[GPUImageVideoCamera alloc]initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
        //输出方向
        self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        //添加音频
        [self.videoCamera addAudioInputsAndOutputs];
        self.videoCamera.delegate = self;
        
        //创建滤镜组合
        GPUImageFilterGroup * filterGroup = [[GPUImageFilterGroup alloc]init];
        //创建磨皮滤镜
        self.bilateralFilter = [[GPUImageBilateralFilter alloc]init];
        //创建美白滤镜
        self.brightnessFilter = [[GPUImageBrightnessFilter alloc]init];
        //将滤镜加入滤镜组合
        [filterGroup addTarget:self.bilateralFilter];
        [filterGroup addTarget:self.brightnessFilter];
        //设置滤镜组链
        [self.bilateralFilter addTarget:self.brightnessFilter];
        [filterGroup setInitialFilters:@[self.bilateralFilter]];
        filterGroup.terminalFilter = self.brightnessFilter;
        
        //创建预览视图
        GPUImageView * previewView = [[GPUImageView alloc]initWithFrame:viewController.view.frame];
        [self.backView addSubview:previewView];
        [viewController.view insertSubview:self.backView atIndex:0];
        
        // 设置GPUImage处理链，从数据源 => 滤镜 => 最终界面效果
        [self.videoCamera addTarget:filterGroup];
        [filterGroup addTarget:previewView];
        
        // 必须调用startCameraCapture，底层才会把采集到的视频源，渲染到GPUImageView中，就能显示了。
        // 开始采集视频
        [self.videoCamera startCameraCapture];
    }
    return self;
}

//切换摄像头
-(void)changeCamera
{
    [self.videoCamera rotateCamera];
}

//采集到数据的代理回调
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    NSLog(@"采集到数据:%@,",sampleBuffer);
}

@end
