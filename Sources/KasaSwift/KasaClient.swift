//
//  KasaClient.swift
//  KasaSwift
//
//  A native Swift client for TP-Link Kasa Cloud API interactions.
//  Created for the open-source community by ShortBridge (https://shortbridge.app).
//

import Foundation

/// Standalone, asynchronous client for TP-Link Kasa Cloud API interactions.
public struct KasaClient: Sendable {
    
    public let session: URLSession
    public let baseURL: String
    
    public init(session: URLSession? = nil, baseURL: String = "https://wap.tplinkcloud.com") {
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10.0
            config.timeoutIntervalForResource = 10.0
            self.session = URLSession(configuration: config)
        }
        self.baseURL = baseURL
    }
    
    // MARK: - Errors
    
    public enum KasaError: LocalizedError, Sendable {
        case invalidURL(String)
        case httpError(statusCode: Int, responseBody: String)
        case apiError(code: Int, message: String)
        case missingToken
        case decodingFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case .invalidURL(let url):
                return "Invalid URL: \(url)"
            case .httpError(let code, let body):
                return "HTTP \(code) error from TP-Link cloud: \(body)"
            case .apiError(let code, let msg):
                return "TP-Link API error (\(code)): \(msg)"
            case .missingToken:
                return "No authentication token found in response."
            case .decodingFailed(let reason):
                return "Failed to decode response: \(reason)"
            }
        }
    }
    
    // MARK: - Models
    
    public struct LoginRequest: Codable, Sendable {
        public let method: String
        public let params: LoginParams
        
        public init(method: String = "login", params: LoginParams) {
            self.method = method
            self.params = params
        }
    }
    
    public struct LoginParams: Codable, Sendable {
        public let appType: String
        public let cloudUserName: String
        public let cloudPassword: String
        public let terminalUUID: String
        
        public init(appType: String = "Kasa_Android", cloudUserName: String, cloudPassword: String, terminalUUID: String = UUID().uuidString) {
            self.appType = appType
            self.cloudUserName = cloudUserName
            self.cloudPassword = cloudPassword
            self.terminalUUID = terminalUUID
        }
    }
    
    public struct LoginResponse: Codable, Sendable {
        public let errorCode: Int
        public let msg: String?
        public let result: LoginResult?
        
        enum CodingKeys: String, CodingKey {
            case errorCode = "error_code"
            case msg, result
        }
    }
    
    public struct LoginResult: Codable, Sendable {
        public let accountId: String?
        public let regTime: String?
        public let token: String?
        public let email: String?
    }
    
    public struct DeviceListRequest: Codable, Sendable {
        public let method: String
        
        public init(method: String = "getDeviceList") {
            self.method = method
        }
    }
    
    public struct DeviceListResponse: Codable, Sendable {
        public let errorCode: Int
        public let msg: String?
        public let result: DeviceListResult?
        
        enum CodingKeys: String, CodingKey {
            case errorCode = "error_code"
            case msg, result
        }
    }
    
    public struct DeviceListResult: Codable, Sendable {
        public let deviceList: [KasaDeviceItem]?
    }
    
    public struct KasaDeviceItem: Codable, Sendable, Identifiable {
        public let deviceType: String
        public let role: Int
        public let fwVer: String
        public let appServerUrl: String
        public let deviceRegion: String
        public let deviceId: String
        public let deviceName: String
        public let deviceHwVer: String
        public let alias: String
        public let deviceMac: String
        public let oemId: String
        public let deviceModel: String
        public let hwId: String
        public let fwId: String
        public let isSameRegion: Bool
        public let status: Int
        
        public var id: String { deviceId }
        public var displayName: String { alias.isEmpty ? deviceName : alias }
    }
    
    public struct PassthroughRequest: Codable, Sendable {
        public let method: String
        public let params: PassthroughParams
        
        public init(method: String = "passthrough", params: PassthroughParams) {
            self.method = method
            self.params = params
        }
    }
    
    public struct PassthroughParams: Codable, Sendable {
        public let deviceId: String
        public let requestData: String
        
        public init(deviceId: String, requestData: String) {
            self.deviceId = deviceId
            self.requestData = requestData
        }
    }
    
    public struct PassthroughResponse: Codable, Sendable {
        public let errorCode: Int
        public let msg: String?
        public let result: PassthroughResult?
        
        enum CodingKeys: String, CodingKey {
            case errorCode = "error_code"
            case msg, result
        }
    }
    
    public struct PassthroughResult: Codable, Sendable {
        public let responseData: String?
    }
    
    // MARK: - API Methods
    
    /// Authenticate against TP-Link Cloud and retrieve an API access token.
    public func login(email: String, password: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw KasaError.invalidURL(baseURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = LoginRequest(
            params: LoginParams(cloudUserName: email, cloudPassword: password)
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
        let respStr = String(data: data, encoding: .utf8) ?? ""
        
        guard statusCode == 200 else {
            throw KasaError.httpError(statusCode: statusCode, responseBody: respStr)
        }
        
        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
        if decoded.errorCode != 0 {
            throw KasaError.apiError(code: decoded.errorCode, message: decoded.msg ?? "Login failed")
        }
        
        guard let token = decoded.result?.token else {
            throw KasaError.missingToken
        }
        return token
    }
    
    /// Retrieve all devices registered to the user's account.
    public func getDevices(token: String) async throws -> [KasaDeviceItem] {
        let urlString = "\(baseURL)?token=\(token)"
        guard let url = URL(string: urlString) else {
            throw KasaError.invalidURL(urlString)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = DeviceListRequest()
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
        let respStr = String(data: data, encoding: .utf8) ?? ""
        
        guard statusCode == 200 else {
            throw KasaError.httpError(statusCode: statusCode, responseBody: respStr)
        }
        
        let decoded = try JSONDecoder().decode(DeviceListResponse.self, from: data)
        if decoded.errorCode != 0 {
            throw KasaError.apiError(code: decoded.errorCode, message: decoded.msg ?? "Failed to fetch devices")
        }
        return decoded.result?.deviceList ?? []
    }
    
    /// Toggle relay state (on or off) for a smart plug or smart switch.
    public func setDeviceRelayState(deviceId: String, isOn: Bool, token: String) async throws -> String {
        let urlString = "\(baseURL)?token=\(token)"
        guard let url = URL(string: urlString) else {
            throw KasaError.invalidURL(urlString)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let cmdJson = "{\"system\":{\"set_relay_state\":{\"state\":\(isOn ? 1 : 0)}}}"
        let payload = PassthroughRequest(
            params: PassthroughParams(deviceId: deviceId, requestData: cmdJson)
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
        let respStr = String(data: data, encoding: .utf8) ?? ""
        
        guard statusCode == 200 else {
            throw KasaError.httpError(statusCode: statusCode, responseBody: respStr)
        }
        
        let decoded = try JSONDecoder().decode(PassthroughResponse.self, from: data)
        if decoded.errorCode != 0 {
            throw KasaError.apiError(code: decoded.errorCode, message: decoded.msg ?? "Failed to change device state")
        }
        return decoded.result?.responseData ?? "Success"
    }
}
