'use client';

import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';

export default function AdminDashboard() {
  const [poNumber, setPoNumber] = useState('');
  const [shipments, setShipments] = useState(['']);

  const addShipment = () => setShipments([...shipments, '']);
  
  const createPO = async () => {
    const { data: po, error } = await supabase
      .from('purchase_orders')
      .insert([{ po_number: poNumber, customer_id: 'some-customer-uuid' }]) // Customer selection needed
      .select()
      .single();

    if (po) {
      await supabase.from('shipments').insert(
        shipments.map((di, i) => ({ po_id: po.id, di_number: `${poNumber}-DI-${i+1}` }))
      );
      alert('PO and shipments created!');
    }
  };

  return (
    <div className="p-8 max-w-2xl">
      <h1 className="text-2xl font-bold mb-6">Admin: Create PO</h1>
      <input 
        placeholder="PO Number" 
        className="w-full p-2 border rounded mb-4"
        onChange={(e) => setPoNumber(e.target.value)} 
      />
      {shipments.map((_, i) => (
        <div key={i} className="mb-2">Shipment DI #{i+1}</div>
      ))}
      <Button onClick={addShipment} className="mb-4">Add Shipment DI</Button>
      <Button onClick={createPO} className="w-full">Create PO & Shipments</Button>
    </div>
  );
}
