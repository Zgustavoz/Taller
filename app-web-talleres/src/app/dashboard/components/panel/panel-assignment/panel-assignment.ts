import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { Respuestas } from '../../../interface/dataSummaryManager.interface';

@Component({
  selector: 'panel-assignment',
  imports: [],
  templateUrl: './panel-assignment.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PanelAssignment {
  public assignedTasks = signal<Respuestas>({
    aceptadas: 30,
    rechazadas: 10
  })
  public totalTasks = this.assignedTasks().aceptadas + this.assignedTasks().rechazadas;

  acceptedPercentage(): number {
    return Math.round((this.assignedTasks().aceptadas / this.totalTasks) * 100);
  }

  rejectedPercentage(): number {
    return Math.round((this.assignedTasks().rechazadas / this.totalTasks) * 100);
  }

}
