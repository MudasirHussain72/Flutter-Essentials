import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_app/bloc/contacts_bloc.dart';
import 'package:contacts_app/model/contact.dart';
import 'package:contacts_app/remote/response/api_response.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late ContactsBloc contactsBloc;

  @override
  void initState() {
    super.initState();
    contactsBloc = ContactsBloc()..add(FetchContacts());
  }

  Future<void> _refreshContacts() async {
    contactsBloc.add(FetchContacts());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _showEditDialog(Contact contact) async {
    final TextEditingController nameController =
        TextEditingController(text: contact.name);
    final TextEditingController numberController =
        TextEditingController(text: contact.number);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: numberController,
                decoration: const InputDecoration(labelText: 'Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () {
                final updatedContact = Contact(
                  id: contact.id,
                  name: nameController.text,
                  number: numberController.text,
                );
                contactsBloc.add(UpdateContact(contact: updatedContact));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => contactsBloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Contacts'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: BlocBuilder<ContactsBloc, ContactsState>(
              builder: (context, state) {
                if (state.isSyncing) {
                  return const LinearProgressIndicator();
                } else {
                  return Container();
                }
              },
            ),
          ),
        ),
        body: BlocBuilder<ContactsBloc, ContactsState>(
          builder: (context, state) {
            switch (state.contactsList.status) {
              case Status.loading:
                return const Center(child: CircularProgressIndicator());
              case Status.completed:
                final contacts = state.contactsList.data ?? [];
                return RefreshIndicator(
                  onRefresh: _refreshContacts,
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        leading: InkWell(
                          onDoubleTap: () {
                            _showEditDialog(contact); // Open dialog for editing
                          },
                          child: CircleAvatar(
                            radius: 24,
                            child: Text(
                              contact.name
                                  .substring(0, 1)
                                  .toString()
                                  .toUpperCase(),
                            ),
                          ),
                        ),
                        title: Text(
                          contact.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        subtitle: Text(
                          contact.number,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            contactsBloc
                                .add(DeleteContact(contactId: contact.id));
                          },
                        ),
                      );
                    },
                  ),
                );
              case Status.error:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 50, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to fetch contacts.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          contactsBloc.add(FetchContacts());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              default:
                return Container();
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final faker = Faker();
            final newContact = Contact(
              id: FirebaseFirestore.instance.collection('contacts').doc().id,
              name: faker.person.name(),
              number: faker.phoneNumber.us(),
            );
            contactsBloc.add(AddContact(contact: newContact));
          },
          tooltip: 'Add Contact',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
