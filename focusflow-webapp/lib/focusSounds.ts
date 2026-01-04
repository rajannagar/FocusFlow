// Focus sounds matching iOS app
export enum FocusSound {
  AngelsByMySide = 'angelsbymyside',
  Fireplace = 'fireplace',
  FloatingGarden = 'floatinggarden',
  Hearty = 'hearty',
  LightRainAmbient = 'light-rain-ambient',
  LongNight = 'longnight',
  SoundAmbience = 'sound-ambience',
  StreetMarketFrance = 'street-market-gap-france',
  TheLightBetweenUs = 'thelightbetweenus',
  Underwater = 'underwater',
  Yesterday = 'yesterday',
}

export const focusSounds = [
  { id: FocusSound.AngelsByMySide, name: 'Angels by My Side', emoji: '👼' },
  { id: FocusSound.Fireplace, name: 'Cozy Fireplace', emoji: '🔥' },
  { id: FocusSound.FloatingGarden, name: 'Floating Garden', emoji: '🌺' },
  { id: FocusSound.Hearty, name: 'Hearty', emoji: '💚' },
  { id: FocusSound.LightRainAmbient, name: 'Light Rain', emoji: '🌧️' },
  { id: FocusSound.LongNight, name: 'Long Night', emoji: '🌙' },
  { id: FocusSound.SoundAmbience, name: 'Soft Ambience', emoji: '🌊' },
  { id: FocusSound.StreetMarketFrance, name: 'French Street Market', emoji: '🇫🇷' },
  { id: FocusSound.TheLightBetweenUs, name: 'The Light Between Us', emoji: '✨' },
  { id: FocusSound.Underwater, name: 'Underwater', emoji: '🌊' },
  { id: FocusSound.Yesterday, name: 'Yesterday', emoji: '🎵' },
];

export function getFocusSoundName(soundId: string): string {
  return focusSounds.find(s => s.id === soundId)?.name || soundId;
}

