//
//  File.swift
//  
//
//  Created by gree on 2021/6/7.
//

import Foundation
extension Process {
    
    /// 执行命令
    /// - Parameters:
    ///   - launchPath: 命令路径
    ///   - arguments: 命令参数
    ///   - currentDirectoryPath: 命令执行目录
    ///   - environment: 环境变量
    /// - Returns: 返回执行结果
    static func executable(launchPath:String,
                           arguments:[String],
                           currentDirectoryPath:String? = nil,
                           environment:[String:String]? = nil)->Pipe{
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments
        if let environment = environment {
            process.environment = environment
        }
        if let currentDirectoryPath = currentDirectoryPath {
            process.currentDirectoryPath = currentDirectoryPath
        }
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        return pipe
    }
}
