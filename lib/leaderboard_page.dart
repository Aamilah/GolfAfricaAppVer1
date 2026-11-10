import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:golf_africa/notification_services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:country_flags/country_flags.dart';
import 'dart:async';
import 'home_page.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

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
                                "SWINGING FOR THE WIN",
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
                                Icons.sports_golf_sharp,
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
              const SizedBox(height: 65),
              Column(
                children: [
                  SectionTitle(title: "TOURNAMENT OF THE DAY"),
                  EventCardWidget(),
                  SectionTitle(title: "LEADERBOARD"),
                  LeaderboardWidget(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ApiService {
  final String leaderboardUrl =
      'https://golfafricagolf.com/app/leaderboard.php';
  final String liveUpdatesUrl =
      'https://golfafricagolf.com/app/live_updates.php';

  int lastCheckedTimestamp = 0; // Store the last update time

  // Fetch initial leaderboard data
  Future<LeaderboardData> fetchLeaderboard() async {
    final response = await http.get(Uri.parse(leaderboardUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      lastCheckedTimestamp =
          DateTime.now().millisecondsSinceEpoch ~/
          1000; // Set last checked time
      return LeaderboardData.fromJson(data);
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }

  // Long polling for updates
  Future<List<dynamic>> fetchLiveUpdates() async {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$liveUpdatesUrl?last_checked=$lastCheckedTimestamp'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['newScores'].isNotEmpty) {
            lastCheckedTimestamp =
                DateTime.now().millisecondsSinceEpoch ~/
                1000; // Update timestamp
            return data['newScores']; // Return new scores
          }
        }
      } catch (e) {
        print('Error fetching live updates: $e');
      }

      await Future.delayed(Duration(seconds: 3)); // Delay before next poll
    }
  }
}

class LeaderboardData {
  final MatchDetails match;
  late List<Player> players;
  final List<Hole> holes;
  final String mostRecentUpdate;

  LeaderboardData({
    required this.match,
    required this.players,
    required this.holes,
    required this.mostRecentUpdate,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    return LeaderboardData(
      match: MatchDetails.fromJson(json['match']),
      players:
          (json['players'] as List<dynamic>)
              .map((player) => Player.fromJson(player))
              .toList(),
      holes:
          (json['holes'] as List<dynamic>)
              .map((hole) => Hole.fromJson(hole))
              .toList(),
      mostRecentUpdate: json['most_recent_added_on'] ?? 'No updates available',
    );
  }
}

class MatchDetails {
  final String tourName;
  final String tournamentName;
  final String location;
  final String tourLogo;
  final String dateStart;
  final String dateEnd;
  final String dates;
  final int rounds;

  MatchDetails({
    required this.tourName,
    required this.tournamentName,
    required this.location,
    required this.tourLogo,
    required this.dateStart,
    required this.dateEnd,
    required this.dates,
    required this.rounds,
  });

  factory MatchDetails.fromJson(Map<String, dynamic> json) {
    return MatchDetails(
      tourName: json['tour_name'],
      tournamentName: json['tournament_name'],
      location: json['location'],
      tourLogo: json['tour_logo'],
      dateStart: json['db_date_start'],
      dateEnd: json['db_date_end'],
      dates: json['dates'],
      rounds: json['Rounds'],
    );
  }
}

class Player {
  final int id;
  final String firstName;
  final String lastName;
  final String flag;
  final bool playerCut;
  final int latestRound;
  late int totalScore;
  late int totalPlayerPar;
  final Map<int, Map<int, int>> scores;
  final Map<int, int> roundTotals;
  final Map<int, int> playerPar;

  Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.flag,
    required this.playerCut,
    required this.latestRound,
    required this.totalScore,
    required this.totalPlayerPar,
    required this.scores,
    required this.roundTotals,
    required this.playerPar,
  });

  String get formattedParDifference {
    int diff = totalPlayerPar;
    if (diff == 0) return 'PAR'; // If 0, display "PAR"
    return diff > 0 ? '+$diff' : '$diff'; // Add "+" for positive numbers
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['PlayerID'],
      firstName: json['FirstName'],
      lastName: json['LastName'],
      flag: json['Flag'],
      playerCut: json['player_cut'] == 1,
      latestRound: json['latest_round'],
      totalScore: json['total_score'] ?? 0,
      totalPlayerPar: json['totalPlayerPar'] ?? 0,
      scores: (json['scores'] as Map<String, dynamic>).map((round, holes) {
        return MapEntry(
          int.parse(round),
          (holes as Map<String, dynamic>).map((hole, score) {
            return MapEntry(int.parse(hole), score as int);
          }),
        );
      }),
      roundTotals: (json['roundTotals'] as Map<String, dynamic>).map((
        round,
        total,
      ) {
        return MapEntry(int.parse(round), total as int);
      }),
      playerPar: (json['playerPar'] as Map<String, dynamic>).map((
        round,
        total,
      ) {
        return MapEntry(int.parse(round), total as int);
      }),
    );
  }
}

