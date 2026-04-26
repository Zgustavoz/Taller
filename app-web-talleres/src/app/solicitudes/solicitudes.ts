import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { HeaderPage } from "../shared/components/header-page/header-page";
import { MapComponent, type MapLocation } from '../shared/components/map/map';
import { TallerSolicitudesService } from '../taller/service/taller-solicitudes.service';
import { Auth } from '../auth/service/auth';
import type { SolicitudPanelMinimo } from '../taller/interface/solicitud-panel-minimo.interface';
import type { AsignacionMinima, DetalleTallerMinimo, HistorialMinimo, MultimediaMinima } from '../taller/interface/detalle-taller-minimo.interface';

@Component({
  selector: 'app-solicitudes',
  imports: [HeaderPage, MapComponent],
  templateUrl: './solicitudes.html',
  styleUrl: './solicitudes.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Solicitudes implements OnInit {
  private readonly tallerSolicitudesService = inject(TallerSolicitudesService);
  private readonly authService = inject(Auth);

  readonly camposMinimosPanel = this.tallerSolicitudesService.camposMinimosPanel;

  readonly solicitudes = signal<SolicitudPanelMinimo[]>([]);
  readonly detalle = signal<DetalleTallerMinimo | null>(null);
  readonly estadoFiltro = signal<string>('notificando');
  readonly incidenteSeleccionadoId = signal<number | null>(null);
  readonly cargandoListado = signal<boolean>(false);
  readonly cargandoDetalle = signal<boolean>(false);
  readonly aceptandoId = signal<number | null>(null);
  readonly rechazandoId = signal<number | null>(null);
  readonly actualizandoEstadoId = signal<number | null>(null);
  readonly error = signal<string | null>(null);

  readonly filtros = [
    { estado: 'pendiente', label: 'Pendientes' },
    { estado: 'notificando', label: 'Notificando' },
    { estado: 'asignado', label: 'Asignados' },
    { estado: 'en_progreso', label: 'En proceso' },
    { estado: 'todos', label: 'Todos' },
  ] as const;

  readonly totalSolicitudes = computed(() => this.solicitudes().length);
  readonly tallerActual = computed(() => this.authService.taller());
  readonly detalleActivo = computed(() => this.detalle());
  readonly imagenesDetalle = computed(() =>
    this.detalleActivo()?.multimedia.items.filter((item) => this.esImagen(item)) ?? []
  );
  readonly audiosDetalle = computed(() =>
    this.detalleActivo()?.multimedia.items.filter((item) => this.esAudio(item)) ?? []
  );
  readonly historialOrdenado = computed(() => {
    const historial = [...(this.detalleActivo()?.historial ?? [])];
    return historial.sort((a, b) => this.toTimestamp(b.creado_at) - this.toTimestamp(a.creado_at));
  });
  readonly ubicacionMapa = computed(() => {
    const ubicacion = this.detalleActivo()?.ubicacion;
    if (!ubicacion) {
      return null;
    }

    if (
      typeof ubicacion.latitud !== 'number' ||
      !Number.isFinite(ubicacion.latitud) ||
      typeof ubicacion.longitud !== 'number' ||
      !Number.isFinite(ubicacion.longitud)
    ) {
      return null;
    }

    return {
      latitud: ubicacion.latitud,
      longitud: ubicacion.longitud,
    };
  });
  readonly centroMapa = computed<[number, number]>(() => {
    const ubicacion = this.ubicacionMapa();
    if (!ubicacion) {
      return [-63.18117, -17.78326];
    }
    return [ubicacion.longitud, ubicacion.latitud];
  });
  readonly zoomMapa = computed(() => (this.ubicacionMapa() ? 13 : 4));
  readonly asignacionMapa = computed<AsignacionMinima | null>(() => {
    const asignaciones = this.detalleActivo()?.asignaciones ?? [];
    if (asignaciones.length === 0) {
      return null;
    }

    const tallerIdActual = this.tallerActual()?.id ?? null;
    const delTallerActual = tallerIdActual
      ? asignaciones.filter((item) => item.taller_id === tallerIdActual)
      : [];
    const conCoordenadas = (lista: AsignacionMinima[]) =>
      lista.filter((item) => this.isValidCoordPair(item.latitud_taller, item.longitud_taller));

    return (
      conCoordenadas(delTallerActual)[0] ??
      conCoordenadas(asignaciones.filter((item) => item.estado === 'aceptado' || item.estado === 'asignado'))[0] ??
      delTallerActual[0] ??
      conCoordenadas(asignaciones)[0] ??
      asignaciones[0] ??
      null
    );
  });
  readonly ubicacionTallerMapa = computed<MapLocation | null>(() => {
    const asignacion = this.asignacionMapa();
    const latitud = asignacion?.latitud_taller;
    const longitud = asignacion?.longitud_taller;
    if (typeof latitud !== 'number' || !Number.isFinite(latitud) || typeof longitud !== 'number' || !Number.isFinite(longitud)) {
      return null;
    }

    return {
      latitud,
      longitud,
    };
  });
  readonly puntosSecundariosMapa = computed<MapLocation[]>(() => {
    const taller = this.ubicacionTallerMapa();
    return taller ? [taller] : [];
  });
  readonly distanciaTallerIncidenteKm = computed<number | null>(() => {
    const asignacion = this.asignacionMapa();
    if (typeof asignacion?.distancia_km === 'number' && Number.isFinite(asignacion.distancia_km)) {
      return asignacion.distancia_km;
    }

    const incidente = this.ubicacionMapa();
    const taller = this.ubicacionTallerMapa();
    if (!incidente || !taller) {
      return null;
    }

    return this.calcularDistanciaKm(
      incidente.latitud,
      incidente.longitud,
      taller.latitud,
      taller.longitud,
    );
  });
  readonly tiempoEstimadoLlegadaMin = computed<number | null>(() => {
    const distanciaKm = this.distanciaTallerIncidenteKm();
    if (typeof distanciaKm !== 'number' || !Number.isFinite(distanciaKm)) {
      return null;
    }

    const velocidadPromedioKmH = 35;
    const minutos = (distanciaKm / velocidadPromedioKmH) * 60;
    return Math.max(5, Math.round(minutos));
  });
  readonly fichaResumenEntries = computed(() => {
    const ficha = this.detalleActivo()?.ia.ficha_resumen;
    if (!ficha) {
      return [];
    }

    return Object.entries(ficha).map(([key, value]) => ({
      key,
      value: this.formatUnknown(value),
    }));
  });
  readonly analisisGeminiPretty = computed(() => {
    const raw = this.detalleActivo()?.ia.analisis_raw;
    if (!raw) {
      return null;
    }
    try {
      return JSON.stringify(raw, null, 2);
    } catch {
      return null;
    }
  });

  ngOnInit(): void {
    this.cargarSolicitudes();
  }

  cambiarFiltro(estado: string): void {
    this.estadoFiltro.set(estado);
    this.incidenteSeleccionadoId.set(null);
    this.detalle.set(null);
    this.cargarSolicitudes();
  }

  cargarSolicitudes(): void {
    this.cargandoListado.set(true);
    this.error.set(null);

    const filtro = this.estadoFiltro() === 'todos' ? '' : this.estadoFiltro();
    this.tallerSolicitudesService.listarSolicitudesMinimas(filtro).subscribe((items) => {
      this.solicitudes.set(items);
      this.cargandoListado.set(false);
    });
  }

  verDetalle(incidenteId: number): void {
    this.cargandoDetalle.set(true);
    this.error.set(null);
    this.incidenteSeleccionadoId.set(incidenteId);

    this.tallerSolicitudesService.obtenerDetalleMinimo(incidenteId).subscribe((data) => {
      if (!data) {
        this.error.set('No se pudo cargar el detalle de la solicitud.');
      }
      this.detalle.set(data);
      this.cargandoDetalle.set(false);
    });
  }

  aceptarSolicitud(solicitud: SolicitudPanelMinimo): void {
    const tallerId = this.tallerActual()?.id;
    if (!tallerId) {
      this.error.set('No se pudo identificar el taller autenticado.');
      return;
    }

    this.aceptandoId.set(solicitud.id);
    this.error.set(null);

    this.tallerSolicitudesService
      .aceptarSolicitud(solicitud.id, tallerId)
      .subscribe((ok) => {
        if (!ok) {
          this.error.set('No se pudo aceptar la solicitud. Intenta nuevamente.');
          this.aceptandoId.set(null);
          return;
        }

        this.aceptandoId.set(null);
        this.cargarSolicitudes();
        this.verDetalle(solicitud.id);
      });
  }

  rechazarSolicitud(solicitud: SolicitudPanelMinimo): void {
    const tallerId = this.tallerActual()?.id;
    if (!tallerId) {
      this.error.set('No se pudo identificar el taller autenticado.');
      return;
    }

    this.rechazandoId.set(solicitud.id);
    this.error.set(null);

    this.tallerSolicitudesService
      .rechazarSolicitud(solicitud.id, tallerId)
      .subscribe((ok) => {
        if (!ok) {
          this.error.set('No se pudo rechazar la solicitud. Intenta nuevamente.');
          this.rechazandoId.set(null);
          return;
        }

        this.rechazandoId.set(null);
        this.cargarSolicitudes();
        if (this.incidenteSeleccionadoId() === solicitud.id) {
          this.verDetalle(solicitud.id);
        }
      });
  }

  iniciarOperacion(solicitud: SolicitudPanelMinimo): void {
    if (!this.puedeIniciarOperacion(solicitud)) {
      return;
    }
    this.actualizarEstadoOperacion(solicitud.id, 'en_progreso');
  }

  marcarResuelto(solicitud: SolicitudPanelMinimo): void {
    if (!this.puedeMarcarResuelto(solicitud)) {
      return;
    }
    this.actualizarEstadoOperacion(solicitud.id, 'resuelto');
  }

  puedeAceptarRechazar(solicitud: SolicitudPanelMinimo): boolean {
    return solicitud.estado === 'pendiente' || solicitud.estado === 'notificando';
  }

  puedeIniciarOperacion(solicitud: SolicitudPanelMinimo): boolean {
    return solicitud.estado === 'asignado';
  }

  puedeMarcarResuelto(solicitud: SolicitudPanelMinimo): boolean {
    return solicitud.estado === 'en_progreso' || solicitud.estado === 'en_proceso';
  }

  private actualizarEstadoOperacion(
    incidenteId: number,
    estado: 'en_progreso' | 'resuelto'
  ): void {
    this.actualizandoEstadoId.set(incidenteId);
    this.error.set(null);

    this.tallerSolicitudesService.actualizarEstadoIncidente(incidenteId, estado).subscribe((ok) => {
      if (!ok) {
        this.error.set('No se pudo actualizar el estado operativo del incidente.');
        this.actualizandoEstadoId.set(null);
        return;
      }

      this.actualizandoEstadoId.set(null);
      this.cargarSolicitudes();
      if (this.incidenteSeleccionadoId() === incidenteId) {
        this.verDetalle(incidenteId);
      }
    });
  }

  getNivelPrioridad(prioridad: number | null): string {
    if (prioridad === null) {
      return 'Sin prioridad';
    }
    if (prioridad >= 4) {
      return 'Alta';
    }
    if (prioridad === 3) {
      return 'Media';
    }
    return 'Baja';
  }

  getClassEstado(estado: string): string {
    const map: Record<string, string> = {
      pendiente: 'badge badge-warning badge-soft',
      notificando: 'badge badge-info badge-soft',
      asignado: 'badge badge-primary badge-soft',
      en_progreso: 'badge badge-secondary badge-soft',
      en_proceso: 'badge badge-secondary badge-soft',
      resuelto: 'badge badge-success badge-soft',
      rechazado: 'badge badge-error badge-soft',
      cerrado: 'badge badge-neutral badge-soft',
      cancelado: 'badge badge-neutral badge-soft',
    };

    return map[estado] ?? 'badge badge-ghost';
  }

  getClassPrioridad(prioridad: number | null): string {
    if (prioridad === null) {
      return 'badge badge-outline';
    }
    if (prioridad >= 4) {
      return 'badge badge-error';
    }
    if (prioridad === 3) {
      return 'badge badge-warning';
    }
    return 'badge badge-success';
  }

  getConfianza(confianza: number | null): string {
    if (typeof confianza !== 'number') {
      return 'N/D';
    }
    return `${Math.round(confianza * 100)}%`;
  }

  getDistanciaTexto(distanciaKm: number | null): string {
    if (typeof distanciaKm !== 'number' || !Number.isFinite(distanciaKm)) {
      return 'N/D';
    }
    return `${distanciaKm.toFixed(1)} km`;
  }

  getTiempoEstimadoTexto(minutos: number | null): string {
    if (typeof minutos !== 'number' || !Number.isFinite(minutos)) {
      return 'N/D';
    }

    return `${minutos} min`;
  }

  formatearFecha(fecha: string | null): string {
    if (!fecha) {
      return 'Sin fecha';
    }

    const date = new Date(fecha);
    if (Number.isNaN(date.getTime())) {
      return fecha;
    }

    return new Intl.DateTimeFormat('es-BO', {
      dateStyle: 'medium',
      timeStyle: 'short',
    }).format(date);
  }

  esImagen(item: MultimediaMinima): boolean {
    const tipo = (item.tipo_archivo || '').toLowerCase();
    const mime = (item.tipo_mime || '').toLowerCase();
    const url = item.url_almacenamiento.toLowerCase();

    return (
      tipo.includes('imagen') ||
      tipo.includes('image') ||
      mime.startsWith('image/') ||
      /\.(png|jpe?g|webp|gif|bmp|svg)(\?|$)/.test(url)
    );
  }

  esAudio(item: MultimediaMinima): boolean {
    const tipo = (item.tipo_archivo || '').toLowerCase();
    const mime = (item.tipo_mime || '').toLowerCase();
    const url = item.url_almacenamiento.toLowerCase();

    return (
      tipo.includes('audio') ||
      mime.startsWith('audio/') ||
      /\.(mp3|wav|ogg|aac|m4a|webm)(\?|$)/.test(url)
    );
  }

  esCloudinary(url: string): boolean {
    return url.includes('res.cloudinary.com');
  }

  tituloMultimedia(item: MultimediaMinima, index: number): string {
    const fileName = this.fileNameFromUrl(item.url_almacenamiento);
    if (fileName) {
      return fileName;
    }
    return `${item.tipo_archivo || 'archivo'} ${index + 1}`;
  }

  trackBySolicitudId(_: number, solicitud: SolicitudPanelMinimo): number {
    return solicitud.id;
  }

  trackByHistorial(_: number, item: HistorialMinimo): string {
    return `${item.creado_at ?? 'na'}-${item.estado_nuevo}-${item.tipo_actor}`;
  }

  trackByMultimedia(_: number, item: MultimediaMinima): number {
    return item.id;
  }

  private fileNameFromUrl(url: string): string | null {
    try {
      const pathname = new URL(url).pathname;
      const file = pathname.split('/').pop();
      return file ? decodeURIComponent(file) : null;
    } catch {
      return null;
    }
  }

  private toTimestamp(fecha: string | null): number {
    if (!fecha) {
      return 0;
    }

    const date = new Date(fecha);
    if (Number.isNaN(date.getTime())) {
      return 0;
    }

    return date.getTime();
  }

  private formatUnknown(value: unknown): string {
    if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
      return String(value);
    }

    if (Array.isArray(value)) {
      return value.map((entry) => this.formatUnknown(entry)).join(', ');
    }

    if (value && typeof value === 'object') {
      try {
        return JSON.stringify(value);
      } catch {
        return 'Objeto';
      }
    }

    return 'N/D';
  }

  private isValidCoordPair(latitud: number | null | undefined, longitud: number | null | undefined): boolean {
    return (
      typeof latitud === 'number' &&
      Number.isFinite(latitud) &&
      typeof longitud === 'number' &&
      Number.isFinite(longitud)
    );
  }

  private calcularDistanciaKm(
    latitudA: number,
    longitudA: number,
    latitudB: number,
    longitudB: number,
  ): number {
    const rad = (valor: number) => (valor * Math.PI) / 180;
    const dLat = rad(latitudB - latitudA);
    const dLng = rad(longitudB - longitudA);

    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(rad(latitudA)) * Math.cos(rad(latitudB)) * Math.sin(dLng / 2) ** 2;

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const radioTierraKm = 6371;
    return radioTierraKm * c;
  }
}
