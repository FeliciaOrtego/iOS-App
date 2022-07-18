//
//  GWSUser.swift
//  AppTemplatesCore
//
//  Created by Jared Sullivan and Florian Marcu on 2/2/17.
//  Copyright © 2017 iOS App Templates. All rights reserved.
//

import Firebase
import FirebaseFirestore
import Foundation

open class GWSUser: NSObject, GWSGenericBaseModel, NSCoding {
    static let defaultAvatarURL = "https://www.iosapptemplates.com/wp-content/uploads/2019/06/empty-avatar.jpg"
    let kUserOnlinePresenceInterval: Int = 70

    var uid: String?
    var username: String?
    var email: String?
    var firstName: String?
    var lastName: String?
    var phoneNumber: String?
    var profilePictureURL: String? {
        didSet {
            hasDefaultAvatar = (profilePictureURL == nil
                || profilePictureURL == ""
                || profilePictureURL == GWSUser.defaultAvatarURL)
        }
    }

    var pushToken: String?
    var pushKitToken: String?
    var isOnline: Bool = false
    var lastOnlineDateTime: Date?
    var photos: [String]?
    var location: GWSLocation?
    var hasDefaultAvatar: Bool = true
    var isAdmin: Bool = false
    var teamId: Int?
    var vendorID: String? // If set, this user is the admin for this vendorID (e.g. restaurant owner)
    var role: String?
    var isActive: Bool = false
    var settings = [String: Any]()
    var inboundFriendsCount: Int?
    var outboundFriendsCount: Int?

    init(uid: String = "",
         firstName: String?,
         lastName: String?,
         avatarURL: String? = nil,
         email: String = "",
         phoneNumber: String = "",
         pushToken: String? = nil,
         pushKitToken: String? = nil,
         photos: [String]? = [],
         isOnline: Bool = false,
         lastOnlineDateTime: Date? = nil,
         location: GWSLocation? = nil,
         isAdmin: Bool = false,
         teamId: Int? = -1,
         vendorID: String? = nil,
         role: String = "",
         isActive: Bool = false,
         settings: [String: Any] = [:],
         inboundFriendsCount: Int? = nil,
         outboundFriendsCount: Int? = nil)
    {
        self.firstName = firstName
        self.lastName = lastName
        self.uid = uid
        self.email = email
        self.phoneNumber = phoneNumber
        profilePictureURL = ((avatarURL?.count ?? 0) > 0 ? avatarURL : GWSUser.defaultAvatarURL)
        hasDefaultAvatar = (avatarURL == nil || avatarURL == "" || avatarURL == GWSUser.defaultAvatarURL)
        self.pushToken = pushToken
        self.pushKitToken = pushKitToken
        self.photos = photos
        self.isOnline = isOnline
        self.lastOnlineDateTime = lastOnlineDateTime
        self.location = location
        self.isAdmin = isAdmin
        self.teamId = teamId
        self.vendorID = vendorID
        self.role = role
        self.isActive = isActive
        self.settings = settings
        self.inboundFriendsCount = inboundFriendsCount
        self.outboundFriendsCount = outboundFriendsCount
    }

    public init(representation: [String: Any]) {
        super.init()
        decodeFromDict(representation)
    }

    public required init(jsonDict: [String: Any]) {
        super.init()
        decodeFromDict(jsonDict)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(uid, forKey: "uid")
        aCoder.encode(username, forKey: "username")
        aCoder.encode(email, forKey: "email")
        aCoder.encode(phoneNumber, forKey: "phone")
        aCoder.encode(firstName, forKey: "firstName")
        aCoder.encode(lastName, forKey: "lastName")
        aCoder.encode(profilePictureURL, forKey: "profilePictureURL")
        aCoder.encode(pushToken, forKey: "pushToken")
        aCoder.encode(pushKitToken, forKey: "pushKitToken")
        aCoder.encode(isOnline, forKey: "isOnline")
        aCoder.encode(lastOnlineDateTime, forKey: "lastOnlineTimestamp")
        aCoder.encode(photos, forKey: "photos")
        aCoder.encode(location, forKey: "location")
        aCoder.encode(isAdmin, forKey: "isAdmin")
        aCoder.encode(teamId, forKey: "teamId")
        aCoder.encode(role, forKey: "role")
        aCoder.encode(isActive, forKey: "isActive")
        if let vendorID = vendorID {
            aCoder.encode(vendorID, forKey: "vendorID")
        }
        if let inboundFriendsCount = inboundFriendsCount {
            aCoder.encode(inboundFriendsCount, forKey: "inboundFriendsCount")
        }
        if let outboundFriendsCount = outboundFriendsCount {
            aCoder.encode(outboundFriendsCount, forKey: "outboundFriendsCount")
        }
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        self.init(uid: aDecoder.decodeObject(forKey: "uid") as? String ?? "unknown",
                  firstName: aDecoder.decodeObject(forKey: "firstName") as? String ?? "",
                  lastName: aDecoder.decodeObject(forKey: "lastName") as? String ?? "",
                  avatarURL: aDecoder.decodeObject(forKey: "profilePictureURL") as? String ?? GWSUser.defaultAvatarURL,
                  email: aDecoder.decodeObject(forKey: "email") as? String ?? "",
                  phoneNumber: aDecoder.decodeObject(forKey: "phone") as? String ?? "",
                  pushToken: aDecoder.decodeObject(forKey: "pushToken") as? String ?? "",
                  pushKitToken: aDecoder.decodeObject(forKey: "pushKitToken") as? String ?? "",
                  photos: aDecoder.decodeObject(forKey: "photos") as? [String] ?? [],
                  isOnline: aDecoder.decodeBool(forKey: "isOnline"),
                  lastOnlineDateTime: aDecoder.decodeObject(forKey: "lastOnlineTimestamp") as? Date ?? nil,
                  location: aDecoder.decodeObject(forKey: "location") as? GWSLocation,
                  isAdmin: aDecoder.decodeBool(forKey: "isAdmin"),
                  teamId: aDecoder.decodeObject(forKey: "teamId") as? Int,
                  vendorID: aDecoder.decodeObject(forKey: "vendorID") as? String,
                  role: aDecoder.decodeObject(forKey: "role") as? String ?? "",
                  isActive: aDecoder.decodeBool(forKey: "isActive"),
                  settings: aDecoder.decodeObject(forKey: "settings") as? [String: Any] ?? [:],
                  inboundFriendsCount: aDecoder.decodeObject(forKey: "inboundFriendsCount") as? Int ?? nil,
                  outboundFriendsCount: aDecoder.decodeObject(forKey: "outboundFriendsCount") as? Int ?? nil)
    }

//    public func mapping(map: Map) {
//        username            <- map["username"]
//        email               <- map["email"]
//        firstName           <- map["first_name"]
//        lastName            <- map["last_name"]
//        profilePictureURL   <- map["profile_picture"]
//    }