class Hole {
  final int holeNumber;
  final String par;
  final int yards;

  Hole({required this.holeNumber, required this.par, required this.yards});

  factory Hole.fromJson(Map<String, dynamic> json) {
    return Hole(
      holeNumber: json['HoleNumber'],
      par: json['Par']?.toString() ?? '-',
      yards: json['Yards'] ?? 0,
    );
  }
}

class EventCardWidget extends StatefulWidget {
  const EventCardWidget({super.key});

  @override
  _EventCardWidgetState createState() => _EventCardWidgetState();
}

class _EventCardWidgetState extends State<EventCardWidget> {
  bool isLoading = true;
  MatchDetails? matchDetails;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadMatchDetails();
  }

  void _loadMatchDetails() async {
    try {
      final leaderboardData = await ApiService().fetchLeaderboard();
      setState(() {
        matchDetails = leaderboardData.match;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle the error (you could show a Snackbar or an error message)
    }
  }

  @override
  Widget build(BuildContext context) {
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
                : matchDetails == null
                ? const Center(child: Text("Failed to load event details"))
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SvgPicture.network(
                        matchDetails!.tourLogo,
                        width: 100,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            matchDetails!.dates,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 7,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            matchDetails!.tournamentName,
                            style: const TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            matchDetails!.location,
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

class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({super.key});

  @override
  _LeaderboardWidgetState createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  late LeaderboardData leaderboardData;
  Set<int> expandedRows = {}; // Track multiple expanded rows
  bool isLoading = true;
  bool isPolling = true;
  List<Player> previousTopPlayers = [];
  bool isNotificationInProgress = false; // Prevent multiple notifications

  @override
  void initState() {
    super.initState();
    _scheduleLeaderboardNotifications();
    _initializeLeaderboard();
  }

  @override
  void dispose() {
    isPolling = false; // Stop polling when widget is disposed
    super.dispose();
  }

  // Load initial leaderboard
  void _initializeLeaderboard() async {
    try {
      leaderboardData = await ApiService().fetchLeaderboard();

      setState(() => isLoading = false);
      _fetchLiveUpdates(); // Start long polling after loading
    } catch (e) {}
  }

  void _sendTopPlayersNotification(List<Player> topPlayers) async {
    // Prepare the notification body
    String topPlayersMessage = 'Top players:\n';
    for (int i = 0; i < topPlayers.length && i < 5; i++) {
      final player = topPlayers[i];
      topPlayersMessage +=
          '${i + 1}. ${player.lastName} - ${player.totalPlayerPar}\n';
    }

    // Send notification with the top players
    await NotiService().showNotification(
      title: 'Leaderboard Update!',
      body: topPlayersMessage,
    );
  }

  Future<void> _fetchLatestLeaderboardAndNotify() async {
    try {
      leaderboardData = await ApiService().fetchLeaderboard();
      if (leaderboardData.players.isNotEmpty) {
        String topPlayersMessage = 'Top players:\n';
        for (int i = 0; i < leaderboardData.players.length && i < 5; i++) {
          final player = leaderboardData.players[i];
          topPlayersMessage +=
              '${i + 1}. ${player.lastName} - ${player.totalPlayerPar}\n';
        }

        await NotiService().showNotification(
          id: 203,
          title: 'Updated Leaderboard!',
          body: topPlayersMessage,
        );
      }
    } catch (e) {
      print("Error fetching leaderboard: $e");
    }
  }

  void _scheduleLeaderboardNotifications() async {
    await NotiService().scheduleNotification(
      id: 201,
      title: 'Morning Leaderboard Update!',
      body: 'Check out the latest leaderboard standings.',
      hour: 11,
      minute: 30,
    );

    await NotiService().scheduleNotification(
      id: 202,
      title: 'Evening Leaderboard Update!',
      body: 'See how the leaderboard changed today.',
      hour: 18,
      minute: 0,
    );
  }

  void _fetchLiveUpdates() async {
    while (isPolling) {
      try {
        // Fetch the latest leaderboard data to get the updated totalPlayerPar values
        leaderboardData = await ApiService().fetchLeaderboard();

        // Fetch the live updates for new scores
        List<dynamic> newScores = await ApiService().fetchLiveUpdates();

        if (newScores.isNotEmpty && mounted) {
          setState(() {
            for (var score in newScores) {
              int playerID = score['PlayerID'];
              int round = score['RoundNumber'];
              int hole = score['HoleNumber'];
              int newScore = score['Score'];

              try {
                // Find the player or throw exception
                final player = leaderboardData.players.firstWhere(
                  (p) => p.id == playerID,
                );

                // Ensure the player exists and has a valid ID
                if (player.id == playerID) {
                  // Ensure the round entry exists
                  player.scores.putIfAbsent(round, () => {});

                  // Update hole score
                  player.scores[round]![hole] = newScore;

                  // Calculate round total by summing all hole scores in the round
                  player.roundTotals[round] = player.scores[round]!.values.fold(
                    0,
                    (sum, score) => sum + score,
                  );

                  // Calculate total score by summing all round totals
                  player.totalScore = player.roundTotals.values.fold(
                    0,
                    (sum, roundTotal) => sum + roundTotal,
                  );

                  // Ensure roundPar exists before computing playerPar
                  int roundPar = 72;
                  player.playerPar[round] =
                      player.roundTotals[round]! - roundPar;

                  // Now fetch the totalPlayerPar value again from the updated leaderboardData
                  player.totalPlayerPar = player.totalPlayerPar;
                }
              } catch (e) {}
            }

            leaderboardData.players.sort(
              (a, b) => a.totalPlayerPar.compareTo(b.totalPlayerPar),
            );
          });
        }
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator()) // Loading state
        : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Table(
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                columnWidths: {
                  0: const FlexColumnWidth(1),
                  1: const FlexColumnWidth(1.5),
                  2: const FlexColumnWidth(3),
                  leaderboardData.match.rounds + 4: const FlexColumnWidth(),
                  for (int i = 0; i < leaderboardData.match.rounds; i++)
                    i + 3: const FlexColumnWidth(),
                  leaderboardData.match.rounds + 3: const FlexColumnWidth(),
                },
                children: [
                  _tableRow([
                    "#",
                    "Country",
                    "Player",
                    "Par",
                    ...List.generate(
                      leaderboardData.match.rounds,
                      (i) => "R${i + 1}",
                    ),
                    "Total",
                  ], isHeader: true),
                ],
              ),
              // Iterate over players
              ...leaderboardData.players.asMap().entries.map((entry) {
                int index = entry.key;
                Player player = entry.value;
                bool isExpanded = expandedRows.contains(index);

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            expandedRows.remove(index);
                          } else {
                            expandedRows.add(index);
                          }
                        });
                      },
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        columnWidths: {
                          0: const FlexColumnWidth(1),
                          1: const FlexColumnWidth(1.5),
                          2: const FlexColumnWidth(3),
                          leaderboardData.match.rounds + 4:
                              const FlexColumnWidth(),
                          for (int i = 0; i < leaderboardData.match.rounds; i++)
                            i + 3: const FlexColumnWidth(),
                          leaderboardData.match.rounds + 3:
                              const FlexColumnWidth(),
                        },
                        children: [
                          _playerRow(
                            (index + 1).toString(),
                            player,
                            leaderboardData.match.rounds,
                          ),
                        ],
                      ),
                    ),
                    // Show GolfScoreTable when row is expanded
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: GolfScoreTable(
                          player: player,
                          leaderboardData: leaderboardData,
                          holes:
                              leaderboardData
                                  .holes, // Access holes from LeaderboardData
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        );
  }

  TableRow _tableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      children:
          cells.map((text) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                    fontSize: MediaQuery.of(context).size.width * 0.017,
                    color: isHeader ? Colors.black54 : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
    );
  }

  TableRow _playerRow(String position, Player player, int rounds) {
    return TableRow(
      children: [
        _buildCell(position),
        _buildCountryCell(player.flag),
        _buildPlayerName(player),
        _buildParCell(player.formattedParDifference.toString()),
        for (int i = 1; i <= rounds; i++)
          _buildCell(
            player.roundTotals[i]?.toString() ??
                (player.scores[i]?.values.fold(
                          0,
                          (sum, score) => sum + score,
                        ) ??
                        0)
                    .toString(),
          ),
        _buildTotalCell(player.totalScore.toString()),
      ],
    );
  }

  Widget _buildCell(String text) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 7,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build the player name (first name and last name)
  Widget _buildPlayerName(Player player) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player.firstName,
            style: const TextStyle(fontSize: 7, color: Colors.black),
          ),
          Text(
            player.lastName,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build the Par cell with background and rounded corners
  Widget _buildParCell(String par) {
    int diff = int.tryParse(par) ?? 0;

    Color backgroundColor;
    if (diff > 0) {
      backgroundColor = Colors.red; // Positive values: Red
    } else if (diff < 0) {
      backgroundColor = Colors.green; // Negative values: Green
    } else {
      backgroundColor = Colors.blue.shade900; // Zero: Dark Blue
    }

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 5.0),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              par,
              style: const TextStyle(
                fontSize: 7,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCell(String total) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 5.0),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              total,
              style: const TextStyle(
                fontSize: 7,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryCell(String countryCode) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 5.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: CountryFlag.fromCountryCode(
            countryCode,
            width: 30,
            height: 30,
            shape: const RoundedRectangle(6),
          ),
        ),
      ),
    );
  }
}

