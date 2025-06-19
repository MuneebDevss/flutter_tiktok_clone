import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance/Core/UrlHandler/url_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class UserEntity {
  final String uid;
  final String email;
  final String name;

  UserEntity({
    required this.name,
    required this.uid,
    required this.email,
  });

  // Convert UserEntity to a Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
    };
  }

  // Factory constructor to create a UserEntity from Firestore data
  factory UserEntity.fromMap(Map<String, dynamic> map, String documentId) {
    return UserEntity(
      uid: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
    );
  }
}

// Define the Users Repository
class UsersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionName = "Users";
  final RxString updatingProgress = 'idle'.obs;
  Future<void> updateUserProfile(UserEntity user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Register a new user with email and password
  Future<UserEntity> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a UserEntity
      UserEntity newUser = UserEntity(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
      );

      // Store user in Firestore
      await _firestore
          .collection(_collectionName)
          .doc(newUser.uid)
          .set(newUser.toMap());

      return newUser;
    } catch (e) {
      throw Exception("Failed to register user: $e");
    }
  }

  // Login user with email and password
  Future<UserEntity?> loginUser(String email, String password) async {
    try {
      // Authenticate the user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Retrieve user data from Firestore
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
          .collection(_collectionName)
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        return UserEntity.fromMap(userDoc.data()!, userDoc.id);
      } else {
        throw Exception("User not found in Firestore.");
      }
    } catch (e) {
      throw Exception("Failed to log in user: $e");
    }
  }

  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    await user?.reload(); // Reload user to get the latest state
    return user!.emailVerified;
  }

  // Validate phone number format (Pakistani format)
  bool validatePhoneNumber(String phoneNumber) {
    final regex = RegExp(r'^\+92[0-9]{10}\$');
    return regex.hasMatch(phoneNumber);
  }

  // Validate password format
  bool validatePassword(String password) {
    final regex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@#\$!%*?&])[A-Za-z\d@#\$!%*?&]{8,}\$');
    return regex.hasMatch(password);
  }

  // Retrieve user details by UID
  Future<UserEntity> getUserById(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection(_collectionName).doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        return UserEntity.fromMap(userDoc.data()!, userDoc.id);
      } else {
        return UserEntity(uid: "", email: "", name: "");
      }
    } catch (e) {
      throw Exception("Failed to retrieve user: $e");
    }
  }

  // Logout the user
  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  Future<UserEntity> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await getUserById(user.uid);
    } else {
      return UserEntity(uid: "", email: "", name: "");
    }
  }

  // Changing the currency
  Future<void> updateCurrency(
      String preferedCurrency, String oldCurrency) async {
    try {
      print('$oldCurrency/$preferedCurrency');
      final apiResponse = await UrlHandler.get(
        'https://v6.exchangerate-api.com/v6/0de649711946d6a668e1860a/pair/$oldCurrency/$preferedCurrency',
        '',
      );
      double conversionRate = apiResponse['conversion_rate'];
      final user = _auth.currentUser;

      if (user != null) {
        updatingProgress.value = "Updating Assets";
        await updateAssetsCurrency(user, conversionRate);

        updatingProgress.value = "Updating Budgets";
        await updateBudgetsCurrency(user, conversionRate);

        updatingProgress.value = "Updating Debts";
        await updateDebtsCurrency(user, conversionRate);

        updatingProgress.value = "Updating Business Expenses";
        await updateBusinessExpensesCurrency(user, conversionRate);

        updatingProgress.value = "Updating Expenses";
        await updateExpensesCurrency(user, conversionRate);

        updatingProgress.value = "Updating Income";
        await updateIncomeCurrency(user, conversionRate);

        updatingProgress.value = "Updating Savings";
        await updateSavingsCurrency(user, conversionRate);

        updatingProgress.value = "Updating Tax Calculations";
        await updateTaxCalsCurrency(user, conversionRate);

        updatingProgress.value = "Updating Tax Payments";
        await updateTaxPaymentsCurrency(user, conversionRate);

        updatingProgress.value = "Updating Zakat Payments";
        await updateZakatPaymentsCurrency(user, conversionRate);

        updatingProgress.value = "Updating Tax Returns";
        await updateTaxReturnsCurrency(user, conversionRate);

        updatingProgress.value = "Updating Zakat";
        await updateZakatCurrency(user, conversionRate);

        updatingProgress.value = "Idle";
      }
    } on Exception catch (e) {
      print(e.toString());
      throw Exception("Failed to update currency: $e");
    }
  }

  Future<void> updateAssetsCurrency(User user, double conversionRate) async {
    await _firestore
        .collection('assets')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        double value = data['value'];
        double totalValue = data['totalValue'];
        await doc.reference.update({
          'value': value * conversionRate,
          'totalValue': totalValue * conversionRate,
        });
      }
    });
  }

  Future<void> updateSavingsCurrency(User user, double conversionRate) async {
    await _firestore
        .collection('savings_goals')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        double value = data['savedAmount'];
        double totalValue = data['targetAmount'];
        await doc.reference.update({
          'savedAmount': value * conversionRate,
          'targetAmount': totalValue * conversionRate,
        });
      }
    });
  }

  Future<void> updateZakatCurrency(User user, double conversionRate) async {
    await _firestore
        .collection(
            'zakatCalculations') // Replace with your actual collection name
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();

        double assets = (data['assets'] ?? 0).toDouble();
        double liabilities = (data['liabilities'] ?? 0).toDouble();
        double totalIncome = (data['totalIncome'] ?? 0).toDouble();
        double totalZakat = (data['totalZakat'] ?? 0).toDouble();
        double zakatFromAssets = (data['zakatFromAssets'] ?? 0).toDouble();
        double zakatFromIncome = (data['zakatFromIncome'] ?? 0).toDouble();

        await doc.reference.update({
          'assets': assets * conversionRate,
          'liabilities': liabilities * conversionRate,
          'totalIncome': totalIncome * conversionRate,
          'totalZakat': totalZakat * conversionRate,
          'zakatFromAssets': zakatFromAssets * conversionRate,
          'zakatFromIncome': zakatFromIncome * conversionRate,
        });
      }
    });
  }

  Future<void> updateTaxReturnsCurrency(
      User user, double conversionRate) async {
    await _firestore
        .collection('tax_returns') // Adjust collection name if needed
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();

        double annualIncome = (data['annualIncome'] ?? 0).toDouble();
        double deductionsExemptions =
            (data['deductionsExemptions'] ?? 0).toDouble();
        double refundDue = (data['refundDue'] ?? 0).toDouble();
        double taxLiability = (data['taxLiability'] ?? 0).toDouble();
        double withholdingTaxPaid =
            (data['withholdingTaxPaid'] ?? 0).toDouble();

        await doc.reference.update({
          'annualIncome': annualIncome * conversionRate,
          'deductionsExemptions': deductionsExemptions * conversionRate,
          'refundDue': refundDue * conversionRate,
          'taxLiability': taxLiability * conversionRate,
          'withholdingTaxPaid': withholdingTaxPaid * conversionRate,
        });
      }
    });
  }

  Future<void> updateTaxCalsCurrency(User user, double conversionRate) async {
    await _firestore
        .collection('tax_calulations')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        double businessIncome = data['businessIncome'];
        double deductions = data['deductions'];
        double investmentIncome = data['investmentIncome'];
        double netTax = data['netTax'];
        double rentalIncome = data['rentalIncome'];
        double taxCredits = data['taxCredits'];
        double taxLiability = data['taxLiability'];
        double totalIncome = data['totalIncome'];
        await doc.reference.update({
          'businessIncome': businessIncome * conversionRate,
          'deductions': deductions * conversionRate,
          'investmentIncome': investmentIncome * conversionRate,
          'netTax': netTax * conversionRate,
          'rentalIncome': rentalIncome * conversionRate,
          'taxCredits': taxCredits * conversionRate,
          'taxLiability': taxLiability * conversionRate,
          'totalIncome': totalIncome * conversionRate,
        });
      }
    });
  }

  Future<void> updateDebtsCurrency(User user, double conversionRate) async {
    await _firestore
        .collection('debts')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        double totalValue = data['totalAmount'];
        await doc.reference.update({
          'totalAmount': totalValue * conversionRate,
        });
      }
    });
  }

  Future<void> updateBusinessExpensesCurrency(
      User user, double conversionRate) async {
    await _firestore
        .collection('businessExpenses')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        double value = data['amount'];
        await doc.reference.update({
          'amount': value * conversionRate,
        });
      }
    });
  }

  Future<void> updateExpensesCurrency(User user, double conversionRate) async {
    await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        double value = data['amount'];
        await doc.reference.update({
          'amount': value * conversionRate,
        });
      }
    });
  }

  Future<void> updateIncomeCurrency(User user, double conversionRate) async {
    await _firestore
        .collection('incomeEntries')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        double value = data['amount'];
        await doc.reference.update({
          'amount': value * conversionRate,
        });
      }
    });
  }

  Future<void> updateTaxPaymentsCurrency(
      User user, double conversionRate) async {
    await _firestore
        .collection('tax_payments')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        double value = data['amount'];
        await doc.reference.update({
          'amount': value * conversionRate,
        });
      }
    });
  }

  Future<void> updateZakatPaymentsCurrency(
      User user, double conversionRate) async {
    await _firestore
        .collection('zakatPayments')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        double value = data['amount'];
        await doc.reference.update({
          'amount': value * conversionRate,
        });
      }
    });
  }

  Future<void> updateBudgetsCurrency(User user, double conversionRate) async {
    await _firestore.collection('budgets').get().then((querySnapshot) async {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        double value = data['amount'];
        await doc.reference.update({
          'amount': value * conversionRate,
        });
      }
    });
  }
}
