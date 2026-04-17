import type { LucideIcon } from "@lucide/angular";

export interface OptionsSidebar {
  label: string;
  icon: LucideIcon;
  tooltip: string;
  title: string;
  route?: string;
}
