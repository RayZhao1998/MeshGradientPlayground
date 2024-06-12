//
//  Item.swift
//  MeshGradientPlayground
//
//  Created by ZiyuanZhao on 2024/6/12.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
