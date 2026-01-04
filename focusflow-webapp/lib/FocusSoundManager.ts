// Web Audio API wrapper matching iOS FocusSoundManager behavior

import { FocusSound } from '@/types';

class FocusSoundManager {
  private static instance: FocusSoundManager;
  private audioContext: AudioContext | null = null;
  private audioBuffer: AudioBuffer | null = null;
  private sourceNode: AudioBufferSourceNode | null = null;
  private gainNode: GainNode | null = null;
  private currentSound: FocusSound | null = null;
  private isPlaying: boolean = false;
  private startOffset: number = 0;
  private startTime: number = 0;

  private constructor() {
    // Initialize audio context on first user interaction
    if (typeof window !== 'undefined') {
      this.initAudioContext();
    }
  }

  static getInstance(): FocusSoundManager {
    if (!FocusSoundManager.instance) {
      FocusSoundManager.instance = new FocusSoundManager();
    }
    return FocusSoundManager.instance;
  }

  private async initAudioContext() {
    if (this.audioContext) return;
    
    try {
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    } catch (e) {
      console.error('Failed to initialize AudioContext:', e);
    }
  }

  private async loadSound(sound: FocusSound): Promise<AudioBuffer | null> {
    if (!this.audioContext) {
      await this.initAudioContext();
      if (!this.audioContext) return null;
    }

    try {
      const response = await fetch(`/sounds/${sound}.mp3`);
      if (!response.ok) {
        console.warn(`Sound file not found: ${sound}.mp3`);
        return null;
      }
      
      const arrayBuffer = await response.arrayBuffer();
      const audioBuffer = await this.audioContext.decodeAudioData(arrayBuffer);
      return audioBuffer;
    } catch (e) {
      console.error(`Failed to load sound ${sound}:`, e);
      return null;
    }
  }

  async play(sound: FocusSound): Promise<void> {
    // If same sound is already playing, don't restart
    if (this.currentSound === sound && this.isPlaying && this.sourceNode) {
      return;
    }

    // If same sound is loaded but paused, resume it
    if (this.currentSound === sound && !this.isPlaying && this.audioBuffer) {
      this.resume();
      return;
    }

    // Stop current sound
    this.stop();

    // Load and play new sound
    const buffer = await this.loadSound(sound);
    if (!buffer || !this.audioContext) return;

    this.audioBuffer = buffer;
    this.currentSound = sound;
    this.startOffset = 0;
    this.startTime = this.audioContext.currentTime;

    this.createSourceNode();
  }

  private createSourceNode() {
    if (!this.audioContext || !this.audioBuffer) return;

    // Create source node
    const source = this.audioContext.createBufferSource();
    source.buffer = this.audioBuffer;
    source.loop = true; // Loop infinitely like iOS

    // Create gain node for volume control
    const gain = this.audioContext.createGain();
    gain.gain.value = 1.0;

    // Connect nodes
    source.connect(gain);
    gain.connect(this.audioContext.destination);

    // Start playback
    source.start(0, this.startOffset);

    this.sourceNode = source;
    this.gainNode = gain;
    this.isPlaying = true;
  }

  pause(): void {
    if (!this.isPlaying || !this.audioContext || !this.sourceNode) return;

    // Calculate current playback position
    this.startOffset += this.audioContext.currentTime - this.startTime;
    
    // Stop current source
    try {
      this.sourceNode.stop();
    } catch (e) {
      // Source may already be stopped
    }

    this.sourceNode = null;
    this.gainNode = null;
    this.isPlaying = false;
  }

  resume(): void {
    if (this.isPlaying || !this.audioBuffer || !this.audioContext) return;

    this.startTime = this.audioContext.currentTime;
    this.createSourceNode();
  }

  stop(): void {
    if (this.sourceNode) {
      try {
        this.sourceNode.stop();
      } catch (e) {
        // Source may already be stopped
      }
    }

    this.sourceNode = null;
    this.gainNode = null;
    this.audioBuffer = null;
    this.currentSound = null;
    this.isPlaying = false;
    this.startOffset = 0;
    this.startTime = 0;
  }

  setVolume(value: number): void {
    const volume = Math.max(0, Math.min(1, value));
    if (this.gainNode) {
      this.gainNode.gain.value = volume;
    }
  }

  isPlayingSound(sound: FocusSound): boolean {
    return this.currentSound === sound && this.isPlaying;
  }

  isLoaded(sound: FocusSound): boolean {
    return this.currentSound === sound && this.audioBuffer !== null;
  }

  getCurrentSound(): FocusSound | null {
    return this.currentSound;
  }
}

// Export singleton instance
export const focusSoundManager = FocusSoundManager.getInstance();

