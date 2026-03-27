
"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  CreditCard, Check, Star, Zap, Shield, Clock,
  Crown, AlertCircle, Loader2, CheckCircle2,
  Gift, X, ExternalLink, TrendingUp, RefreshCw,
  ChevronRight, XCircle,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { toast } from "sonner";
import StripeConfigModal from "./StripeConfigModal";
import PaymentHistoryTable from "./PaymentHistoryTable";

interface Plan {
  id: string;
  name: string;
  monthlyPrice: number;
  annualPrice: number;
  annualSavings: number;
  gradient: string;
  icon: React.ElementType;
  badge?: string;
  features: string[];
  popular?: boolean;
}

const plans: Plan[] = [
  {
    id: "basico",
    name: "Básico",
    monthlyPrice: 9900,
    annualPrice: 99000,
    annualSavings: 19800,
    gradient: "from-blue-500 to-blue-700",
    icon: Zap,
    features: [
      "Hasta 35 alumnos",
      "Registro de asistencia",
      "Planeaciones básicas",
      "Reportes simples",
      "Soporte por email",
    ],
  },
  {
    id: "profesional",
    name: "Profesional",
    monthlyPrice: 19900,
    annualPrice: 199000,
    annualSavings: 39800,
    gradient: "from-violet-600 to-purple-700",
    icon: Star,
    badge: "⭐ Más Popular",
    popular: true,
    features: [
      "Alumnos ilimitados",
      "Herramientas de IA incluidas",
      "Generación de imágenes IA",
      "Planeaciones con IA",
      "Evidencias y portafolio",
      "Comunicación con padres",
      "Reportes avanzados",
      "Soporte prioritario",
    ],
  },
  {
    id: "institucional",
    name: "Institucional",
    monthlyPrice: 49900,
    annualPrice: 499000,
    annualSavings: 99800,
    gradient: "from-amber-500 to-orange-600",
    icon: Crown,
    badge: "🏫 Para Escuelas",
    features: [
      "Todo lo de Profesional",
      "Múltiples maestros",
      "Panel de director",
      "Gestión de grupos",
      "Reportes institucionales",
      "Integración con SEP",
      "Capacitación incluida",
      "Soporte 24/7 dedicado",
    ],
  },
];

function formatPrice(cents: number): string {
  return `$${(cents / 100).toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ",")}`;
}

export default function SuscripcionSection() {
  const [billingInterval, setBillingInterval] = useState<"month" | "year">("month");
  const [isLoading, setIsLoading] = useState<string | null>(null);
  const [showStripeConfig, setShowStripeConfig] = useState(false);

  const handleSubscribe = async (plan: Plan) => {
    setIsLoading(plan.id);
    const unitAmount = billingInterval === "year" ? plan.annualPrice : plan.monthlyPrice;

    try {
      const res = await fetch("/next_api/stripe/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          productName: `PlaneaDocente ${plan.name} - ${billingInterval === "year" ? "Anual" : "Mensual"}`,
          amount: unitAmount,
          currency: "mxn",
          quantity: 1,
          interval: billingInterval,
        }),
      });

      const data = await res.json();

      if (data?.data?.url) {
        window.location.href = data.data.url;
      } else {
        toast.error("No se pudo iniciar el pago. Verifica la configuración de Stripe.");
      }
    } catch {
      toast.error("Error de conexión. Intenta de nuevo.");
    } finally {
      setIsLoading(null);
    }
  };

  return (
    <div className="space-y-8">
      <HeroBanner />
      <TrialBanner />

      <BillingToggle billingInterval={billingInterval} onChange={setBillingInterval} />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {plans.map((plan, i) => (
          <PlanCard
            key={plan.id}
            plan={plan}
            index={i}
            billingInterval={billingInterval}
            isLoading={isLoading === plan.id}
            onSubscribe={handleSubscribe}
          />
        ))}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <TrustCard icon={<Shield className="w-6 h-6 text-green-500" />} title="Pago Seguro" desc="Procesado por Stripe con cifrado SSL de 256 bits" />
        <TrustCard icon={<Zap className="w-6 h-6 text-yellow-500" />} title="Activación Inmediata" desc="Tu suscripción se activa al instante después del pago" />
        <TrustCard icon={<Star className="w-6 h-6 text-blue-500" />} title="Cancela Cuando Quieras" desc="Sin contratos ni penalizaciones por cancelación" />
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-3">
          <div>
            <CardTitle className="text-base">Configuración de Stripe</CardTitle>
            <CardDescription>Conecta tu cuenta de Stripe para recibir pagos de tus suscriptores</CardDescription>
          </div>
          <Button variant="outline" size="sm" onClick={() => setShowStripeConfig(true)}>
            <CreditCard className="w-4 h-4 mr-2" />
            Configurar Stripe
          </Button>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {[
              { label: "STRIPE_SECRET_KEY", desc: "Clave secreta del servidor (sk_live_...)", icon: Shield },
              { label: "STRIPE_WEBHOOK_SECRET", desc: "Para confirmar pagos (whsec_...)", icon: TrendingUp },
            ].map((item) => {
              const Icon = item.icon;
              return (
                <div key={item.label} className="flex items-start gap-2 bg-muted/50 rounded-lg p-3">
                  <Icon className="w-4 h-4 text-muted-foreground shrink-0 mt-0.5" />
                  <div>
                    <p className="text-xs font-mono font-medium">{item.label}</p>
                    <p className="text-xs text-muted-foreground">{item.desc}</p>
                  </div>
                </div>
              );
            })}
          </div>
          <p className="text-xs text-muted-foreground mt-3">
            Estas variables deben configurarse en el servidor. Obtén tus claves en{" "}
            <a href="https://dashboard.stripe.com/apikeys" target="_blank" rel="noopener noreferrer" className="text-primary underline inline-flex items-center gap-1">
              dashboard.stripe.com <ExternalLink className="w-3 h-3" />
            </a>
          </p>
        </CardContent>
      </Card>

      <PaymentHistoryTable />

      <FaqSection />

      <AnimatePresence>
        {showStripeConfig && (
          <StripeConfigModal onClose={() => setShowStripeConfig(false)} />
        )}
      </AnimatePresence>
    </div>
  );
}

