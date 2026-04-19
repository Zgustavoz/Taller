import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  inject,
  input,
  OnDestroy,
  OnInit,
  effect,
  output,
  PLATFORM_ID,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import type { ModeMap } from '../../../interface/mapa.interface';
import { environment } from '../../../../environments/environment';

export interface MapLocation {
  latitud: number;
  longitud: number;
}

type MapboxModule = typeof import('mapbox-gl');
type MapboxMap = import('mapbox-gl').Map;
type MapboxMarker = import('mapbox-gl').Marker;


@Component({
  selector: 'app-map',
  imports: [],
  templateUrl: './map.html',
  styleUrl: './map.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MapComponent implements OnInit, OnDestroy {

  private readonly platformId = inject(PLATFORM_ID);
  private readonly mapContainer = viewChild.required<ElementRef<HTMLDivElement>>('mapContainer');

  private mapboxModule?: MapboxModule;
  private map?: MapboxMap;
  private marker?: MapboxMarker;
  private readonly locationEffect = effect(() => {
    const location = this.initialLocation();
    if (!location || !this.map || !this.mapboxModule) {
      return;
    }

    this.placeMarker([location.longitud, location.latitud], false, false);
  });

  public mode = input.required<ModeMap>();
  public initialCenter = input<[number, number]>([-63.18117, -17.78326]);
  public initialZoom = input<number>(4);
  public showSearchBox = input<boolean>(false);
  public initialLocation = input<MapLocation | null>(null);

  public locationSelected = output<MapLocation>();

  public isRegisterMode(): boolean {
    return this.mode() === 'register';
  }

  async ngOnInit(): Promise<void> {
    if (!isPlatformBrowser(this.platformId)) {
      return;
    }

    this.mapboxModule = await import('mapbox-gl');
    this.mapboxModule.default.accessToken = environment.MAPBOX_ACCESS_TOKEN;

    this.map = new this.mapboxModule.default.Map({
      container: this.mapContainer().nativeElement,
      style: 'mapbox://styles/mapbox/streets-v12',
      center: this.initialCenter(),
      zoom: this.initialZoom(),
    });

    this.map.addControl(new this.mapboxModule.default.NavigationControl(), 'top-right');

    this.map.on('load', () => {
      const initialLocation = this.initialLocation();
      if (initialLocation) {
        this.placeMarker([initialLocation.longitud, initialLocation.latitud], false, false);
      }
    });

    if (this.isRegisterMode()) {
      this.map.on('click', (event) => {
        this.placeMarker([event.lngLat.lng, event.lngLat.lat], true, true);
      });
    }
  }

  ngOnDestroy(): void {
    this.marker?.remove();
    this.map?.remove();
    this.marker = undefined;
    this.map = undefined;
    this.mapboxModule = undefined;
  }

  private placeMarker(lngLat: [number, number], shouldFlyTo: boolean, shouldEmitLocation: boolean): void {
    if (!this.map || !this.mapboxModule) {
      return;
    }

    this.marker?.remove();
    this.marker = new this.mapboxModule.default.Marker({
      draggable: this.isRegisterMode(),
      color: '#d11f1f',
    })
      .setLngLat(lngLat)
      .addTo(this.map);

    if (shouldEmitLocation) {
      this.emitLocation();
    }

    if (this.isRegisterMode()) {
      this.marker.on('dragend', () => this.emitLocation());
    }

    if (shouldFlyTo) {
      this.map.flyTo({ center: lngLat, zoom: Math.max(this.map.getZoom(), 13) });
    }
  }

  private emitLocation(): void {
    const markerLngLat = this.marker?.getLngLat();
    if (!markerLngLat) {
      return;
    }

    this.locationSelected.emit({
      latitud: markerLngLat.lat,
      longitud: markerLngLat.lng,
    });
  }

}
