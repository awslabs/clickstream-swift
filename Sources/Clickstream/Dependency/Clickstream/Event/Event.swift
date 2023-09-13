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
    static func checkAttribute(currentNumber: Int, key: String, value: AttributeValue) -> EventError {
        if currentNumber >= Limit.MAX_NUM_OF_ATTRIBUTES {
            let errorMsg = """
            reached the max number of attributes limit (\(Limit.MAX_NUM_OF_ATTRIBUTES)).\
             and the attribute: \(key) will not be recorded
            """
            log.error(errorMsg)
            let errorString = "attribute name: \(key)"
            return EventError(errorCode: ErrorCode.ATTRIBUTE_SIZE_EXCEED,
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
            return EventError(errorCode: ErrorCode.ATTRIBUTE_NAME_LENGTH_EXCEED,
                              errorMessage: "\(errorString.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
        }
        if !isValidName(name: key) {
            let errorMsg = """
            attribute : \(key), was not valid, attribute name can only contains uppercase\
             and lowercase letters, underscores, number, and is not start with a number.\
             so the attribute will not be recorded
            """
            log.error(errorMsg)
            return EventError(errorCode: ErrorCode.ATTRIBUTE_NAME_INVALID,
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
                return EventError(errorCode: ErrorCode.ATTRIBUTE_VALUE_LENGTH_EXCEED,
                                  errorMessage: "\(errrorString.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
            }
        }
        return EventError(errorCode: ErrorCode.NO_ERROR, errorMessage: "")
    }

    /// Check the user attribute error.
    /// - Parameters:
    ///   - currentNumber: current attribute number
    ///   - key: attribute key
    ///   - value: attribute value
    /// - Returns: the ErrorType
    static func checkUserAttribute(currentNumber: Int, key: String, value: AttributeValue) -> EventError {
        if currentNumber >= Limit.MAX_NUM_OF_USER_ATTRIBUTES {
            let errorMsg = """
            reached the max number of user attributes limit (\(Limit.MAX_NUM_OF_USER_ATTRIBUTES)).\
             and the user attribute: \(key) will not be recorded
            """
            log.error(errorMsg)
            let errorString = "attribute name: \(key)"
            return EventError(errorCode: ErrorCode.USER_ATTRIBUTE_SIZE_EXCEED,
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
            return EventError(errorCode: ErrorCode.USER_ATTRIBUTE_NAME_LENGTH_EXCEED,
                              errorMessage: "\(errorString.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
        }
        if !isValidName(name: key) {
            let errorMsg = """
            user attribute : \(key), was not valid, user attribute name can only contains uppercase\
             and lowercase letters, underscores, number, and is not start with a number.\
             so the attribute will not be recorded
            """
            log.error(errorMsg)
            return EventError(errorCode: ErrorCode.USER_ATTRIBUTE_NAME_INVALID,
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
                return EventError(errorCode: ErrorCode.USER_ATTRIBUTE_VALUE_LENGTH_EXCEED,
                                  errorMessage: "\(errrorString.prefix(Limit.MAX_LENGTH_OF_ERROR_VALUE))")
            }
        }
        return EventError(errorCode: ErrorCode.NO_ERROR, errorMessage: "")
    }

    /// Check the event name whether valide
    /// - Parameter eventType: the event name
    /// - Returns: the EventError object
    static func checkEventType(eventType: String) -> EventError {
        if eventType.utf8.count > Event.Limit.MAX_EVENT_TYPE_LENGTH {
            let errorMsg = """
            Event name is too long, the max event type length is \
            \(Limit.MAX_EVENT_TYPE_LENGTH) characters. event name: \(eventType)
            """
            log.error(errorMsg)
            return EventError(errorCode: ErrorCode.EVENT_NAME_LENGTH_EXCEED, errorMessage: errorMsg)
        } else if !isValidName(name: eventType) {
            let errorMsg = """
            Event name can only contains uppercase and lowercase letters, underscores, number,\
             and is not start with a number. event name: \(eventType)
            """
            log.error(errorMsg)
            return EventError(errorCode: ErrorCode.EVENT_NAME_INVALID, errorMessage: errorMsg)
        }
        return EventError(errorCode: ErrorCode.NO_ERROR, errorMessage: "")
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
        static let PREVIOUS_SCREEN_UNIQUEID = "_previous_screen_unique_id"
        static let PREVIOUS_TIMESTAMP = "_previous_timestamp"
        static let SCREEN_ID = "_screen_id"
        static let SCREEN_NAME = "_screen_name"
        static let SCREEN_UNIQUEID = "_screen_unique_id"
        static let IS_FIRST_TIME = "_is_first_time"
        static let EXCEPTION_NAME = "_exception_name"
        static let EXCEPTION_REASON = "_exception_reason"
        static let EXCEPTION_STACK = "_excepiton_stack"
        static let ERROR_CODE = "_error_code"
        static let ERROR_MESSAGE = "_error_message"
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
        static let APP_START = "_app_start"
        static let APP_END = "_app_end"
        static let APP_EXCEPTION = "_app_exception"
        static let CLICKSTREAM_ERROR = "_clickstream_error"
    }

    enum ErrorCode {
        static let NO_ERROR = 0
        static let EVENT_NAME_INVALID = 1_001
        static let EVENT_NAME_LENGTH_EXCEED = 1_002
        static let ATTRIBUTE_NAME_LENGTH_EXCEED = 2_001
        static let ATTRIBUTE_NAME_INVALID = 2_002
        static let ATTRIBUTE_VALUE_LENGTH_EXCEED = 2_003
        static let ATTRIBUTE_SIZE_EXCEED = 2_004
        static let USER_ATTRIBUTE_SIZE_EXCEED = 3_001
        static let USER_ATTRIBUTE_NAME_LENGTH_EXCEED = 3_002
        static let USER_ATTRIBUTE_NAME_INVALID = 3_003
        static let USER_ATTRIBUTE_VALUE_LENGTH_EXCEED = 3_004
    }

    class EventError {
        let errorCode: Int
        let errorMessage: String
        init(errorCode: Int, errorMessage: String) {
            self.errorCode = errorCode
            self.errorMessage = errorMessage
        }
    }
}

extension Event: ClickstreamLogger {}
