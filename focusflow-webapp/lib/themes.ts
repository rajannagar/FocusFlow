// Theme system matching iOS app themes

export type AppTheme = 
  | 'forest'
  | 'neon'
  | 'peach'
  | 'cyber'
  | 'ocean'
  | 'sunrise'
  | 'amber'
  | 'mint'
  | 'royal'
  | 'slate';

export interface ThemeColors {
  accentPrimary: string;
  accentSecondary: string;
  background: string;
  backgroundElevated: string;
  backgroundSubtle: string;
  backgroundMuted: string;
}

export const themes: Record<AppTheme, ThemeColors> = {
  forest: {
    accentPrimary: 'rgb(140, 230, 179)', // #8CE6B3
    accentSecondary: 'rgb(107, 199, 158)', // #6BC79E
    background: 'rgb(13, 28, 23)', // #0D1C17
    backgroundElevated: 'rgb(20, 40, 33)', // #142821
    backgroundSubtle: 'rgb(18, 35, 29)', // #12231D
    backgroundMuted: 'rgb(25, 50, 42)', // #19322A
  },
  neon: {
    accentPrimary: 'rgb(64, 242, 217)', // #40F2D9
    accentSecondary: 'rgb(153, 102, 255)', // #9966FF
    background: 'rgb(5, 13, 31)', // #050D1F
    backgroundElevated: 'rgb(15, 23, 51)', // #0F1733
    backgroundSubtle: 'rgb(10, 18, 41)', // #0A1229
    backgroundMuted: 'rgb(20, 28, 61)', // #141C3D
  },
  peach: {
    accentPrimary: 'rgb(255, 184, 161)', // #FFB8A1
    accentSecondary: 'rgb(255, 217, 179)', // #FFD9B3
    background: 'rgb(41, 20, 28)', // #29141C
    backgroundElevated: 'rgb(60, 30, 40)', // #3C1E28
    backgroundSubtle: 'rgb(50, 25, 35)', // #321923
    backgroundMuted: 'rgb(79, 38, 46)', // #4F262E
  },
  cyber: {
    accentPrimary: 'rgb(204, 153, 255)', // #CC99FF
    accentSecondary: 'rgb(97, 220, 255)', // #61DCFF
    background: 'rgb(15, 10, 46)', // #0F0A2E
    backgroundElevated: 'rgb(30, 20, 66)', // #1E1442
    backgroundSubtle: 'rgb(23, 15, 56)', // #170F38
    backgroundMuted: 'rgb(46, 23, 82)', // #2E1752
  },
  ocean: {
    accentPrimary: 'rgb(122, 214, 255)', // #7AD6FF
    accentSecondary: 'rgb(59, 242, 245)', // #3BF2F5
    background: 'rgb(5, 20, 38)', // #051426
    backgroundElevated: 'rgb(15, 35, 58)', // #0F233A
    backgroundSubtle: 'rgb(10, 28, 48)', // #0A1C30
    backgroundMuted: 'rgb(20, 45, 70)', // #142D46
  },
  sunrise: {
    accentPrimary: 'rgb(255, 158, 161)', // #FF9EA1
    accentSecondary: 'rgb(255, 204, 140)', // #FFCC8C
    background: 'rgb(26, 15, 51)', // #1A0F33
    backgroundElevated: 'rgb(51, 30, 77)', // #331E4D
    backgroundSubtle: 'rgb(38, 23, 64)', // #261740
    backgroundMuted: 'rgb(64, 43, 92)', // #402B5C
  },
  amber: {
    accentPrimary: 'rgb(255, 199, 115)', // #FFC773
    accentSecondary: 'rgb(255, 153, 102)', // #FF9966
    background: 'rgb(26, 15, 10)', // #1A0F0A
    backgroundElevated: 'rgb(51, 30, 20)', // #331E14
    backgroundSubtle: 'rgb(38, 23, 15)', // #26170F
    backgroundMuted: 'rgb(77, 46, 26)', // #4D2E1A
  },
  mint: {
    accentPrimary: 'rgb(153, 245, 199)', // #99F5C7
    accentSecondary: 'rgb(117, 224, 235)', // #75E0EB
    background: 'rgb(5, 26, 23)', // #051A17
    backgroundElevated: 'rgb(15, 46, 41)', // #0F2E29
    backgroundSubtle: 'rgb(10, 36, 32)', // #0A2420
    backgroundMuted: 'rgb(20, 61, 54)', // #143D36
  },
  royal: {
    accentPrimary: 'rgb(166, 184, 255)', // #A6B8FF
    accentSecondary: 'rgb(128, 153, 255)', // #8099FF
    background: 'rgb(13, 13, 41)', // #0D0D29
    backgroundElevated: 'rgb(23, 23, 61)', // #17173D
    backgroundSubtle: 'rgb(18, 18, 51)', // #121233
    backgroundMuted: 'rgb(33, 33, 82)', // #212152
  },
  slate: {
    accentPrimary: 'rgb(191, 209, 245)', // #BFD1F5
    accentSecondary: 'rgb(179, 194, 230)', // #B3C2E6
    background: 'rgb(15, 18, 28)', // #0F121C
    backgroundElevated: 'rgb(28, 33, 46)', // #1C212E
    backgroundSubtle: 'rgb(21, 25, 38)', // #151926
    backgroundMuted: 'rgb(38, 46, 61)', // #262E3D
  },
};

export const themeNames: Record<AppTheme, string> = {
  forest: 'Forest',
  neon: 'Neon Glow',
  peach: 'Soft Peach',
  cyber: 'Cyber Violet',
  ocean: 'Ocean Mist',
  sunrise: 'Sunrise Coral',
  amber: 'Solar Amber',
  mint: 'Mint Aura',
  royal: 'Royal Indigo',
  slate: 'Cosmic Slate',
};

export const defaultTheme: AppTheme = 'forest';

