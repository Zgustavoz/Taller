import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { NavbarState } from "./navbar-state/navbar-state";
import { LucidePanelLeftOpen } from "@lucide/angular";
import { NavbarPerfil } from "./navbar-perfil/navbar-perfil";

@Component({
  selector: 'app-navbar',
  imports: [NavbarState, LucidePanelLeftOpen, NavbarPerfil],
  templateUrl: './navbar.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Navbar {
  public drawerId = input.required<string>();
}
