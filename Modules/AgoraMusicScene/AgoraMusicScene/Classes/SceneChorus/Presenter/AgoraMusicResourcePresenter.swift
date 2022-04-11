//
//  AgoraMusicResourcePresenter.swift
//  AgoraMusicScene
//
//  Created by Jonathan on 2022/2/18.
//

import Foundation

public class AgoraMusicModel: Decodable, Equatable {
    let name: String
    let identifier: String
    let music: String
    let lyric: String
    var musicPath: String = ""
    var lrcPath: String = ""
    
    private enum CodingKeys: String, CodingKey {
        case name
        case identifier
        case music
        case lyric
    }
    
    public static func == (lhs: AgoraMusicModel, rhs: AgoraMusicModel) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

class AgoraMusicResourcePresenter {
    
    public var sounds = [AgoraMusicModel]()
    
    func fetchData() {
        guard let path = Bundle.agoraMusicScene().path(forResource: "musics", ofType: "json") else {
            return
        }
        let url = URL(fileURLWithPath: path)
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        guard let data = try? Data.init(contentsOf: url),
              let musicInfos = try? decoder.decode([AgoraMusicModel].self, from: data as Data)
        else {
            return
        }
        var temp = [AgoraMusicModel]()
        for info in musicInfos {
            if let musicPath = Bundle.agoraMusicScene().path(forResource: info.music, ofType: ""),
               let lrcPath = Bundle.agoraMusicScene().path(forResource: info.lyric, ofType: "") {
                info.musicPath = musicPath
                info.lrcPath = lrcPath
                temp.append(info)
            }
        }
        self.sounds = temp
    }
    
    func musicWithName(name: String) -> AgoraMusicModel? {
        return self.sounds.first(where: {$0.name == name})
    }
    
    func musicWithID(identifer: String) -> AgoraMusicModel? {
        return self.sounds.first(where: {$0.identifier == identifer})
    }
    
    func musicIndexWithID(identifer: String) -> Int {
        var index: Int = 0
        for model in sounds {
            if model.identifier == identifer {
                return index
            } else {
                index = index + 1
            }
        }
        return index
    }
    
}
