'use client';

import { useState } from 'react';

type Currency = 'USD' | 'CAD';

interface CurrencySelectorProps {
  onCurrencyChange: (currency: Currency) => void;
  defaultCurrency?: Currency;
}

export default function CurrencySelector({ onCurrencyChange, defaultCurrency = 'CAD' }: CurrencySelectorProps) {
  const [selectedCurrency, setSelectedCurrency] = useState<Currency>(defaultCurrency);

  const handleCurrencyChange = (currency: Currency) => {
    setSelectedCurrency(currency);
    onCurrencyChange(currency);
  };

  return (
    <div className="flex items-center gap-1 bg-[var(--background-subtle)] rounded-full p-1 border border-[var(--border)]">
      <button
        onClick={() => handleCurrencyChange('USD')}
        className={`px-4 py-2 rounded-full text-sm font-medium transition-all duration-300 ${
          selectedCurrency === 'USD'
            ? 'bg-[var(--accent-primary)] text-white shadow-sm shadow-[var(--accent-glow)]'
            : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)]'
        }`}
        type="button"
      >
        USD
      </button>
      <button
        onClick={() => handleCurrencyChange('CAD')}
        className={`px-4 py-2 rounded-full text-sm font-medium transition-all duration-300 ${
          selectedCurrency === 'CAD'
            ? 'bg-[var(--accent-primary)] text-white shadow-sm shadow-[var(--accent-glow)]'
            : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)]'
        }`}
        type="button"
      >
        CAD
      </button>
    </div>
  );
}
