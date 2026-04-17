import { ChangeDetectionStrategy, Component, inject, input } from '@angular/core';
import { HeaderPage } from "../../../shared/components/header-page/header-page";
import { PanelCard } from "../../components/panel/panel-card/panel-card";
import { Dashboard } from '../../service/dashboard';
import { LucideCheck, LucideClock, LucideStar, LucideX } from '@lucide/angular';
import { PanelStatsRubro } from "../../components/panel/panel-stats-rubro/panel-stats-rubro";
import { PanelRating } from "../../components/panel/panel-rating/panel-rating";
import { PanelAssignment } from "../../components/panel/panel-assignment/panel-assignment";

@Component({
  selector: 'app-control-panel',
  imports: [HeaderPage, PanelCard, PanelStatsRubro, PanelRating, PanelAssignment],
  templateUrl: './control-panel.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export default class ControlPanel {
  public dashboardService = inject(Dashboard);
  protected readonly iconComplete = LucideCheck;
  protected readonly iconCancel = LucideX;
  protected readonly iconClock = LucideClock;
  protected readonly iconStar = LucideStar;
}
