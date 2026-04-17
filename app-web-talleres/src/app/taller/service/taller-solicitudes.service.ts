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
    return this.http
      .get<unknown[]>(`${baseUrl}${tallerSolicitudesEndpoint}?estado=${encodeURIComponent(estado)}`)
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
      resumen: this.toNullableString(raw['resumen'])
    };
  }

  mapDetalleMinimo(row: unknown): DetalleTallerMinimo {
    const raw = this.asRecord(row);
    const tipo = this.asRecord(raw['tipo_incidente']);
    const usuario = this.asRecord(raw['usuario']);
    const vehiculo = this.asRecord(raw['vehiculo']);
    const multimedia = Array.isArray(raw['multimedia']) ? raw['multimedia'] : [];
    const historialRaw = Array.isArray(raw['historial']) ? raw['historial'] : [];

    return {
      id: this.toNumber(raw['id']),
      estado: this.toStringOrDefault(raw['estado']),
      prioridad: this.toNullableNumber(raw['nivel_prioridad']),
      tipo_incidente: {
        id: this.toNullableNumber(tipo['id']),
        nombre: this.toNullableString(tipo['nombre']),
        codigo: this.toNullableString(tipo['codigo'])
      },
      ubicacion: {
        latitud: this.toNullableNumber(raw['latitud']),
        longitud: this.toNullableNumber(raw['longitud']),
        texto_direccion: this.toNullableString(raw['texto_direccion'])
      },
      usuario: {
        id: this.toNullableNumber(usuario['id']),
        nombre: this.toNullableString(usuario['nombre']),
        telefono: this.toNullableString(usuario['telefono'])
      },
      vehiculo: {
        id: this.toNullableNumber(vehiculo['id']),
        placa: this.toNullableString(vehiculo['placa']),
        marca: this.toNullableString(vehiculo['marca']),
        modelo: this.toNullableString(vehiculo['modelo'])
      },
      multimedia: {
        cantidad: multimedia.length,
        tiene_imagen: this.hasMedia(multimedia, 'imagen'),
        tiene_audio: this.hasMedia(multimedia, 'audio')
      },
      ia: {
        clasificacion: this.toNullableString(raw['analisis_ia']),
        confianza: this.toNullableNumber(raw['confianza_ia']),
        resumen: this.toNullableString(raw['ficha_resumen'])
      },
      asignacion: {
        id_taller: this.toNullableNumber(raw['taller_asignado_id']),
        id_tecnico: this.toNullableNumber(raw['tecnico_asignado_id']),
        eta_min: this.toNullableNumber(raw['tiempo_estimado_llegada_min'])
      },
      historial: historialRaw.map((item) => this.mapHistorial(item))
    };
  }

  private mapHistorial(item: unknown): HistorialMinimo {
    const raw = this.asRecord(item);
    return {
      estado_anterior: this.toNullableString(raw['estado_anterior']),
      estado_nuevo: this.toStringOrDefault(raw['estado_nuevo']),
      creado_en: this.toStringOrDefault(raw['creado_en']),
      tipo_actor: this.toStringOrDefault(raw['tipo_actor'])
    };
  }

  private hasMedia(multimedia: unknown[], tipo: string): boolean {
    return multimedia.some((item) => {
      const raw = this.asRecord(item);
      return this.toNullableString(raw['tipo_media']) === tipo;
    });
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
