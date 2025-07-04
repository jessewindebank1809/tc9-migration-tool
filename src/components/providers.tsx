'use client';

import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppNavigation } from '@/components/layout/AppNavigation';
import { AppInitializer } from '@/components/providers/AppInitializer';

// Create a client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      retry: 1,
    },
  },
});

interface ProvidersProps {
  children: React.ReactNode;
}

export function Providers({ children }: ProvidersProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <AppInitializer />
      <AppNavigation>
        {children}
      </AppNavigation>
    </QueryClientProvider>
  );
} 