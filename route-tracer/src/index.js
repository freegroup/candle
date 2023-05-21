import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

import { Device } from './Device.js';
import { Map } from './Map.js';
import { Route } from './Route.js';

// Initialize GPS coordinates array
let gpsCoordinatesArray = require('./route.json');
let route = new Route(gpsCoordinatesArray);
Map.init();
Map.setRoute(route);

let lastVibratedIndex = -1;

function onPositionUpdate(position) {
  const lat = position.coords.latitude;
  const lng = position.coords.longitude;
  const currentLatLng = L.latLng(lat, lng);

  Map.setUserPosition(currentLatLng)

  // Update current index based on current position
  let segment = route.getClosestSegment(currentLatLng);
  let currentCoordinateIndex = segment.start.index;

  if (currentCoordinateIndex > lastVibratedIndex) {
    Device.vibrate();
    lastVibratedIndex = currentCoordinateIndex;
    if (currentCoordinateIndex < route.length - 1) {
      Map.setNextMarker(route[currentCoordinateIndex + 1]);
    } else {
      Map.setNextMarker(null);
    }
  }

  // Calculate the distance and angle
  if (route[currentCoordinateIndex + 1]) {
    const nearestCoord = route[currentCoordinateIndex + 1];
    const nearestCoordLatLng = L.latLng(nearestCoord);
    
    const distance = currentLatLng.distanceTo(nearestCoordLatLng);
    const angle = currentLatLng.bearingTo(nearestCoordLatLng);

    Map.setInfo(distance, currentCoordinateIndex, angle);
  }
}


function onStartButtonClick() {
  (async () => {
    if (Device.watchId !== null) {
      Device.stopGPSTracking();
      document.getElementById("start-button").innerText = "Start";
    } else {
      await Device.startGPSTracking(onPositionUpdate, route);
      document.getElementById("start-button").innerText = "Stop";
    }
  })();
}
document.getElementById('start-button').addEventListener('click', onStartButtonClick);


function handleVisibilityChange() {
  if (document.visibilityState === 'visible') {
    (async () => {
      await Device.requestGeolocationPermission();
      await Device.requestWakeLock();
    })();
  }
}

// Event Listener für 'visibilitychange'
document.addEventListener('visibilitychange', handleVisibilityChange);
// Führen Sie die Funktion aus, wenn die Seite bereits sichtbar ist
if (document.visibilityState === 'visible') {
  handleVisibilityChange();
}

