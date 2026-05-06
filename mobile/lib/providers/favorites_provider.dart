import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  List<String> _favoriteProductIds = [];
  bool _isLoading = false;

  FavoritesProvider({required ApiService apiService}) : _apiService = apiService;

  List<String> get favoriteProductIds => _favoriteProductIds;
  bool get isLoading => _isLoading;

  bool isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  Future<void> fetchFavorites(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _favoriteProductIds = await _apiService.getFavorites(token);
    } catch (e) {
      print('Erro ao carregar favoritos: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String token, String productId) async {
    final bool currentlyFavorite = isFavorite(productId);
    
    // Optmistic UI update
    if (currentlyFavorite) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();

    try {
      if (currentlyFavorite) {
        await _apiService.removeFavorite(token, productId);
      } else {
        await _apiService.addFavorite(token, productId);
      }
    } catch (e) {
      print('Erro ao alternar favorito: $e');
      // Rollback on failure
      if (currentlyFavorite) {
        _favoriteProductIds.add(productId);
      } else {
        _favoriteProductIds.remove(productId);
      }
      notifyListeners();
    }
  }
}
