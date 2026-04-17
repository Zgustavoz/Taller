import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-header-page',
  imports: [],
  templateUrl: './header-page.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HeaderPage {
  public title = input.required<string>();
  public subtitle = input<string>();
}
