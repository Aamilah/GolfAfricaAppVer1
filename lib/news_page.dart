import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'home_page.dart';
import 'package:golf_africa/notification_services.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key}); // Default value 3 if not passed

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
                                "A HOLE LOT OF ACTION",
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
                                Icons.menu_book,
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
              const SizedBox(height: 30),
              Column(
                children: const [
                  SectionTitle(title: "THE TEE TIME ON THE FAIRWAY"),
                  NewsSection(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsArticle {
  final int id;
  final String category;
  final String title;
  final String datePublished;
  final String imageUrl;
  final String content;
  final String highlight;
  final String content_right;
  final String conclusion;
  final String author;

  NewsArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.datePublished,
    required this.imageUrl,
    required this.content,
    this.highlight = '',
    required this.content_right,
    required this.conclusion,
    this.author = '',
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: int.tryParse(json['id'].toString()) ?? 0,
      category: json['category'] ?? 'Unknown Category',
      title: json['title'] ?? 'No Title',
      datePublished: json['date_published'] ?? 'Unknown Date',
      imageUrl: json['image_url'] ?? '',
      content: json['content'] ?? 'No Content Available',
      highlight: json['highlight'] ?? '',
      content_right: json['content_right'] ?? '',
      conclusion: json['conclusion'] ?? '',
      author: json['author'] ?? 'Anonymous',
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News'),
        backgroundColor: Color.fromRGBO(
          180,
          10,
          8,
          1,
        ), // Set background color to red
        foregroundColor: Colors.white, // Set text color to white
      ),
      body: SingleChildScrollView(
        // Wrap the content in a scrollable view
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(article.imageUrl, fit: BoxFit.cover),
            SizedBox(height: 10),
            Text(
              article.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Date Published: ${article.datePublished}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            SizedBox(height: 20),
            Text(article.content, style: TextStyle(fontSize: 14)),
            SizedBox(height: 20),
            Text(
              article.highlight,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(article.content_right, style: TextStyle(fontSize: 14)),
            SizedBox(height: 20),
            Text(article.conclusion, style: TextStyle(fontSize: 14)),
            SizedBox(height: 20),
            if (article.author.isNotEmpty)
              Text(
                'Written by : ${article.author}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NewsSection extends StatefulWidget {
  const NewsSection({super.key});

  @override
  _NewsSectionState createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  List<NewsArticle> articles = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _newsTimer; // Store the timer

  @override
  void initState() {
    super.initState();
    fetchNews();
    _scrollController.addListener(_onScroll);

    // Store the timer and schedule periodic fetch
    _newsTimer = Timer.periodic(Duration(minutes: 10), (Timer t) {
      if (mounted) {
        fetchNews();
      } else {
        t.cancel(); // Cancel timer if widget is no longer mounted
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose scroll controller
    _newsTimer?.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }

  void _scheduleNotificationForLatestArticle(NewsArticle article) {
    NotiService().scheduleNotification(
      id: 101,
      title: "Latest Article Published!",
      body: article.title,
      hour: 13,
      minute: 45,
    );
  }

  Future<void> fetchNews() async {
    if (!mounted) return; // Prevent state updates after dispose

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://golfafricagolf.com/app/fetch_news.php?page=$currentPage',
        ),
      );

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic> && decoded.containsKey("articles")) {
        List<NewsArticle> newArticles =
            (decoded["articles"] as List)
                .map((json) => NewsArticle.fromJson(json))
                .toList();

        if (newArticles.isEmpty) {
          hasMore = false;
        } else {
          if (mounted) {
            setState(() {
              articles.addAll(newArticles);
              currentPage++;
              isLoading = false;
            });

            NewsArticle latestArticle = newArticles.first;
            _scheduleNotificationForLatestArticle(latestArticle);
          }
        }
      }
    } catch (e) {
      print("Error fetching news: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading) {
      fetchNews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: articles.length + 2,
              itemBuilder: (context, index) {
                if (index < articles.length) {
                  return _buildNewsCard(articles[index]);
                } else {
                  return isLoading
                      ? const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 20,
                        ),
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : hasMore
                      ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : const Padding(
                        padding: EdgeInsets.only(bottom: 50),
                        child: Center(
                          child: Text(
                            "No more articles",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(article: article),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: IntrinsicHeight(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                        article.imageUrl,
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
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
                              article.category,
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.015,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            article.title,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.03,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "Date Published: ${article.datePublished}",
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.02,
                                color: Color.fromARGB(255, 65, 64, 64),
                              ),
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
        ),
      ),
    );
  }
}
