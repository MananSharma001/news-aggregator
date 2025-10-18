import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(NewsApp());

class NewsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Aggregator',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiKey = 'a7efbfec6d5a4fdd9caa72cc006f2607'; // <- replace this
  String category = 'technology';
  bool loading = false;
  List articles = [];

  final List<String> categories = [
    'technology', 'business', 'sports', 'health', 'science', 'entertainment'
  ];

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    setState(() => loading = true);
    final url = Uri.parse(
      'https://newsapi.org/v2/top-headlines?category=$category&pageSize=30&apiKey=$apiKey',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => articles = data['articles'] ?? []);
      } else {
        debugPrint('Failed to load: ${res.statusCode}');
        setState(() => articles = []);
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => articles = []);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open article')),
      );
    }
  }

  Widget articleCard(article) {
    final title = article['title'] ?? '';
    final description = article['description'] ?? '';
    final imageUrl = article['urlToImage'];
    final source = (article['source'] ?? {})['name'] ?? 'Source';
    final url = article['url'] ?? '';

    return Card(
      color: Colors.grey[900],
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: imageUrl != null
            ? Image.network(imageUrl, width: 80, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Icon(Icons.image))
            : Container(width:80, color: Colors.grey[800], child: Icon(Icons.image)),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('$source • ${description}', maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => _openUrl(url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Aggregator'),
        actions: [
          IconButton(icon: Icon(Icons.info_outline), onPressed: () => showAbout(context)),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: categories.map((c) {
                final active = c == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: active,
                    onSelected: (_) {
                      setState(() => category = c);
                      fetchArticles();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchArticles,
                    child: ListView.builder(
                      itemCount: articles.length,
                      itemBuilder: (_, i) => articleCard(articles[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('About'),
        content: Text('News Aggregator\\nData provided by NewsAPI.org — articles link back to original publishers.'),
        actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: Text('OK'))],
      ),
    );
  }
}