class GolfScoreTable extends StatelessWidget {
  final Player player;
  final LeaderboardData leaderboardData;
  final List<Hole> holes;

  const GolfScoreTable({
    super.key,
    required this.player,
    required this.leaderboardData,
    required this.holes,
  });

  @override
  Widget build(BuildContext context) {
    int rounds = player.latestRound;

    // Map holeNumber to par values
    Map<int, int> parValues = {
      for (var hole in holes) hole.holeNumber: int.tryParse(hole.par) ?? 0,
    };

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: {
                0: const FixedColumnWidth(60),
                for (int hole = 1; hole <= 9; hole++)
                  hole: const FixedColumnWidth(40),
                10: const FixedColumnWidth(50),
                for (int hole = 10; hole <= 18; hole++)
                  hole: const FixedColumnWidth(40),
                19: const FixedColumnWidth(40),
                20: const FixedColumnWidth(50),
                21: const FixedColumnWidth(50),
                22: const FixedColumnWidth(50),
              },
              children: [
                _tableRow(
                  ["Hole"] +
                      List.generate(9, (i) => "${i + 1}") +
                      ["Out"] +
                      List.generate(9, (i) => "${i + 10}") +
                      ["In", "Total", "Par"],
                  isHeader: true,
                ),
                for (int roundIndex = 1; roundIndex <= rounds; roundIndex++)
                  _tableRow(
                    [
                      "R$roundIndex",
                      ...List.generate(
                        9,
                        (holeIndex) => _getScoreText(roundIndex, holeIndex + 1),
                      ),
                      _calculateOutScore(roundIndex).toString(),
                      ...List.generate(
                        9,
                        (holeIndex) =>
                            _getScoreText(roundIndex, holeIndex + 10),
                      ),
                      _calculateInScore(roundIndex).toString(),
                      (_calculateOutScore(roundIndex) +
                              _calculateInScore(roundIndex))
                          .toString(),
                      ((_calculateOutScore(roundIndex) +
                                  _calculateInScore(roundIndex)) -
                              72)
                          .toString(),
                    ],
                    roundIndex: roundIndex,
                    parValues: parValues,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _colorLegendCell(
                    "Hole-in-one",
                    Color.fromRGBO(252, 194, 0, 1),
                  ),
                  _colorLegendCell("Eagle", Color.fromRGBO(243, 231, 2, 1)),
                  _colorLegendCell("Birdie", Color.fromRGBO(176, 10, 8, 1)),
                  _colorLegendCell("Par", Color.fromRGBO(26, 42, 151, 1)),
                  _colorLegendCell("Bogey", Colors.grey),
                  _colorLegendCell("Double Bogey", Colors.black),
                  _colorLegendCell("Others", Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to create the legend cell with colored background
  Widget _colorLegendCell(String text, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getScoreText(int roundIndex, int holeNumber) {
    var score = player.scores[roundIndex]?[holeNumber];
    return score != null ? score.toString() : "-";
  }

  int _calculateOutScore(int roundIndex) {
    return List.generate(
      9,
      (i) => player.scores[roundIndex]?[i + 1] ?? 0,
    ).reduce((a, b) => a + b);
  }

  int _calculateInScore(int roundIndex) {
    return List.generate(
      9,
      (i) => player.scores[roundIndex]?[i + 10] ?? 0,
    ).reduce((a, b) => a + b);
  }

  TableRow _tableRow(
    List<String> cells, {
    bool isHeader = false,
    int? roundIndex,
    Map<int, int>? parValues,
  }) {
    return TableRow(
      children: List.generate(cells.length, (index) {
        String text = cells[index];
        Color backgroundColor = Colors.transparent;
        Color textColor = isHeader ? Colors.black : Colors.black54;

        // Skip non-hole columns
        List<int> nonHoleColumns = [10, 20, 21]; // OUT, IN, Total, To Par
        if (!isHeader && roundIndex != null && parValues != null) {
          if (!nonHoleColumns.contains(index)) {
            // Adjust hole number by skipping OUT column
            int holeNumber = index < 10 ? index : index - 1;
            int parValue = parValues[holeNumber] ?? 0;
            int? score = int.tryParse(text);

            if (score != null && parValue > 0) {
              backgroundColor =
                  (score == 1)
                      ? Color.fromRGBO(252, 194, 0, 1) // Hole-in-one (gold)
                      : (score == parValue - 2)
                      ? Color.fromRGBO(243, 231, 2, 1) // Eagle (yellow)
                      : (score == parValue - 1)
                      ? Color.fromRGBO(176, 10, 8, 1) // Birdie (red)
                      : (score == parValue)
                      ? Color.fromRGBO(26, 42, 151, 1) // Par (blue)
                      : (score == parValue + 1)
                      ? Colors
                          .grey // Bogey
                      : (score == parValue + 2)
                      ? Colors
                          .black // Double Bogey
                      : Colors.white; // Others

              // Adjust text color for contrast
              if (backgroundColor == Colors.black ||
                  backgroundColor == Color.fromRGBO(26, 42, 151, 1) ||
                  backgroundColor == Color.fromRGBO(176, 10, 8, 1) ||
                  backgroundColor == Colors.grey ||
                  backgroundColor == Color.fromRGBO(252, 194, 0, 1)) {
                textColor = Colors.white;
              } else {
                textColor = Colors.black54;
              }
            }
          }
        }

        return Container(
          decoration: BoxDecoration(
            color:
                backgroundColor != Colors.transparent ? backgroundColor : null,
            borderRadius: BorderRadius.circular(16),
            border:
                backgroundColor != Colors.transparent
                    ? Border.all(color: Colors.grey.shade300)
                    : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: 9,
                color: textColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}
