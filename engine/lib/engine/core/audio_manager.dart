import 'package:audioplayers/audioplayers.dart';
import 'asset_loader.dart';

/// Gerenciador global de áudio da engine
/// - Sons (SFX): via AudioPool (reuso eficiente)
/// - Músicas (BGM): via AudioPlayer com cache
class AudioManager {
  static final AudioManager instance = AudioManager._internal();
  AudioManager._internal();

  // Cache de pools de efeitos sonoros
  final Map<String, AudioPool> _soundPools = {};

  // Cache de players de músicas
  final Map<String, AudioPlayer> _musicPlayers = {};

  // ===========================================================
  // Sons (SFX)
  // ===========================================================

  /// Prepara (ou reutiliza) um pool para um efeito sonoro
  Future<AudioPool> _getSoundPool(String path, {int maxPlayers = 4}) async {
    if (_soundPools.containsKey(path)) {
      return _soundPools[path]!;
    }

    final source = AssetLoader.getSoundSource(path);
    final pool = await AudioPool.create(source: source, maxPlayers: maxPlayers);

    _soundPools[path] = pool;
    return pool;
  }

  /// Toca um efeito sonoro curto
  Future<void> playSound(
    String path, {
    double volume = 1.0,
    int maxPlayers = 4,
  }) async {
    final pool = await _getSoundPool(path, maxPlayers: maxPlayers);
    pool.start(volume: volume);
  }

  /// Remove manualmente um efeito do cache
  Future<void> disposeSound(String path) async {
    if (_soundPools.containsKey(path)) {
      await _soundPools[path]!.dispose();
      _soundPools.remove(path);
    }
  }

  /// Remove todos os efeitos do cache
  Future<void> disposeAllSounds() async {
    for (final pool in _soundPools.values) {
      await pool.dispose();
    }
    _soundPools.clear();
  }

  // ===========================================================
  // Músicas (BGM)
  // ===========================================================

  /// Inicia música em loop (ou ignora se já está tocando)
  Future<void> playMusic(
    String path, {
    double volume = 1.0,
    bool loop = true,
  }) async {
    if (_musicPlayers.containsKey(path)) {
      return; // já está tocando
    }

    final player = AudioPlayer();
    await player.setVolume(volume);
    if (loop) {
      await player.setReleaseMode(ReleaseMode.loop);
    }
    await player.play(AssetLoader.getMusicSource(path));
    _musicPlayers[path] = player;
  }

  /// Para música específica
  Future<void> stopMusic(String path) async {
    if (_musicPlayers.containsKey(path)) {
      await _musicPlayers[path]!.stop();
      await _musicPlayers[path]!.dispose();
      _musicPlayers.remove(path);
    }
  }

  /// Para todas as músicas
  Future<void> stopAllMusic() async {
    for (final player in _musicPlayers.values) {
      if (player.state == PlayerState.playing) {
        await player.stop();
        await player.dispose();
      }
    }
    _musicPlayers.clear();
  }
}
