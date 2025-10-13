import Foundation

CFPreferencesAppSynchronize("com.apple.Terminal" as CFString)
_ = CFPreferencesCopyKeyList("com.apple.Terminal" as CFString,
                             kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
