
"use client";

import { motion, AnimatePresence } from "framer-motion";
import {
  Home, Users, CalendarCheck, BookOpen, Target,
  BarChart3, Camera, FileText, MessageSquare, Settings,
  Download, X, GraduationCap, ChevronRight, Wand2, CreditCard,
} from "lucide-react";
import { useAppStore } from "@/store/app-store";
import { cn } from "@/lib/utils";

const navItems = [
  { id: "inicio", label: "Inicio", icon: Home, emoji: "🏠" },
  { id: "alumnos", label: "Alumnos", icon: Users, emoji: "📚" },
  { id: "asistencia", label: "Asistencia", icon: CalendarCheck, emoji: "📅" },
  { id: "planeacion", label: "Planeación", icon: BookOpen, emoji: "📝" },
  { id: "actividades", label: "Actividades", icon: Target, emoji: "🎯" },
  { id: "evaluaciones", label: "Evaluaciones", icon: BarChart3, emoji: "📊" },
  { id: "evidencias", label: "Evidencias", icon: Camera, emoji: "📷" },
  { id: "reportes", label: "Reportes", icon: FileText, emoji: "📄" },
  { id: "padres", label: "Padres", icon: MessageSquare, emoji: "👨‍👩‍👧" },
  { id: "herramientas-ia", label: "Herramientas IA", icon: Wand2, emoji: "🤖" },
  { id: "suscripcion", label: "Suscripción", icon: CreditCard, emoji: "💳" },
  { id: "configuracion", label: "Configuración", icon: Settings, emoji: "⚙️" },
  { id: "descargas", label: "Descargar App", icon: Download, emoji: "⬇️" },
] as const;

export default function AppSidebar() {
  const { activeSection, setActiveSection, sidebarOpen, setSidebarOpen } = useAppStore();

  return (
    <>
      <AnimatePresence>
        {sidebarOpen && (
          <motion.div
            className="fixed inset-0 bg-black/40 z-20 lg:hidden"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setSidebarOpen(false)}
          />
        )}
      </AnimatePresence>

      <motion.aside
        className={cn(
          "fixed top-0 left-0 h-full z-30 flex flex-col",
          "bg-sidebar text-sidebar-foreground shadow-2xl",
          "lg:relative lg:translate-x-0"
        )}
        initial={false}
        animate={{ width: sidebarOpen ? 256 : 0, x: sidebarOpen ? 0 : -256 }}
        transition={{ type: "spring", stiffness: 300, damping: 30 }}
        style={{ overflow: "hidden" }}
      >
        <div className="flex flex-col h-full min-w-[256px]">
          <SidebarHeader onClose={() => setSidebarOpen(false)} />
          <nav className="flex-1 overflow-y-auto py-4 px-3">
            {navItems.map((item) => (
              <NavItem
                key={item.id}
                item={item}
                isActive={activeSection === item.id}
                onClick={() => {
                  setActiveSection(item.id as typeof activeSection);
                  if (window.innerWidth < 1024) setSidebarOpen(false);
                }}
              />
            ))}
          </nav>
          <SidebarFooter />
        </div>
      </motion.aside>
    </>
  );
}

function SidebarHeader({ onClose }: { onClose: () => void }) {
  return (
    <div className="flex items-center justify-between px-4 py-5 border-b border-sidebar-border">
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 rounded-xl bg-primary flex items-center justify-center shadow-lg">
          <GraduationCap className="w-5 h-5 text-white" />
        </div>
        <div>
          <h1 className="font-bold text-base text-sidebar-foreground leading-tight">PlaneaDocente</h1>
          <p className="text-xs text-sidebar-foreground/60">Sistema Educativo</p>
        </div>
      </div>
      <button
        onClick={onClose}
        className="lg:hidden p-1.5 rounded-lg hover:bg-sidebar-accent transition-colors"
      >
        <X className="w-4 h-4" />
      </button>
    </div>
  );
}

function NavItem({
  item,
  isActive,
  onClick,
}: {
  item: (typeof navItems)[number];
  isActive: boolean;
  onClick: () => void;
}) {
  const isSubscription = item.id === "suscripcion";
  return (
    <motion.button
      onClick={onClick}
      whileHover={{ x: 4 }}
      whileTap={{ scale: 0.97 }}
      className={cn(
        "w-full flex items-center gap-3 px-3 py-2.5 rounded-xl mb-1 text-sm font-medium transition-all",
        isActive
          ? "bg-sidebar-primary text-sidebar-primary-foreground shadow-md"
          : isSubscription
          ? "text-yellow-400 hover:bg-yellow-500/10 border border-yellow-500/30"
          : "text-sidebar-foreground/80 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
      )}
    >
      <span className="text-base">{item.emoji}</span>
      <span className="flex-1 text-left">{item.label}</span>
      {isActive && <ChevronRight className="w-3.5 h-3.5 opacity-70" />}
      {isSubscription && !isActive && (
        <span className="text-xs bg-yellow-500/20 text-yellow-400 px-1.5 py-0.5 rounded-full font-bold">
          PRO
        </span>
      )}
    </motion.button>
  );
}

function SidebarFooter() {
  return (
    <div className="px-4 py-4 border-t border-sidebar-border">
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 rounded-full bg-sidebar-accent flex items-center justify-center">
          <span className="text-xs font-bold text-sidebar-accent-foreground">MA</span>
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-xs font-semibold text-sidebar-foreground truncate">Maestra Ana</p>
          <p className="text-xs text-sidebar-foreground/50 truncate">3°A · Primaria</p>
        </div>
      </div>
    </div>
  );
}
