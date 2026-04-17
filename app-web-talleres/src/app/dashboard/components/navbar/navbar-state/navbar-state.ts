import { ChangeDetectionStrategy, Component, computed, output, signal } from '@angular/core';
import { LucideRadius } from "@lucide/angular";

@Component({
  selector: 'app-navbar-state',
  imports: [LucideRadius],
  templateUrl: './navbar-state.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NavbarState {
  public workshopStateValue = signal<boolean>(true);
  public stateChanged = output<boolean>();
  public statusWorkshop = computed(() => this.workshopStateValue() ? 'En línea' : 'Desconectado');

  onToggle(value: boolean) {
    this.workshopStateValue.set(value);
    this.stateChanged.emit(value);
  }
}
