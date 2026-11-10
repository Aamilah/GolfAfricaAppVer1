import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'news_page.dart';
import 'leaderboard_page.dart';
import 'package:golf_africa/notification_services.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
                                "GOLF IS ALL ABOUT CATCHING THAT FEELING",
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
                                Icons.celebration,
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
                children: const [
                  SectionTitle(title: "ACTION OVER ON THE GREEN"),
                  EventCardWidget(),
                  SectionTitle(title: "SWINGING FOR THE WIN"),
                  MainLeaderboardWidgetState(),
                  SectionTitle(title: "A HOLE LOT OF ACTION"),
                  MainNewsSection(),
                  // SectionTitle(title: "BIRDIES AND BIG MOMENTS"),
                  Footer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Align title to the left
        children: [
          Flexible(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: "Poppins",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainLeaderboardWidgetState extends StatefulWidget {
  const MainLeaderboardWidgetState({super.key});

  @override
  _MainLeaderboardWidgetState createState() => _MainLeaderboardWidgetState();
}

class _MainLeaderboardWidgetState extends State<MainLeaderboardWidgetState> {
  late LeaderboardData leaderboardData;
  bool isLoading = true;
  bool isPolling = true;
  List<Player> previousTopPlayers = [];

  @override
  void initState() {
    super.initState();
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
      leaderboardData.players.sort(
        (a, b) => a.totalPlayerPar.compareTo(b.totalPlayerPar),
      );

      // Store the initial top 3 players
      previousTopPlayers = leaderboardData.players.take(3).toList();

      setState(() => isLoading = false);
      _fetchLiveUpdates(); // Start long polling after loading
    } catch (e) {
      print('Error loading leaderboard: $e');
    }
  }

  // Send notification when the top 3 players change
  void _sendTopPlayersNotification(List<Player> topPlayers) async {
    if (topPlayers.isEmpty) {
      print('No players available for notification.');
      return;
    }

    // Prepare the notification body
    String topPlayersMessage = 'Top players:\n';
    String expandedBody = "";

    // Iterate over the top 3 players and build the messages
    for (int i = 0; i < topPlayers.length && i < 3; i++) {
      final player = topPlayers[i];
      topPlayersMessage +=
          '${i + 1}. ${player.lastName} - ${player.totalPlayerPar}\n';
      expandedBody +=
          '${i + 1}. ${player.firstName} ${player.lastName} - ${player.totalPlayerPar}\n';
    }

    // Send notification with the top players
    await NotiService().showNotification(
      title: 'Leaderboard Update!',
      body: topPlayersMessage,
      expandedBody: expandedBody, // Expanded body with full details
    );
  }

  // Fetch live updates and compare top 3 players
  void _fetchLiveUpdates() async {
    while (isPolling) {
      try {
        // Fetch the latest leaderboard data to get the updated totalPlayerPar values
        LeaderboardData newLeaderboardData =
            await ApiService().fetchLeaderboard();

        // Fetch the live updates for new scores
        List<dynamic> newScores = await ApiService().fetchLiveUpdates();

        if (newScores.isNotEmpty && mounted) {
          setState(() {
            // Update players with new scores
            for (var score in newScores) {
              int playerID = score['PlayerID'];

              try {
                final player = newLeaderboardData.players.firstWhere(
                  (p) => p.id == playerID,
                );

                if (player.id == playerID) {
                  player.totalPlayerPar =
                      player.totalPlayerPar; // Update only totalPlayerPar
                }
              } catch (e) {}
            }

            // Sort the leaderboard data by totalPlayerPar
            newLeaderboardData.players.sort(
              (a, b) => a.totalPlayerPar.compareTo(b.totalPlayerPar),
            );

            // Keep only the top 3 players
            List<Player> newTopPlayers =
                newLeaderboardData.players.take(3).toList();

            // Check if the top 3 players have changed
            if (!_topPlayersEqual(previousTopPlayers, newTopPlayers)) {
              // Send notification if the top 3 players have changed
              _sendTopPlayersNotification(newTopPlayers);

              // Update the previous top players list
              previousTopPlayers = newTopPlayers;
            }

            // Only update the leaderboardData with the top 3 players for display
            setState(() {
              leaderboardData.players = newTopPlayers;
            });
          });
        }
      } catch (e) {
        print('Error fetching live updates: $e');
      }
    }
  }

  // Helper method to check if the top 3 players are the same
  bool _topPlayersEqual(
    List<Player> oldTopPlayers,
    List<Player> newTopPlayers,
  ) {
    if (oldTopPlayers.length != newTopPlayers.length) {
      return false;
    }

    for (int i = 0; i < oldTopPlayers.length; i++) {
      if (oldTopPlayers[i].id != newTopPlayers[i].id) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
          child: CircularProgressIndicator(),
        ) // Show loader while loading
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
                  0: FixedColumnWidth(40),
                  1: FixedColumnWidth(80),
                  2: FlexColumnWidth(),
                  3: FixedColumnWidth(60),
                },
                children: [
                  _tableRow(["#", "Country", "Player", "Par"], isHeader: true),
                  // Generate rows dynamically for only the top 3 players
                  ...leaderboardData.players.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    Player player = entry.value;
                    return _playerRow(index.toString(), player);
                  }),
                ],
              ),
            ],
          ),
        );
  }

  TableRow _playerRow(String position, Player player) {
    return TableRow(
      children: [
        _buildCell(position),
        _buildCountryCell(player.flag),
        _buildPlayerName(player),
        _buildParCell(player.formattedParDifference.toString()),
      ],
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
                    fontSize: 9,
                    color: isHeader ? Colors.black54 : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
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

  Widget _buildParCell(String par) {
    int diff = int.tryParse(par) ?? 0;
    Color backgroundColor;
    if (diff > 0) {
      backgroundColor = Colors.red;
    } else if (diff < 0) {
      backgroundColor = Colors.green;
    } else {
      backgroundColor = Colors.blue.shade900;
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
                fontSize: 8,
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
            width: 50,
            height: 40,
            shape: const RoundedRectangle(6),
          ),
        ),
      ),
    );
  }
}

