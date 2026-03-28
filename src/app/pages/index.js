import { loadStripe } from '@stripe/stripe-js';

export default function Home() {

  const pagar = async () => {
    const res = await fetch('/api/crear-pago', {
      method: 'POST',
    });

    const data = await res.json();

    const stripe = await loadStripe('pk_test_TU_CLAVE_PUBLICA');

    await stripe.redirectToCheckout({
      sessionId: data.id,
    });
  };

  return (
    <div>
      <h1>Planea Docente</h1>
      <button onClick={pagar}>Comprar</button>
    </div>
  );
}