import Foundation
struct Config: Codable {
    var current_environment: String
    var environments: [String: Environment]
    var default_files: [String]
    
    func getCurrentEnvironmentModel(fresh: Bool = false) -> Environment {
        var invalidated = false;

        struct Static {
            static var result: Environment?
            static var lastEnvironment: String?
        }
        
        if nil == Static.lastEnvironment {
            Static.lastEnvironment = self.current_environment
        }
        
        if self.current_environment != Static.lastEnvironment || fresh {
            Static.lastEnvironment = self.current_environment
            invalidated = true
        }

        if invalidated || Static.result == nil {
            Static.result = self.environments[self.current_environment]!
        }

        return Static.result!
    }
    
    func getFiles(fresh: Bool = false) -> [String] {
        var invalidated = false;
        
        struct Static {
            static var result: [String]?
            static var lastEnvironment: String?
        }
        
        if nil == Static.lastEnvironment {
            Static.lastEnvironment = self.current_environment
        }
        
        if self.current_environment != Static.lastEnvironment! || fresh {
            Static.lastEnvironment = self.current_environment
            invalidated = true
        }
        

        if invalidated || Static.result == nil {
            Static.result = Array(Set(self.environments[self.current_environment]!.files! + self.default_files))
        }

        return Static.result!
    }
    
    func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(self)
        
        let fileURL = URL(fileURLWithPath: ConfigService.configPath)
        try jsonData.write(to: fileURL, options: .atomic)
    }
}
