import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dialog.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_chat_demo/auth/auth.dart';
import 'package:flutter_chat_demo/utils/common_utils.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';


class AuthorizationScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AuthorizationScreenState();
  }
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  int _smsCountdown = 60;
  PageController _pageController = PageController(initialPage: 0);
  Timer _timer;
  AuthorizationLogics _authorizationLogics  = AuthorizationLogics();

  Country _country = Country(isoCode: 'uz', phoneCode: '998');
  String _countryCode = '998'; 
  bool _smsCodeSent = false;
  bool signIn = false;
  FirebaseUser firebaseUser;


  MaskTextInputFormatter _phoneValueController = MaskTextInputFormatter(
      mask: '(###) ###-###',
      filter: {"#": RegExp(r'[0-9]')}); //phone number mask
  TextEditingController _smsCodeValueController = TextEditingController();
  var textEditingController = TextEditingController();
  String pinCode;
  FocusNode focusNode;
  bool hasError = false;
  String currentText;
  bool isTeacher;
  String selectedItem;

  @override
  void initState() {
    focusNode = new FocusNode();
    _countryCode = '+${_country.phoneCode}';    
    super.initState();
  }

  Future<dynamic> checkExistingUser() async {

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    
    if(!sharedPreferences.containsKey("id")){
      print("========= Log in phone Number --- " +
        sharedPreferences.getString("phoneNumber"));

      return false;
    }    
  }

  @override
  Widget build(BuildContext context) {
   
   return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (BuildContext context, AsyncSnapshot spSnapshot) {
        if (spSnapshot.data == ConnectionState.waiting || spSnapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Container(
                child: CupertinoActivityIndicator(
                  radius: 20,
                ),
              ),
            ),
          );
        }         
         String uid = spSnapshot.data.getString('id');      
         bool isTeach = spSnapshot.data.getBool('isTeacher');
         print("----------id == $uid");
         print("----------is teacher == $isTeach");

      if(uid != null)
        return MainScreen(currentUserId: uid,isTeacher:isTeach);

      return SafeArea(
        child:  Scaffold(
            key: _scaffoldKey,
            body: GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              child: ListView(
                children: <Widget>[
                  SizedBox(height: screenAwareHeight(350, context)),
                  Center(
                    child: Text(" Войти ",
                            style: TextStyle(
                                fontSize: screenAwareHeight(75, context),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'RobotoMono',
                                color:Colors.green ))                      
                  ),
                  NotificationListener<OverscrollIndicatorNotification>(
                    onNotification: (overscroll) {
                      overscroll.disallowGlow();
                      return false;
                    },
                    child: SizedBox(
                      height: screenAwareHeight(1400, context),
                      child: PageView(
                        physics: NeverScrollableScrollPhysics(),
                        controller: _pageController,
                        children: <Widget>[
                          _buildPhoneInputPage(),
                          _buildCodeInputPage(),
                          _buildSelectPage()
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )));
      });
  }

//////////////
  Widget _buildPhoneInputPage() {
    return Column(
      children: <Widget>[
        SizedBox(height: screenAwareHeight(90, context)),
        Text('Войти с помощью номера',
            textAlign: TextAlign.start,
            style: TextStyle(
                color: Colors.black,
                fontSize: screenAwareHeight(45, context),
                fontWeight: FontWeight.bold)),
        SizedBox(height: screenAwareHeight(30, context)),
        _buildPhoneNumberInputField(),       
        SizedBox(height: screenAwareHeight(40, context)),       
        SizedBox(height: screenAwareHeight(100, context)),
        RaisedButton(
        onPressed: () => _sendSms(),
        color:Colors.green[300],
        padding: EdgeInsets.only(right: 35,left: 35),
        shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(18.0),
        side: BorderSide(color: Colors.greenAccent)
        ),
        child: Text('Получить код',style: TextStyle(color: Colors.white),),        
      ),                 
      ],
    );
  }

  Widget _buildCodeInputPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: screenAwareHeight(60, context)),
        Text(
          ' Введите код ',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.black,
              fontSize: screenAwareHeight(55, context),
              fontWeight: FontWeight.bold),
        ),
        SizedBox(height: screenAwareHeight(40, context)),
        _buildCodeInputField(),
        SizedBox(height: screenAwareHeight(56, context)),
        Flexible(
            child: SizedBox(
          height: screenAwareHeight(150, context),
          width: screenAwareWidth(650, context),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                ),
                children: _smsCodeSent
                    ? <TextSpan>[
                        TextSpan(text: 'Вы получите SMS код на \n '),
                        TextSpan(
                            text: '+998 ${_phoneValueController.getMaskedText()}',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                            text: ' в течение  $_smsCountdown сек. \n '),
                      ]
                    : <TextSpan>[
                        TextSpan(
                            text: 'Вы можете попробовать еще раз',
                            style: TextStyle(
                                fontSize: screenAwareHeight(45, context),
                                color: Colors.black45)),
                      ]),
          ),
        )),
        SizedBox(height: screenAwareHeight(56, context)),
        //children widget
        _buildCodeInputButtons(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(width: screenAwareWidth(40, context)),
            Text("Повторить",
                style: TextStyle(fontSize: screenAwareHeight(40, context))),
            SizedBox(width: screenAwareWidth(50, context)),
            Padding(
                padding: EdgeInsets.only(left: screenAwareWidth(30, context)),
                child: Text("Подтвердить",
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: screenAwareHeight(40, context))))
          ],
        ),
        SizedBox(height: screenAwareHeight(30, context)),
      ],
    );
  }

  Widget _buildPhoneNumberInputField() {
    return SizedBox(
      width: screenAwareWidth(750, context),
      child: Container(
          padding: EdgeInsets.only(left: 15.0),
          decoration: BoxDecoration(
              color: Color.fromRGBO(235, 235, 240, 1),
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          child: TextField(
            cursorColor:Colors.blue,
            cursorRadius: Radius.circular(10.0),
            cursorWidth: 3.0,
            inputFormatters: [_phoneValueController],
            keyboardType: TextInputType.phone,
            controller: textEditingController,
            decoration: InputDecoration(
              hintStyle: TextStyle(
                  fontSize: screenAwareHeight(55, context), color: Colors.grey),
              hintText: '(777) 777 777',
              border: InputBorder.none,
              prefixIcon: GestureDetector(
                child: Container(
                  alignment: Alignment.center,
                  width: screenAwareWidth(250.0, context),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: CountryPickerUtils.getDefaultFlagImage(_country),
                      ),
                      SizedBox(width: screenAwareWidth(5, context)),
                      Expanded(
                        flex: 4,
                        child: Text(
                          _countryCode,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenAwareHeight(55, context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: _openCountryPickerDialog,
              ),
            ),
            style: TextStyle(fontSize: screenAwareHeight(55, context)),
          )),
    );
  }

  Widget _buildCodeInputField() {
    return Center(
        child: Padding(
      padding: EdgeInsets.only(left: 10.0, right: 10.0),
      child: PinCodeTextField(
        length: 6,
        autoFocus: true,
        obsecureText: false,
        borderWidth: 2.0,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        textStyle: TextStyle(fontSize: 25),
        animationType: AnimationType.fade,
        shape: PinCodeFieldShape.underline,
        animationDuration: Duration(milliseconds: 250),
        fieldHeight: 45,
        fieldWidth: 40,
        activeColor: Colors.black,
        backgroundColor: Colors.white,
        textInputType: TextInputType.number,
        onChanged: (value) {
          setState(() {
            currentText = value;
            print(currentText.length);
            if (currentText.length == 6)
              pinCode = currentText;
            else
              pinCode = currentText;
          });
        },
      ),
    ));
  }

  Widget _buildCodeInputButtons() {
    return SizedBox(
      width: screenAwareWidth(480, context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            height: screenAwareHeight(180, context),
            width: screenAwareWidth(180, context),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
            child: FloatingActionButton(
              highlightElevation: 5,
              backgroundColor: (_smsCodeSent ? Colors.grey : Colors.green),
              elevation: 1,
              heroTag: "again",
              child: Icon(
                Icons.refresh,
                size: screenAwareHeight(100, context),
              ),
              onPressed: _smsCodeSent
                  ? null
                  : () => _pageController.animateToPage(0,
                      duration: Duration(milliseconds: 450),
                      curve: Curves.ease),
              tooltip: "Повторить",
            ),
          ),
          Container(
              height: screenAwareHeight(180, context),
              width: screenAwareWidth(180, context),
              decoration: BoxDecoration(
                shape: BoxShape.circle,                
              ),
              child: FloatingActionButton(
                backgroundColor:Colors.green,
                elevation: 1,
                heroTag: "confirm",
                child: Icon(
                  Icons.keyboard_arrow_right,
                  size: screenAwareHeight(110, context),
                ),
                onPressed: () =>
                    // sending verification code from firebase to firebase and Backend
                    _doLogin(),
              )),
        ],
      ),
    );
  }

  _buildSelectPage(){
     return Column(
      children: <Widget>[
        SizedBox(height: screenAwareHeight(90, context)),
        Text('Выберите свою роль',
            textAlign: TextAlign.start,
            style: TextStyle(
                color: Colors.black,
                fontSize: screenAwareHeight(45, context),
                fontWeight: FontWeight.bold)),                
                DropdownButton<String>(
                  isExpanded: true,
                  items: <String>['Учитель', 'Ученик'].map((String value) {
                    return  DropdownMenuItem<String>(
                      value: value,              
                      child:  ListTile(
                            contentPadding:
                                EdgeInsets.only(bottom: 10.0),
                            title: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                                SizedBox(
                                  width: screenAwareWidth(
                                      30, context),
                                ),
                                Text("$value")
                              ],
                            )),                                               
                    );
                  }).toList(),
                  hint: Text(" Выберите "),
                  value: selectedItem??null,
                  icon: Icon(Icons.account_circle),
                  onChanged: (val) {

                     if(val == "Ученик") 
                      setState(() {
                        selectedItem = val;
                        isTeacher = false;
                      });
                      else
                      setState(() {
                        selectedItem = val;
                        isTeacher = true;
                      });
                  },
        ),               
        SizedBox(height: screenAwareHeight(100, context)),
        RaisedButton(
        onPressed: () => _doneFunc(isTeacher),
        color:Colors.green[200],
        child: Text('Готово'),        
      ),                 
      ],
    );     
  }
  ////////////////////////////////////////////////////////////////////
  // UI Functions
  ////////////////////////////////////////////////////////////////////

  void _openCountryPickerDialog() {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: const Color(0xFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        child: CountryPickerDialog(
          divider: Divider(),
          isDividerEnabled: true,
          searchCursorColor: Colors.green,
          searchInputDecoration: InputDecoration(
            hintText: 'Поиск...',
          ),
          isSearchable: true,
          onValuePicked: (Country country) => setState(() {
            _country = country;
            _countryCode = '+${country.phoneCode}';
          }),
          title: Text('Выберите страну:'),
          itemBuilder: (Country country) => Container(
            child: Row(
              children: <Widget>[
                CountryPickerUtils.getDefaultFlagImage(country),
                Text(
                  ' +${country.phoneCode} ${country.isoCode}',
                  style: TextStyle(
                      fontSize: screenAwareHeight(37, context),
                      color: Theme.of(context).textTheme.body2.color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

   _doneFunc(bool currentSelect){
    print("$currentSelect");
    
    if (currentSelect ==  null) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          duration: Duration(seconds: 1),
          backgroundColor: Colors.redAccent,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.error_outline),
              SizedBox(width: screenAwareWidth(15, context)),
              Expanded(child: Text('Пожалуйста, Выберите роль'))
            ],
          ),
        ),
      );
    } else {         
      _authorizationLogics.doneFirebase(firebaseUser,currentSelect);
      Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MainScreen(currentUserId: firebaseUser.uid,isTeacher:currentSelect)));
    }
  }

  void _sendSms() {
    FocusScope.of(context).requestFocus(FocusNode());
    String formattedPhone = _phoneValueController
        .getUnmaskedText()
        .replaceAll(RegExp(r'\s\b|\b\s'), '');
    String phoneNumber = _countryCode + formattedPhone;

    print(phoneNumber + ' ' + phoneNumber.length.toString());
    print("${phoneNumber.length}");
    if (phoneNumber.length < 11) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          duration: Duration(seconds: 1),
          backgroundColor: Colors.redAccent,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.error_outline),
              SizedBox(width: screenAwareWidth(15, context)),
              Expanded(child: Text('Введите действующий номер телефона'))
            ],
          ),
        ),
      );
    } else {
      setState(() {
        _smsCodeSent = true;
      });
      _pageController.animateToPage(1,
          duration: Duration(milliseconds: 850), curve: Curves.easeInCubic);
      _startSmsTimer();
      _authorizationLogics.sendCode(phoneNumber);
    }
  }

  // let's registrate or auth user
  _doLogin() async {
    if (pinCode == null || pinCode.length != 6) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          duration: Duration(seconds: 1),
          backgroundColor: Colors.redAccent,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.error_outline),
              SizedBox(width: screenAwareWidth(15, context)),
              Expanded(child: Text('Пожалуйста введите код правильно!'))
            ],
          ),
        ),
      );
    } else {
      firebaseUser = await _authorizationLogics.signIn(pinCode);

      if (firebaseUser == null) {
        _scaffoldKey.currentState.showSnackBar(
          SnackBar(
            duration: Duration(seconds: 7),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                _scaffoldKey.currentState.hideCurrentSnackBar();
              },
            ),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.error_outline),
                SizedBox(width: screenAwareWidth(15, context)),
                Expanded(child: Text('Неправильный SMS-код'))
              ],
            ),
          ),
        );
      } else {
          _pageController.animateToPage(2,
          duration: Duration(milliseconds: 850), curve: Curves.easeInCubic);              
      }
    }
  }

  void _startSmsTimer() {
    if (mounted) {
      _timer = Timer.periodic(
        Duration(seconds: 1),
        (Timer timer) => setState(() {
          if (_smsCountdown < 1) {
            _smsCountdown = 60;
            _timer.cancel();
            setState(() {
              _smsCodeSent = false;
              //_codeValueController = null;
            });
          } else {
            _smsCountdown = _smsCountdown - 1;
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _phoneValueController ?? null;
    _timer?.cancel();
    _smsCodeValueController?.clear();
    textEditingController?.clear();
  }
}
