import 'dart:convert';
import 'dart:io';

import 'package:bubbly/api/api_service.dart';
import 'package:bubbly/utils/colors.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsService {
  static final ContactsService _instance = ContactsService._internal();

  factory ContactsService() => _instance;

  ContactsService._internal();

  /// Request contacts permission and handle the result
  /// This is specifically designed for one-time sync
  Future<bool> requestContactPermission(BuildContext context) async {
    print('⚡ ContactsService: Requesting permission for one-time sync...');
    
    // First try using FlutterContacts permission API
    bool granted = await FlutterContacts.requestPermission(readonly: true);
    print('⚡ ContactsService: Permission ${granted ? "GRANTED" : "DENIED"}');
    
    if (granted) {
      return true;
    } else {
      // Show a dialog explaining why we need contacts and that this is a one-time sync
      if (context.mounted) {
        print('⚡ ContactsService: Showing one-time sync permission dialog');
        await showDialog(
          context: context,
          barrierDismissible: false, // Force user to make a choice
          builder: (context) => AlertDialog(
            title: Text('One-Time Contact Sync'),
            content: Text('We need to sync your contacts just once to help you find friends using this app. We will never ask for this permission again. Your privacy is important to us.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Not Now'),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ColorRes.colorTheme, ColorRes.colorPink],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Text(
                    'Allow Access',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        print('⚡ ContactsService: Context not mounted, cannot show dialog');
      }
      return false;
    }
  }

  /// Fetch contacts  /// Generate a CSV file from contacts
  Future<String?> generateContactsCsv() async {
    try {
      // Check if contacts permission is granted - force permission dialog
      bool permissionGranted = await FlutterContacts.requestPermission(readonly: true);
      
      if (!permissionGranted) {
        print('⚡ ContactsService: Contacts permission not granted');
        return null;
      }
      
      // Get all contacts (with full info)
      List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
        withThumbnail: false,
        withAccounts: false,
        withGroups: false,
      );
      
      // Create CSV content
      final StringBuffer csvContent = StringBuffer();
      
      // Add header
      csvContent.writeln('Name,Phone,Email');
      
      // If no contacts found, add some sample data to prevent empty CSV
      if (contacts.isEmpty) {
        csvContent.writeln('No contacts found on device');
      } else {
        // Process each contact
        for (final contact in contacts) {
          // Get name (safely handle nulls and commas)
          String name = '${contact.name.first} ${contact.name.last}';
          name = name.trim().replaceAll(',', ' ');
          if (name.isEmpty) name = 'Unknown';
          
          // Get primary phone (safely handle nulls and commas)
          String phone = '';
          if (contact.phones.isNotEmpty) {
            phone = contact.phones.first.number.replaceAll(',', '');
          }
          
          // Get primary email (safely handle nulls and commas)
          String email = '';
          if (contact.emails.isNotEmpty) {
            email = contact.emails.first.address.replaceAll(',', '');
          }
          
          // Add to CSV
          csvContent.writeln('$name,$phone,$email');
        }
      }
      
      // Save to file
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/contacts.csv';
      final File file = File(path);
      await file.writeAsString(csvContent.toString());
      
      return path;
    } catch (e) {
      print('Error generating contacts CSV: $e');
      return null;
    }
  }

  Future<bool> processAndUploadContacts(BuildContext context) async {
    try {
      print('⚡ ContactsService: Starting one-time contact sync process...');
      
      // Check if the context is valid before proceeding
      if (!context.mounted) {
        print('⚡ ContactsService: Context not mounted, cannot process contacts');
        return false;
      }
      
      // Request permission first - use a more direct approach with a better explanation
      print('⚡ ContactsService: Requesting permission (one-time only)...');
      bool hasPermission = await requestContactPermission(context);
      print('⚡ ContactsService: Permission result: $hasPermission');
      
      if (!hasPermission) {
        print('⚡ ContactsService: Permission denied, aborting contact sync');
        // Return false without showing an error message
        // This avoids disturbing users who choose not to sync contacts
        return false;
      }
      
      // Show a quick toast to indicate the sync has started (more subtle)
      if (context.mounted) {
        print('⚡ ContactsService: Showing sync started message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Syncing contacts'),
            duration: Duration(seconds: 2),
            backgroundColor: ColorRes.colorTheme,
          ),
        );
      }
      
      // Generate CSV file
      print('⚡ ContactsService: Generating CSV file...');
      String? csvPath = await generateContactsCsv();
      print('⚡ ContactsService: CSV path: $csvPath');
      
      if (csvPath == null) {
        print('⚡ ContactsService: Failed to generate CSV, aborting');
        return false;
      }
      
      // Upload the CSV file
      print('⚡ ContactsService: Uploading CSV file to server...');
      bool success = await ApiService().uploadContactsCsv(csvPath);
      print('⚡ ContactsService: Upload result: $success');
      
      // Show success message if upload was successful and context is still valid
      // Use the gradient styling as preferred by the user (colorTheme to colorPink)
      if (success && context.mounted) {
        print('⚡ ContactsService: Showing success notification');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorRes.colorTheme, ColorRes.colorPink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Contacts synced successfully!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      }
      
      return success;
    } catch (e) {
      print('⚡ ContactsService: Error processing contacts: $e');
      return false;
    }
  }
}
