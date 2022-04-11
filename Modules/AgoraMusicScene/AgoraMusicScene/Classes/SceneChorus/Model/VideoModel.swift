//
//  ClientModel.swift
//  AgoraMusicScene
//
//  Created by CP on 2022/2/9.
//

import Foundation

struct VideoModel: Decodable {
    var hasBeenRendered: Bool = false
    var Name: String = ""
    var StreamID: String = ""
}
