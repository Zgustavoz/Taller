import { Routes } from '@angular/router';
import { Solicitudes } from './solicitudes/solicitudes';
import { Dashboard } from './dashboard/dashboard';
import { Taller } from './taller/taller';
import { isAuthenticatedGuard } from './auth/guards/is-authenticated.guard';
import { isNotAuthenticatedGuard } from './auth/guards/is-not-authenticated.guard';

export const routes: Routes = [
  {
    path: 'auth',
    canMatch: [isNotAuthenticatedGuard],
    loadChildren: () => import('./auth/auth.routes')
  },
  {
    path: 'dashboard',
    canMatch: [isAuthenticatedGuard],
    component: Dashboard,
    children: [
      {
        path: 'solicitudes',
        component: Solicitudes
      },
      {
        path: 'control-panel',
        loadComponent: () => import('./dashboard/page/control-panel/control-panel')
      },
      {
        path: 'tecnicos',
        component: Taller
      }
    ]
  },
  {
    path: '**',
    redirectTo: 'dashboard/control-panel'
  }
];
