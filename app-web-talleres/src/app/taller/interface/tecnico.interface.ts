export interface UbicacionActual {
  latitud: number;
  longitud: number;
}

export interface Tecnico {
  id: number;
  taller_id: number;
  nombre_completo: string;
  telefono: string | null;
  ubicacion_actual: UbicacionActual | null;
  especialidades: string[];
  esta_disponible: boolean;
  token_fcm: string | null;
  esta_activo: boolean;
  creado_en: string;
}

export interface TecnicoCreateRequest {
  taller_id: number;
  nombre_completo: string;
  telefono: string | null;
  ubicacion_actual: UbicacionActual | null;
  especialidades: string[];
  esta_disponible: boolean;
  token_fcm?: string | null;
  esta_activo: boolean;
}

export interface TecnicoUpdateRequest {
  nombre_completo?: string;
  telefono?: string | null;
  ubicacion_actual?: UbicacionActual | null;
  especialidades?: string[];
  esta_disponible?: boolean;
  token_fcm?: string | null;
  esta_activo?: boolean;
}
