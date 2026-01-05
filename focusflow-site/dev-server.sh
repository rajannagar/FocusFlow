#!/bin/bash

# FocusFlow Site - Development Server Startup Script

echo "🚀 Starting FocusFlow Site Development Server..."
echo ""

# Check if .env.local exists
if [ ! -f .env.local ]; then
    echo "⚠️  Warning: .env.local file not found!"
    echo "   Create a .env.local file with the following variables:"
    echo "   - NEXT_PUBLIC_SITE_URL=http://localhost:3000"
    echo "   - NEXT_PUBLIC_SUPABASE_URL=your_supabase_url"
    echo "   - NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_key"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Start the dev server
echo "🌐 Starting Next.js dev server on http://localhost:3000"
echo "   Press Ctrl+C to stop the server"
echo ""

npm run dev

