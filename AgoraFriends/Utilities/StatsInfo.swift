//
//  StatsInfo.swift
//  AgoraFriends
//
//  Created by Praveen Kumar on 14/04/2022.
//

import Foundation

enum StatsProp {
    case txBitRate, rxBitrate, lastMileDelayRate
}

class StatsInfo: NSObject {
    
    static var txList: Array = [Int]()
    static var rxList: Array = [Int]()
    static var lastMileDelayList: Array = [Int]()
    
    static var meanTx : Float = 0
    static var meanRx : Float = 0
    static var meanLastmile : Float = 0
       
    static func addnewValueToList(tx value1: Int,rx value2: Int, lastmile value3: Int  ) -> (Float, Float,Float) {
        
        if value1 >= 0 {
            if txList.count >= 10 {
                txList.remove(at: 0)
            }
            txList.append(value1)
        }
        
        if (value2 >= 0) {
            if rxList.count >= 10 {
            rxList.remove(at: 0)
            }
            rxList.append(value2)
        }
        
        if (value3 >= 0) {
            if lastMileDelayList.count >= 10 {
            lastMileDelayList.remove(at: 0)
            }
            lastMileDelayList.append(value3)
        }
        
        let sumTx = txList.reduce(0, +)
        let meanTX = Float(sumTx) / Float(txList.count)
        
        let sumRx = rxList.reduce(0, +)
        let meanRX = Float(sumRx) / Float(rxList.count)
        
        let sumMileDelay = lastMileDelayList.reduce(0, +)
        let meanMileDelay = Float(sumMileDelay) / Float(lastMileDelayList.count)
        
        return (meanTX, meanRX, meanMileDelay)
       
    }
    
   
}


