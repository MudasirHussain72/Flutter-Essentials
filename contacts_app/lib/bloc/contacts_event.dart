part of 'contacts_bloc.dart';

abstract class ContactsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchContacts extends ContactsEvent {}

class FetchContact extends ContactsEvent {
  final String contactId;

  FetchContact({required this.contactId});

  @override
  List<Object?> get props => [contactId];
}

class AddContact extends ContactsEvent {
  final Contact contact;

  AddContact({required this.contact});

  @override
  List<Object?> get props => [contact];
}

class UpdateContact extends ContactsEvent {
  final Contact contact;

  UpdateContact({required this.contact});

  @override
  List<Object?> get props => [contact];
}

class DeleteContact extends ContactsEvent {
  final String contactId;

  DeleteContact({required this.contactId});

  @override
  List<Object?> get props => [contactId];
}
