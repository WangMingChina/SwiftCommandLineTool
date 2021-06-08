
import Foundation
do{
    let ipaTool = try IpaTool(projectPath: "/Users/gree/gmall_ios",
                          configuration: .debug,
                          exportOptionsPlist: "/Users/gree/Desktop/greeMall_ipa/2021-06-03 09:48:40/ExportOptions.plist",
                          pgyerKey: "51895949ad44dcc3934f47c17aa0c0e5")
    
    /*
    var output = ipaTool.podInstall()
    print(output.readData)
    exit(-1)
    print(ipaTool)
    print("执行clean")
    */
    var output = ipaTool.clean()
    if output.readData.count > 0 {
        print("执行失败clean error = \(output.readData)")
        exit(-1)
    }
    print("执行archive")
    output = ipaTool.archive()
    if !FileManager.default.fileExists(atPath: ipaTool.xcarchive) {
        print("执行失败archive error = \(output.readData)")
        exit(-1)
    }
    print("执行exportArchive")
    output = ipaTool.exportArchive()
    
    if !FileManager.default.fileExists(atPath: ipaTool.exportIpaPath.appPath("\(ipaTool.scheme).ipa")) {
        print("执行失败exportArchive error =\(output.readData)")
        exit(-1)
    }
    print("导出ipa成功\(ipaTool.exportIpaPath)")
    print("开始上传蒲公英")
    ipaTool.update()
}catch{
    print(error)
}


