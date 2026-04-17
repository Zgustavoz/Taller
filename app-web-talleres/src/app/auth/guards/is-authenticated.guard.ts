import { inject } from '@angular/core';
import { CanMatchFn, Router } from '@angular/router';
import { map } from 'rxjs';
import { Auth } from '../service/auth';

export const isAuthenticatedGuard: CanMatchFn = () => {
  const authService = inject(Auth);
  const router = inject(Router);

  const status = authService.authStatus();

  if (status === 'authenticated') {
    return true;
  }

  if (status === 'not-authenticated') {
    return router.parseUrl('/auth/login');
  }

  return authService.checkAuthStatus().pipe(
    map((isAuthenticated) => {
      if (isAuthenticated) {
        return true;
      }

      return router.parseUrl('/auth/login');
    })
  );
};
