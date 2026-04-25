import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { JsonPipe } from '@angular/common';
import { HeaderPage } from "../shared/components/header-page/header-page";
import { TallerSolicitudesService } from '../taller/service/taller-solicitudes.service';
import { Auth } from '../auth/service/auth';
import type { SolicitudPanelMinimo } from '../taller/interface/solicitud-panel-minimo.interface';
import type { DetalleTallerMinimo } from '../taller/interface/detalle-taller-minimo.interface';

@Component({
  selector: 'app-solicitudes',
  imports: [HeaderPage, JsonPipe],
  templateUrl: './solicitudes.html',
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

  readonly totalSolicitudes = computed(() => this.solicitudes().length);
  readonly tallerActual = computed(() => this.authService.taller());

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
}
