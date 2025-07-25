import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'letter_physics.dart';
import 'particle_effects.dart';

class ObjectPool<T> {
  final Queue<T> _available = Queue<T>();
  final Set<T> _inUse = <T>{};
  final T Function() _factory;
  final void Function(T)? _reset;
  final int _maxSize;

  ObjectPool({
    required T Function() factory,
    void Function(T)? reset,
    int maxSize = 50,
  }) : _factory = factory, _reset = reset, _maxSize = maxSize;

  T acquire() {
    T object;
    if (_available.isNotEmpty) {
      object = _available.removeFirst();
    } else {
      object = _factory();
    }
    
    _inUse.add(object);
    return object;
  }

  void release(T object) {
    if (_inUse.contains(object)) {
      _inUse.remove(object);
      
      if (_available.length < _maxSize) {
        _reset?.call(object);
        _available.add(object);
      }
    }
  }

  void clear() {
    _available.clear();
    _inUse.clear();
  }

  int get availableCount => _available.length;
  int get inUseCount => _inUse.length;
  int get totalCount => _available.length + _inUse.length;
}

class PerformanceManager {
  static PerformanceManager? _instance;
  static PerformanceManager get instance => _instance ??= PerformanceManager._();
  
  PerformanceManager._();

  // 对象池
  late final ObjectPool<LetterBody> _letterPool;
  late final ObjectPool<ParticleExplosion> _explosionPool;
  
  // 性能统计
  int _frameCount = 0;
  double _lastFpsTime = 0;
  double _currentFps = 60;
  int _activeLetters = 0;
  int _activeParticles = 0;

  void initialize() {
    _letterPool = ObjectPool<LetterBody>(
      factory: () => LetterBody(
        letter: 'A',
        color: const Color(0xFF00F3FF),
        initialPosition: Vector2.zero(),
      ),
      reset: _resetLetter,
      maxSize: 100,
    );

    _explosionPool = ObjectPool<ParticleExplosion>(
      factory: () => ParticleExplosion(
        position: Vector2.zero(),
        baseColor: const Color(0xFF00F3FF),
      ),
      reset: _resetExplosion,
      maxSize: 50,
    );
  }

  void _resetLetter(LetterBody letter) {
    // 重置字母状态
    letter.removeFromParent();
  }

  void _resetExplosion(ParticleExplosion explosion) {
    // 重置爆炸效果状态
    explosion.removeFromParent();
    explosion.particles.clear();
  }

  LetterBody acquireLetter() {
    return _letterPool.acquire();
  }

  void releaseLetter(LetterBody letter) {
    _letterPool.release(letter);
    _activeLetters--;
  }

  ParticleExplosion acquireExplosion() {
    return _explosionPool.acquire();
  }

  void releaseExplosion(ParticleExplosion explosion) {
    _explosionPool.release(explosion);
    _activeParticles--;
  }

  void updateStats(double dt) {
    _frameCount++;
    _lastFpsTime += dt;
    
    if (_lastFpsTime >= 1.0) {
      _currentFps = _frameCount / _lastFpsTime;
      _frameCount = 0;
      _lastFpsTime = 0;
    }
  }

  void incrementActiveLetters() => _activeLetters++;
  void incrementActiveParticles() => _activeParticles++;

  // 性能监控getters
  double get currentFps => _currentFps;
  int get activeLetters => _activeLetters;
  int get activeParticles => _activeParticles;
  int get availableLetters => _letterPool.availableCount;
  int get availableExplosions => _explosionPool.availableCount;
  
  Map<String, dynamic> getPerformanceStats() {
    return {
      'fps': _currentFps.toStringAsFixed(1),
      'activeLetters': _activeLetters,
      'activeParticles': _activeParticles,
      'pooledLetters': _letterPool.availableCount,
      'pooledExplosions': _explosionPool.availableCount,
      'totalLetterObjects': _letterPool.totalCount,
      'totalExplosionObjects': _explosionPool.totalCount,
    };
  }

  void dispose() {
    _letterPool.clear();
    _explosionPool.clear();
  }
}

// 性能优化的组件基类
mixin PerformanceOptimized {
  static const int maxComponentsPerFrame = 10;
  static int _componentsThisFrame = 0;
  static double _frameStartTime = 0;
  
  bool shouldUpdate(double currentTime) {
    // 重置每帧计数器
    if (currentTime - _frameStartTime > 0.016) { // ~60 FPS
      _componentsThisFrame = 0;
      _frameStartTime = currentTime;
    }
    
    // 限制每帧更新的组件数量
    if (_componentsThisFrame >= maxComponentsPerFrame) {
      return false;
    }
    
    _componentsThisFrame++;
    return true;
  }
  
  bool isOffScreen(Vector2 position, Vector2 screenSize) {
    const margin = 50.0;
    return position.x < -margin || 
           position.x > screenSize.x + margin ||
           position.y < -margin || 
           position.y > screenSize.y + margin;
  }
}