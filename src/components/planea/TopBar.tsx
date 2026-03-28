
"use client";

import { Menu, Bell, Search, Moon, Sun } from "lucide-react";
import { useTheme } from "next-themes";
import { useAppStore } from "@/store/app-store";
import { Button } from "@/components/ui/button";

const sectionTitles: Record<string, string> = {
  inicio: "Dashboard",
  alumnos: "Alumnos",
  asistencia: "Asistencia",
  planeacion: "Planeación",
  actividades: "Actividades",
  evaluaciones: "Evaluaciones",
  evidencias: "Evidencias",
  reportes: "Reportes",
  padres: "Comunicación con Padres",
  configuracion: "Configuración",
  descargas: "Descargar PlaneaDocente",
  "herramientas-ia": "Herramientas IA",
  suscripcion: "Planes y Suscripción",
};

export default function TopBar() {
  const { toggleSidebar, activeSection } = useAppStore();
  const { theme, setTheme } = useTheme();

  return (
    <header className="h-16 bg-card border-b border-border flex items-center px-4 gap-4 sticky top-0 z-10 shadow-sm">
      <Button variant="ghost" size="icon" onClick={toggleSidebar} className="shrink-0">
        <Menu className="w-5 h-5" />
      </Button>

      <div className="flex-1">
        <h2 className="font-semibold text-base text-foreground">
          {sectionTitles[activeSection] ?? "PlaneaDocente"}
        </h2>
        <p className="text-xs text-muted-foreground">Ciclo Escolar 2024-2025</p>
      </div>

      <div className="hidden md:flex items-center gap-2 bg-muted rounded-lg px-3 py-1.5">
        <Search className="w-4 h-4 text-muted-foreground" />
        <input
          placeholder="Buscar..."
          className="bg-transparent text-sm outline-none w-40 placeholder:text-muted-foreground"
        />
      </div>

      <Button variant="ghost" size="icon" className="relative">
        <Bell className="w-5 h-5" />
        <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full" />
      </Button>

      <Button
        variant="ghost"
        size="icon"
        onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
      >
        <Sun className="w-4 h-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
        <Moon className="absolute w-4 h-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
      </Button>
    </header>
  );
}