function HeroBanner() {
  return (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-gradient-to-r from-violet-600 via-purple-600 to-indigo-700 rounded-2xl p-8 text-white shadow-xl"
    >
      <div className="flex flex-col md:flex-row items-center gap-6">
        <div className="w-20 h-20 bg-white/20 rounded-2xl flex items-center justify-center shrink-0">
          <CreditCard className="w-10 h-10" />
        </div>
        <div className="flex-1 text-center md:text-left">
          <h2 className="text-3xl font-bold mb-2">Planes y Suscripciones</h2>
          <p className="text-white/80 text-lg mb-1">Elige el plan perfecto para ti</p>
          <p className="text-white/60 text-sm">Pagos seguros con Stripe · Cancela cuando quieras · 15 días de prueba gratis</p>
        </div>
        <div className="flex flex-col gap-2 shrink-0">
          {["💳 Pago seguro con Stripe", "🔒 Datos protegidos", "✅ Cancela cuando quieras"].map((f) => (
            <div key={f} className="flex items-center gap-2 bg-white/20 rounded-xl px-4 py-2 text-sm">
              <CheckCircle2 className="w-4 h-4 text-emerald-300 shrink-0" />
              <span>{f}</span>
            </div>
          ))}
        </div>
      </div>
    </motion.div>
  );
}

function TrialBanner() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.1 }}
      className="bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 rounded-2xl p-5"
    >
      <div className="flex items-center gap-4">
        <div className="w-12 h-12 bg-emerald-100 dark:bg-emerald-900 rounded-xl flex items-center justify-center shrink-0">
          <Gift className="w-6 h-6 text-emerald-600" />
        </div>
        <div className="flex-1">
          <h3 className="font-bold text-emerald-800 dark:text-emerald-300 text-lg">
            🎁 15 días de prueba GRATIS en todos los planes
          </h3>
          <p className="text-sm text-emerald-700 dark:text-emerald-400">
            Prueba PlaneaDocente sin costo. No se te cobrará nada hasta que termine tu período de prueba.
            Cancela en cualquier momento sin penalización.
          </p>
        </div>
        <div className="hidden md:flex items-center gap-2 bg-emerald-100 dark:bg-emerald-900 rounded-xl px-4 py-3 shrink-0">
          <Clock className="w-5 h-5 text-emerald-600" />
          <div>
            <p className="text-xs text-emerald-600 font-medium">Prueba gratuita</p>
            <p className="text-2xl font-bold text-emerald-700 dark:text-emerald-300">15 días</p>
          </div>
        </div>
      </div>
    </motion.div>
  );
}

function BillingToggle({
  billingInterval,
  onChange,
}: {
  billingInterval: "month" | "year";
  onChange: (v: "month" | "year") => void;
}) {
  return (
    <div className="flex items-center justify-center gap-4">
      <span className={`text-sm font-medium ${billingInterval === "month" ? "text-foreground" : "text-muted-foreground"}`}>
        Mensual
      </span>
      <button
        onClick={() => onChange(billingInterval === "month" ? "year" : "month")}
        className={`relative w-14 h-7 rounded-full transition-colors ${
          billingInterval === "year" ? "bg-primary" : "bg-muted-foreground/30"
        }`}
      >
        <div
          className={`absolute top-0.5 w-6 h-6 bg-white rounded-full shadow-sm transition-transform ${
            billingInterval === "year" ? "translate-x-7" : "translate-x-0.5"
          }`}
        />
      </button>
      <div className="flex items-center gap-2">
        <span className={`text-sm font-medium ${billingInterval === "year" ? "text-foreground" : "text-muted-foreground"}`}>
          Anual
        </span>
        <Badge className="bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-400 text-xs font-bold">
          Ahorra 2 meses
        </Badge>
      </div>
    </div>
  );
}

