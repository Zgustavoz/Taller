export interface SolicitudPanelMinimo {
  id: number;
  estado: string;
  prioridad: number | null;
  tipo_incidente: string | null;
  distancia_km: number | null;
  score_asignacion: number | null;
  creado_at: string | null;
  usuario_nombre: string | null;
  vehiculo_placa: string | null;
  resumen: string | null;
}
