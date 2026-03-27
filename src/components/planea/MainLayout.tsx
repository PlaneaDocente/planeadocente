
"use client";

import { AppStoreProvider, useAppStore } from "@/store/app-store";
import AppSidebar from "./AppSidebar";
import TopBar from "./TopBar";
import DashboardSection from "./DashboardSection";
import AlumnosSection from "./AlumnosSection";
import AsistenciaSection from "./AsistenciaSection";
import PlaneacionSection from "./PlaneacionSection";
import ActividadesSection from "./ActividadesSection";
import EvaluacionesSection from "./EvaluacionesSection";
import EvidenciasSection from "./EvidenciasSection";
import ReportesSection from "./ReportesSection";
import PadresSection from "./PadresSection";
import ConfiguracionSection from "./ConfiguracionSection";
import DescargasSection from "./DescargasSection";
import HerramientasIASection from "./HerramientasIASection";
import SuscripcionSection from "./SuscripcionSection";

function MainContent() {
  const { activeSection } = useAppStore();

  return (
    <div className="flex h-screen bg-background overflow-hidden">
      <AppSidebar />
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <TopBar />
        <main className="flex-1 overflow-y-auto p-4 md:p-6">
          <div className="max-w-7xl mx-auto">
            {activeSection === "inicio" && <DashboardSection />}
            {activeSection === "alumnos" && <AlumnosSection />}
            {activeSection === "asistencia" && <AsistenciaSection />}
            {activeSection === "planeacion" && <PlaneacionSection />}
            {activeSection === "actividades" && <ActividadesSection />}
            {activeSection === "evaluaciones" && <EvaluacionesSection />}
            {activeSection === "evidencias" && <EvidenciasSection />}
            {activeSection === "reportes" && <ReportesSection />}
            {activeSection === "padres" && <PadresSection />}
            {activeSection === "configuracion" && <ConfiguracionSection />}
            {activeSection === "descargas" && <DescargasSection />}
            {activeSection === "herramientas-ia" && <HerramientasIASection />}
            {activeSection === "suscripcion" && <SuscripcionSection />}
          </div>
        </main>
      </div>
    </div>
  );
}

export default function MainLayout() {
  return (
    <AppStoreProvider>
      <MainContent />
    </AppStoreProvider>
  );
}
