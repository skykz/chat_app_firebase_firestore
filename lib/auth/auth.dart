import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthorizationLogics {

  String _verificationId;
  String _phoneNumber;
  String _accessToken, _refreshToken;
  dynamic customeUserJson;
  FirebaseUser currentUser;
  SharedPreferences prefs;


  Future<void> sendCode(String phoneNumber) async {
    _phoneNumber = phoneNumber;

    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential authCredential) {
      print('VERIFIED');
    };

    final PhoneVerificationFailed verificationFailed =
        (AuthException exception) {
      print('${exception.message}');
    };

    final PhoneCodeAutoRetrievalTimeout autoRetrievalTimeout =
        (String verificationId) {
      this._verificationId = verificationId;
    };

    final PhoneCodeSent smsCodeSent =
        (String verificationId, [int forceCodeResend]) {
      this._verificationId = verificationId;
    };
    print("GOOD I recieved phon number here ____ " + phoneNumber);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        codeAutoRetrievalTimeout: autoRetrievalTimeout,
        codeSent: smsCodeSent,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        timeout: const Duration(seconds: 60),
      );
    } catch (error) {
      print('EXCEPTION: ' + error.message);
    }
  }

  signIn(String smsCode) async {   
    print("heree - step 0 Func starts -------------");

    AuthCredential authCredential = PhoneAuthProvider.getCredential(
        verificationId: this._verificationId, smsCode: smsCode);

    final FirebaseUser user = (await FirebaseAuth.instance
            .signInWithCredential(authCredential)
            .catchError((onError) => print('al-e $onError')))
        ?.user;

    if (user == null) {
      return null;
    }else{
      return user;
    }
          
  }

  doneFirebase(FirebaseUser user,bool selectedItem) async {

      
    print("-- user auth-data -- ${user.email}");    
    print("-- user auth-data -- ${user.getIdToken()}");    
    print("-- user auth-data -- ${user.metadata}");    
    print("-- user auth-data -- ${user.phoneNumber}");

    print("-- user auth-data -- ${user.photoUrl}");
    print("-- user auth-data -- ${user.providerId}");
    print("-- user auth-data -- ${user.uid}");    


      prefs = await SharedPreferences.getInstance();

     if (user != null) {
      // Check is already sign up
      final QuerySnapshot result =
          await Firestore.instance.collection('users').where('id', isEqualTo: user.uid).getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if (documents.length == 0) {
        // Update data to server if new user
        Firestore.instance.collection('users').document(user.uid).setData({
          'phoneNumber': user.phoneNumber,
          'id': user.uid,
          'isTeacher':selectedItem,
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'chattingWith': selectedItem
        });

        // Write data to local
        currentUser = user;
        await prefs.setString('id', user.uid);
        await prefs.setBool('isTeacher', selectedItem);
        await prefs.setString('phoneNumber', user.phoneNumber);        

      } else {
        // Write data to local
        await prefs.setString('id', documents[0]['id']);
        await prefs.setString('phoneNumber', documents[0]['phoneNumber']);
        await prefs.setBool('isTeacher', documents[0]['isTeacher']);

      }
    
    } else {
      Fluttertoast.showToast(msg: " Ошибка при авторизации! ");      
    }

  }
}