    public func fullName() -> String {
        guard let firstName = firstName,
              let lastName = lastName
        else {
            return self.firstName ?? self.lastName ?? ""
        }
        return "\(firstName) \(lastName)"
    }

    public func firstWordFromName() -> String {
        if let firstName = firstName, let first = firstName.components(separatedBy: " ").first {
            return first
        }
        return "No name"
    }

    var initials: String {
        if let f = firstName?.first, let l = lastName?.first {
            return String(f) + String(l)
        }
        return "?"
    }

    var representation: [String: Any] {
        var rep: [String: Any] = [
            "userID": uid ?? "default",
            "id": uid ?? "default",
            "profilePictureURL": profilePictureURL ?? GWSUser.defaultAvatarURL,
            "username": username ?? "",
            "email": email ?? "",
            "firstName": firstName ?? "",
            "lastName": lastName ?? "",
            "pushToken": pushToken ?? "",
            "pushKitToken": pushKitToken ?? "",
            "photos": photos ?? "",
            "role": role ?? "",
            "isActive": isActive,
            "inboundFriendsCount": inboundFriendsCount ?? 0,
            "outboundFriendsCount": outboundFriendsCount ?? 0,
        ]
        if let location = location {
            rep["location"] = location.representation
        }
        return rep
    }

    public func showOnlineStatus() -> Bool {
        var showOnlineStatus = isOnline
        if showOnlineStatus, let lastOnlineDateTime = lastOnlineDateTime {
            let lastOnlineDateTimeInSeconds = Int(Date().timeIntervalSince(lastOnlineDateTime))
            if lastOnlineDateTimeInSeconds > kUserOnlinePresenceInterval {
                showOnlineStatus = false
            }
        }
        return showOnlineStatus
    }

    // - Helper methods
    func decodeFromDict(_ jsonDict: [String: Any]) {
        firstName = jsonDict["firstName"] as? String
        lastName = jsonDict["lastName"] as? String
        let avatarURL = jsonDict["profilePictureURL"] as? String
        profilePictureURL = (avatarURL?.count ?? 0) > 0 ? avatarURL : GWSUser.defaultAvatarURL
        hasDefaultAvatar = (avatarURL == nil || avatarURL == "" || avatarURL == GWSUser.defaultAvatarURL)
        username = jsonDict["username"] as? String
        email = jsonDict["email"] as? String
        phoneNumber = jsonDict["phone"] as? String
        uid = jsonDict["id"] as? String
        pushToken = jsonDict["pushToken"] as? String
        pushKitToken = jsonDict["pushKitToken"] as? String
        photos = jsonDict["photos"] as? [String]
        isAdmin = (jsonDict["isAdmin"] as? Bool) ?? false
        teamId = (jsonDict["teamId"] as? Int) ?? -1
        isOnline = (jsonDict["isOnline"] as? Bool) ?? false
        lastOnlineDateTime = (jsonDict["lastOnlineTimestamp"] as? Timestamp)?.dateValue()
        vendorID = jsonDict["vendorID"] as? String
        role = jsonDict["role"] as? String
        isActive = (jsonDict["isActive"] as? Bool) ?? false

        var location: GWSLocation?
        if let locationDict = jsonDict["location"] as? [String: Any] {
            location = GWSLocation(representation: locationDict)
        }
        self.location = location
        if let settings = jsonDict["settings"] as? [String: Any] {
            self.settings = settings
        }
        inboundFriendsCount = jsonDict["inboundFriendsCount"] as? Int
        outboundFriendsCount = jsonDict["outboundFriendsCount"] as? Int
    }

    override public var hash: Int {
        var hasher = Hasher()
        hasher.combine(uid)
        return hasher.finalize()
    }

    override open func isEqual(_ object: Any?) -> Bool {
        guard let user = object as? GWSUser else { return false }
        return uid == user.uid
    }
}

enum GWSRole: String {
    case user
    case driver
    case vendor
    case admin
    case taxiDriver
}
