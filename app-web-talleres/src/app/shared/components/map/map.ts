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
type MapboxGeoJSONSource = import('mapbox-gl').GeoJSONSource;


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
  private secondaryMarkers: MapboxMarker[] = [];
  private routeVisible = false;
  private readonly locationEffect = effect(() => {
    const location = this.initialLocation();
    if (!location || !this.map || !this.mapboxModule) {
      return;
    }

    this.placeMarker([location.longitud, location.latitud], false, false);
  });
  private readonly secondaryLocationsEffect = effect(() => {
    const locations = this.secondaryLocations();
    if (!this.map || !this.mapboxModule || this.isRegisterMode()) {
      return;
    }

    this.renderSecondaryMarkers(locations);
  });

  public mode = input.required<ModeMap>();
  public initialCenter = input<[number, number]>([-63.18117, -17.78326]);
  public initialZoom = input<number>(4);
  public showSearchBox = input<boolean>(false);
  public initialLocation = input<MapLocation | null>(null);
  public secondaryLocations = input<MapLocation[]>([]);

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

      this.renderRouteLine();
    });

    if (this.isRegisterMode()) {
      this.map.on('click', (event) => {
        this.placeMarker([event.lngLat.lng, event.lngLat.lat], true, true);
      });
    }
  }

  ngOnDestroy(): void {
    this.marker?.remove();
    this.secondaryMarkers.forEach((marker) => marker.remove());
    this.secondaryMarkers = [];
    this.removeRouteLine();
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

    if (!this.isRegisterMode()) {
      this.renderSecondaryMarkers(this.secondaryLocations());
      this.renderRouteLine();
    }

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

  private renderSecondaryMarkers(locations: MapLocation[]): void {
    if (!this.map || !this.mapboxModule) {
      return;
    }

    this.secondaryMarkers.forEach((marker) => marker.remove());
    this.secondaryMarkers = [];

    for (const location of locations) {
      if (
        typeof location.latitud !== 'number' ||
        !Number.isFinite(location.latitud) ||
        typeof location.longitud !== 'number' ||
        !Number.isFinite(location.longitud)
      ) {
        continue;
      }

      const marker = new this.mapboxModule.default.Marker({
        draggable: false,
        color: '#2563eb',
      })
        .setLngLat([location.longitud, location.latitud])
        .addTo(this.map);

      this.secondaryMarkers.push(marker);
    }

    this.fitBoundsToMarkers();
    this.renderRouteLine();
  }

  private renderRouteLine(): void {
    if (!this.map || !this.mapboxModule || this.isRegisterMode()) {
      return;
    }

    const principal = this.marker?.getLngLat();
    const secundaria = this.secondaryMarkers[0]?.getLngLat();

    if (!principal || !secundaria) {
      this.removeRouteLine();
      return;
    }

    const routeData = {
      type: 'Feature',
      geometry: {
        type: 'LineString',
        coordinates: [
          [principal.lng, principal.lat],
          [secundaria.lng, secundaria.lat],
        ],
      },
      properties: {},
    };

    const existingSource = this.map.getSource('incident-route') as MapboxGeoJSONSource | undefined;
    if (existingSource) {
      existingSource.setData(routeData as never);
    } else {
      this.map.addSource('incident-route', {
        type: 'geojson',
        data: routeData as never,
      });
    }

    if (!this.map.getLayer('incident-route-line')) {
      this.map.addLayer({
        id: 'incident-route-line',
        type: 'line',
        source: 'incident-route',
        layout: {
          'line-cap': 'round',
          'line-join': 'round',
        },
        paint: {
          'line-color': '#2563eb',
          'line-width': 4,
          'line-dasharray': [1.5, 1.2],
          'line-opacity': 0.9,
        },
      });
    }

    this.routeVisible = true;
  }

  private removeRouteLine(): void {
    if (!this.map) {
      return;
    }

    if (this.map.getLayer('incident-route-line')) {
      this.map.removeLayer('incident-route-line');
    }

    if (this.map.getSource('incident-route')) {
      this.map.removeSource('incident-route');
    }

    this.routeVisible = false;
  }

  private fitBoundsToMarkers(): void {
    if (!this.map || !this.mapboxModule) {
      return;
    }

    const points: [number, number][] = [];
    const principal = this.marker?.getLngLat();
    if (principal) {
      points.push([principal.lng, principal.lat]);
    }

    for (const marker of this.secondaryMarkers) {
      const p = marker.getLngLat();
      points.push([p.lng, p.lat]);
    }

    if (points.length < 2) {
      return;
    }

    const bounds = new this.mapboxModule.default.LngLatBounds(points[0], points[0]);
    for (const point of points.slice(1)) {
      bounds.extend(point);
    }

    this.map.fitBounds(bounds, {
      padding: 60,
      maxZoom: 14,
      duration: 0,
    });
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
