import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { Demanda } from '../../../interface/dataSummaryManager.interface';

@Component({
  selector: 'panel-stats-rubro',
  imports: [],
  templateUrl: './panel-stats-rubro.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PanelStatsRubro {
  public demandData = signal<Demanda[]>([
    { tipo: 'Mecánica', cantidad: 100 },
    { tipo: 'Eléctrica', cantidad: 60 },
    { tipo: 'Carrocería', cantidad: 17 },
    { tipo: 'Pintura', cantidad: 5 },
  ]);
  private porcentajeTotal = this.demandData().reduce((acc, curr) => acc + curr.cantidad, 0);

  currentPercentage(cantidad: number): number {
    return Math.round((cantidad / this.porcentajeTotal) * 100);
  }

  barProgress(val: number): string {
    if (val >= 50) return 'progress-primary'
    if (val >= 30 && val < 50) return 'progress-secondary'
    return 'progress-neutral'
  }
}
