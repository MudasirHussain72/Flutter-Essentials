import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_app/model/contact.dart';
import 'package:contacts_app/remote/response/api_response.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';

part 'contacts_event.dart';
part 'contacts_state.dart';

class ContactsBloc extends HydratedBloc<ContactsEvent, ContactsState> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ContactsBloc() : super(ContactsState(contactsList: ApiResponse.initial())) {
    on<FetchContacts>(_fetchContacts);
    on<AddContact>(_addContact);
    on<UpdateContact>(_updateContact);
    on<DeleteContact>(_deleteContact);
    on<FetchContact>(_fetchContact);
  }

  Future<void> _fetchContacts(
      FetchContacts event, Emitter<ContactsState> emit) async {
    emit(state.copyWith(isSyncing: true));

    try {
      final snapshot = await firestore.collection('contacts').get();
      final contacts =
          snapshot.docs.map((doc) => Contact.fromJson(doc.data())).toList();
      emit(state.copyWith(
        contactsList: ApiResponse.completed(contacts),
        isSyncing: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        contactsList: ApiResponse.error('Failed to fetch contacts'),
        isSyncing: false,
      ));
    }
  }

  Future<void> _fetchContact(
      FetchContact event, Emitter<ContactsState> emit) async {
    if (state.contactsList.status == Status.completed) {
      emit(state.copyWith(isSyncing: true));

      try {
        final doc =
            await firestore.collection('contacts').doc(event.contactId).get();
        final contact = Contact.fromJson(doc.data()!);

        // Check if the contact is already in the list
        final contacts = List<Contact>.from(state.contactsList.data!);
        final contactIndex =
            contacts.indexWhere((c) => c.id == event.contactId);

        if (contactIndex != -1) {
          // Update existing contact
          contacts[contactIndex] = contact;
        } else {
          // Add new contact
          contacts.add(contact);
        }

        emit(state.copyWith(
          contactsList: ApiResponse.completed(contacts),
          isSyncing: false,
        ));
      } catch (e) {
        emit(state.copyWith(
          isSyncing: false,
          errorMessage: 'Failed to fetch contact',
        ));
      }
    } else {
      emit(state.copyWith(errorMessage: 'Unexpected state'));
    }
  }

  Future<void> _addContact(
      AddContact event, Emitter<ContactsState> emit) async {
    if (state.contactsList.status == Status.completed) {
      emit(state.copyWith(isSyncing: true));

      try {
        await firestore
            .collection('contacts')
            .doc(event.contact.id)
            .set(event.contact.toJson());
        add(FetchContact(contactId: event.contact.id));
      } catch (e) {
        emit(state.copyWith(
          isSyncing: false,
          errorMessage: 'Failed to add contact',
        ));
      }
    }
  }

  Future<void> _updateContact(
      UpdateContact event, Emitter<ContactsState> emit) async {
    if (state.contactsList.status == Status.completed) {
      emit(state.copyWith(isSyncing: true));

      try {
        await firestore
            .collection('contacts')
            .doc(event.contact.id)
            .update(event.contact.toJson());
        add(FetchContact(contactId: event.contact.id));
      } catch (e) {
        emit(state.copyWith(
          isSyncing: false,
          errorMessage: 'Failed to update contact',
        ));
      }
    }
  }

  Future<void> _deleteContact(
      DeleteContact event, Emitter<ContactsState> emit) async {
    if (state.contactsList.status == Status.completed) {
      emit(state.copyWith(isSyncing: true));

      try {
        final query = await firestore
            .collection('contacts')
            .where('id', isEqualTo: event.contactId)
            .get();
        for (var doc in query.docs) {
          await doc.reference.delete();
        }

        final updatedContacts = List<Contact>.from(state.contactsList.data!)
          ..removeWhere((contact) => contact.id == event.contactId);
        emit(state.copyWith(
          contactsList: ApiResponse.completed(updatedContacts),
          isSyncing: false,
        ));
      } catch (e) {
        emit(state.copyWith(
          isSyncing: false,
          errorMessage: 'Failed to delete contact',
        ));
      }
    }
  }

  @override
  ContactsState? fromJson(Map<String, dynamic> json) {
    try {
      return ContactsState.fromJson(json);
    } catch (_) {
      return ContactsState(contactsList: ApiResponse.initial());
    }
  }

  @override
  Map<String, dynamic>? toJson(ContactsState state) {
    return state.toJson();
  }
}
