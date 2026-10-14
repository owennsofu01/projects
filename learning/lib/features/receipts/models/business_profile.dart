/// The shop details printed at the top and bottom of every receipt.
/// Stored as a `businessProfile` map on the user's Firestore doc.
class BusinessProfile {
  final String name;
  final String phone;
  final String address;
  final String footer;

  const BusinessProfile({
    this.name = '',
    this.phone = '',
    this.address = '',
    this.footer = '',
  });

  static const empty = BusinessProfile();

  factory BusinessProfile.fromMap(Map<String, dynamic>? data) {
    if (data == null) return empty;
    return BusinessProfile(
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      footer: data['footer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'address': address,
    'footer': footer,
  };
}
