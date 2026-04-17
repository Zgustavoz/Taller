import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { Auth } from '../../service/auth';

@Component({
  selector: 'app-login-page',
  imports: [RouterLink, ReactiveFormsModule],
  templateUrl: './login-page.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LoginPage {
  public fb = inject(FormBuilder);
  private authService = inject(Auth);
  private router = inject(Router);

  public hasError = signal(false);
  public isPosting = signal(false);

  loginForm = this.fb.group({
    correo: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]]
  })
  onSubmit() {
    if (this.loginForm.invalid) {
      this.hasError.set(true);
      setTimeout(() => {
        this.hasError.set(false);
      }, 2000);
      return;
    }
    const correo = this.loginForm.controls.correo.value ?? '';
    const password = this.loginForm.controls.password.value ?? '';

    this.isPosting.set(true);

    this.authService.login(correo, password).subscribe((isAuthenticated) => {
      this.isPosting.set(false);

      if (isAuthenticated) {
        this.router.navigateByUrl('/dashboard/control-panel');
        return;
      }

      this.hasError.set(true);
      setTimeout(() => {
        this.hasError.set(false);
      }, 2000);
    });
  }
}
