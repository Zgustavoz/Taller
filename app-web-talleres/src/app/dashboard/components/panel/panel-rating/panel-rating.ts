import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import type { UltimasResena } from '../../../interface/dataSummaryManager.interface';

@Component({
  selector: 'panel-rating',
  imports: [],
  templateUrl: './panel-rating.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PanelRating {
  public ratings = signal<UltimasResena[]>([{
    score: 2,
    comentario: 'Excelente servicio, muy rápido y profesional.',
    foto_usuario: 'https://img.daisyui.com/images/profile/demo/1@94.webp',
    prioridad_incidente: 5,
    usuario: 'Juan Pérez'
  },
  {
    score: 5,
    comentario: 'El servicio fue aceptable, pero se puede mejorar.',
    foto_usuario: 'https://img.daisyui.com/images/profile/demo/2@94.webp',
    prioridad_incidente: 0,
    usuario: 'María García'
  },
  {
    score: 5,
    comentario: 'El servicio fue aceptable, pero se puede mejorar.',
    foto_usuario: 'https://img.daisyui.com/images/profile/demo/2@94.webp',
    prioridad_incidente: 0,
    usuario: 'María García'
  }
  ])

  viewRating(score: number): boolean {
    return score >= 4;
  }
}
