import 'package:finance/Core/HelpingFunctions/widgets/profile_controller.dart';
import 'package:finance/Features/Auth/Domain/Repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  final UserEntity currentUser;
  final UsersRepository authRepository;

  const EditProfilePage({
    super.key,
    required this.currentUser,
    required this.authRepository,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController currencyController;
  late String oldCurrency;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentUser.name);
    emailController = TextEditingController(text: widget.currentUser.email);
    
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    currencyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      final updatedUser = UserEntity(
        uid: widget.currentUser.uid,
        name: nameController.text,
        email: emailController.text,
      );

      await widget.authRepository.updateUserProfile(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Get.find<ProfileController>().user = updatedUser; // Update directly
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        print(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Obx(() {
        if (widget.authRepository.updatingProgress.value != 'idle') {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${widget.authRepository.updatingProgress.value}   ",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    trackGap: 0.2,
                    padding: EdgeInsets.all(0.1),
                    constraints: BoxConstraints(
                        maxWidth: 150, minWidth: 20, minHeight: 20),
                  ),
                ],
              ),
              Text(
                'Please Wait this Can take a while',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.apply(fontSizeDelta: -2, color: Colors.blue),
              )
            ],
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              // const SizedBox(height: 16),
              // TextField(
              //   controller: emailController,
              //   decoration: const InputDecoration(
              //     labelText: 'Email',
              //     border: OutlineInputBorder(),
              //   ),
              //   keyboardType: TextInputType.emailAddress,
              // ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CurrencyAutocompleteScreen(
                currencyController: currencyController,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text('Update Profile'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class CurrencyAutocompleteScreen extends StatelessWidget {
  // List of world currencies (for demonstration purposes)
  final List<String> worldCurrencies = [
    'INR - Indian Rupee',
    'PKR - Pakistani Rupee',
    'BDT - Bangladeshi Taka',
    'NPR - Nepalese Rupee',
    'AED - United Arab Emirates Dirham',
    'SAR - Saudi Riyal',
    'KWD - Kuwaiti Dinar',
    'OMR - Omani Rial',
    'QAR - Qatari Rial',
    'BHD - Bahraini Dinar',
    'JOD - Jordanian Dinar',
    'LBP - Lebanese Pound',
    'USD - United States Dollar'
  ];

  final TextEditingController currencyController;
  CurrencyAutocompleteScreen({super.key, required this.currencyController});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return worldCurrencies; // Return the entire list if the input is empty
        } else {
          // Filter the list of currencies based on user input
          return worldCurrencies.where((currency) => currency
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()));
        }
      },
      onSelected: (String selection) {
        if (selection.length > 2) {
          currencyController.text = selection.substring(
              0, 3); // Set the selected currency to the controller
        } else {
          currencyController.text = selection;
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (value.length > 2) {
                currencyController.text = value.substring(0, 3);
              }
            }
          },
          decoration: InputDecoration(
            hintText: 'Select a Currency', // Hint text for the input field
            // or you can use labelText instead:
            // labelText: 'Currency', // Label text above the input field
          ),
        );
      },
    );
  }
}
