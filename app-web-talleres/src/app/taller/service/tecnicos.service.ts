import { inject, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import type { Tecnico, TecnicoCreateRequest, TecnicoUpdateRequest } from '../interface/tecnico.interface';

const baseUrl = environment.BASE_URL;
const tecnicosEndpoint = environment.TECNICOS_ENDPOINT;
const tecnicosMeEndpoint = environment.TECNICOS_ME_ENDPOINT;

@Injectable({
  providedIn: 'root'
})
export class TecnicosService {
  private readonly http = inject(HttpClient);

  listar(soloActivos = false): Observable<Tecnico[]> {
    return this.http.get<Tecnico[]>(`${baseUrl}${tecnicosEndpoint}?solo_activos=${soloActivos}`);
  }

  listarMisTecnicos(soloActivos = false): Observable<Tecnico[]> {
    return this.http.get<Tecnico[]>(`${baseUrl}${tecnicosMeEndpoint}?solo_activos=${soloActivos}`);
  }

  crear(payload: TecnicoCreateRequest): Observable<Tecnico> {
    return this.http.post<Tecnico>(`${baseUrl}${tecnicosEndpoint}/`, payload);
  }

  actualizar(tecnicoId: number, payload: TecnicoUpdateRequest): Observable<Tecnico> {
    return this.http.put<Tecnico>(`${baseUrl}${tecnicosEndpoint}/${tecnicoId}`, payload);
  }

  cambiarEstado(tecnicoId: number, estado: boolean): Observable<Tecnico> {
    return this.http.patch<Tecnico>(`${baseUrl}${tecnicosEndpoint}/${tecnicoId}/estado?estado=${estado}`, {});
  }

  eliminar(tecnicoId: number): Observable<{ mensaje: string }> {
    return this.http.delete<{ mensaje: string }>(`${baseUrl}${tecnicosEndpoint}/${tecnicoId}`);
  }
}
