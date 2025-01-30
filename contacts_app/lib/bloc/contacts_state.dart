part of 'contacts_bloc.dart';

class ContactsState extends Equatable {
  final ApiResponse<List<Contact>> contactsList;
  final bool isSyncing;
  final String? errorMessage;

  const ContactsState({
    required this.contactsList,
    this.isSyncing = false,
    this.errorMessage,
  });

  ContactsState copyWith({
    ApiResponse<List<Contact>>? contactsList,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return ContactsState(
      contactsList: contactsList ?? this.contactsList,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [contactsList, isSyncing, errorMessage ?? ''];

  factory ContactsState.fromJson(Map<String, dynamic> json) {
    return ContactsState(
      contactsList: ApiResponse<List<Contact>>.fromJson(
        json['contactsList'],
        (data) => (data as List).map((item) => Contact.fromJson(item)).toList(),
      ),
      isSyncing: json['isSyncing'] ?? false,
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contactsList': contactsList.toJson((contact) => contact),
      'isSyncing': isSyncing,
      'errorMessage': errorMessage,
    };
  }
}
