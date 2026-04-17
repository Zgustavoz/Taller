import { Injectable, signal } from '@angular/core';
import type { DataSummaryManager } from '../interface/dataSummaryManager.interface';

@Injectable({
  providedIn: 'root'
})
export class Dashboard {
  public panelData = signal<DataSummaryManager>({
    taller: {
      nombre: '',
      disponible: false,
      radio_km: 0
    },
    kpis: {
      completados_hoy: 0,
      tasa_cancelacion_pct: 0,
      tiempo_llegada_avg_min: 0,
      rating_global: 0
    },
    graficos: {
      demanda: [],
      respuestas: {
        aceptadas: 0,
        rechazadas: 0
      }
    },
    ultimas_resenas: []
  })
}
