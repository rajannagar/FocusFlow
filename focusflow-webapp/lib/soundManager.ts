// Sound Manager for Focus Sounds
class SoundManager {
  private audio: HTMLAudioElement | null = null;
  private currentSound: string | null = null;
  private isPlaying: boolean = false;
  private volume: number = 0.5;

  play(soundId: string | null) {
    this.stop();
    
    if (!soundId) {
      return;
    }

    try {
      // For web, we'll use placeholder audio URLs
      // In production, these should be actual sound files hosted somewhere
      const soundUrl = `/sounds/${soundId}.mp3`;
      
      this.audio = new Audio(soundUrl);
      this.audio.loop = true;
      this.audio.volume = this.volume;
      
      this.audio.play().catch((error) => {
        console.warn('Could not play sound:', error);
        // Fallback: use Web Audio API or show user message
      });
      
      this.currentSound = soundId;
      this.isPlaying = true;
    } catch (error) {
      console.error('Error playing sound:', error);
    }
  }

  pause() {
    if (this.audio && this.isPlaying) {
      this.audio.pause();
      this.isPlaying = false;
    }
  }

  resume() {
    if (this.audio && this.currentSound && !this.isPlaying) {
      this.audio.play().catch((error) => {
        console.warn('Could not resume sound:', error);
      });
      this.isPlaying = true;
    }
  }

  stop() {
    if (this.audio) {
      this.audio.pause();
      this.audio.currentTime = 0;
      this.audio = null;
    }
    this.currentSound = null;
    this.isPlaying = false;
  }

  setVolume(volume: number) {
    this.volume = Math.max(0, Math.min(1, volume));
    if (this.audio) {
      this.audio.volume = this.volume;
    }
  }

  getCurrentSound(): string | null {
    return this.currentSound;
  }

  getIsPlaying(): boolean {
    return this.isPlaying;
  }
}

export const soundManager = new SoundManager();

