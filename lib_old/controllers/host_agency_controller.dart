import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HostAgencyController extends ChangeNotifier {
  List<Map<String, dynamic>> _hosts = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _applicationStatus;

  List<Map<String, dynamic>> get hosts => _hosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get applicationStatus => _applicationStatus;

  HostAgencyController() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load hosts
      final hostsJson = prefs.getStringList('hosts') ?? [];
      _hosts = hostsJson.map((json) {
        final parts = json.split('|');
        return {
          'id': parts[0],
          'name': parts[1],
          'hours': parts[2],
          'target': parts[3],
          'progress': double.tryParse(parts[4]) ?? 0.0,
          'earnings': parts[5],
          'status': parts.length > 6 ? parts[6] : 'active',
        };
      }).toList();
      
      // Load application status
      final applicationJson = prefs.getString('host_application');
      if (applicationJson != null) {
        final parts = applicationJson.split('|');
        _applicationStatus = {
          'id': parts[0],
          'name': parts[1],
          'proof': parts[2],
          'status': parts[3], // 'pending', 'approved', 'rejected'
          'submittedAt': parts[4],
        };
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitApplication({
    required String id,
    required String name,
    required String proof,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      final prefs = await SharedPreferences.getInstance();
      final applicationJson = '$id|$name|$proof|pending|${DateTime.now().toIso8601String()}';
      await prefs.setString('host_application', applicationJson);
      
      _applicationStatus = {
        'id': id,
        'name': name,
        'proof': proof,
        'status': 'pending',
        'submittedAt': DateTime.now().toIso8601String(),
      };
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addHost({
    required String id,
    required String name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      final newHost = {
        'id': id,
        'name': name,
        'hours': '0',
        'target': '20h',
        'progress': 0.0,
        'earnings': '0',
        'status': 'active',
      };
      
      _hosts.add(newHost);
      
      final prefs = await SharedPreferences.getInstance();
      final hostsJson = _hosts.map((host) => 
        '${host['id']}|${host['name']}|${host['hours']}|${host['target']}|${host['progress']}|${host['earnings']}|${host['status']}'
      ).toList();
      await prefs.setStringList('hosts', hostsJson);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeHost(String hostId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      _hosts.removeWhere((host) => host['id'] == hostId);
      
      final prefs = await SharedPreferences.getInstance();
      final hostsJson = _hosts.map((host) => 
        '${host['id']}|${host['name']}|${host['hours']}|${host['target']}|${host['progress']}|${host['earnings']}|${host['status']}'
      ).toList();
      await prefs.setStringList('hosts', hostsJson);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHostProgress(String hostId, double progress) async {
    try {
      final index = _hosts.indexWhere((host) => host['id'] == hostId);
      if (index != -1) {
        _hosts[index]['progress'] = progress.clamp(0.0, 1.0);
        
        final prefs = await SharedPreferences.getInstance();
        final hostsJson = _hosts.map((host) => 
          '${host['id']}|${host['name']}|${host['hours']}|${host['target']}|${host['progress']}|${host['earnings']}|${host['status']}'
        ).toList();
        await prefs.setStringList('hosts', hostsJson);
        
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
