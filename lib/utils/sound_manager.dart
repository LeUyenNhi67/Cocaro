import 'package:flutter/foundation.dart';
import 'dart:js' as js;

class SoundManager {
  /// Phát âm thanh click nhẹ, tức thì khi đặt quân cờ.
  /// Kết hợp oscillator sine + noise burst tạo cảm giác "snap" tự nhiên.
  static void playMove() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('eval', [
        """
        (function() {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          window.__caroAudioCtx = window.__caroAudioCtx || new AudioCtx();
          var ctx = window.__caroAudioCtx;
          if (ctx.state === 'suspended') ctx.resume();

          var now = ctx.currentTime;

          // --- Tone chính: "click" ngắn gọn ---
          var osc1 = ctx.createOscillator();
          var gain1 = ctx.createGain();
          osc1.type = 'sine';
          osc1.frequency.setValueAtTime(900, now);
          osc1.frequency.exponentialRampToValueAtTime(480, now + 0.07);
          gain1.gain.setValueAtTime(0.0001, now);
          gain1.gain.exponentialRampToValueAtTime(0.12, now + 0.008);
          gain1.gain.exponentialRampToValueAtTime(0.0001, now + 0.12);
          osc1.connect(gain1);
          gain1.connect(ctx.destination);
          osc1.start(now);
          osc1.stop(now + 0.13);

          // --- Harmonic: thêm chiều sâu ---
          var osc2 = ctx.createOscillator();
          var gain2 = ctx.createGain();
          osc2.type = 'triangle';
          osc2.frequency.setValueAtTime(1380, now);
          osc2.frequency.exponentialRampToValueAtTime(700, now + 0.06);
          gain2.gain.setValueAtTime(0.0001, now);
          gain2.gain.exponentialRampToValueAtTime(0.04, now + 0.007);
          gain2.gain.exponentialRampToValueAtTime(0.0001, now + 0.09);
          osc2.connect(gain2);
          gain2.connect(ctx.destination);
          osc2.start(now);
          osc2.stop(now + 0.1);

          // --- Noise burst: cảm giác "đặt quân" chân thực ---
          try {
            var bufferSize = Math.floor(ctx.sampleRate * 0.04);
            var noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
            var data = noiseBuffer.getChannelData(0);
            for (var i = 0; i < bufferSize; i++) {
              data[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / bufferSize, 3);
            }
            var noise = ctx.createBufferSource();
            noise.buffer = noiseBuffer;
            var noiseFilter = ctx.createBiquadFilter();
            noiseFilter.type = 'bandpass';
            noiseFilter.frequency.value = 2200;
            noiseFilter.Q.value = 0.8;
            var noiseGain = ctx.createGain();
            noiseGain.gain.setValueAtTime(0.055, now);
            noiseGain.gain.exponentialRampToValueAtTime(0.0001, now + 0.04);
            noise.connect(noiseFilter);
            noiseFilter.connect(noiseGain);
            noiseGain.connect(ctx.destination);
            noise.start(now);
          } catch(e) {}
        })()
      """,
      ]);
    } catch (e) {
      debugPrint('Error playing move sound: \$e');
    }
  }

  /// Phát nhạc chiến thắng vui vẻ khi người chơi thắng.
  /// Arpeggio thăng dần kết hợp chord nền tạo cảm giác thành tựu.
  static void playWin() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('eval', [
        """
        (function() {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          window.__caroAudioCtx = window.__caroAudioCtx || new AudioCtx();
          var ctx = window.__caroAudioCtx;
          if (ctx.state === 'suspended') ctx.resume();

          // --- Reverb đơn giản bằng convolver ---
          function createReverb(ctx, duration) {
            try {
              var len = Math.floor(ctx.sampleRate * duration);
              var impulse = ctx.createBuffer(2, len, ctx.sampleRate);
              for (var c = 0; c < 2; c++) {
                var ch = impulse.getChannelData(c);
                for (var i = 0; i < len; i++) {
                  ch[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, 2.5);
                }
              }
              var conv = ctx.createConvolver();
              conv.buffer = impulse;
              return conv;
            } catch(e) { return null; }
          }

          function playNote(freq, type, startTime, duration, vol, useReverb) {
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = type || 'triangle';
            osc.frequency.value = freq;
            gain.gain.setValueAtTime(0.0001, startTime);
            gain.gain.exponentialRampToValueAtTime(vol || 0.09, startTime + 0.025);
            gain.gain.setValueAtTime(vol || 0.09, startTime + duration * 0.65);
            gain.gain.exponentialRampToValueAtTime(0.0001, startTime + duration);
            if (useReverb) {
              var reverb = createReverb(ctx, 0.5);
              var wet = ctx.createGain();
              wet.gain.value = 0.22;
              if (reverb) {
                osc.connect(gain);
                gain.connect(reverb);
                reverb.connect(wet);
                wet.connect(ctx.destination);
                gain.connect(ctx.destination);
              } else {
                osc.connect(gain);
                gain.connect(ctx.destination);
              }
            } else {
              osc.connect(gain);
              gain.connect(ctx.destination);
            }
            osc.start(startTime);
            osc.stop(startTime + duration + 0.05);
          }

          var now = ctx.currentTime;

          // Arpeggio chính (C major pentatonic thăng dần)
          // Do  Mi  Sol Do5  Mi5 Sol5 Do6  Sol5 (hướng lên rồi giải phóng)
          var melody = [
            {f: 523.25, d: 0.18, t: 0.00},
            {f: 659.25, d: 0.18, t: 0.13},
            {f: 783.99, d: 0.18, t: 0.25},
            {f: 1046.5, d: 0.22, t: 0.37},
            {f: 1174.66,d: 0.22, t: 0.48},
            {f: 1318.51,d: 0.28, t: 0.60},
            {f: 1567.98,d: 0.38, t: 0.73},
            {f: 2093.0, d: 0.65, t: 0.90},
          ];
          melody.forEach(function(n) {
            playNote(n.f, 'triangle', now + n.t, n.d, 0.085, false);
          });

          // Chord nền (C major) xuất hiện sau 0.85s
          var chordTime = now + 0.85;
          [[261.63, 'sine', 1.1, 0.045],
           [329.63, 'sine', 1.1, 0.038],
           [392.00, 'sine', 1.1, 0.038],
           [523.25, 'sine', 1.1, 0.032]
          ].forEach(function(c) {
            playNote(c[0], c[1], chordTime, c[2], c[3], true);
          });

          // "Shine" glitter: sparkle cao nhẹ
          [2093.0, 2349.32, 2637.02].forEach(function(freq, i) {
            playNote(freq, 'sine', now + 0.95 + i * 0.09, 0.15, 0.022, false);
          });
        })()
      """,
      ]);
    } catch (e) {
      debugPrint('Error playing win sound: \$e');
    }
  }

  /// Phát âm thanh thất bại nhẹ nhàng, tiếc nuối khi thua AI.
  /// Giai điệu xuống dần với vibrato tạo cảm giác buồn nhưng không nặng nề.
  static void playLose() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('eval', [
        """
        (function() {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          window.__caroAudioCtx = window.__caroAudioCtx || new AudioCtx();
          var ctx = window.__caroAudioCtx;
          if (ctx.state === 'suspended') ctx.resume();

          function playNoteWithVibrato(freq, type, startTime, duration, vol, vibratoDepth, vibratoRate) {
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = type || 'sine';
            osc.frequency.value = freq;

            // Vibrato
            if (vibratoDepth && vibratoRate) {
              var lfo = ctx.createOscillator();
              var lfoGain = ctx.createGain();
              lfo.type = 'sine';
              lfo.frequency.value = vibratoRate;
              lfoGain.gain.value = vibratoDepth;
              lfo.connect(lfoGain);
              lfoGain.connect(osc.frequency);
              lfo.start(startTime + 0.08);
              lfo.stop(startTime + duration);
            }

            gain.gain.setValueAtTime(0.0001, startTime);
            gain.gain.exponentialRampToValueAtTime(vol || 0.07, startTime + 0.06);
            gain.gain.setValueAtTime(vol || 0.07, startTime + duration * 0.6);
            gain.gain.exponentialRampToValueAtTime(0.0001, startTime + duration);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(startTime);
            osc.stop(startTime + duration + 0.05);
          }

          var now = ctx.currentTime;

          // Giai điệu xuống: Sol -> Fa -> Mi -> Re -> Do (diatonic descend)
          // Mỗi nốt có vibrato tăng dần để tạo cảm giác ngân dài, tiếc nuối
          var notes = [
            {f: 392.00, t: 0.00, d: 0.55, v: 0.082, vd: 3,  vr: 4.5},
            {f: 349.23, t: 0.38, d: 0.60, v: 0.076, vd: 4,  vr: 4.8},
            {f: 329.63, t: 0.80, d: 0.65, v: 0.070, vd: 5,  vr: 5.0},
            {f: 293.66, t: 1.26, d: 0.75, v: 0.062, vd: 6,  vr: 5.2},
            {f: 261.63, t: 1.78, d: 1.10, v: 0.052, vd: 7,  vr: 4.8},
          ];
          notes.forEach(function(n) {
            playNoteWithVibrato(n.f, 'triangle', now + n.t, n.d, n.v, n.vd, n.vr);
          });

          // Nốt cuối thấp hơn: tạo cảm giác "nặng lòng" nhẹ
          playNoteWithVibrato(196.00, 'sine', now + 2.05, 1.0, 0.035, 3, 4.0);

          // Harmony nhẹ phía sau
          playNoteWithVibrato(329.63, 'sine', now + 0.80, 1.45, 0.022, 4, 5.0);
          playNoteWithVibrato(261.63, 'sine', now + 1.26, 1.60, 0.018, 5, 4.8);
        })()
      """,
      ]);
    } catch (e) {
      debugPrint('Error playing lose sound: \$e');
    }
  }

  /// Phát âm thanh hòa cờ: trung lập, cân bằng, không vui không buồn.
  static void playDraw() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('eval', [
        """
        (function() {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          window.__caroAudioCtx = window.__caroAudioCtx || new AudioCtx();
          var ctx = window.__caroAudioCtx;
          if (ctx.state === 'suspended') ctx.resume();

          function playTone(freq, type, startTime, duration, vol) {
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = type || 'sine';
            osc.frequency.value = freq;
            gain.gain.setValueAtTime(0.0001, startTime);
            gain.gain.exponentialRampToValueAtTime(vol || 0.07, startTime + 0.04);
            gain.gain.exponentialRampToValueAtTime(0.0001, startTime + duration);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(startTime);
            osc.stop(startTime + duration + 0.05);
          }

          var now = ctx.currentTime;

          // Double beep trung lập: lên rồi xuống nhẹ (A4 -> F#4 -> A4)
          playTone(440.00, 'sine',     now + 0.00, 0.22, 0.075);
          playTone(369.99, 'triangle', now + 0.22, 0.22, 0.060);
          playTone(440.00, 'sine',     now + 0.44, 0.35, 0.065);

          // Chord nhẹ nhàng (A minor: A-C-E) kết thúc
          playTone(220.00, 'sine',     now + 0.55, 0.80, 0.030);
          playTone(261.63, 'sine',     now + 0.58, 0.78, 0.025);
          playTone(329.63, 'sine',     now + 0.61, 0.76, 0.020);
        })()
      """,
      ]);
    } catch (e) {
      debugPrint('Error playing draw sound: \$e');
    }
  }
}
