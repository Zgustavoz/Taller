export interface DataSummaryManager {
  taller: Taller;
  kpis: Kpis;
  graficos: Graficos;
  ultimas_resenas: UltimasResena[];
}

export interface Graficos {
  demanda: Demanda[];
  respuestas: Respuestas;
}

export interface Demanda {
  tipo: string;
  cantidad: number;
}

export interface Respuestas {
  aceptadas: number;
  rechazadas: number;
}

export interface Kpis {
  completados_hoy: number;
  tasa_cancelacion_pct: number;
  tiempo_llegada_avg_min: number;
  rating_global: number;
}

export interface Taller {
  nombre: string;
  disponible: boolean;
  radio_km: number;
}

export interface UltimasResena {
  score: number;
  comentario: string;
  foto_usuario: string;
  prioridad_incidente: number;
  usuario?: string;
}