function PlanCard({
  plan,
  index,
  billingInterval,
  isLoading,
  onSubscribe,
}: {
  plan: Plan;
  index: number;
  billingInterval: "month" | "year";
  isLoading: boolean;
  onSubscribe: (plan: Plan) => void;
}) {
  const Icon = plan.icon;
  const monthlyEquivalent = billingInterval === "year"
    ? Math.round(plan.annualPrice / 12)
    : plan.monthlyPrice;
  const annualTotal = plan.annualPrice;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.1 }}
      className={`relative bg-card rounded-2xl border shadow-sm overflow-hidden flex flex-col ${
        plan.popular ? "border-primary shadow-lg shadow-primary/10 scale-[1.02]" : "border-border"
      }`}
    >
      {plan.popular && (
        <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-violet-500 to-purple-600" />
      )}

      <div className={`bg-gradient-to-br ${plan.gradient} p-6 text-white`}>
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
              <Icon className="w-5 h-5" />
            </div>
            <h3 className="text-xl font-bold">{plan.name}</h3>
          </div>
          {plan.badge && (
            <span className="text-xs bg-white/20 px-2.5 py-1 rounded-full font-bold">
              {plan.badge}
            </span>
          )}
        </div>
        <div className="flex items-end gap-1 mb-1">
          <span className="text-4xl font-bold">{formatPrice(monthlyEquivalent)}</span>
          <span className="text-white/70 text-sm mb-1">/mes</span>
        </div>
        {billingInterval === "year" ? (
          <p className="text-white/70 text-xs">
            {formatPrice(annualTotal)} al año · Ahorras {formatPrice(plan.annualSavings)}
          </p>
        ) : (
          <p className="text-white/70 text-xs">Facturado mensualmente</p>
        )}
      </div>

      <div className="p-6 flex-1 flex flex-col">
        <div className="mb-4 bg-emerald-50 dark:bg-emerald-950/40 rounded-xl px-3 py-2 flex items-center gap-2">
          <Gift className="w-4 h-4 text-emerald-600 shrink-0" />
          <p className="text-xs text-emerald-700 dark:text-emerald-400 font-medium">
            15 días de prueba gratis incluidos
          </p>
        </div>

        <ul className="space-y-2.5 flex-1 mb-6">
          {plan.features.map((feature) => (
            <li key={feature} className="flex items-start gap-2.5">
              <Check className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />
              <span className="text-sm text-foreground">{feature}</span>
            </li>
          ))}
        </ul>

        <Button
          onClick={() => onSubscribe(plan)}
          disabled={isLoading}
          className={`w-full gap-2 font-semibold ${
            plan.popular
              ? "bg-gradient-to-r from-violet-600 to-purple-600 hover:from-violet-700 hover:to-purple-700"
              : ""
          }`}
          variant={plan.popular ? "default" : "outline"}
        >
          {isLoading ? (
            <><Loader2 className="w-4 h-4 animate-spin" /> Procesando...</>
          ) : (
            <><CreditCard className="w-4 h-4" /> Comenzar prueba gratis</>
          )}
        </Button>
        <p className="text-xs text-muted-foreground text-center mt-2">
          Sin cargo por 15 días · Cancela cuando quieras
        </p>
      </div>
    </motion.div>
  );
}

function TrustCard({ icon, title, desc }: { icon: React.ReactNode; title: string; desc: string }) {
  return (
    <Card>
      <CardContent className="flex items-start gap-3 py-4">
        <div className="mt-0.5 shrink-0">{icon}</div>
        <div>
          <p className="font-semibold text-sm">{title}</p>
          <p className="text-xs text-muted-foreground mt-0.5">{desc}</p>
        </div>
      </CardContent>
    </Card>
  );
}

function FaqSection() {
  const faqs = [
    { q: "¿Cuándo se me cobra?", a: "No se te cobra nada durante los primeros 15 días. Al terminar la prueba, se realiza el primer cobro automáticamente." },
    { q: "¿Puedo cancelar en cualquier momento?", a: "Sí, puedes cancelar tu suscripción en cualquier momento desde tu panel de Stripe. No hay penalizaciones." },
    { q: "¿Qué métodos de pago aceptan?", a: "Aceptamos todas las tarjetas de crédito y débito (Visa, Mastercard, American Express) a través de Stripe." },
    { q: "¿Puedo cambiar de plan?", a: "Sí, puedes cambiar de plan mensual a anual o viceversa en cualquier momento. El cambio aplica al siguiente ciclo." },
    { q: "¿Mis datos están seguros?", a: "Sí. Stripe es el procesador de pagos más seguro del mundo. Nunca almacenamos datos de tu tarjeta." },
    { q: "¿Cómo obtengo mi clave de Stripe?", a: "Ve a dashboard.stripe.com, crea una cuenta gratuita, y en Developers → API Keys encontrarás tus claves." },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <AlertCircle className="w-5 h-5 text-primary" />
          Preguntas Frecuentes
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {faqs.map((faq, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.05 }}
              className="border-b border-border pb-4 last:border-0 last:pb-0"
            >
              <p className="text-sm font-semibold text-foreground mb-1">{faq.q}</p>
              <p className="text-sm text-muted-foreground">{faq.a}</p>
            </motion.div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
