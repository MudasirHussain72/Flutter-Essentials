import 'package:flutter/material.dart';

class LoginController with ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;
  setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  // google sig  in for mobile
  Future<void> loginWithGoogle(BuildContext context) async {
    setLoading(true);
    // try {
    //   //To check internet connectivity
    //   await InternetAddress.lookup('firebase.google.com');
    //   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    //   final GoogleSignInAuthentication? googleAuth =
    //       await googleUser?.authentication;
    //   if (googleAuth == null) {
    //     return;
    //   }
    //   final credential = GoogleAuthProvider.credential(
    //     accessToken: googleAuth.accessToken,
    //     idToken: googleAuth.idToken,
    //   );
    //   await auth.signInWithCredential(credential).then((value) async {
    //     SessionController().userId = value.user!.uid.toString();
    //     if (await userExists()) {
    //       Navigator.pushNamedAndRemoveUntil(
    //           context, RouteName.dashboardView, (route) => false);
    //       Utils.toastMessage("User login successfully");
    //       setLoading(false);
    //     } else {
    //       firestore.doc(value.user!.uid.toString()).set({
    //         'uid': value.user!.uid.toString(),
    //         'email': value.user!.email.toString(),
    //         'onlineStatus': 'noOne',
    //         'phone': '',
    //         'city': '',
    //         'address': '',
    //         'userName': value.user!.displayName,
    //         'profileImage': value.user!.photoURL,
    //         'userLocationLat': '',
    //         'userLocationLong': '',
    //       }).then((value) {
    //         // Navigator.pushNamed(context, RouteName.dashboardView);
    //         Navigator.pushNamedAndRemoveUntil(
    //             context, RouteName.dashboardView, (route) => false);
    //         Utils.toastMessage("User login successfully");
    //         setLoading(false);
    //       });
    //     }
    //   }).onError((error, stackTrace) {
    //     setLoading(false);
    //     Utils.toastMessage(error.toString());
    //   });
    // } catch (e) {
    //   setLoading(false);
    //   Utils.toastMessage(e.toString());
    //   if (kDebugMode) {
    //     print("Error: $e");
    //   }
    //   return;
    // }
  }

  //for checking user exists or not?
  // static Future<bool> userExists(String uid) async {
  //   return (await FirebaseFirestore.instance.collection('users').doc(uid).get())
  //       .exists;
  // }

  // // signInWithGoogle for web
  // Future<User?> signInWithGoogle(BuildContext context) async {
  //   // Initialize Firebase
  //   await Firebase.initializeApp();
  //   User? user;
  //   FirebaseAuth auth = FirebaseAuth.instance;
  //   // The `GoogleAuthProvider` can only be
  //   // used while running on the web
  //   GoogleAuthProvider authProvider = GoogleAuthProvider();

  //   try {
  //     final UserCredential userCredential =
  //         await auth.signInWithPopup(authProvider);
  //     user = userCredential.user;
  //   } catch (e) {
  //     print(e);
  //   }

  //   if (user != null) {
  //     bool userAlreadyExists = await userExists(user.uid);
  //     if (!userAlreadyExists) {
  //       UserModel userModel = UserModel(
  //         name: user.displayName,
  //         email: user.email,
  //         uid: user.uid,
  //         role: 'player',
  //         photo: user.photoURL,
  //       );

  //       // saving user data in database
  //       await SignUpRepository()
  //           .createUser(user.uid, userModel)
  //           .then((value) async {
  //         CollectionReference ref =
  //             FirebaseFirestore.instance.collection('users');
  //         await ref.doc(user!.uid).get().then((value) async {
  //           setLoading(false);
  //           await SessionController.saveUserInPreference(
  //               value.data(), value['role']);
  //           await SessionController.getUserFromPreference()
  //               .then((value) => Navigator.pushAndRemoveUntil(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => HomeScreen(),
  //                   ),
  //                   (route) => false));
  //         });
  //       });
  //     } else {
  //       CollectionReference ref =
  //           FirebaseFirestore.instance.collection('users');
  //       await ref.doc(user.uid).get().then((value) async {
  //         setLoading(false);
  //         await SessionController.saveUserInPreference(
  //             value.data(), value['role']);
  //         await SessionController.getUserFromPreference()
  //             .then((value) => Navigator.pushAndRemoveUntil(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => HomeScreen(),
  //                 ),
  //                 (route) => false));
  //       });
  //     }
  //   }
  //   return user;
  // }
}
