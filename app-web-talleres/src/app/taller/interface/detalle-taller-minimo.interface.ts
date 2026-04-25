export interface HistorialMinimo {
  estado_anterior: string | null;
  estado_nuevo: string;
  creado_at: string | null;
  tipo_actor: string;
  notas: string | null;
}

export interface MultimediaMinima {
  id: number;
  tipo_archivo: string;
  url_almacenamiento: string;
  tipo_mime: string | null;
  transcripcion: string | null;
  resultado_ia: unknown;
}

export interface AsignacionMinima {
  taller_id: number;
  estado: string;
  distancia_km: number | null;
  puntuacion: number | null;
}

export interface DetalleTallerMinimo {
  id: number;
  estado: string;
  prioridad: number | null;
  ubicacion: {
    latitud: number | null;
    longitud: number | null;
    texto_direccion: string | null;
  };
  descripcion: string | null;
  usuario_id: number | null;
  vehiculo_id: number | null;
  tipo_incidente_id: number | null;
  taller_asignado_id: number | null;
  tecnico_asignado_id: number | null;
  tiempo_estimado_llegada_min: number | null;
  multimedia: {
    cantidad: number;
    tiene_imagen: boolean;
    tiene_audio: boolean;
    items: MultimediaMinima[];
  };
  ia: {
    clasificacion: string | null;
    confianza: number | null;
    resumen: string | null;
    ficha_resumen: Record<string, unknown> | null;
    analisis_raw: Record<string, unknown> | null;
  };
  asignaciones: AsignacionMinima[];
  historial: HistorialMinimo[];
}
