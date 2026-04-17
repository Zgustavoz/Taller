import { ChangeDetectionStrategy, Component } from '@angular/core';
import { HeaderPage } from "../shared/components/header-page/header-page";

@Component({
  selector: 'app-solicitudes',
  imports: [HeaderPage],
  templateUrl: './solicitudes.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Solicitudes { }
