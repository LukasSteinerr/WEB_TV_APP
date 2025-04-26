import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tvapp/screens/xtream_categories_screen.dart';
import 'package:tvapp/services/playlist_storage_service.dart';

class AddXtreamScreen extends StatefulWidget {
  @override
  _AddXtreamScreenState createState() => _AddXtreamScreenState();
}

class _AddXtreamScreenState extends State<AddXtreamScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _savedXtreamServers = [];
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedServers();
  }

  Future<void> _loadSavedServers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get connections from storage service
      final connections = await PlaylistStorageService.getXtreamConnections();

      setState(() {
        // Convert to the format used by this screen
        _savedXtreamServers = connections
            .map((connection) => {
                  'name': connection['name'] ?? 'Unnamed Connection',
                  'server_url': connection['serverUrl'] ?? '',
                  'username': connection['username'] ?? '',
                  'password': connection['password'] ?? '',
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load saved connections: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveServer(
      String name, String serverUrl, String username, String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save connection using storage service
      final success = await PlaylistStorageService.saveXtreamConnection(
        name: name,
        serverUrl: serverUrl,
        username: username,
        password: password,
      );

      if (success) {
        // Reload connections
        await _loadSavedServers();

        // Clear form
        _serverUrlController.clear();
        _usernameController.clear();
        _passwordController.clear();
        _nameController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection added successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to save connection';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save connection: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteServer(int index) async {
    if (index < 0 || index >= _savedXtreamServers.length) {
      return;
    }

    final connectionName = _savedXtreamServers[index]['name'] ?? '';

    setState(() {
      _isLoading = true;
    });

    try {
      // Delete connection using storage service
      final success =
          await PlaylistStorageService.deleteXtreamConnection(connectionName);

      if (success) {
        // Reload connections
        await _loadSavedServers();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection deleted')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to delete connection';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete connection: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final serverUrl = _serverUrlController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // Remove trailing slash if present
      final baseUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;

      // Construct the API URL for player_api.php
      final apiUrl =
          '$baseUrl/player_api.php?username=$username&password=$password';

      // Make the request
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      // Try to parse the response as JSON
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['user_info'] == null) {
        throw Exception('Invalid response from server');
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection successful! Server is valid.')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Xtream Connection'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(8.0),
                      margin: EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Connection Name',
                            border: OutlineInputBorder(),
                            hintText: 'My IPTV Service',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name for this connection';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: _serverUrlController,
                          decoration: InputDecoration(
                            labelText: 'Server URL',
                            border: OutlineInputBorder(),
                            hintText: 'http://example.com:25461',
                            helperText:
                                'Include http:// or https:// and port if needed',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the server URL';
                            }
                            if (!value.startsWith('http://') &&
                                !value.startsWith('https://')) {
                              return 'URL must start with http:// or https://';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.0),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _testConnection,
                                icon: Icon(Icons.check_circle),
                                label: Text('Test Connection'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _saveServer(
                                _nameController.text.trim(),
                                _serverUrlController.text.trim(),
                                _usernameController.text.trim(),
                                _passwordController.text.trim(),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('Add Connection'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.0),
                  Text(
                    'Saved Connections',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  _savedXtreamServers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No connections saved yet'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _savedXtreamServers.length,
                          itemBuilder: (context, index) {
                            final server = _savedXtreamServers[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                title: Text(
                                    server['name'] ?? 'Unnamed Connection'),
                                subtitle: Text(
                                  server['server_url'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteServer(index),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Navigate to Xtream categories screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          XtreamCategoriesScreen(
                                        connectionName: server['name'] ??
                                            'Unnamed Connection',
                                        serverUrl: server['server_url'] ?? '',
                                        username: server['username'] ?? '',
                                        password: server['password'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
