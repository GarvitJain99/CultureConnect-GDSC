import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarPage extends StatefulWidget {
  final String communityId;

  CalendarPage({required this.communityId});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final eventsSnapshot = await _firestore
        .collection('communities')
        .doc(widget.communityId)
        .collection('events')
        .get();

    for (var doc in eventsSnapshot.docs) {
      final event = Event.fromMap(doc.data());
      final eventDate = DateTime(event.date.year, event.date.month, event.date.day);

      if (_events[eventDate] == null) {
        _events[eventDate] = [];
      }
      _events[eventDate]!.add(event);
    }

    setState(() {});
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  void _announceEvent() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _eventNameController = TextEditingController();
        TextEditingController _eventDescriptionController = TextEditingController();

        return AlertDialog(
          title: Text("Announce Event"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _eventNameController,
                decoration: InputDecoration(labelText: "Event Name"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _eventDescriptionController,
                decoration: InputDecoration(labelText: "Event Description"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (_eventNameController.text.trim().isEmpty ||
                    _eventDescriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill all fields.")),
                  );
                  return;
                }

                final userId = _auth.currentUser!.uid;
                final userDoc = await _firestore.collection('users').doc(userId).get();
                final userName = userDoc['name'];

                final event = Event(
                  name: _eventNameController.text.trim(),
                  description: _eventDescriptionController.text.trim(),
                  date: _selectedDay!,
                  organizer: userName,
                );

                await _firestore
                    .collection('communities')
                    .doc(widget.communityId)
                    .collection('events')
                    .add(event.toMap());

                Navigator.pop(context);
                _loadEvents();
              },
              child: Text("Announce"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Community Calendar"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _announceEvent,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onFormatChanged: _onFormatChanged,
            onPageChanged: _onPageChanged,
            onDaySelected: _onDaySelected,
            eventLoader: (day) => _events[day] ?? [],
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          Expanded(
            child: ListView(
              children: _events[_selectedDay]?.map((event) {
                return ListTile(
                  title: Text(event.name),
                  subtitle: Text(event.description),
                  trailing: Text("Organized by: ${event.organizer}"),
                );
              }).toList() ?? [],
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final String name;
  final String description;
  final DateTime date;
  final String organizer;

  Event({
    required this.name,
    required this.description,
    required this.date,
    required this.organizer,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'date': date,
      'organizer': organizer,
    };
  }

  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      name: map['name'],
      description: map['description'],
      date: (map['date'] as Timestamp).toDate(),
      organizer: map['organizer'],
    );
  }
}