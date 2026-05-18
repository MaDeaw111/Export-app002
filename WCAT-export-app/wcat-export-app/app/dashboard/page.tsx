'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';

const statuses = [
  'pending_production', 'pending_packaging', 'awaiting_loading', 
  'loaded_into_container', 'awaiting_bl_confirmation', 'awaiting_all_docs', 'etd', 'eta'
];

export default function Dashboard() {
  const [data, setData] = useState<any[]>([]);

  useEffect(() => {
    async function fetchData() {
      const { data: poData, error } = await supabase
        .from('purchase_orders')
        .select('*, shipments(*)');
      if (poData) setData(poData);
    }
    fetchData();
  }, []);

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Customer Dashboard</h1>
      {data.map((po) => (
        <div key={po.id} className="border p-4 mb-4 rounded-lg shadow-sm">
          <h2 className="text-xl font-semibold">PO: {po.po_number}</h2>
          <div className="mt-4">
            {po.shipments.map((shipment: any) => (
              <div key={shipment.id} className="ml-4 p-2 border-l-2 border-gray-200">
                <p className="font-medium">DI: {shipment.di_number}</p>
                <div className="flex gap-1 mt-2">
                  {statuses.map((s, i) => (
                    <div key={s} className={`h-2 flex-1 rounded ${statuses.indexOf(shipment.status) >= i ? 'bg-green-500' : 'bg-gray-200'}`} />
                  ))}
                </div>
                <p className="text-sm text-gray-500 mt-1 capitalize">{shipment.status.replace('_', ' ')}</p>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
