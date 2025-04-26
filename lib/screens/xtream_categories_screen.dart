import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tvapp/screens/xtream_channels_screen.dart';

class XtreamCategoriesScreen extends StatefulWidget {
  final String connectionName;
  final String serverUrl;
  final String username;
  final String password;

  XtreamCategoriesScreen({
    required this.connectionName,
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  @override
  _XtreamCategoriesScreenState createState() => _XtreamCategoriesScreenState();
}

class _XtreamCategoriesScreenState extends State<XtreamCategoriesScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _liveCategories = [];
  List<Map<String, dynamic>> _vodCategories = [];
  List<Map<String, dynamic>> _seriesCategories = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final baseUrl = widget.serverUrl.endsWith('/')
          ? widget.serverUrl.substring(0, widget.serverUrl.length - 1)
          : widget.serverUrl;

      // Load Live TV categories
      final liveUrl =
          '$baseUrl/player_api.php?username=${widget.username}&password=${widget.password}&action=get_live_categories';
      final liveResponse = await http.get(Uri.parse(liveUrl));

      if (liveResponse.statusCode != 200) {
        throw Exception(
            'Failed to load live categories: HTTP ${liveResponse.statusCode}');
      }

      // Load VOD categories
      final vodUrl =
          '$baseUrl/player_api.php?username=${widget.username}&password=${widget.password}&action=get_vod_categories';
      final vodResponse = await http.get(Uri.parse(vodUrl));

      if (vodResponse.statusCode != 200) {
        throw Exception(
            'Failed to load VOD categories: HTTP ${vodResponse.statusCode}');
      }

      // Load Series categories
      final seriesUrl =
          '$baseUrl/player_api.php?username=${widget.username}&password=${widget.password}&action=get_series_categories';
      final seriesResponse = await http.get(Uri.parse(seriesUrl));

      if (seriesResponse.statusCode != 200) {
        throw Exception(
            'Failed to load series categories: HTTP ${seriesResponse.statusCode}');
      }

      setState(() {
        _liveCategories =
            List<Map<String, dynamic>>.from(json.decode(liveResponse.body));
        _vodCategories =
            List<Map<String, dynamic>>.from(json.decode(vodResponse.body));
        _seriesCategories =
            List<Map<String, dynamic>>.from(json.decode(seriesResponse.body));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connectionName),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Live TV'),
            Tab(text: 'Movies'),
            Tab(text: 'Series'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCategories,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Live TV Categories
                    _buildCategoryList(_liveCategories, 'live'),

                    // VOD Categories
                    _buildCategoryList(_vodCategories, 'vod'),

                    // Series Categories
                    _buildCategoryList(_seriesCategories, 'series'),
                  ],
                ),
    );
  }

  Widget _buildCategoryList(
      List<Map<String, dynamic>> categories, String type) {
    if (categories.isEmpty) {
      return Center(
        child: Text('No categories found'),
      );
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryId = category['category_id']?.toString() ?? '';
        final categoryName = category['category_name'] ?? 'Unknown';

        return ListTile(
          title: Text(categoryName),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => XtreamChannelsScreen(
                  categoryName: categoryName,
                  categoryId: categoryId,
                  serverUrl: widget.serverUrl,
                  username: widget.username,
                  password: widget.password,
                  type: type,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
