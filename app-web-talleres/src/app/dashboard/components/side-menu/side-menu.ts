import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { SideMenuOptions } from "./side-menu-options/side-menu-options";
import { SideMenuHeader } from "./side-menu-header/side-menu-header";

@Component({
  selector: 'app-side-menu',
  imports: [SideMenuOptions, SideMenuHeader],
  templateUrl: './side-menu.html',
  host: {
    class: 'drawer-side is-drawer-close:overflow-visible',
  },
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SideMenu {
  readonly drawerId = input.required<string>();
}
