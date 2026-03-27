
"use client";

import { useState } from "react";
import { CheckCircle2, XCircle, Clock, CreditCard, RefreshCw } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

interface PaymentRecord {
  id: string;
  fecha: string;
  descripcion: string;
  monto: string;
  estado: "succeeded" | "pending" | "failed";
  metodo: string;
}

const MOCK_PAYMENTS: PaymentRecord[] = [
  { id: "pi_001", fecha: "2025-06-01", descripcion: "PlaneaDocente Profesional - Mensual", monto: "$199.00 MXN", estado: "succeeded", metodo: "Visa •••• 4242" },
  { id: "pi_002", fecha: "2025-05-01", descripcion: "PlaneaDocente Profesional - Mensual", monto: "$199.00 MXN", estado: "succeeded", metodo: "Visa •••• 4242" },
  { id: "pi_003", fecha: "2025-04-01", descripcion: "PlaneaDocente Básico - Mensual", monto: "$99.00 MXN", estado: "failed", metodo: "Mastercard •••• 5555" },
];

const estadoBadge = {
  succeeded: { label: "Pagado", icon: CheckCircle2, className: "bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300" },
  pending: { label: "Pendiente", icon: Clock, className: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300" },
  failed: { label: "Fallido", icon: XCircle, className: "bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300" },
};

export default function PaymentHistoryTable() {
  const [payments] = useState<PaymentRecord[]>(MOCK_PAYMENTS);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await new Promise((r) => setTimeout(r, 800));
    setIsRefreshing(false);
  };

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-3">
        <div>
          <CardTitle className="text-base">Historial de Pagos</CardTitle>
          <CardDescription>Registro de todos tus pagos y suscripciones</CardDescription>
        </div>
        <Button variant="ghost" size="sm" onClick={handleRefresh} disabled={isRefreshing}>
          <RefreshCw className={`w-4 h-4 mr-1 ${isRefreshing ? "animate-spin" : ""}`} />
          Actualizar
        </Button>
      </CardHeader>
      <CardContent>
        {payments.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            <CreditCard className="w-10 h-10 mx-auto mb-2 opacity-30" />
            <p className="text-sm">No hay pagos registrados aún</p>
          </div>
        ) : (
          <div className="space-y-2">
            {payments.map((p) => {
              const status = estadoBadge[p.estado];
              const StatusIcon = status.icon;
              return (
                <div
                  key={p.id}
                  className="flex items-center justify-between p-3 rounded-lg border bg-muted/30 hover:bg-muted/50 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                      <CreditCard className="w-4 h-4 text-primary" />
                    </div>
                    <div>
                      <p className="text-sm font-medium">{p.descripcion}</p>
                      <p className="text-xs text-muted-foreground">{p.fecha} · {p.metodo}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-sm font-semibold">{p.monto}</span>
                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${status.className}`}>
                      <StatusIcon className="w-3 h-3" />
                      {status.label}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
