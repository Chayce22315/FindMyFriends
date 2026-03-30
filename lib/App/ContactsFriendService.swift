import Contacts
import Foundation

struct ContactPick: Identifiable, Hashable {
    let id: String
    let name: String
}

final class ContactsFriendService: ObservableObject {
    @Published private(set) var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published private(set) var contacts: [ContactPick] = []

    private let store = CNContactStore()

    init() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestAccess() {
        store.requestAccess(for: .contacts) { [weak self] ok, _ in
            DispatchQueue.main.async {
                self?.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
                if ok {
                    self?.reloadContacts()
                }
            }
        }
    }

    func reloadContacts() {
        guard authorizationStatus == .authorized else { return }
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var result: [ContactPick] = []
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let full = [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                let name = full.isEmpty ? "Contact" : full
                result.append(ContactPick(id: contact.identifier, name: name))
            }
        } catch {
            result = []
        }
        contacts = result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
