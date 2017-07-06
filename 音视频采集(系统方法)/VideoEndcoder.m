//
//  VideoEndcoder.m
//  音视频采集(系统方法)
//
//  Created by 赵旭鹏 on 2017/6/29.
//  Copyright © 2017年 赵旭鹏. All rights reserved.
//

#import "VideoEndcoder.h"
#import <VideoToolbox/VideoToolbox.h>
@implementation VideoEndcoder
{
    int frameID;
    VTCompressionSessionRef EncodingSession;
    CMFormatDescriptionRef  format;
    NSFileHandle *fileHandle;
}


-(instancetype)initVideoEndcoder
{
    if (self == [super init]) {
        frameID = 0;
        int width = 480, height = 640;
        //设置编码结束数据回调
        VTCompressionOutputCallback cb = encodeOutputCallback;
        //编码器创建
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, cb, (__bridge void *)(self),  &EncodingSession);
        
        if (status == noErr) {
            // 设置参数
            // 设置实时编码输出，降低编码延迟
            status = VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
            // h264 profile, 直播一般使用baseline，可减少由于b帧带来的延时
            status = VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
            //设置码率，上限，单位是bps
            int bitRate = width * height * 3 * 4 * 8;
            CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
            VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
            //设置码率，均值，单位是byte
            int bitRateLimit = width * height * 3 * 4;
            CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
            VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
            // 设置关键帧（GOPsize)间隔
            int frameInterval = 10;
            CFNumberRef  frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
            VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRef);
            // 设置期望帧率
            int fps = 10;
            CFNumberRef  fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
            VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
            
            // 关闭重排Frame，因为有了B帧（双向预测帧，根据前后的图像计算出本帧）后，编码顺序可能跟显示顺序不同。此参数可以关闭B帧。
            VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
            
            //参数设置完毕，准备开始，至此初始化完成，随时来数据，随时编码
            status = VTCompressionSessionPrepareToEncodeFrames(EncodingSession);
            if (status != noErr) {
                NSLog(@"视频硬编码器初始化失败！");
            }
        }else{
             NSLog(@"视频硬编码器创建失败！");
        }
       
    }
    return self;
}

//进行逐帧编码
-(void)encodeFrame:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    // 帧时间，如果不设置会导致时间轴过长。
    CMTime presentationTimeStamp = CMTimeMake(frameID++, 1000);
    VTEncodeInfoFlags flags;
    OSStatus statusCode = VTCompressionSessionEncodeFrame(EncodingSession,
                                                          imageBuffer,
                                                          presentationTimeStamp,
                                                          kCMTimeInvalid,
                                                          NULL, NULL, &flags);
    if (statusCode != noErr) {
        NSLog(@"H264: 编码失败 %d", (int)statusCode);
        
        VTCompressionSessionInvalidate(EncodingSession);
        CFRelease(EncodingSession);
        EncodingSession = NULL;
        return;
    }
    NSLog(@"H264: 编码成功！");
}
//停止编码
- (void)stopEncodeSession
{
    VTCompressionSessionCompleteFrames(EncodingSession, kCMTimeInvalid);
    
    VTCompressionSessionInvalidate(EncodingSession);
    
    CFRelease(EncodingSession);
    EncodingSession = NULL;
}

// 编码回调，每当系统编码完一帧之后，会异步掉用该方法，此为c语言方法
void encodeOutputCallback(void *userData, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,CMSampleBufferRef sampleBuffer )
{
    NSLog(@"H264: 数据编码成功:%@",sampleBuffer);
    if (status != noErr) {
        NSLog(@"didCompressH264 error: with status %d, infoFlags %d", (int)status, (int)infoFlags);
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    ViewController* vc = (__bridge ViewController*)userData;
    
    // 判断当前帧是否为关键帧
    bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    // 获取sps & pps数据. sps pps只需获取一次，保存在h264文件开头即可
    if (keyframe && !vc->_spsppsFound)
    {
        size_t spsSize, spsCount;
        size_t ppsSize, ppsCount;
        
        const uint8_t *spsData, *ppsData;
        
        CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
        OSStatus err0 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 0, &spsData, &spsSize, &spsCount, 0 );
        OSStatus err1 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 1, &ppsData, &ppsSize, &ppsCount, 0 );
        
        if (err0==noErr && err1==noErr)
        {
            vc->_spsppsFound = 1;
            [vc writeH264Data:(void *)spsData length:spsSize addStartCode:YES];
            [vc writeH264Data:(void *)ppsData length:ppsSize addStartCode:YES];
            
            NSLog(@"got sps/pps data. Length: sps=%zu, pps=%zu", spsSize, ppsSize);
        }
    }
    
    size_t lengthAtOffset, totalLength;
    char *data;
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus error = CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &data);
    
    if (error == noErr) {
        size_t offset = 0;
        const int lengthInfoSize = 4; // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        
        // 循环获取nalu数据
        while (offset < totalLength - lengthInfoSize) {
            uint32_t naluLength = 0;
            memcpy(&naluLength, data + offset, lengthInfoSize); // 获取nalu的长度，
            
            // 大端模式转化为系统端模式
            naluLength = CFSwapInt32BigToHost(naluLength);
            NSLog(@"got nalu data, length=%d, totalLength=%zu", naluLength, totalLength);
            
            // 保存nalu数据到文件
            [vc writeH264Data:data+offset+lengthInfoSize length:naluLength addStartCode:YES];
            
            // 读取下一个nalu，一次回调可能包含多个nalu
            offset += lengthInfoSize + naluLength;
        }
    }
}

// 保存h264数据到文件
- (void) writeH264Data:(void*)data length:(size_t)length addStartCode:(BOOL)b
{
    // 添加4字节的 h264 协议 start code
    const Byte bytes[] = "\x00\x00\x00\x01";
    
    if (_h264File) {
        if(b)
            fwrite(bytes, 1, 4, _h264File);
        
        fwrite(data, 1, length, _h264File);
    } else {
        NSLog(@"_h264File null error, check if it open successed");
    }
}

@end
