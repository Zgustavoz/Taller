import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { MapComponent, type MapLocation } from '../../../shared/components/map/map';
import { Auth } from '../../service/auth';
import type { RegisterWorkshopRequest } from '../../interface/register-workshop-request.interface';

@Component({
  selector: 'app-register-page',
  imports: [ReactiveFormsModule, MapComponent, RouterLink],
  templateUrl: './register-page.html',
  styleUrls: ['./register-page.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RegisterPage {

  private readonly fb = inject(FormBuilder);
  private readonly authService = inject(Auth);
  private readonly router = inject(Router);

  public readonly currentStep = signal(1);
  public readonly isPosting = signal(false);
  public readonly hasError = signal(false);
  public readonly hasSuccess = signal(false);
  public readonly transitionDirection = signal<'next' | 'prev'>('next');
  public readonly confettiPieces = Array.from({ length: 24 }, (_, index) => index);

  public readonly isFirstStep = computed(() => this.currentStep() === 1);
  public readonly isLastStep = computed(() => this.currentStep() === 3);

  public readonly registerForm = this.fb.group({
    nombre_propietario: this.fb.control('', [Validators.required, Validators.minLength(3)]),
    nombre_negocio: this.fb.control('', [Validators.required, Validators.minLength(3)]),
    correo: this.fb.control('', [Validators.required, Validators.email]),
    telefono: this.fb.control('', [Validators.required, Validators.minLength(7)]),
    contrasena: this.fb.control('', [Validators.required, Validators.minLength(6)]),
    direccion: this.fb.control('', [Validators.required, Validators.minLength(6)]),
    radio_cobertura_km: this.fb.control(10, [Validators.required, Validators.min(1)]),
    especialidades_texto: this.fb.control('', [Validators.required]),
    esta_disponible: this.fb.control(true, [Validators.required]),
    esta_activo: this.fb.control(true, [Validators.required]),
    token_fcm: this.fb.control(''),
    ubicacion: this.fb.group({
      latitud: this.fb.control<number | null>(null, [Validators.required, Validators.min(-90), Validators.max(90)]),
      longitud: this.fb.control<number | null>(null, [Validators.required, Validators.min(-180), Validators.max(180)]),
    }),
  });

  public onLocationSelected(location: MapLocation): void {
    this.registerForm.patchValue({
      ubicacion: {
        latitud: location.latitud,
        longitud: location.longitud,
      },
    });
  }

  public goNextStep(): void {
    if (!this.validateCurrentStep()) {
      return;
    }

    this.transitionDirection.set('next');
    this.currentStep.update((step) => Math.min(step + 1, 3));
  }

  public goPreviousStep(): void {
    this.transitionDirection.set('prev');
    this.currentStep.update((step) => Math.max(step - 1, 1));
  }

  public onSubmit(): void {
    this.hasError.set(false);
    this.hasSuccess.set(false);

    if (!this.validateCurrentStep()) {
      return;
    }

    if (this.registerForm.invalid) {
      this.registerForm.markAllAsTouched();
      this.hasError.set(true);
      return;
    }

    const payload = this.buildPayload();
    if (!payload) {
      this.hasError.set(true);
      return;
    }

    this.isPosting.set(true);
    this.authService.registerWorkshop(payload).subscribe((isRegistered) => {
      this.isPosting.set(false);

      if (!isRegistered) {
        this.hasError.set(true);
        return;
      }

      this.hasSuccess.set(true);
      this.registerForm.reset({
        radio_cobertura_km: 10,
        esta_disponible: true,
        esta_activo: true,
        token_fcm: '',
        ubicacion: {
          latitud: null,
          longitud: null,
        },
      });
      this.currentStep.set(1);
      setTimeout(() => {
        this.router.navigateByUrl('/auth/login');
      }, 2600);
    });
  }

  public closeSuccessModal(): void {
    this.hasSuccess.set(false);
  }

  private validateCurrentStep(): boolean {
    if (this.currentStep() === 1) {
      const isValid =
        this.registerForm.controls.nombre_propietario.valid &&
        this.registerForm.controls.nombre_negocio.valid &&
        this.registerForm.controls.correo.valid &&
        this.registerForm.controls.telefono.valid &&
        this.registerForm.controls.contrasena.valid;

      if (!isValid) {
        this.registerForm.controls.nombre_propietario.markAsTouched();
        this.registerForm.controls.nombre_negocio.markAsTouched();
        this.registerForm.controls.correo.markAsTouched();
        this.registerForm.controls.telefono.markAsTouched();
        this.registerForm.controls.contrasena.markAsTouched();
      }
      return isValid;
    }

    if (this.currentStep() === 2) {
      const isValid =
        this.registerForm.controls.direccion.valid &&
        this.registerForm.controls.radio_cobertura_km.valid &&
        this.registerForm.controls.especialidades_texto.valid;

      if (!isValid) {
        this.registerForm.controls.direccion.markAsTouched();
        this.registerForm.controls.radio_cobertura_km.markAsTouched();
        this.registerForm.controls.especialidades_texto.markAsTouched();
      }
      return isValid;
    }

    const locationGroup = this.registerForm.controls.ubicacion;
    locationGroup.markAllAsTouched();
    return locationGroup.valid;
  }

  private buildPayload(): RegisterWorkshopRequest | null {
    const value = this.registerForm.getRawValue();
    const latitud = value.ubicacion?.latitud;
    const longitud = value.ubicacion?.longitud;

    if (latitud === null || latitud === undefined || longitud === null || longitud === undefined) {
      return null;
    }

    const especialidades = (value.especialidades_texto ?? '')
      .split(',')
      .map((item) => item.trim())
      .filter((item) => item.length > 0);

    return {
      nombre_propietario: value.nombre_propietario ?? '',
      nombre_negocio: value.nombre_negocio ?? '',
      correo: value.correo ?? '',
      telefono: value.telefono ?? '',
      direccion: value.direccion ?? '',
      ubicacion: {
        latitud,
        longitud,
      },
      radio_cobertura_km: Number(value.radio_cobertura_km ?? 0),
      especialidades,
      esta_disponible: value.esta_disponible ?? true,
      calificacion_promedio: 0,
      token_fcm: value.token_fcm ?? '',
      esta_activo: value.esta_activo ?? true,
      contrasena: value.contrasena ?? '',
    };
  }
}
