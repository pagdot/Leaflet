import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:potato_notes/internal/methods.dart';

import 'package:potato_notes/internal/app_info.dart';
import 'package:potato_notes/internal/note_helper.dart';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

List<int> reminderList = List<int>();

class ModifyNotesRoute extends StatefulWidget {
  Note note = Note();
  ModifyNotesRoute(Note note) {
    this.note = note;
  }

  @override
  _ModifyNotesState createState() => new _ModifyNotesState(note);
}

class _ModifyNotesState extends State<ModifyNotesRoute> with SingleTickerProviderStateMixin {
  int noteId;
  String noteTitle = "";
  String noteContent = "";
  int noteIsStarred = 0;
  int noteDate = 0;
  int noteColor;
  String noteImagePath;
  int noteIsList = 0;
  String noteListParseString;
  String noteReminders;

  _ModifyNotesState(Note note) {
    this.noteId = note.id;
    this.noteTitle = note.title;
    this.noteContent = note.content;
    this.noteIsStarred = note.isStarred;
    this.noteDate = note.date;
    this.noteColor = note.color;
    this.noteImagePath = note.imagePath;
    this.noteIsList = note.isList;
    this.noteListParseString = note.listParseString;
    this.noteReminders = note.reminders;
  }

  NoteHelper noteHelper = new NoteHelper();
  static GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  List<ListPair> checkList = List<ListPair>();

  TextEditingController entryTextController = TextEditingController(text: "");
  List<TextEditingController> textControllers = List<TextEditingController>();
  AnimationController _controller;

  void noteIdInit() async {
    noteId = noteId == null ? await noteIdSearcher() : noteId;
  }

  void reminderListPopulater() {
    reminderList.clear();
    if(noteReminders != null) {
      List<String> reminderListString = noteReminders.split(":");
      reminderListString.forEach((item) {
        String milliseconds = item != "" ? item : null;
        if(milliseconds != null) {
          reminderList.add(int.parse(milliseconds));
        }
      });
      noteReminders = reminderList.join(":");
    }
  }

  void noteRemindersUpdater() {
    noteReminders = reminderList.join(":");
  }

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(saveAndPop);
    _controller = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    reminderList.clear();
    noteIdInit();
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(saveAndPop);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController titleController = TextEditingController(text: noteTitle);
    TextEditingController contentController = TextEditingController(text: noteContent);

    titleController.selection = TextSelection.collapsed(offset: noteTitle.length);
    contentController.selection = TextSelection.collapsed(offset: noteContent.length);

    reminderListPopulater();

    Brightness getBarsColorFromNoteColor() {
      double noteColorBrightness = Color(noteColor).computeLuminance();
      
      if(noteColorBrightness > 0.5) {
        return Brightness.dark;
      } else {
        return Brightness.light;
      }
    }

    Brightness systemBarsIconBrightness = Theme.of(context).brightness == Brightness.dark ?
        Brightness.light :
        Brightness.dark;

    changeSystemBarsColors(noteColor == null ? Theme.of(context).cardColor : Color(noteColor),
        noteColor == null ? Theme.of(context).cardColor : Color(noteColor),
        noteColor == null ? systemBarsIconBrightness : getBarsColorFromNoteColor());
    
    Color getElementsColorBasedOnThemeContext() {
      Color colorToReturn;
      if(noteColor == null) {
        Theme.of(context).brightness == Brightness.dark ?
            colorToReturn = Colors.white :
            colorToReturn = Colors.black;
      } else {
        double noteColorBrightness = Color(noteColor).computeLuminance();
      
        if(noteColorBrightness > 0.5) {
          colorToReturn = Colors.black;
        } else {
          colorToReturn = Colors.white;
        }
      }

      return colorToReturn;
    }

