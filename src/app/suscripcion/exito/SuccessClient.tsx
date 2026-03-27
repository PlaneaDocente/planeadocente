
"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { CheckCircle2, ArrowRight, GraduationCap, Star } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

export default function SuccessClient() {
  const router = useRouter();

  useEffect(() => {
    const timer = setTimeout(() => router.push("/"), 10000);
    return () => clearTimeout(timer);
  }, [router]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-100 dark:from-green-950 dark:to-emerald-900 flex items-center justify-center p-4">
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ type: "spring", stiffness: 200, damping: 20 }}
        className="w-full max-w-md"
      >
        <Card className="shadow-2xl border-green-200 dark:border-green-800">
          <CardContent className="pt-8 pb-8 text-center space-y-6">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.2, type: "spring", stiffness: 300 }}
              className="w-24 h-24 rounded-full bg-green-100 dark:bg-green-900 flex items-center justify-center mx-auto"
            >
              <CheckCircle2 className="w-12 h-12 text-green-600 dark:text-green-400" />
            </motion.div>

            <div className="space-y-2">
              <h1 className="text-3xl font-bold text-green-700 dark:text-green-300">¡Pago Exitoso! 🎉</h1>
              <p className="text-muted-foreground">
                Tu suscripción a PlaneaDocente ha sido activada correctamente.
              </p>
            </div>

            <div className="space-y-2">
              {[
                { icon: GraduationCap, text: "Acceso completo activado" },
                { icon: Star, text: "15 días de prueba gratuita iniciados" },
              ].map(({ icon: Icon, text }) => (
                <div
                  key={text}
                  className="flex items-center justify-center gap-2 p-3 bg-green-50 dark:bg-green-950 rounded-lg border border-green-200 dark:border-green-800"
                >
                  <Icon className="w-5 h-5 text-green-600" />
                  <p className="text-sm font-medium text-green-700 dark:text-green-300">{text}</p>
                </div>
              ))}
            </div>

            <p className="text-xs text-muted-foreground">
              Serás redirigido automáticamente al dashboard en unos segundos...
            </p>

            <Button onClick={() => router.push("/")} className="w-full gap-2">
              Ir al Dashboard
              <ArrowRight className="w-4 h-4" />
            </Button>
          </CardContent>
        </Card>
      </motion.div>
    </div>
  );
}