class MainNewsSection extends StatelessWidget {
  const MainNewsSection({super.key}); // Default to 3 articles

  Future<List<NewsArticle>> fetchNews() async {
    try {
      const currentPage = 1;

      final response = await http.get(
        Uri.parse(
          'https://golfafricagolf.com/app/fetch_news.php?page=$currentPage',
        ),
      );

      if (response.statusCode == 200) {
        print("Response body: ${response.body}");

        final Map<String, dynamic> data = jsonDecode(response.body);

        // Now use 'articles' instead of 'data'
        if (data.containsKey('articles')) {
          final List<dynamic> articlesData = data['articles'];
          print("Total articles received: ${articlesData.length}");

          return articlesData
              .map((json) => NewsArticle.fromJson(json))
              .toList();
        } else {
          print("No 'articles' field in response");
        }
      } else {
        print("Failed to load news: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching news: $e");
    }

    return []; // Return an empty list if something fails
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsArticle>>(
      future: fetchNews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No news available'));
        } else {
          List<NewsArticle> articles = snapshot.data!;
          return Column(
            children:
                articles.map((article) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => NewsDetailPage(article: article),
                        ),
                      );
                    },
                    child: _buildNewsCard(
                      category: article.category,
                      title: article.title,
                      date: article.datePublished,
                      imageUrl: article.imageUrl,
                    ),
                  );
                }).toList(),
          );
        }
      },
    );
  }

  Widget _buildNewsCard({
    required String category,
    required String title,
    required String date,
    required String imageUrl,
    Color? backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      child: IntrinsicHeight(
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 120,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.error,
                        size: 50,
                        color: Colors.red,
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                // ✅ Corrected Placement
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Date Published: $date",
                        style: const TextStyle(
                          fontSize: 5,
                          color: Color.fromARGB(255, 65, 64, 64),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20), // Moves the container away from edges
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: Color.fromRGBO(180, 10, 8, 1), // Background color
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Join the golf revolution",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Stay up to date with us.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your answer to all things golf and Africa.",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
