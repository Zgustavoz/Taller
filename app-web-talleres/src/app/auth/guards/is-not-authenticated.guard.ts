import { inject } from '@angular/core';
import { CanMatchFn, Router } from '@angular/router';
import { map } from 'rxjs';
import { Auth } from '../service/auth';

export const isNotAuthenticatedGuard: CanMatchFn = () => {
  const authService = inject(Auth);
  const router = inject(Router);

  const status = authService.authStatus();

  if (status === 'not-authenticated') {
    return true;
  }

  if (status === 'authenticated') {
    return router.parseUrl('/dashboard/control-panel');
  }

  return authService.checkAuthStatus().pipe(
    map((isAuthenticated) => {
      if (isAuthenticated) {
        return router.parseUrl('/dashboard/control-panel');
      }

      return true;
    })
  );
};
