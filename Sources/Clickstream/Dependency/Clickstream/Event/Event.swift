//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

enum Event {
    /// Check the attribute error.
    /// - Parameters:
    ///   - currentNumber: current attribute number
    ///   - key: attribute key
    ///   - value: attribute value
    /// - Returns: the ErrorType
    static func checkAttribute(currentNumber: Int, key: String, value: AttributeValue) -> EventError? {
        if currentNumber >= Limit.MAX_NUM_OF_ATTRIBUTES {
            let errorMsg = """
            reached the max number of attributes limit (\(Limit.MAX_NUM_OF_ATTRIBUTES)).\
             and the attribute: \(key) will not be recorded
            """
            log.error(errorMsg)
            let errorString = "attribute name: \(key)"
            return EventError(errorType: ErrorType.ATTRIBUTE_SIZE_EXCEED,
                              errorMessage: "\(errorString.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
        }
        let nameLength = key.utf8.count
        if nameLength > Limit.MAX_LENGTH_OF_NAME {
            let errorMsg = """
            attribute : \(key), reached the max length of attributes name limit(\(Limit.MAX_LENGTH_OF_NAME).\
             current length is:(\(nameLength)) and the attribute will not be recorded
            """
            log.error(errorMsg)
            let errorString = "attribute name length is:(\(nameLength)) name is: \(key)"
            return EventError(errorType: ErrorType.ATTRIBUTE_NAME_LENGTH_EXCEED,
                              errorMessage: "\(errorString.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
        }
        if !isValidName(name: key) {
            let errorMsg = """
            attribute : \(key), was not valid, attribute name can only contains uppercase\
             and lowercase letters, underscores, number, and is not start with a number.\
             so the attribute will not be recorded
            """
            log.error(errorMsg)
            return EventError(errorType: ErrorType.ATTRIBUTE_NAME_INVALID,
                              errorMessage: "\(key.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
        }
        if let value = value as? String {
            let valueLength = value.utf8.count
            if valueLength > Limit.MAX_LENGTH_OF_VALUE {
                let errorMsg = """
                attribute : \(key), reached the max length of attributes value limit\
                (\(Limit.MAX_LENGTH_OF_VALUE)). current length is:(\(valueLength)).\
                 and the attribute will not be recorded, attribute value: \(value)
                """
                log.error(errorMsg)
                let errrorString = "attribute name: \(key), attribute value: \(value)"
                return EventError(errorType: ErrorType.ATTRIBUTE_VALUE_LENGTH_EXCEED,
                                  errorMessage: "\(errrorString.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
            }
        }
        return nil
    }

    /// Check the user attribute error.
    /// - Parameters:
    ///   - currentNumber: current attribute number
    ///   - key: attribute key
    ///   - value: attribute value
    /// - Returns: the ErrorType
    static func checkUserAttribute(currentNumber: Int, key: String, value: AttributeValue) -> EventError? {
        if currentNumber >= Limit.MAX_NUM_OF_USER_ATTRIBUTES {
            let errorMsg = """
            reached the max number of user attributes limit (\(Limit.MAX_NUM_OF_USER_ATTRIBUTES)).\
             and the user attribute: \(key) will not be recorded
            """
            log.error(errorMsg)
            let errorString = "attribute name: \(key)"
            return EventError(errorType: ErrorType.ATTRIBUTE_SIZE_EXCEED,
                              errorMessage: "\(errorString.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))...")
        }
        let nameLength = key.utf8.count
        if nameLength > Limit.MAX_LENGTH_OF_NAME {
            let errorMsg = """
            user attribute : \(key), reached the max length of attributes name limit\
            (\(Limit.MAX_LENGTH_OF_NAME). current length is:(\(nameLength))\
             and the attribute will not be recorded
            """
            log.error(errorMsg)
            let errorString = "user attribute name length is:(\(nameLength)) name is: \(key)"
            return EventError(errorType: ErrorType.ATTRIBUTE_NAME_LENGTH_EXCEED,
                              errorMessage: "\(errorString.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
        }
        if !isValidName(name: key) {
            let errorMsg = """
            user attribute : \(key), was not valid, user attribute name can only contains uppercase\
             and lowercase letters, underscores, number, and is not start with a number.\
             so the attribute will not be recorded
            """
            log.error(errorMsg)
            return EventError(errorType: ErrorType.ATTRIBUTE_NAME_INVALID,
                              errorMessage: "\(key.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
        }
        if let value = value as? String {
            let valueLength = value.utf8.count
            if valueLength > Limit.MAX_LENGTH_OF_USER_VALUE {
                let errorMsg = """
                user attribute : \(key), reached the max length of attributes value limit\
                 (\(Limit.MAX_LENGTH_OF_USER_VALUE)). current length is:(\(valueLength)).\
                 and the attribute will not be recorded, attribute value: \(value)
                """
                log.error(errorMsg)
                let errrorString = "attribute name: \(key), attribute value: \(value)"
                return EventError(errorType: ErrorType.ATTRIBUTE_VALUE_LENGTH_EXCEED,
                                  errorMessage: "\(errrorString.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
            }
        }
        return nil
    }

    /// Check the event name whether valide
    /// - Parameter eventType: the event name
    /// - Returns: the eventType is valide and the error type
    static func isValidEventType(eventType: String) -> (Bool, String) {
        if eventType.utf8.count > Event.Limit.MAX_EVENT_TYPE_LENGTH {
            let errorMsg = """
            Event name is too long, the max event type length is \
            \(Limit.MAX_EVENT_TYPE_LENGTH) characters. event name: \(eventType)
            """
            return (false, errorMsg)
        } else if !isValidName(name: eventType) {
            let errorMsg = """
            Event name can only contains uppercase and lowercase letters, underscores, number,\
             and is not start with a number. event name: \(eventType)
            """
            return (false, errorMsg)
        }
        return (true, "")
    }

    /// Verify the string whether only contains number, uppercase and lowercase letters,
    /// underscores, and is not start with a number
    /// - Parameter name: the name to verify
    /// - Returns: the name is valid.
    static func isValidName(name: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: "^(?![0-9])[0-9a-zA-Z_]+$")
        let range = NSRange(location: 0, length: name.utf8.count)
        let matches = regex?.matches(in: name, range: range)
        if matches != nil {
            return !matches!.isEmpty
        } else {
            return false
        }
    }

    enum ReservedAttribute {
        static let USER_ID = "_user_id"
        static let USER_FIRST_TOUCH_TIMESTAMP = "_user_first_touch_timestamp"
        static let PREVIOUS_APP_VERSION = "_previous_app_version"
        static let PREVIOUS_OS_VERSION = "_previous_os_version"
        static let ENGAGEMENT_TIMESTAMP = "_engagement_time_msec"
        static let ENTRANCES = "_entrances"
        static let PREVIOUS_SCREEN_ID = "_previous_screen_id"
        static let PREVIOUS_SCREEN_NAME = "_previous_screen_name"
        static let SCREEN_ID = "_screen_id"
        static let SCREEN_NAME = "_screen_name"
    }

    enum User {
        static let USER_ID_NIL = "_clickstream_user_id_nil"
        static let USER_ID_EMPTY = "_clickstream_user_id_empty"
    }

    enum Limit {
        /// max event type length
        static let MAX_EVENT_TYPE_LENGTH = 50

        /// max limit of single event attribute number.
        static let MAX_NUM_OF_ATTRIBUTES = 500

        /// max limit of single event user attribute number.
        static let MAX_NUM_OF_USER_ATTRIBUTES = 100

        /// max limit of attribute name character length.
        static let MAX_LENGTH_OF_NAME = 50

        /// max limit of attribute value character length.
        static let MAX_LENGTH_OF_VALUE = 1_024

        /// max limit of user attribute value character length.
        static let MAX_LENGTH_OF_USER_VALUE = 256

        /// max limit of one batch event number.
        static let MAX_EVENT_NUMBER_OF_BATCH = 100

        /// max limit of error attribute value length.
        static let MAX_LENGTH_OF_ERROR_VALUE = 256
    }

    enum PresetEvent {
        static let SESSION_START = "_session_start"
        static let PROFILE_SET = "_profile_set"
        static let APP_UPDATE = "_app_update"
        static let OS_UPDATE = "_os_update"
        static let FIRST_OPEN = "_first_open"
        static let USER_ENGAGEMENT = "_user_engagement"
        static let SCREEN_VIEW = "_screen_view"
    }

    enum ErrorType {
        static let ATTRIBUTE_NAME_INVALID = "_error_name_invalid"
        static let ATTRIBUTE_NAME_LENGTH_EXCEED = "_error_name_length_exceed"
        static let ATTRIBUTE_VALUE_LENGTH_EXCEED = "_error_value_length_exceed"
        static let ATTRIBUTE_SIZE_EXCEED = "_error_attribute_size_exceed"
    }

    class EventError {
        let errorType: String
        let errorMessage: String
        init(errorType: String, errorMessage: String) {
            self.errorType = errorType
            self.errorMessage = errorMessage
        }
    }
}

extension Event: ClickstreamLogger {}
