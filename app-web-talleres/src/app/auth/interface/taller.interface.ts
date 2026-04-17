export interface Taller {
  nombre_propietario: string;
  nombre_negocio: string;
  correo: string;
  telefono: string;
  direccion: string;
  ubicacion: {
    latitud: number;
    longitud: number;
  };
  radio_cobertura_km: number;
  especialidades: string[];
  esta_disponible: boolean;
  calificacion_promedio: number;
  token_fcm: string;
  esta_activo: boolean;
  id: number;
  creado_en: string;
}
