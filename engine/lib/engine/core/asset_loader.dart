import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Classe responsável por carregar e cachear assets (imagens, sons, músicas, etc.)
class AssetLoader {
  // 🔹 Pastas padrão
  static final String _assetFolder =
      "assets"; // Não pode ser alterado pela estrutura do audioplayers
  static String _imagesFolder = "images";
  static String _soundsFolder = "sounds";
  static String _musicFolder = "music";

  // 🔹 Cache
  static final Map<String, ui.Image> _imageCache = {};

  // ===========================================================
  // Configuração de pastas
  // ===========================================================

  /// Define a pasta de imagens (default: "images")
  static void setImagesFolder(String folder) {
    _imagesFolder = folder;
  }

  /// Define a pasta de sons (default: "sounds")
  static void setSoundsFolder(String folder) {
    _soundsFolder = folder;
  }

  /// Define a pasta de músicas (default: "music")
  static void setMusicFolder(String folder) {
    _musicFolder = folder;
  }

  // ===========================================================
  // Métodos para Imagens
  // ===========================================================

  /// Carrega uma imagem a partir dos assets, com cache.
  /// Exemplo:
  ///   AssetLoader.loadImage("player.png")
  ///   -> assets/images/player.png
  static Future<ui.Image> loadImage(String path) async {
    final fullPath = "$_assetFolder/$_imagesFolder/$path";

    if (_imageCache.containsKey(fullPath)) {
      return _imageCache[fullPath]!;
    }

    final data = await rootBundle.load(fullPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();

    _imageCache[fullPath] = frame.image;
    return frame.image;
  }

  static ui.Image? getCachedImage(String path) {
    final fullPath = "$_assetFolder/$_imagesFolder/$path";
    return _imageCache[fullPath];
  }

  // ===========================================================
  // Métodos para Sons (SFX) — stub
  // ===========================================================

  /// Retorna o source do som.
  /// Exemplo:
  ///   AssetLoader.getSoundSource("explosion.mp3")
  ///   -> assets/sounds/explosion.mp3
  static AssetSource getSoundSource(String path) {
    final fullPath = "$_soundsFolder/$path";
    return AssetSource(fullPath);
  }

  // ===========================================================
  // Métodos para Músicas (BGM) — stub
  // ===========================================================

  /// Retorna o source da música.
  /// Exemplo:
  ///   AssetLoader.getMusicSource("theme.mp3")
  ///   -> assets/music/theme.mp3
  static AssetSource getMusicSource(String path) {
    final fullPath = "$_musicFolder/$path";
    return AssetSource(fullPath);
  }

  // ===========================================================
  // Métodos utilitários
  // ===========================================================

  static void clearImageCache() => _imageCache.clear();

  static void removeImageFromCache(String path) {
    final fullPath = "$_imagesFolder/$path";
    _imageCache.remove(fullPath);
  }
}
