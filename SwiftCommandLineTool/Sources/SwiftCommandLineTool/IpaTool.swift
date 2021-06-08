//
//  File.swift
//  
//
//  Created by gree on 2021/6/7.
//

import Foundation
import Alamofire
extension String{
    func appPath(_ value:String) -> String {
        if self.hasSuffix("/") {
            return self + value
        }
        return self + "/" + value
    }
}
struct IpaTool {
    
    struct Output {
        var pipe:Pipe
        var readData:String
        init(pipe:Pipe) {
            self.pipe = pipe
            self.readData = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? ""
        }
    }
    enum Configuration:String {
        case debug = "Debug"
        case release = "Release"
    }
    
    var workspace:String{
        projectPath.appPath("\(projectName).xcworkspace")
    }
    ///scheme
    var scheme:String
    ///Debug|Release
    var configuration:Configuration
    ///编译产物路径
    var xcarchive:String{
        exportIpaPath.appPath("\(projectName).xcarchive")
    }
    ///配置文件路径
    var exportOptionsPlist:String
    ///导出ipa包的路径
    var exportIpaPath:String
    ///项目路径
    let projectPath:String
    ///项目名称
    let projectName:String
    ///存放打包目录
    let packageDirectory:String
    ///蒲公英_api_key
    let pgyerKey:String
    
