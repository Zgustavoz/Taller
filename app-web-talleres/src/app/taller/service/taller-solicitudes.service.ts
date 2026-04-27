import { inject, Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { catchError, map, Observable, of } from 'rxjs';

import { environment } from '../../../environments/environment';
import type { DetalleTallerMinimo, HistorialMinimo } from '../interface/detalle-taller-minimo.interface';
import type { SolicitudPanelMinimo } from '../interface/solicitud-panel-minimo.interface';

const baseUrl = environment.BASE_URL;
const tallerSolicitudesEndpoint = environment.TALLER_SOLICITUDES_ENDPOINT;

@Injectable({
  providedIn: 'root'
})
export class TallerSolicitudesService {
  private readonly http = inject(HttpClient);

  // Contrato mínimo que Web necesita para pintar el panel de solicitudes.
  readonly camposMinimosPanel = signal<readonly (keyof SolicitudPanelMinimo)[]>([
    'id',
    'estado',
    'prioridad',
    'tipo_incidente',
    'distancia_km',
    'score_asignacion',
    'creado_at',
    'usuario_nombre',
    'vehiculo_placa',
    'resumen'
  ]);

  // Campos mínimos para que el taller pueda decidir aceptar/rechazar rápido.
  readonly camposMinimosDetalle = signal<readonly string[]>([
    'id',
    'estado',
    'prioridad',
    'tipo_incidente.id',
    'tipo_incidente.nombre',
    'tipo_incidente.codigo',
    'ubicacion.latitud',
    'ubicacion.longitud',
    'ubicacion.texto_direccion',
    'usuario.id',
    'usuario.nombre',
    'usuario.telefono',
    'vehiculo.id',
    'vehiculo.placa',
    'vehiculo.marca',
    'vehiculo.modelo',
    'multimedia.cantidad',
    'multimedia.tiene_imagen',
    'multimedia.tiene_audio',
    'ia.clasificacion',
    'ia.confianza',
    'ia.resumen',
    'asignacion.id_taller',
    'asignacion.id_tecnico',
    'asignacion.eta_min',
    'historial'
  ]);

  listarSolicitudesMinimas(estado = 'pendiente'): Observable<SolicitudPanelMinimo[]> {
    const queryEstado = estado ? `?estado=${encodeURIComponent(estado)}` : '';
    return this.http
      .get<unknown[]>(`${baseUrl}${tallerSolicitudesEndpoint}${queryEstado}`)
      .pipe(
        map((rows) => rows.map((item) => this.mapPanelMinimo(item))),
        catchError(() => of([]))
      );
  }

  obtenerDetalleMinimo(incidenteId: number): Observable<DetalleTallerMinimo | null> {
    return this.http
      .get<unknown>(`${environment.BASE_URL}/incidentes/${incidenteId}`)
      .pipe(
        map((row) => this.mapDetalleMinimo(row)),
        catchError(() => of(null))
      );
  }

  aceptarSolicitud(
    incidenteId: number,
    tallerId: number,
    tecnicoId?: number,
    tiempoEstimadoMin?: number
  ): Observable<boolean> {
    const params = new URLSearchParams({ taller_id: String(tallerId) });
    if (typeof tecnicoId === 'number') {
      params.set('tecnico_id', String(tecnicoId));
    }
    if (typeof tiempoEstimadoMin === 'number') {
      params.set('tiempo_estimado_min', String(tiempoEstimadoMin));
    }

    return this.http
      .post<unknown>(`${environment.BASE_URL}/incidentes/${incidenteId}/aceptar?${params.toString()}`, {})
      .pipe(
        map(() => true),
        catchError(() => of(false))
      );
  }

  rechazarSolicitud(
    incidenteId: number,
    tallerId: number,
    notas?: string
  ): Observable<boolean> {
    const params = new URLSearchParams({ taller_id: String(tallerId) });
    if (notas && notas.trim().length > 0) {
      params.set('notas', notas.trim());
    }

    return this.http
      .post<unknown>(`${environment.BASE_URL}/incidentes/${incidenteId}/rechazar?${params.toString()}`, {})
      .pipe(
        map(() => true),
        catchError(() => of(false))
      );
  }

  actualizarEstadoIncidente(
    incidenteId: number,
    estado: 'en_progreso' | 'resuelto',
    notas?: string
  ): Observable<boolean> {
    const params = new URLSearchParams({ estado });
    if (notas && notas.trim().length > 0) {
      params.set('notas', notas.trim());
    }

    return this.http
      .patch<unknown>(`${environment.BASE_URL}/incidentes/${incidenteId}/estado?${params.toString()}`, {})
      .pipe(
        map(() => true),
        catchError(() => of(false))
      );
  }

  mapPanelMinimo(row: unknown): SolicitudPanelMinimo {
    const raw = this.asRecord(row);

    return {
      id: this.toNumber(raw['id']),
      estado: this.toStringOrDefault(raw['estado']),
      prioridad: this.toNullableNumber(raw['nivel_prioridad']),
      tipo_incidente: this.toNullableString(raw['tipo_incidente_nombre']),
      distancia_km: this.toNullableNumber(raw['distancia_km']),
      score_asignacion: this.toNullableNumber(raw['score']),
      creado_at: this.toNullableString(raw['creado_at']),
      usuario_nombre: this.toNullableString(raw['usuario_nombre']),
      vehiculo_placa: this.toNullableString(raw['vehiculo_placa']),
      resumen: this.toResumen(raw['resumen'])
    };
  }

  mapDetalleMinimo(row: unknown): DetalleTallerMinimo {
    const raw = this.asRecord(row);
    const analisis = this.toObject(raw['analisis_ia']);
    const ficha = this.toObject(raw['ficha_resumen']);
    const multimedia = Array.isArray(raw['multimedia']) ? raw['multimedia'] : [];
    const asignacionesRaw = Array.isArray(raw['asignaciones']) ? raw['asignaciones'] : [];
    const historialRaw = Array.isArray(raw['historial']) ? raw['historial'] : [];

    return {
      id: this.toNumber(raw['id']),
      estado: this.toStringOrDefault(raw['estado']),
      prioridad: this.toNullableNumber(raw['nivel_prioridad']),
      ubicacion: {
        latitud: this.toNullableNumber(raw['latitud']),
        longitud: this.toNullableNumber(raw['longitud']),
        texto_direccion: this.toNullableString(raw['texto_direccion'])
      },
      descripcion: this.toNullableString(raw['descripcion']),
      usuario_id: this.toNullableNumber(raw['usuario_id']),
      vehiculo_id: this.toNullableNumber(raw['vehiculo_id']),
      tipo_incidente_id: this.toNullableNumber(raw['tipo_incidente_id']),
      taller_asignado_id: this.toNullableNumber(raw['taller_asignado_id']),
      tecnico_asignado_id: this.toNullableNumber(raw['tecnico_asignado_id']),
      tiempo_estimado_llegada_min: this.toNullableNumber(raw['tiempo_estimado_llegada_min']),
      multimedia: {
        cantidad: multimedia.length,
        tiene_imagen: this.hasMedia(multimedia, 'tipo_archivo', 'imagen'),
        tiene_audio: this.hasMedia(multimedia, 'tipo_archivo', 'audio'),
        items: multimedia.map((item) => this.mapMultimedia(item))
      },
      ia: {
        clasificacion: this.toNullableString(analisis?.['tipo_detectado'] ?? null),
        confianza: this.toNullableNumber(analisis?.['confianza'] ?? null),
        resumen: this.toNullableString(analisis?.['resumen'] ?? ficha?.['problema_principal'] ?? null),
        ficha_resumen: ficha,
        analisis_raw: analisis
      },
      asignaciones: asignacionesRaw.map((item) => this.mapAsignacion(item)),
      historial: historialRaw.map((item) => this.mapHistorial(item))
    };
  }

  private mapHistorial(item: unknown): HistorialMinimo {
    const raw = this.asRecord(item);
    return {
      estado_anterior: this.toNullableString(raw['estado_anterior']),
      estado_nuevo: this.toStringOrDefault(raw['estado_nuevo']),
      creado_at: this.toNullableString(raw['creado_at']),
      tipo_actor: this.toStringOrDefault(raw['tipo_actor']),
      notas: this.toNullableString(raw['notas'])
    };
  }

  private mapMultimedia(item: unknown) {
    const raw = this.asRecord(item);
    return {
      id: this.toNumber(raw['id']),
      tipo_archivo: this.toStringOrDefault(raw['tipo_archivo']),
      url_almacenamiento: this.toStringOrDefault(raw['url_almacenamiento']),
      tipo_mime: this.toNullableString(raw['tipo_mime']),
      transcripcion: this.toNullableString(raw['transcripcion']),
      resultado_ia: this.toObject(raw['resultado_ia']) ?? raw['resultado_ia'] ?? null,
    };
  }

  private mapAsignacion(item: unknown) {
    const raw = this.asRecord(item);
    return {
      taller_id: this.toNumber(raw['taller_id']),
      estado: this.toStringOrDefault(raw['estado']),
      distancia_km: this.toNullableNumber(raw['distancia_km']),
      puntuacion: this.toNullableNumber(raw['puntuacion']),
      nombre_taller: this.toNullableString(raw['nombre_taller']),
      telefono_taller: this.toNullableString(raw['telefono_taller']),
      direccion_taller: this.toNullableString(raw['direccion_taller']),
      latitud_taller: this.toNullableNumber(raw['latitud_taller']),
      longitud_taller: this.toNullableNumber(raw['longitud_taller']),
    };
  }

  private hasMedia(multimedia: unknown[], key: string, tipo: string): boolean {
    return multimedia.some((item) => {
      const raw = this.asRecord(item);
      return this.toNullableString(raw[key]) === tipo;
    });
  }

  private toResumen(value: unknown): string | null {
    if (typeof value === 'string') {
      return value;
    }

    if (typeof value === 'object' && value !== null) {
      const raw = value as Record<string, unknown>;
      const principal = raw['problema_principal'];
      if (typeof principal === 'string') {
        return principal;
      }
      try {
        return JSON.stringify(raw);
      } catch {
        return null;
      }
    }

    return null;
  }

  private toObject(value: unknown): Record<string, unknown> | null {
    if (typeof value === 'object' && value !== null) {
      return value as Record<string, unknown>;
    }

    if (typeof value === 'string') {
      const parsed = this.parseJsonLike(value);
      if (parsed && typeof parsed === 'object') {
        return parsed as Record<string, unknown>;
      }
    }

    return null;
  }

  private parseJsonLike(value: string): unknown | null {
    const text = value.trim();
    if (!text.startsWith('{') && !text.startsWith('[')) {
      return null;
    }

    try {
      return JSON.parse(text);
    } catch {
      return null;
    }
  }

  private asRecord(value: unknown): Record<string, unknown> {
    if (typeof value === 'object' && value !== null) {
      return value as Record<string, unknown>;
    }
    return {};
  }

  private toNumber(value: unknown): number {
    if (typeof value === 'number') {
      return value;
    }
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  private toNullableNumber(value: unknown): number | null {
    if (value === null || value === undefined || value === '') {
      return null;
    }
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  private toNullableString(value: unknown): string | null {
    if (typeof value === 'string') {
      return value;
    }
    return null;
  }

  private toStringOrDefault(value: unknown): string {
    if (typeof value === 'string') {
      return value;
    }
    return '';
  }
}
