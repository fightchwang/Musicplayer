//
//  LyricView.swift
//  MusicPlayer
//
//  Created by 王春浩 on 15/8/9.
//  Copyright © 2015年 f1ve. All rights reserved.
//

import Foundation
import UIKit

///
/// 描述：显示歌词控件
///
/// 作者：huangyibiao
class LyricView:UIView {
    private var scorllView:UIScrollView!
    private var keyArray = NSMutableArray()
    private var titleArray = NSMutableArray()
    private var lineLabelArray = NSMutableArray()
    private var currentPlayingLineTime: float_t = 0.0
    private var lineLabelArrayColored = NSMutableArray()
    private var eachLineCost = NSMutableArray()
    internal var duration:Float = 0.0
    private var fulledKeyArray = NSMutableArray()
    
    ///
    /// 重写父类的方法
    ///
    override init(frame: CGRect){
        super.init(frame: frame)
        self.scorllView = UIScrollView(frame: CGRectMake(0 , 0, self.frame.width , self.frame.height))
        self.addSubview(self.scorllView)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///
    /// public 方法区
    ///
    
    ///
    /// 描述:解析歌词
    /// 参数:lrcPath LRC歌词的路径
    func parseSonge(lrcPath: String){
        self.keyArray.removeAllObjects()
        self.titleArray.removeAllObjects()
        
        let content = NSString(data: NSData(contentsOfFile: lrcPath)!, encoding: NSUTF8StringEncoding)
        let array = content?.componentsSeparatedByString("\n")
        guard let _ = array else {return}
        
        for line in array!{
            guard let lrcLine = line as? NSString else {continue}
            if lrcLine.length != 0 {
                self.parseLRCLine(lrcLine)
            }
        }
        self.bubbleSortLrcLines(self.keyArray)
        getEachLineCost()
        
        self.scorllView.contentOffset = CGPointZero
        self.scorllView.contentSize = CGSizeMake(self.scorllView.frame.width, CGFloat(self.keyArray.count * 25))
        self.configureLRCLineLabels()
    }
    
    ///
    /// 描述：移除显示歌词的标签
    ///
    func removeAllSubviewsInScrollView() {
        for subview in self.scorllView.subviews{
            subview.removeFromSuperview()
        }
        
        self.lineLabelArray.removeAllObjects()
    }
    
    ///
    /// 描述： 移除之前的歌词数据
    func clearLRCContents(){
        self.keyArray.removeAllObjects()
        self.titleArray.removeAllObjects()
    }
    
    ///
    /// 描述：指定歌词播放的时间，会根据时间滚动到对应的歌词行
    /// 
    /// 参数：time 歌词播放的时间
    func moveToLRCLine(time: NSString){
        if self.keyArray.count != 0 {
            let currentTimeValue = self.timeToFloat(time)
            
            var index = 0
            var hasFound = false
            var tmpTimeValue:Float = 0.0
            for index = 0; index < self.keyArray.count; index++ {
                guard let lrcTime = self.keyArray[index] as? NSString else {continue}
                tmpTimeValue = self.timeToFloat(lrcTime)
                if fabs(tmpTimeValue - currentTimeValue) <= fabs(0.000000001){
                    hasFound = true
                    currentPlayingLineTime = tmpTimeValue
                    break
                }
            }
            
            if hasFound || (!hasFound  && currentPlayingLineTime < currentTimeValue){
//                NSLog("time from outter \(currentTimeValue)")
//                NSLog("time from key \(tmpTimeValue)")
                if index < self.lineLabelArray.count{
                    guard let label = self.lineLabelArray[index] as? UILabel else {return}
                    updateCurrentTimeLRC(label)
                    self.scorllView.setContentOffset(CGPointMake(0.0, 25.0 * CGFloat(index)), animated: true)
                    
                }
            }
            
        }
    }
    ///
    ///描述：当歌词文本内容大于文本框的宽度时，动画滑动歌词并染色
    ///
    ///参数: label 该行歌词label
    func animationLRCLine(label:UILabel, coloredLabel:UILabel, timeCost:Float){
       
        let labelOriginPoint:CGPoint = label.frame.origin
        let labelSize:CGSize = label.frame.size
        let labelOriginFrame = label.frame
        let time = Double(timeCost)
        UILabel.animateWithDuration(time, delay: 0, options: .CurveLinear, animations: {
                NSLog("each line cost:\(time)")
                if label.frame.width <= self.scorllView.frame.width{
                    //只染色
                    coloredLabel.frame = CGRectMake(labelOriginPoint.x, labelOriginPoint.y, labelSize.width, labelSize.height)
                }else{
                    //染色并滑动歌词
                    coloredLabel.frame = CGRectMake(self.scorllView.frame.width - labelSize.width, labelOriginPoint.y, labelSize.width, labelSize.height)
                    label.frame = CGRectMake(self.scorllView.frame.width - labelSize.width, labelOriginPoint.y, labelSize.width, labelSize.height)
                }
                }, completion: {
                (finished:Bool) -> () in
                label.frame = labelOriginFrame
                coloredLabel.frame = labelOriginFrame
                coloredLabel.textColor = UIColor.lightGrayColor()
        })
        
    }
    
    /// private 方法区
    ///
    
    
    ///
    /// 描述：遍历fulledKeyArray获取每行歌词的展示时间
    ///
    /// 参数:
    private func getEachLineCost(){
        var costInSeconds:Float = 0.0
        for var i = 0 ; i < self.fulledKeyArray.count - 1 ; i++ {

            let firstTime = self.fulledKeyArray[i] as! NSString
            let seciondTime = self.fulledKeyArray[i+1] as! NSString
            let costInSecondsSec = Float(seciondTime.substringToIndex(2))! * 60.0 +
                                   Float(seciondTime.substringWithRange(NSMakeRange(3, 2)))! +
                                   Float(seciondTime.substringFromIndex(6))! / 100.0
            
            let costInSecondsFst =  Float(firstTime.substringToIndex(2))! * 60.0 +
                                    Float(firstTime.substringWithRange(NSMakeRange(3, 2)))! +
                                    Float(firstTime.substringFromIndex(6))! / 100.0
            NSLog("costInSecondsSec:\(costInSecondsSec), costInSecondsFst \(costInSecondsFst)")
            costInSeconds = costInSecondsSec - costInSecondsFst
            NSLog("costInSeconds \(costInSeconds)")
            self.eachLineCost.addObject(costInSeconds)
        }
        let lastTime = self.fulledKeyArray[self.fulledKeyArray.count - 1] as! NSString
        let costInSecondsLast = Float(lastTime.substringToIndex(2))! * 60.0 +
                                Float(lastTime.substringWithRange(NSMakeRange(3, 2)))! +
                                Float(lastTime.substringFromIndex(6))! / 100.0
        NSLog("costInSecondsLast:\(costInSecondsLast), lastTime \(lastTime)")
        NSLog("costInSeconds \(costInSeconds)")
        costInSeconds = self.duration - costInSecondsLast
        self.eachLineCost.addObject(costInSeconds)
    }
    
    
    
    
    
    
    
    ///
    /// 描述: 解析歌词行
    ///
    /// 参数: lrcLine 该行歌词
    
    private func parseLRCLine(lrcLine: NSString){
        var array = lrcLine.componentsSeparatedByString("\n")
        for var i = 0 ; i < array.count ; i++ {
            let tempString = array[i] as! NSString
            var lineArray = tempString.componentsSeparatedByString("]")
            
            for var j = 0; j < lineArray.count ; j++ {
                let line = lineArray[j] as! NSString
                
                if  line.length > 8 {
                    let str1 = line.substringWithRange(NSMakeRange(3, 1))
                    let str2 = line.substringWithRange(NSMakeRange(6, 1))
                    
                    if str1 == ":" && str2 == "." {
                        let lrc = lineArray.last as? NSString
                        let time = line.substringWithRange(NSMakeRange(1, 8)) as NSString
                        self.fulledKeyArray.addObject(time)
                        // 时间作为KEY
                        self.keyArray.addObject(time.substringToIndex(5))
                        // 歌词会为值
                        self.titleArray.addObject(lrc!)

                    }
                    
                }
            }
        }
        
    }
    
    ///
    /// 描述：对所有歌词行进行冒泡排序
    /// 
    /// 参数:array 要进行冒牌排序的数组
    
    private func bubbleSortLrcLines(array: NSMutableArray){
        for var i = 0 ; i  < array.count; i++ {
            
            for var j = 0 ; j < array.count - i - 1; j++ {
                let firstValue = self.timeToFloat(array[j] as! NSString)
                let secondValue = self.timeToFloat(array[j+1] as! NSString)
                
                if firstValue > secondValue {
                    array.exchangeObjectAtIndex(j, withObjectAtIndex: j+1)
                    self.titleArray.exchangeObjectAtIndex(j, withObjectAtIndex: j+1)
                }
            }
            
        }
    }
    
    ///
    /// 描述：把时间字符串转换成浮点值
    ///
    /// 参数: time 时间字符串，格式为:"05:11"
    
    private func timeToFloat(time: NSString) -> float_t{
        var array = time.componentsSeparatedByString(":")
        
        var result:NSString = "\(array[0])"
        if array.count >= 2 {
            result = "\(array[0]).\(array[1])"
        }
        return result.floatValue
    }
    
    ///
    /// 描述:创建显示歌词的标签
    ///
    private func configureLRCLineLabels(){
        self.removeAllSubviewsInScrollView()
        
        for var i = 0; i < self.titleArray.count ; i++ {
            let title = titleArray[i] as! String
            let olderWidth = (title as NSString).sizeWithAttributes([NSFontAttributeName:UIFont.systemFontOfSize(14.0)])
            //居中
            let xCordinate = olderWidth.width > self.frame.width ? 0.0 : (self.frame.width - olderWidth.width) / 2.0
            let label = UILabel(frame: CGRectMake(xCordinate , 25.0 * CGFloat(i) + self.scorllView.frame.height / 2.0 , olderWidth.width, 25.0))
            let labelWithColor = UILabel(frame: CGRectMake(xCordinate, 25.0 * CGFloat(i) + self.scorllView.frame.height / 2.0 , 0.0, 25.0))
            label.text = title
            label.textColor = UIColor.lightGrayColor()
            label.font = UIFont.systemFontOfSize(14.0)
            label.lineBreakMode = NSLineBreakMode.ByClipping
            
            labelWithColor.text = title
            labelWithColor.textColor = UIColor(red: 192.0 / 255.0, green: 37.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0)
            labelWithColor.font = UIFont.systemFontOfSize(14.0)
            labelWithColor.lineBreakMode = NSLineBreakMode.ByClipping
            
            self.scorllView.addSubview(label)
            self.scorllView.addSubview(labelWithColor)
            self.lineLabelArray.addObject(label)
            self.lineLabelArrayColored.addObject(labelWithColor)
        }
    }
    
    ///
    /// 描述：更新当前显示的歌词 
    ///
    private func updateCurrentTimeLRC(currentLabel: UILabel){
        for label in self.lineLabelArray{
            if let item = label as? UILabel {
                if item == currentLabel {
                    let index = self.lineLabelArray.indexOfObject(currentLabel)
                    let coloredLabel = self.lineLabelArrayColored[index] as! UILabel
                    /// 将导航颜色的下列定义放在全局区
                    ///let kNavColor = UIColor(red: 192.0 / 255.0, green: 37.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0)
//                    item.textColor = UIColor(red: 192.0 / 255.0, green: 37.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0)
//                    item.font = UIFont.boldSystemFontOfSize(14.0)
                    animationLRCLine(item, coloredLabel: coloredLabel, timeCost:self.eachLineCost[index] as! Float)
                }
            }
        }
    }
    
}
