import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Planea Docente - Sistema de Planeación Didáctica',
  description: 'Plataforma profesional para maestros. Crea planeaciones en minutos.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body style={{ margin: 0, padding: 0, fontFamily: 'system-ui, sans-serif' }}>
        {children}
      </body>
    </html>
  );
}
