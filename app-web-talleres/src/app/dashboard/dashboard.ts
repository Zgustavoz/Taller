import { ChangeDetectionStrategy, Component } from '@angular/core';
import { SideMenu } from "./components/side-menu/side-menu";
import { RouterOutlet } from '@angular/router';
import { Navbar } from "./components/navbar/navbar";

@Component({
  selector: 'app-dashboard',
  imports: [SideMenu, RouterOutlet, Navbar],
  templateUrl: './dashboard.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Dashboard {
  readonly drawerId = 'my-drawer-1';
  onToggleValue(value: boolean): void {
    console.log('Toggle value:', value);
  }

}
