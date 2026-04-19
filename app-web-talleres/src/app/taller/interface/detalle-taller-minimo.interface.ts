export interface HistorialMinimo {
  estado_anterior: string | null;
  estado_nuevo: string;
  creado_en: string;
  tipo_actor: string;
}

export interface DetalleTallerMinimo {
  id: number;
  estado: string;
  prioridad: number | null;
  tipo_incidente: {
    id: number | null;
    nombre: string | null;
    codigo: string | null;
  };
  ubicacion: {
    latitud: number | null;
    longitud: number | null;
    texto_direccion: string | null;
  };
  usuario: {
    id: number | null;
    nombre: string | null;
    telefono: string | null;
  };
  vehiculo: {
    id: number | null;
    placa: string | null;
    marca: string | null;
    modelo: string | null;
  };
  multimedia: {
    cantidad: number;
    tiene_imagen: boolean;
    tiene_audio: boolean;
  };
  ia: {
    clasificacion: string | null;
    confianza: number | null;
    resumen: string | null;
  };
  asignacion: {
    id_taller: number | null;
    id_tecnico: number | null;
    eta_min: number | null;
  };
  historial: HistorialMinimo[];
}