    final appInfo = Provider.of<AppInfoProvider>(context);

    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: IconThemeData(
          color: getElementsColorBasedOnThemeContext()
        ),
        textTheme: TextTheme(
          subhead: Theme.of(context).textTheme.subhead.copyWith(
            color: getElementsColorBasedOnThemeContext(),
          ),
        ),
        inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
          hintStyle: TextStyle(
            color: HSLColor.fromColor(getElementsColorBasedOnThemeContext())
                .withAlpha(0.5)
                .toColor(),
          ),
        ),
        unselectedWidgetColor: HSLColor.fromColor(getElementsColorBasedOnThemeContext())
            .withAlpha(0.5)
            .toColor(),
        scaffoldBackgroundColor: noteColor == null ? Theme.of(context).cardColor : Color(noteColor),
        accentColor: getElementsColorBasedOnThemeContext(),
        dividerColor: HSLColor.fromColor(getElementsColorBasedOnThemeContext())
            .withAlpha(0.12)
            .toColor(),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: noteColor == null ? Theme.of(context).cardColor : Color(noteColor),
        ),
        buttonTheme: ButtonThemeData(
          textTheme: ButtonTextTheme.accent,
          hoverColor: appInfo.mainColor
        ),
      ),
      child: Scaffold(
        key: scaffoldKey,
        body: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Container(
                height: 70,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          saveAndPop(true);
                        },
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.add_alert),
                        onPressed: () async {
                          final appInfo = Provider.of<AppInfoProvider>(context);
                          appInfo.date = null;
                          appInfo.time = null;
                          showAddReminderScrollableBottomSheet(context);
                        },
                      ),
                      IconButton(
                        icon: noteIsList == 0 ?
                            Icon(Icons.check_circle_outline) :
                            Icon(Icons.check_circle),
                        onPressed: () => setState(() {
                          if(noteIsList == 0) {
                            noteIsList = 1;
                            checkList.clear();
                            List<String> initialList = noteContent.split("\n");
                            initialList.forEach((item) {
                              checkList.add(ListPair(checkValue: 0, title: item));
                            });
                            updateListParseString();
                          } else {
                            noteIsList = 0;
                            List<String> titleList = List<String>();
                            for(int i = 0; i < checkList.length; i++) {
                              titleList.add(checkList[i].title);
                            }
                            noteContent = titleList.join("\n");
                            checkList.clear();
                          }
                        }),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_a_photo),
                        onPressed: () => showImageActionDialog(context),
                      ),
                      colorChooserCircle(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70),
              child: ListView(
                children: <Widget>[
                  Visibility(
                    visible: noteImagePath != null,
                    child: noteImagePath == null ?
                        Container() :
                        Image(
                          image: FileImage(File(noteImagePath)),
                        ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: titleController,
                      decoration: InputDecoration(hintText: 'Title', border: InputBorder.none),
                      onChanged: (text) {
                        noteTitle = text;
                      },
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: noteIsList == 1,
                    child: Column(
                      children: checkListBuilder(),
                    ),
                  ),
                  Visibility(
                    visible: reminderList.length > 0,
                    child: Column(
                      children: reminderListBuilder(),
                    ),
                  ),
                  Visibility(
                    visible: noteIsList == 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: contentController,
                        decoration: InputDecoration(hintText: 'Content', border: InputBorder.none),
                        onChanged: (text) {
                          noteContent = text;
                        },
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: noteImagePath != null ? 3 : 32,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> checkListBuilder() {
    checkList.clear();
    List<Widget> widgets = List<Widget>();
    List<Widget> checkedWidgets = List<Widget>();
    final appInfo = Provider.of<AppInfoProvider>(context);

    Color getElementsColorBasedOnThemeContext() {
      Color colorToReturn;
      if(noteColor == null) {
        Theme.of(context).brightness == Brightness.dark ?
            colorToReturn = Colors.white :
            colorToReturn = Colors.black;
      } else {
        double noteColorBrightness = Color(noteColor).computeLuminance();
      
        if(noteColorBrightness > 0.5) {
          colorToReturn = Colors.black;
        } else {
          colorToReturn = Colors.white;
        }
      }

      return colorToReturn;
    }

    if(noteListParseString != null) {
      List<String> rawList = noteListParseString.split("\'..\'");

      for(int i = 0; i < rawList.length; i++) {
        List<dynamic> rawStrings = rawList[i].split("\',,\'");

        int checkValue = rawStrings[0] == "" ? 0 : int.parse(rawStrings[0]);
        try{
          checkList.add(ListPair(checkValue: checkValue, title: rawStrings[1]));
        } on RangeError {
          
        }
      }
    }

    if(checkList.length > 0) {
      textControllers.clear();
      for(int i = 0; i < checkList.length; i++) {
        textControllers.add(TextEditingController(text: checkList[i].title.toString()));
        textControllers[i].selection = TextSelection.collapsed(offset: checkList[i].title.length);
        Widget currentWidget = ListTile(
          leading: Checkbox(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: noteColor != null ? getElementsColorBasedOnThemeContext() : appInfo.mainColor,
            checkColor: noteColor == null ? Theme.of(context).cardColor : Color(noteColor),
            value: checkList[i].checkValue == 1,
            onChanged: (value) {
              if(value) {
                setState(() => checkList[i].checkValue = 1);
              } else setState(() => checkList[i].checkValue = 0);
              setState(() => updateListParseString());
            },
          ),
          title: TextField(
            controller: textControllers[i],
            decoration: InputDecoration(border: InputBorder.none),
            onTap: () {
              textControllers[i].selection = TextSelection.collapsed(offset: checkList[i].title.length);
            },
            onChanged: (text) {
              textControllers[i].text = text;
              textControllers[i].selection = TextSelection.collapsed(offset: text.length);
              setState(() {
                checkList[i].title = text;
                updateListParseString();
              });
            },
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              color: checkList[i].checkValue == 1 ?HSLColor.fromColor(getElementsColorBasedOnThemeContext())
                  .withAlpha(0.4)
                  .toColor() : null,
              decoration: checkList[i].checkValue == 1 ? TextDecoration.lineThrough : null,
              decorationColor: checkList[i].checkValue == 1 ? HSLColor.fromColor(getElementsColorBasedOnThemeContext())
                  .withAlpha(0.4)
                  .toColor() : null,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              checkList.removeAt(i);
              textControllers.removeAt(i);
              setState(() => updateListParseString());
            },
          ),
        );

        if(checkList[i].checkValue == 0) {
          widgets.add(
            currentWidget
          );
        } else {
          checkedWidgets.add(
            currentWidget
          );
        }
      }
    }

    widgets.add(
      ListTile(
        leading: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.add),
        ),
        title: TextField(
          controller: entryTextController,
          decoration: InputDecoration(border: InputBorder.none, hintText: "Entry"),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (text) {
            //entryTextController.selection = TextSelection.collapsed(offset: text.length);
          },
          onSubmitted: (text) {
            checkList.add(ListPair(checkValue: 0, title: text));
            textControllers.add(TextEditingController(text: text));
            setState(() {
              updateListParseString();
              entryTextController.text = "";
            });
          },
        ),
      ),
    );

    Animatable<double> _halfTween = Tween<double>(begin: 0.0, end: 0.5);
    Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
    Animation<double> _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));

    _controller.value = 1.0;

    if(checkedWidgets.length > 0) {
      widgets.add(
        ExpansionTile(
          initiallyExpanded: true,
          title: Text(checkedWidgets.length.toString() + " checked entries"),
          children: checkedWidgets,
          leading: RotationTransition(
            turns: _iconTurns,
            child: const Icon(Icons.expand_more),
          ),
          onExpansionChanged: (expanded) {
            if(expanded) {
              _controller.forward();
            } else _controller.reverse();
          },
          trailing: Opacity(
            opacity: 0,
            child: Icon(Icons.expand_more),
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> reminderListBuilder() {
    List<Widget> widgets = List<Widget>();

    for(int i = 0; i < reminderList.length; i++) {
      widgets.add(
        ListTile(
          leading: Icon(Icons.timer),
          title: Text(
            DateFormat("d MMMM yyyy, HH:mm").format(DateTime.fromMillisecondsSinceEpoch(reminderList[i]))
          ),
          onTap: () {
            showAddReminderScrollableBottomSheet(context, index: i);
          },
        )
      );
    }

    return widgets;
  }

  Widget colorChooserCircle() { 
    List<ColorSwatch<dynamic>> colors = <ColorSwatch>[
      MaterialColor(0x00000000, {500: Colors.transparent}),
      MaterialColor(0xFFFFB182, {500: Color(0xFFFFB182)}),
      MaterialColor(0xFFFFF18E, {500: Color(0xFFFFF18E)}),
      MaterialColor(0xFFFFE8D1, {500: Color(0xFFFFE8D1)}),
      MaterialColor(0xFFD8D4F2, {500: Color(0xFFD8D4F2)}),
      MaterialColor(0xFFB9D6F2, {500: Color(0xFFB9D6F2)}),
      MaterialColor(0xFFFFB8D1, {500: Color(0xFFFFB8D1)}),
      MaterialColor(0xFFBCFFC3, {500: Color(0xFFBCFFC3)}),
    ];

    return IconButton(
      icon: Icon(Icons.color_lens),
      onPressed: () => showDialog(
        context: context,
        builder: (context) {
          Color currentColor = noteColor == null ? Colors.transparent : Color(noteColor);
          return AlertDialog(
            title: Text("Note color selector"),
            content: MaterialColorPicker(
              colors: colors,
              allowShades: false,
              circleSize: 70.0,
              onMainColorChange: (color) {
                currentColor = color;
              },
              selectedColor: currentColor,
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Theme.of(context).accentColor),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              FlatButton(
                child: Text(
                  "Confirm",
                  style: TextStyle(color: Theme.of(context).accentColor),
                ),
                onPressed: () {
                  if(currentColor.toString() == "MaterialColor(primary value: Color(0x00000000))"
                      || currentColor.toString() == "Color(0x00000000)") {
                    setState(() => noteColor = null);
                  } else {
                    setState(() => noteColor = currentColor.value);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          );
        }
      ),
    );
  }

  Future<int> noteIdSearcher() async {
    List<Note> noteList = await NoteHelper().getNotes();
    List<int> noteIdList = List<int>();
    
    noteList.forEach((item) {
      noteIdList.add(item.id);
    });

    if(noteIdList.length > 0) {
      return noteIdList[noteIdList.length - 1] + 1;
    } else return 1;
  }

  bool saveAndPop(bool stopDefaultButtonEvent) {
    if (((noteContent != "" || noteTitle != "") && noteIsList == 0) ||
        (noteIsList == 1 && noteListParseString != "")) {
      asyncExecutor();
    } else {
      Navigator.pop(context);
    }
    return true;
  }

  void updateListParseString() {
    List<String> pairedList = List<String>();
    
    checkList.forEach((item) {
      pairedList.add(item.checkValue.toString() + "\',,\'" + item.title);
    });

    noteListParseString = pairedList.join("\'..\'");
  }

  void asyncExecutor() async {
    List<Note> noteList = await noteHelper.getNotes();
    noteDate = DateTime.now().millisecondsSinceEpoch;

    updateListParseString();

    if(noteListParseString == "")
      noteIsList = 0;

    noteRemindersUpdater();

    if(noteReminders == "")
      noteReminders = null;

    await noteHelper.insert(Note(
      id: noteId,
      title: noteTitle,
      content: noteContent,
      isStarred: noteIsStarred,
      date: noteDate,
      color: noteColor,
      imagePath: noteImagePath,
      isList: noteIsList,
      listParseString: noteListParseString,
      reminders: noteReminders,
    ));
    noteList = await noteHelper.getNotes();
    Navigator.pop(context, noteList);
  }

  void showImageActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Choose action"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))
          ),
          contentPadding: EdgeInsets.only(top: 20, bottom: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(Icons.photo_library),
                title: noteImagePath != null ? Text("Update image") : Text("Add image"),
                onTap: () async {
                  Navigator.pop(context);
                  File image = await ImagePicker.pickImage(source: ImageSource.gallery);
                  if(image != null)
                    setState(() => noteImagePath = image.path);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                enabled: noteImagePath != null,
                leading: Icon(Icons.delete),
                title: Text("Remove image"),
                onTap: () async {
                  setState(() => noteImagePath = null);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void showAddReminderScrollableBottomSheet(BuildContext baseContext, {int index}) {
    final appInfo = Provider.of<AppInfoProvider>(baseContext);

    if(index != null) {
      DateTime generalDate = DateTime.fromMillisecondsSinceEpoch(reminderList[index]);

      appInfo.date = DateTime(generalDate.year, generalDate.month, generalDate.day);
      appInfo.time = TimeOfDay(hour: generalDate.hour, minute: generalDate.minute);
    }

    showDialog(
      context: baseContext,
      builder: (BuildContext context) {

        return AlertDialog(
          title: index != null ? Text("Update reminder") : Text("Add a new reminder"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))
          ),
          contentPadding: EdgeInsets.only(top: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(Icons.timer),
                title: Text("Time"),
                onTap: () async {
                  TimeOfDay result = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now().replacing(minute: TimeOfDay.now().minute + 1),
                    builder: (context, child) {
                      return child;
                    }
                  );

                  setState(() => appInfo.time = result);
                },
                trailing: appInfo.time != null ? Text(appInfo.time.format(context)) : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(Icons.date_range),
                title: Text("Date"),
                onTap: () async {
                  DateTime result = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    initialDate: DateTime.now(),
                    builder: (context, child) {
                      return child;
                    }
                  );

                  setState(() => appInfo.date = result);
                },
                trailing: appInfo.date != null ? Text(DateFormat("d/MM/yy").format(appInfo.date)) : null,
              ),
            ],
          ),
          actions: <Widget>[
            index != null ? FlatButton(
              textColor: appInfo.mainColor,
              hoverColor: appInfo.mainColor,
              child: Text("Remove"),
              onPressed: () async {
                reminderList.removeAt(index);
                await FlutterLocalNotificationsPlugin().cancel(
                  int.parse(noteId.toString() + index.toString())
                );
                setState(() => noteRemindersUpdater());
                Navigator.pop(context);
              },
            ) : Container(),
            FlatButton(
              textColor: appInfo.mainColor,
              hoverColor: appInfo.mainColor,
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            FlatButton(
              textColor: appInfo.mainColor,
              hoverColor: appInfo.mainColor,
              child: Text("Save"),
              onPressed: (appInfo.date != null && appInfo.time != null) ? () async {
                DateTime completeReminder = DateTime(
                  appInfo.date.year,
                  appInfo.date.month,
                  appInfo.date.day,
                  appInfo.time.hour,
                  appInfo.time.minute
                );
                if(index != null) {
                  reminderList[index] = completeReminder.millisecondsSinceEpoch;
                } else {
                  reminderList.add(completeReminder.millisecondsSinceEpoch);
                }
                setState(() => noteRemindersUpdater());
                String notifId = noteId.toString() + (index != null ? index : reminderList.length).toString();
                appInfo.remindersNotifIdList.add(notifId);
                await FlutterLocalNotificationsPlugin().schedule(
                  int.parse(appInfo.remindersNotifIdList.last), noteTitle != "" ? noteTitle : "Reminder",
                  noteContent, completeReminder, NotificationDetails(
                    AndroidNotificationDetails(
                      '1', 'note_reminders_notifications', 'Reminders channel',
                      priority: Priority.High, playSound: true, importance: Importance.High,
                    ),
                    IOSNotificationDetails()
                  ), payload: noteId.toString() + ":" + completeReminder.millisecondsSinceEpoch.toString()
                );
                Navigator.pop(context);
              } : null,
            ),
          ],
        );
      }
    );
  }
}