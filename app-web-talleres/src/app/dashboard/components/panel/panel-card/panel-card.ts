import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { LucideIcon, LucideDynamicIcon, LucideAArrowUp, LucideCircle } from '@lucide/angular';

type ColorCard = 'YELLOW' | 'GREEN' | 'RED' | 'PURPLE';

@Component({
  selector: 'panel-card',
  imports: [LucideDynamicIcon, LucideCircle],
  templateUrl: './panel-card.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PanelCard {
  public statsKapis = input.required<number>();
  public icon = input<LucideIcon>(LucideAArrowUp);
  public title = input.required<string>();
  public color = input<ColorCard>('GREEN');

  colorSelected(): string {
    switch (this.color()) {
      case 'YELLOW':
        return 'bg-yellow-50 text-warning';
      case 'GREEN':
        return 'bg-green-50 text-emerald-500';
      case 'RED':
        return 'bg-red-50 text-red-500';
      case 'PURPLE':
        return 'bg-purple-50 text-primary';
      default:
        return 'bg-green-50 text-emerald-500';
    }
  }
}
