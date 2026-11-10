import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'home_page.dart';
import 'package:golf_africa/notification_services.dart';

class TournamentsPage extends StatelessWidget {
  const TournamentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(34, 133, 56, 1),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 10, // Adjust height (default is 56)
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(34, 133, 56, 1),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Text(
                                "ALL THE ACTION ON THE GREEN HAPPENING IN ONE PLACE",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.golf_course_outlined,
                                color: Colors.green,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 75),
              Column(
                children: [
                  SectionTitle(title: "TODAY'S LINEUP"),
                  EventSection(),

                  SectionTitle(title: "THIS WEEK OVER ON THE GREENS"),
                  EventsCalendar(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventsCalendar extends StatefulWidget {
  const EventsCalendar({super.key});

  @override
  _EventsCalendarState createState() => _EventsCalendarState();
}

class _EventsCalendarState extends State<EventsCalendar> {
  late final PageController _pageController;
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  String _getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1]; // Convert month number to name
  }

  Map<String, List<dynamic>> eventsByDay = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    int currentDayIndex = DateTime.now().weekday - 1; // Monday = 0, Sunday = 6
    _pageController = PageController(initialPage: currentDayIndex);
    fetchEvents();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://golfafricagolf.com/app/fetch_weekly_events.php'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);

        Map<String, List<dynamic>> tempEvents = {};

        // Initialize the map with empty lists for each day
        for (var day in days) {
          tempEvents[day] = [];
        }

        // Convert API response (dates) into day names
        decodedResponse.forEach((date, events) {
          DateTime parsedDate = DateTime.parse(
            date,
          ); // Convert "2025-03-25" to DateTime
          String dayName =
              days[parsedDate.weekday - 1]; // Get the corresponding day name

          if (!tempEvents.containsKey(dayName)) {
            tempEvents[dayName] = [];
          }
          tempEvents[dayName]!.addAll(
            List<dynamic>.from(events),
          ); // Add events to that day
        });

        setState(() {
          eventsByDay = tempEvents;
          isLoading = false;
        });
      } else {
        print("Error: Server returned ${response.statusCode}");
      }
    } on Exception catch (e) {
      print("Error fetching events: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : PageView.builder(
                  controller: _pageController,
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    String currentDay = days[index];
                    DateTime today = DateTime.now();
                    DateTime startOfWeek = today.subtract(
                      Duration(days: today.weekday - 1),
                    ); // Monday as start
                    DateTime currentDate = startOfWeek.add(
                      Duration(days: index),
                    );

                    // Format the date as "Monday, 25 March"
                    String formattedDate =
                        "$currentDay, ${currentDate.day} ${_getMonthName(currentDate.month)}";

                    List<dynamic> events = eventsByDay[currentDay] ?? [];

                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(180, 10, 8, 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display day name
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (events.isEmpty)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    "No tournaments today",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 25),
                            Expanded(
                              child: ListView.builder(
                                itemCount: events.length,
                                itemBuilder: (context, eventIndex) {
                                  var event = events[eventIndex];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  event['dates']?.toString() ??
                                                      'Date not available',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  event['tournament_name']
                                                          ?.toString() ??
                                                      'Unknown Tournament',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  event['location']
                                                          ?.toString() ??
                                                      'Location not available',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          event['tour_logo'] != null
                                              ? SizedBox(
                                                width: 50,
                                                height: 50,
                                                child: SvgPicture.network(
                                                  event['tour_logo'].toString(),
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.contain,
                                                ),
                                              )
                                              : Container(),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

class TodayEvents {
  final String tour_name;
  final String tournament_name;
  final String dates;
  final String tour_logo;
  final String location;

  TodayEvents({
    required this.tour_name,
    required this.tournament_name,
    required this.dates,
    required this.tour_logo,
    required this.location,
  });

  factory TodayEvents.fromJson(Map<String, dynamic> json) {
    return TodayEvents(
      tour_name: json['tour_name'] ?? 'Unknown Category',
      tournament_name: json['tournament_name'] ?? 'No Title',
      dates: json['dates'] ?? 'Unknown Date',
      tour_logo: json['tour_logo'] ?? '',
      location: json['location'] ?? 'No Content Available',
    );
  }
}

class EventSection extends StatefulWidget {
  const EventSection({super.key});

  @override
  _EventSectionState createState() => _EventSectionState();
}

class _EventSectionState extends State<EventSection> {
  List<TodayEvents> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    const url = "https://golfafricagolf.com/app/fetch_events.php";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> eventsJson = jsonDecode(response.body);
        print("Fetched ${eventsJson.length} events");

        setState(() {
          isLoading = false;
          events =
              eventsJson.map((event) => TodayEvents.fromJson(event)).toList();
        });

        // Schedule notifications for all events
        scheduleEventNotifications();
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> scheduleEventNotifications() async {
    final notiService = NotiService();
    await notiService
        .initNotification(); // Ensure notifications are initialized

    for (int i = 0; i < events.length; i++) {
      final event = events[i];

      await notiService.scheduleNotification(
        id: i, // Unique ID for each notification
        title: "Upcoming Event: ${event.tournament_name}",
        body: "Location: ${event.location} | Date: ${event.dates}",
        expandedBody:
            "Don't miss ${event.tournament_name} happening at ${event.location} on ${event.dates}.",
        hour: 12,
        minute: 10,
      );
    }
    print("All events scheduled for notification at 12:30 PM.");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isLoading)
          const CircularProgressIndicator()
        else if (events.isEmpty)
          const Text("No events today")
        else
          ...events.map(
            (event) => _buildEventCard(
              date: event.dates,
              title: event.tournament_name,
              location: event.location,
              imageUrl: event.tour_logo, // Using tour_logo as image URL
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard({
    required String date,
    required String title,
    required String location,
    required String imageUrl,
  }) {
    bool isSvg = imageUrl.toLowerCase().endsWith(".svg");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100, // Adjust width as needed
                      height: 100, // Adjust height as needed
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SvgPicture.network(
                          imageUrl,
                          width: 20,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 7,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.grey,
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
}
