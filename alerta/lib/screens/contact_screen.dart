import 'package:CareAlert/models/user.model.dart';
import 'package:CareAlert/providers/user.provider.dart';
import 'package:CareAlert/screens/add_contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  static const String routeName = '/contact-screen';

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late UserProvider _userProvider;

  void _userListener() {
    setState(() {
      // Trigger rebuild when user changes
    });
  }

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserProvider>(context, listen: false)
      ..getProfile()
      ..addListener(_userListener);
  }

  @override
  void dispose() {
    _userProvider.removeListener(_userListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    
    // Get the contacts list - adjust this based on your User model
    // Options: user.contacts, user.emergencyContacts, user.trustedContacts
    final contacts = user.trustedContacts ?? []; // CHANGE THIS TO MATCH YOUR MODEL

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No contacts available. Please add trusted contacts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AddContactScreen.routeName,
                          );
                        },
                        child: const Text('Add Contact'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade100,
                                child: Text(
                                  contact.name != null && contact.name!.isNotEmpty
                                      ? contact.name![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              title: Text(
                                contact.name ?? 'No name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(contact.phone ?? 'No phone'),
                                    ],
                                  ),
                                  if (contact.email != null &&
                                      contact.email!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.email,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(contact.email!),
                                      ],
                                    ),
                                  if (contact.relationship != null &&
                                      contact.relationship!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(contact.relationship!),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AddContactScreen.routeName,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Add Contact'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }
}