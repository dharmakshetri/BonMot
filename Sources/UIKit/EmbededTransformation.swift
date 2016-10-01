//
//  EmbededTransformation.swift
//  BonMot
//
//  Created by Brian King on 9/28/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

#if os(OSX)
    import AppKit
#else
    import UIKit
#endif

// BonMot embeds transformation objects inside NSAttributedString attributes to do adaptive styling
// To simplify NSAttributedString NSCoding support, these transformations get embedded using plist compatible objects
internal protocol EmbededTransformation {

    /// Return a plist compatible dictionary of any state that's needed to persist the adaption
    var representation: StyleAttributes { get }

    /// This factory method is used to take the adaptations dictionary and create an array of AdaptiveStyleTransformation.
    /// To register a new adaptive transformation, add the type to AdaptiveAttributeHelpers.adaptiveTransformationTypes.
    static func from(representation dictionary: StyleAttributes) -> EmbededTransformation?

}

/// Internal helper functions for managing keys in the StyleAttributes related to adaptive functionality.
internal enum EmbededTransformationHelpers {
    struct Key {
        static let type = "type"
        static let size = "size"
    }

    static var embededTransformationTypes: [EmbededTransformation.Type] = [AdaptiveStyle.self, Tracking.self, Tab.self]

    static func embed(transformation theTransformation: EmbededTransformation, to styleAttributes: StyleAttributes) -> StyleAttributes {
        let representation = theTransformation.representation
        var styleAttributes = styleAttributes
        var adaptions = styleAttributes[BonMotTransformationsAttributeName] as? [StyleAttributes] ?? []

        // Only add the transformation once.
        let contains = adaptions.contains() { NSDictionary(dictionary: $0) == NSDictionary(dictionary: representation) }
        if !contains {
            adaptions.append(representation)
        }
        styleAttributes[BonMotTransformationsAttributeName] = adaptions
        return styleAttributes
    }

    static func transformations<T>(from styleAttributes: StyleAttributes) -> [T] {
        let representations = styleAttributes[BonMotTransformationsAttributeName] as? [StyleAttributes] ?? []
        let results: [T?] = representations.map { representation in
            for type in embededTransformationTypes {
                if let transformation = type.from(representation: representation) as? T {
                    return transformation
                }
            }
            return nil
        }
        return results.flatMap({ $0 })
    }

}

extension AdaptiveStyle: EmbededTransformation {

    struct Key {
        static let family = "family"
    }

    struct Value {
        static let control = "control"
        static let body = "body"
        static let preferred = "preferred"
        static let above = "above"
        static let below = "below"
    }

    var representation: StyleAttributes {
        switch self {
        case let .above(size, family):
            return [
                EmbededTransformationHelpers.Key.type: Value.above,
                EmbededTransformationHelpers.Key.size: size,
                Key.family: family,
            ]
        case let .below(size, family):
            return [
                EmbededTransformationHelpers.Key.type: Value.below,
                EmbededTransformationHelpers.Key.size: size,
                Key.family: family,
            ]
        case .control:
            return [EmbededTransformationHelpers.Key.type: Value.control]
        case .body:
            return [EmbededTransformationHelpers.Key.type: Value.body]
        case .preferred:
            return [EmbededTransformationHelpers.Key.type: Value.preferred]
        }
    }

    static func from(representation dictionary: [String: StyleAttributeValue]) -> EmbededTransformation? {
        switch (dictionary[EmbededTransformationHelpers.Key.type] as? String,
                dictionary[EmbededTransformationHelpers.Key.size] as? CGFloat,
                dictionary[Key.family] as? String) {
        case (Value.control?, nil, nil):
            return AdaptiveStyle.control
        case (Value.body?, nil, nil):
            return AdaptiveStyle.body
        case (Value.preferred?, nil, nil):
            return AdaptiveStyle.preferred
        case let (Value.above?, size?, family?):
            return AdaptiveStyle.above(size: size, family: family)
        case let (Value.below?, size?, family?):
            return AdaptiveStyle.below(size: size, family: family)
        default:
            return nil
        }
    }

}

extension Tracking: EmbededTransformation {

    struct Value {
        static let adobeTracking = "adobe-tracking"
    }

    static func from(representation dictionary: StyleAttributes) -> EmbededTransformation? {
        if case let (Value.adobeTracking?, size?) = (dictionary[EmbededTransformationHelpers.Key.type] as? String, dictionary[EmbededTransformationHelpers.Key.size] as? CGFloat) {
            return Tracking.adobe(size)
        }
        return nil
    }

    var representation: StyleAttributes {
        if case let .adobe(size) = self {
            return [EmbededTransformationHelpers.Key.type: Value.adobeTracking,
                    EmbededTransformationHelpers.Key.size: size]
        }
        else {
            // We don't need to persist regular tracking as it does not depend on the font size.
            return [:]
        }
    }

}

extension Tab: EmbededTransformation {

    struct Value {
        static let spacer = "spacer"
        static let headIndent = "headIndent"
    }

    static func from(representation dictionary: StyleAttributes) -> EmbededTransformation? {
        switch (dictionary[EmbededTransformationHelpers.Key.type] as? String,
                dictionary[EmbededTransformationHelpers.Key.size] as? CGFloat) {
        case (Value.spacer?, let width?):
            return Tab.spacer(width)
        case (Value.headIndent?, let width?):
            return Tab.headIndent(width)
        default:
            return nil
        }
    }

    var representation: StyleAttributes {
        switch self {
        case let .spacer(size):
            return [EmbededTransformationHelpers.Key.type: Value.spacer,
                    EmbededTransformationHelpers.Key.size: size]

        case let .headIndent(size):
            return [EmbededTransformationHelpers.Key.type: Value.headIndent,
                    EmbededTransformationHelpers.Key.size: size]
        }
    }

}
