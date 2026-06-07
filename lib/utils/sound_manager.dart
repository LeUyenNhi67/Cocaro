import 'package:flutter/foundation.dart';
import 'dart:js' as js;

class SoundManager {
  /// Play a short tap sound when the local player places a piece.
  static void playMove() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('eval', [
        """
        (function() {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          window.__caroAudioCtx = window.__caroAudioCtx || new AudioCtx();
          var ctx = window.__caroAudioCtx;
          var osc = ctx.createOscillator();
          var gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(620, ctx.currentTime);
          osc.frequency.exponentialRampToValueAtTime(840, ctx.currentTime + 0.08);
          gain.gain.setValueAtTime(0.0001, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.09, ctx.currentTime + 0.01);
          gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.13);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start();
          osc.stop(ctx.currentTime + 0.14);
        })()
      """,
      ]);
    } catch (e) {
      debugPrint('Error playing move sound: $e');
    }
  }

  /// Play a cheerful major arpeggio when a player wins
  static void playWin() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('eval', [
        """
        (function() {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          window.__caroAudioCtx = window.__caroAudioCtx || new AudioCtx();
          var ctx = window.__caroAudioCtx;
          function playTone(freq, type, duration, delay, volume) {
            setTimeout(() => {
              var osc = ctx.createOscillator();
              var gain = ctx.createGain();
              osc.type = type;
              osc.frequency.value = freq;
              gain.gain.setValueAtTime(0.0001, ctx.currentTime);
              gain.gain.exponentialRampToValueAtTime(volume || 0.08, ctx.currentTime + 0.03);
              gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + duration);
              osc.connect(gain);
              gain.connect(ctx.destination);
              osc.start();
              osc.stop(ctx.currentTime + duration);
            }, delay);
          }
          var notes = [523.25, 659.25, 783.99, 1046.5, 1318.51, 1567.98, 1046.5];
          notes.forEach(function(freq, index) {
            playTone(freq, index < 4 ? 'triangle' : 'sine', 0.42, index * 170, 0.075);
          });
          playTone(261.63, 'sine', 1.45, 980, 0.045);
          playTone(329.63, 'sine', 1.45, 1020, 0.04);
          playTone(392.00, 'sine', 1.45, 1060, 0.04);
        })()
      """,
      ]);
    } catch (e) {
      debugPrint('Error playing win sound: $e');
    }
  }

  /// Play a sad descending sequence when a player loses to the AI
  static void playLose() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('eval', [
        """
        (function() {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          window.__caroAudioCtx = window.__caroAudioCtx || new AudioCtx();
          var ctx = window.__caroAudioCtx;
          function playTone(freq, type, duration, delay, volume) {
            setTimeout(() => {
              var osc = ctx.createOscillator();
              var gain = ctx.createGain();
              osc.type = type;
              osc.frequency.value = freq;
              gain.gain.setValueAtTime(0.0001, ctx.currentTime);
              gain.gain.exponentialRampToValueAtTime(volume || 0.08, ctx.currentTime + 0.04);
              gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + duration);
              osc.connect(gain);
              gain.connect(ctx.destination);
              osc.start();
              osc.stop(ctx.currentTime + duration);
            }, delay);
          }
          playTone(392.00, 'triangle', 0.65, 0, 0.08);
          playTone(349.23, 'triangle', 0.75, 280, 0.075);
          playTone(311.13, 'triangle', 0.9, 620, 0.07);
          playTone(261.63, 'sine', 1.3, 1050, 0.055);
          playTone(196.00, 'sine', 1.6, 1250, 0.035);
        })()
      """,
      ]);
    } catch (e) {
      debugPrint('Error playing lose sound: $e');
    }
  }

  /// Play a neutral double-beep sound for a draw game
  static void playDraw() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('eval', [
        """
        (function() {
          var ctx = new (window.AudioContext || window.webkitAudioContext)();
          function playTone(freq, type, duration, delay) {
            setTimeout(() => {
              var osc = ctx.createOscillator();
              var gain = ctx.createGain();
              osc.type = type;
              osc.frequency.value = freq;
              gain.gain.setValueAtTime(0.08, ctx.currentTime);
              gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + duration);
              osc.connect(gain);
              gain.connect(ctx.destination);
              osc.start();
              osc.stop(ctx.currentTime + duration);
            }, delay);
          }
          // Neutral double beep (A4 -> A4)
          playTone(440.00, 'sine', 0.15, 0);
          playTone(440.00, 'sine', 0.15, 200);
        })()
      """,
      ]);
    } catch (e) {
      debugPrint('Error playing draw sound: $e');
    }
  }
}
