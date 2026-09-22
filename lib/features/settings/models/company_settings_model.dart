// lib/features/settings/models/company_settings_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CompanySettingsModel extends Equatable {
  final String companyName;
  final String? logoUrl;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String phone;
  final String email;
  final String website;
  final String gstNumber;
  final String panNumber;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String branch;
  final String defaultTerms;
  final String defaultNotes;
  final String currency;
  final String currencySymbol;

  const CompanySettingsModel({
    this.companyName = 'Hytide Technologies Pvt Ltd',
    this.logoUrl,
    this.address = '402, High-Tech Tower, Baner Road',
    this.city = 'Pune',
    this.state = 'Maharashtra',
    this.country = 'India',
    this.pincode = '411045',
    this.phone = '+91 98765 43210',
    this.email = 'billing@hytide.com',
    this.website = 'https://hytide.com',
    this.gstNumber = '27AABCH1234F1Z5',
    this.panNumber = 'AABCH1234F',
    this.bankName = 'HDFC Bank Ltd',
    this.accountNumber = '50200098765432',
    this.ifscCode = 'HDFC0001234',
    this.branch = 'Baner Branch, Pune',
    this.defaultTerms =
        '1. Quotation is valid for 15 days from the date of issue.\n'
        '2. 50% advance payment required upon project kickoff.\n'
        '3. Remaining 50% payable upon milestone completion/delivery.\n'
        '4. Taxes applicable as per Government of India GST guidelines.\n'
        '5. Support and maintenance covers 30 days of post-launch bug fixes.',
    this.defaultNotes =
        'Thank you for your business. We look forward to working with your team.',
    this.currency = 'INR',
    this.currencySymbol = '₹',
  });

  String get fullAddress => '$address, $city, $state - $pincode, $country';

  factory CompanySettingsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CompanySettingsModel.fromMap(data);
  }

  factory CompanySettingsModel.fromMap(Map<String, dynamic> data) {
    return CompanySettingsModel(
      companyName: data['companyName'] as String? ?? 'Hytide Technologies Pvt Ltd',
      logoUrl: data['logoUrl'] as String?,
      address: data['address'] as String? ?? '402, High-Tech Tower, Baner Road',
      city: data['city'] as String? ?? 'Pune',
      state: data['state'] as String? ?? 'Maharashtra',
      country: data['country'] as String? ?? 'India',
      pincode: data['pincode'] as String? ?? '411045',
      phone: data['phone'] as String? ?? '+91 98765 43210',
      email: data['email'] as String? ?? 'billing@hytide.com',
      website: data['website'] as String? ?? 'https://hytide.com',
      gstNumber: data['gstNumber'] as String? ?? '27AABCH1234F1Z5',
      panNumber: data['panNumber'] as String? ?? 'AABCH1234F',
      bankName: data['bankName'] as String? ?? 'HDFC Bank Ltd',
      accountNumber: data['accountNumber'] as String? ?? '50200098765432',
      ifscCode: data['ifscCode'] as String? ?? 'HDFC0001234',
      branch: data['branch'] as String? ?? 'Baner Branch, Pune',
      defaultTerms: data['defaultTerms'] as String? ??
          '1. Quotation is valid for 15 days from the date of issue.\n'
          '2. 50% advance payment required upon project kickoff.\n'
          '3. Remaining 50% payable upon milestone completion/delivery.\n'
          '4. Taxes applicable as per Government of India GST guidelines.\n'
          '5. Support and maintenance covers 30 days of post-launch bug fixes.',
      defaultNotes: data['defaultNotes'] as String? ??
          'Thank you for your business. We look forward to working with your team.',
      currency: data['currency'] as String? ?? 'INR',
      currencySymbol: data['currencySymbol'] as String? ?? '₹',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'logoUrl': logoUrl,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'website': website,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'branch': branch,
      'defaultTerms': defaultTerms,
      'defaultNotes': defaultNotes,
      'currency': currency,
      'currencySymbol': currencySymbol,
    };
  }

  @override
  List<Object?> get props => [
        companyName,
        logoUrl,
        address,
        city,
        state,
        country,
        pincode,
        phone,
        email,
        website,
        gstNumber,
        panNumber,
        bankName,
        accountNumber,
        ifscCode,
        branch,
        defaultTerms,
        defaultNotes,
        currency,
        currencySymbol,
      ];
}