    ///
    /// - Parameters:
    ///   - projectPath: 项目路径
    ///   - configuration: Debug|Release
    ///   - exportOptionsPlist: 配置文件Plist的路径
    ///   - pgyerKey: 上传蒲公英的key
    /// - Throws: 抛出错误
    init(projectPath:String,
         configuration:Configuration,
         exportOptionsPlist:String,
         pgyerKey:String) throws {
        self.projectPath = projectPath
        self.configuration = configuration
        self.exportOptionsPlist = exportOptionsPlist
        self.pgyerKey = pgyerKey
        let manager = FileManager.default
        var allFiles = try manager.contentsOfDirectory(atPath: projectPath)
        projectName = allFiles.first(where: { $0.hasSuffix(".xcodeproj")  })?.components(separatedBy: ".").first ?? ""
        packageDirectory = NSHomeDirectory()
            .appPath("Desktop/\(projectName)_ipa")
        
        allFiles = try manager.contentsOfDirectory(atPath: projectPath.appPath("\(projectName).xcodeproj/xcshareddata/xcschemes")
        )
        scheme = allFiles[0].components(separatedBy: ".").first ?? ""
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        exportIpaPath = packageDirectory.appPath(formatter.string(from: Date()))
    }
}
extension IpaTool{
    /// 执行 xcodebuild clean
    func clean()->Output{
        let arguments = ["clean",
                         "-workspace",
                         workspace,
                         "-scheme",
                         scheme,
                         "-configuration",
                         configuration.rawValue,
                         "-quiet",
                        ]
        return Output(pipe: Process.executable(launchPath: "/usr/bin/xcodebuild", arguments: arguments))
    }
    /// 执行 xcodebuild archive
    func archive()->Output{
        let arguments = ["archive",
                         "-workspace",
                         workspace,
                         "-scheme",
                         scheme,
                         "-configuration",
                         configuration.rawValue,
                         "-archivePath",
                         xcarchive,
                         "-quiet",
                        ]
        return Output(pipe: Process.executable(launchPath: "/usr/bin/xcodebuild", arguments: arguments))
    }
    /// 执行 xcodebuild exportArchive
    func exportArchive()->Output{
        let arguments = ["-exportArchive",
                         "-archivePath",
                         xcarchive,
                         "-configuration",
                         configuration.rawValue,
                         "-exportPath",
                         exportIpaPath,
                         "-exportOptionsPlist",
                         exportOptionsPlist,
                         "-quiet",
                        ]
        return Output(pipe: Process.executable(launchPath: "/usr/bin/xcodebuild", arguments: arguments))
    }
    //上传蒲公英
    func update(){
        
        let ipaPath = exportIpaPath.appPath("\(scheme).ipa")
        
        let upload = AF.upload(multipartFormData: { formdata in
            formdata.append(pgyerKey.data(using: .utf8)!, withName: "_api_key")
            formdata.append(URL(fileURLWithPath: ipaPath), withName: "file")
        }, to: URL(string: "https://www.pgyer.com/apiv2/app/upload")!)
        
        var isExit = true
        let queue = DispatchQueue(label: "queue")
        upload.uploadProgress(queue: queue) { progress in
            let p = Int((Double(progress.completedUnitCount) / Double(progress.totalUnitCount)) * 100)
            print("上传进度:\(p)%")
        }
        upload.responseData(queue:queue) { dataResponse in
            switch dataResponse.result {
            case .success(let data):
                let result = String(data: data, encoding: .utf8) ?? ""
                print("上传成功:\(result)")
            case .failure(let error):
                print("上传失败: \(error)")
            }
            isExit = false
        }
        //使用循环换保证命令行程序,不会死掉
        while isExit {
            Thread.sleep(forTimeInterval: 1)
        }
    }
    // pod install
    func podInstall()->Output{
        var environment = [String:String]()
        /*
         添加环境变量LANG = en_US.UTF-8
         否则这个错误
         [33mWARNING: CocoaPods requires your terminal to be using UTF-8 encoding.
         Consider adding the following to ~/.profile:
         export LANG=en_US.UTF-8
         */
        environment["LANG"] = "en_US.UTF-8"
        /*
         添加环境变量PATH = /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/Users/gree/.rvm/bin
         终端运行 echo $PATH 获取
         否则这个错误
         [1mTraceback[m (most recent call last):
         9: from /usr/local/bin/pod:23:in `<main>'
         8: from /usr/local/bin/pod:23:in `load'
         7: from /Library/Ruby/Gems/2.6.0/gems/cocoapods-1.10.1/bin/pod:55:in `<top (required)>'
         6: from /Library/Ruby/Gems/2.6.0/gems/cocoapods-1.10.1/lib/cocoapods/command.rb:49:in `run'
         5: from /Library/Ruby/Gems/2.6.0/gems/cocoapods-1.10.1/lib/cocoapods/command.rb:140:in `verify_minimum_git_version!'
         4: from /Library/Ruby/Gems/2.6.0/gems/cocoapods-1.10.1/lib/cocoapods/command.rb:126:in `git_version'
         3: from /Library/Ruby/Gems/2.6.0/gems/cocoapods-1.10.1/lib/cocoapods/executable.rb:143:in `capture_command'
         2: from /Library/Ruby/Gems/2.6.0/gems/cocoapods-1.10.1/lib/cocoapods/executable.rb:117:in `which!'
         1: from /Library/Ruby/Gems/2.6.0/gems/cocoapods-1.10.1/lib/cocoapods/executable.rb:117:in `tap'
     /Library/Ruby/Gems/2.6.0/gems/cocoapods-1.10.1/lib/cocoapods/executable.rb:118:in `block in which!': [1m[31m[!] Unable to locate the executable `git`[0m ([1;4mPod::Informative[m[1m)[m
         */
        environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/Users/gree/.rvm/bin"
        /*
         添加环境变量CP_HOME_DIR = NSHomeDirectory().appending("/.cocoapods")
         我的cocoapods安装在home目录所以使用这个,
         你们可以在访达->前往文件夹...-> ~/.cocoapods,来获取路径
         否则这个错误
         Analyzing dependencies
         Cloning spec repo `cocoapods` from `https://github.com/CocoaPods/Specs.git`
         [!] Unable to add a source with url `https://github.com/CocoaPods/Specs.git` named `cocoapods`.
         You can try adding it manually in `/var/root/.cocoapods/repos` or via `pod repo add`.
         */
        environment["CP_HOME_DIR"] = NSHomeDirectory().appending("/.cocoapods")
        let pipe = Process.executable(launchPath: "/usr/local/bin/pod",
                                    arguments: ["install"],
                                    currentDirectoryPath: projectPath,
                                    environment: environment)
        return Output(pipe: pipe)
    }
}
