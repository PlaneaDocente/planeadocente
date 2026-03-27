
"use client";

import React, { createContext, useContext, useState, useCallback } from "react";

export type ActiveSection =
  | "inicio"
  | "alumnos"
  | "asistencia"
  | "planeacion"
  | "actividades"
  | "evaluaciones"
  | "evidencias"
  | "reportes"
  | "padres"
  | "configuracion"
  | "descargas"
  | "herramientas-ia"
  | "suscripcion";

interface AppStoreState {
  activeSection: ActiveSection;
  sidebarOpen: boolean;
  setActiveSection: (section: ActiveSection) => void;
  toggleSidebar: () => void;
  setSidebarOpen: (open: boolean) => void;
}

const AppStoreContext = createContext<AppStoreState | null>(null);

export function AppStoreProvider({ children }: { children: React.ReactNode }) {
  const [activeSection, setActiveSectionState] = useState<ActiveSection>("inicio");
  const [sidebarOpen, setSidebarOpenState] = useState(true);

  const setActiveSection = useCallback((section: ActiveSection) => {
    setActiveSectionState(section);
  }, []);

  const toggleSidebar = useCallback(() => {
    setSidebarOpenState((prev) => !prev);
  }, []);

  const setSidebarOpen = useCallback((open: boolean) => {
    setSidebarOpenState(open);
  }, []);

  return (
    <AppStoreContext.Provider
      value={{ activeSection, sidebarOpen, setActiveSection, toggleSidebar, setSidebarOpen }}
    >
      {children}
    </AppStoreContext.Provider>
  );
}

export function useAppStore(): AppStoreState {
  const ctx = useContext(AppStoreContext);
  if (!ctx) {
    throw new Error("useAppStore must be used within AppStoreProvider");
  }
  return ctx;
}
