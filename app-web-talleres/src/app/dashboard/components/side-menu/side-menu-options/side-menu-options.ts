import { ChangeDetectionStrategy, Component } from '@angular/core';
import { LucideClipboardClock, LucideHouse, LucideDynamicIcon, LucideUserRoundCog } from '@lucide/angular';
import type { OptionsSidebar } from '../../../interface/optionsSidebar.interface';
import { RouterLink, RouterLinkActive } from "@angular/router";

@Component({
  selector: 'app-side-menu-options',
  imports: [LucideDynamicIcon, RouterLink, RouterLinkActive],
  templateUrl: './side-menu-options.html',
  host: {
    class: 'menu w-full grow'
  },
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SideMenuOptions {

  public menuOptions: OptionsSidebar[] = [
    {
      label: 'Panel de control',
      icon: LucideHouse,
      tooltip: 'Panel de control',
      title: 'Panel',
      route: '/dashboard/control-panel'
    }, {
      label: 'Solicitudes Pendientes',
      icon: LucideClipboardClock,
      tooltip: 'Solicitudes Pendientes',
      title: 'Solicitudes',
      route: '/dashboard/solicitudes'
    },
    {
      label: 'Servicios Activos',
      icon: LucideUserRoundCog,
      tooltip: 'Servicios Activos',
      title: 'Servicios',
      route: '/dashboard/servicios'
    }
  ]
}
