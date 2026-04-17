import { computed, inject, Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import type { Taller } from '../interface/taller.interface';
import type { AuthResponse } from '../interface/auth-response.interface';
import type { RegisterWorkshopRequest } from '../interface/register-workshop-request.interface';
import { catchError, map, Observable, of } from 'rxjs';

type AuthStatus = 'checking' | 'authenticated' | 'not-authenticated'
const baseUrl = environment.BASE_URL;
const loginTallerEndpoint = environment.TALLER_LOGIN_ENDPOINT;
const meTallerEndpoint = environment.TALLER_ME_ENDPOINT;
const registerTallerEndpoint = environment.TALLER_REGISTER_ENDPOINT;

@Injectable({
  providedIn: 'root'
})
export class Auth {

  private _authStatus = signal<AuthStatus>('checking');
  private _taller = signal<Taller | null>(null);
  private _token = signal<string | null>(null);

  private http = inject(HttpClient);

  public authStatus = computed<AuthStatus>(() => this._authStatus())

  public taller = computed(() => this._taller())
  public user = computed(() => this._taller())
  public token = computed(() => this._token())

  login(correo: string, password: string): Observable<boolean> {
    return this.http.post<AuthResponse>(
      `${baseUrl}${loginTallerEndpoint}`,
      {
        correo,
        password
      },
      { observe: 'response' }
    ).pipe(
      map((response) => {
        const accessToken = response.headers.get('access_token');
        const taller = response.body?.taller ?? null;

        if (!taller) {
          this.logoutLocal();
          return false;
        }

        this._taller.set(taller);
        this._token.set(accessToken);
        this._authStatus.set('authenticated');

        return true;
      }),
      catchError(() => {
        this.logoutLocal();
        return of(false);
      })
    )
  }

  registerWorkshop(payload: RegisterWorkshopRequest): Observable<boolean> {
    return this.http.post(`${baseUrl}${registerTallerEndpoint}`, payload).pipe(
      map(() => true),
      catchError(() => of(false))
    );
  }

  checkAuthStatus(): Observable<boolean> {
    return this.http.get<AuthResponse>(`${baseUrl}${meTallerEndpoint}`, {
      observe: 'response'
    }).pipe(
      map((response) => {
        const accessToken = response.headers.get('access_token');
        const taller = response.body?.taller ?? null;

        if (!taller) {
          this.logoutLocal();
          return false;
        }

        this._taller.set(taller);
        this._token.set(accessToken);
        this._authStatus.set('authenticated');

        return true;
      }),
      catchError(() => {
        this.logoutLocal();
        return of(false);
      })
    )
  }

  logoutLocal(): void {
    this._taller.set(null);
    this._token.set(null);
    this._authStatus.set('not-authenticated');
  }
}
