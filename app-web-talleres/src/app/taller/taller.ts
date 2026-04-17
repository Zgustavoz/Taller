import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { finalize } from 'rxjs';

import { HeaderPage } from '../shared/components/header-page/header-page';
import { Auth } from '../auth/service/auth';
import { MapComponent, type MapLocation } from '../shared/components/map/map';
import { TecnicosService } from './service/tecnicos.service';
import type { Tecnico, TecnicoCreateRequest, TecnicoUpdateRequest } from './interface/tecnico.interface';
import { LucidePhone, LucideUser, LucideWrench } from "@lucide/angular";

@Component({
  selector: 'app-taller',
  imports: [HeaderPage, ReactiveFormsModule, MapComponent, LucidePhone, LucideUser, LucideWrench],
  templateUrl: './taller.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Taller implements OnInit {
  private readonly tecnicosService = inject(TecnicosService);
  private readonly authService = inject(Auth);
  private readonly fb = inject(FormBuilder);

  readonly tecnicos = signal<Tecnico[]>([]);
  readonly loading = signal(false);
  readonly submitting = signal(false);
  readonly deleting = signal<number | null>(null);
  readonly editandoId = signal<number | null>(null);
  readonly errorMessage = signal<string | null>(null);
  readonly successMessage = signal<string | null>(null);
  readonly ubicacionTaller = computed<MapLocation | null>(() => {
    const taller = this.authService.taller();
    const ubicacion = taller?.ubicacion;

    if (!ubicacion) {
      return null;
    }

    return {
      latitud: ubicacion.latitud,
      longitud: ubicacion.longitud,
    };
  });

  readonly ubicacionTecnico = signal<MapLocation | null>(null);

  readonly filtroTexto = signal('');
  readonly filtroEstado = signal<'todos' | 'activos' | 'inactivos'>('todos');
  readonly filtroDisponibilidad = signal<'todos' | 'disponibles' | 'ocupados'>('todos');

  readonly tecnicoForm = this.fb.group({
    nombre_completo: ['', [Validators.required, Validators.minLength(3)]],
    telefono: [''],
    especialidades: [''],
    esta_disponible: [true, [Validators.required]],
    esta_activo: [true, [Validators.required]],
  });

  readonly totalTecnicos = computed(() => this.tecnicos().length);
  readonly totalActivos = computed(() => this.tecnicos().filter((item) => item.esta_activo).length);
  readonly totalDisponibles = computed(() => this.tecnicos().filter((item) => item.esta_disponible && item.esta_activo).length);

  readonly tecnicosFiltrados = computed(() => {
    const texto = this.filtroTexto().trim().toLowerCase();

    return this.tecnicos().filter((item) => {
      const coincideTexto = !texto
        || item.nombre_completo.toLowerCase().includes(texto)
        || (item.telefono ?? '').toLowerCase().includes(texto)
        || item.especialidades.some((esp) => esp.toLowerCase().includes(texto));

      const coincideEstado = this.filtroEstado() === 'todos'
        || (this.filtroEstado() === 'activos' && item.esta_activo)
        || (this.filtroEstado() === 'inactivos' && !item.esta_activo);

      const coincideDisponibilidad = this.filtroDisponibilidad() === 'todos'
        || (this.filtroDisponibilidad() === 'disponibles' && item.esta_disponible)
        || (this.filtroDisponibilidad() === 'ocupados' && !item.esta_disponible);

      return coincideTexto && coincideEstado && coincideDisponibilidad;
    });
  });

  ngOnInit(): void {
    this.ubicacionTecnico.set(this.ubicacionTaller());
    this.cargarTecnicos();
  }

  cargarTecnicos(): void {
    this.errorMessage.set(null);
    this.loading.set(true);

    this.tecnicosService.listarMisTecnicos(false)
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (rows) => {
          this.tecnicos.set(rows);
        },
        error: () => {
          this.errorMessage.set('No se pudo cargar la lista de técnicos.');
        }
      });
  }

  setFiltroTexto(value: string): void {
    this.filtroTexto.set(value);
  }

  onFiltroTextoInput(event: Event): void {
    const target = event.target as HTMLInputElement | null;
    this.setFiltroTexto(target?.value ?? '');
  }

  setFiltroEstado(value: 'todos' | 'activos' | 'inactivos'): void {
    this.filtroEstado.set(value);
  }

  onFiltroEstadoChange(event: Event): void {
    const target = event.target as HTMLSelectElement | null;
    const value = target?.value;
    if (value === 'activos' || value === 'inactivos' || value === 'todos') {
      this.setFiltroEstado(value);
    }
  }

  setFiltroDisponibilidad(value: 'todos' | 'disponibles' | 'ocupados'): void {
    this.filtroDisponibilidad.set(value);
  }

  onFiltroDisponibilidadChange(event: Event): void {
    const target = event.target as HTMLSelectElement | null;
    const value = target?.value;
    if (value === 'disponibles' || value === 'ocupados' || value === 'todos') {
      this.setFiltroDisponibilidad(value);
    }
  }

  get submitLabel(): string {
    return this.editandoId() ? 'Guardar cambios' : 'Registrar técnico';
  }

  resetFormulario(): void {
    this.editandoId.set(null);
    this.ubicacionTecnico.set(this.ubicacionTaller());
    this.tecnicoForm.reset({
      nombre_completo: '',
      telefono: '',
      especialidades: '',
      esta_disponible: true,
      esta_activo: true,
    });
  }

  editarTecnico(tecnico: Tecnico): void {
    this.editandoId.set(tecnico.id);
    this.successMessage.set(null);
    this.errorMessage.set(null);
    this.tecnicoForm.patchValue({
      nombre_completo: tecnico.nombre_completo,
      telefono: tecnico.telefono ?? '',
      especialidades: tecnico.especialidades.join(', '),
      esta_disponible: tecnico.esta_disponible,
      esta_activo: tecnico.esta_activo,
    });
    this.ubicacionTecnico.set(tecnico.ubicacion_actual);
  }

  guardarTecnico(): void {
    if (this.tecnicoForm.invalid) {
      this.tecnicoForm.markAllAsTouched();
      this.errorMessage.set('Completa los campos obligatorios antes de guardar.');
      return;
    }

    if (!this.ubicacionTecnico()) {
      this.errorMessage.set('Define la ubicación del técnico usando el mapa o tu ubicación actual.');
      return;
    }

    const tallerId = this.authService.taller()?.id;
    if (!tallerId && this.editandoId() === null) {
      this.errorMessage.set('No se pudo identificar el taller autenticado.');
      return;
    }

    this.submitting.set(true);
    this.errorMessage.set(null);
    this.successMessage.set(null);

    const raw = this.tecnicoForm.getRawValue();
    const payloadBase = this.mapFormularioToPayloadBase(raw);
    const ubicacion_actual = this.ubicacionTecnico();

    const request$ = this.editandoId() === null
      ? this.tecnicosService.crear({
        ...payloadBase,
        taller_id: tallerId as number,
        ubicacion_actual,
      } as TecnicoCreateRequest)
      : this.tecnicosService.actualizar(this.editandoId() as number, {
        ...payloadBase,
        ubicacion_actual,
      } as TecnicoUpdateRequest);

    request$
      .pipe(finalize(() => this.submitting.set(false)))
      .subscribe({
        next: () => {
          this.successMessage.set(this.editandoId() === null
            ? 'Técnico registrado correctamente.'
            : 'Técnico actualizado correctamente.');
          this.resetFormulario();
          this.cargarTecnicos();
        },
        error: () => {
          this.errorMessage.set('No se pudo guardar el técnico. Verifica los datos e inténtalo nuevamente.');
        }
      });
  }

  toggleEstado(tecnico: Tecnico): void {
    const nuevoEstado = !tecnico.esta_activo;
    this.tecnicosService.cambiarEstado(tecnico.id, nuevoEstado).subscribe({
      next: () => {
        this.successMessage.set(nuevoEstado
          ? 'Técnico reactivado.'
          : 'Técnico dado de baja.');
        this.cargarTecnicos();
      },
      error: () => {
        this.errorMessage.set('No se pudo cambiar el estado del técnico.');
      }
    });
  }

  toggleDisponibilidad(tecnico: Tecnico): void {
    this.tecnicosService.actualizar(tecnico.id, {
      esta_disponible: !tecnico.esta_disponible
    }).subscribe({
      next: () => {
        this.successMessage.set('Disponibilidad actualizada.');
        this.cargarTecnicos();
      },
      error: () => {
        this.errorMessage.set('No se pudo actualizar la disponibilidad.');
      }
    });
  }

  eliminarTecnico(tecnico: Tecnico): void {
    const confirmar = window.confirm(`¿Seguro que deseas eliminar a ${tecnico.nombre_completo}?`);
    if (!confirmar) {
      return;
    }

    this.deleting.set(tecnico.id);
    this.tecnicosService.eliminar(tecnico.id)
      .pipe(finalize(() => this.deleting.set(null)))
      .subscribe({
        next: () => {
          this.successMessage.set('Técnico eliminado correctamente.');
          this.cargarTecnicos();
        },
        error: () => {
          this.errorMessage.set('No se pudo eliminar el técnico.');
        }
      });
  }

  usarMiUbicacion(): void {
    if (!('geolocation' in navigator)) {
      this.errorMessage.set('Tu navegador no soporta geolocalización.');
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.ubicacionTecnico.set({
          latitud: position.coords.latitude,
          longitud: position.coords.longitude,
        });
        this.successMessage.set('Ubicación GPS capturada correctamente.');
      },
      () => {
        this.errorMessage.set('No se pudo obtener la ubicación GPS.');
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    );
  }

  private mapFormularioToPayloadBase(raw: {
    nombre_completo: string | null;
    telefono: string | null;
    especialidades: string | null;
    esta_disponible: boolean | null;
    esta_activo: boolean | null;
  }): TecnicoUpdateRequest {
    const especialidades = (raw.especialidades ?? '')
      .split(',')
      .map((item) => item.trim())
      .filter((item) => item.length > 0);

    return {
      nombre_completo: (raw.nombre_completo ?? '').trim(),
      telefono: (raw.telefono ?? '').trim() || null,
      especialidades,
      esta_disponible: raw.esta_disponible ?? true,
      esta_activo: raw.esta_activo ?? true,
    };
  }
}
