import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Icon } from 'leaflet';

import { DistanceControl } from './DistanceControl';
import { StartControl } from './StartControl';
import { BLEConnectControl } from './BLEConnectControl';


export class Map {
    static userMarker = null
    static nextMarker = null
    static gpsRoute = []
    static route = null
    static map = null
    static distanceControl = null
    static init() {

        delete Icon.Default.prototype._getIconUrl;
        Icon.Default.mergeOptions({
          iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
          iconUrl: require('leaflet/dist/images/marker-icon.png'),
          shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
        });

        // Initialize the map
        this.map = L.map('map').setView([51.505, -0.09], 13);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
            maxZoom: 19,
        }).addTo(this.map);

        this.distanceControl = new DistanceControl();
        this.distanceControl.addTo(this.map);

        this.startControl = new StartControl();
        this.startControl.addTo(this.map);

        this.bleConnectControl = new BLEConnectControl();
        this.bleConnectControl.addTo(this.map);

        function setMapHeight() {
            const mapElement = document.getElementById("map")
            const windowHeight = window.innerHeight
            mapElement.style.height = `${windowHeight}px`
        }
        // Set the initial map height
        setMapHeight()
        // Update the map height when the window is resized
        window.addEventListener("resize", setMapHeight)
    }

    static setRoute(gpsRoute){
        this.gpsRoute = gpsRoute
        this.renderRoute()
        this.renderMarker()
    }
    

    static setInfo(distance, currentCoordinateIndex, angle) {
        this.distanceControl.setInfo(distance, currentCoordinateIndex, angle);
        
        // Pass the angle to the BLEConnectControl
        this.bleConnectControl.setAngle(angle);
    }


    static setUserPosition(coord) {
        this.userMarker.setLatLng(coord);
    }

    static renderRoute() {
        // Display the route
        this.route = L.polyline(this.gpsRoute, { color: 'blue' }).addTo(this.map);
        this.map.fitBounds(this.route.getBounds());

        // Initialize the user's marker
        this.userMarker = L.marker(this.gpsRoute[0], { icon: new Icon.Default() }).addTo(this.map);
    }
      
    static renderMarker() {
        this.gpsRoute.forEach((coord) => {
          L.circleMarker(coord, {
            color: coord.color,
            fillColor: coord.color,
            fillOpacity: 1,
            radius: 5,
          }).addTo(this.map);
        });
    }


    static setNextMarker(coord) {
        if (!this.nextMarker) {
            this.nextMarker = L.circleMarker(coord, {
            color: 'red',
            fillColor: 'red',
            fillOpacity: 1,
            radius: 5,
            }).addTo(this.map);
        } else if (coord) {
            this.nextMarker.setLatLng(coord);
        } else {
            this.map.removeLayer(this.nextMarker);
            this.nextMarker = null;
        }
    }

}
  