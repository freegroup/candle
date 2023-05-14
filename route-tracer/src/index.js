import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Icon } from 'leaflet';
import { extendLatLng } from './leafletExtensions';
import { DistanceControl } from './DistanceControl';
import { StartControl } from './StartControl';

// Erweitert die L.LatLng-Klasse mit den zusätzlichen Funktionen
extendLatLng(L);

delete Icon.Default.prototype._getIconUrl;
Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl: require('leaflet/dist/images/marker-icon.png'),
  shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
});


// Initialize GPS coordinates array
let gpsCoordinatesArray = require('./route.json');
gpsCoordinatesArray = gpsCoordinatesArray.map(coord => ({
  lat: coord[0],
  lng: coord[1],
}));


// Set distanceToDetectHit
const distanceToDetectHit = 3; // Meters
const walkingSpeed = 8; // m/s
const simulationInterval = 100; // ms
const distanceToInsert = 5; // Meter
const minSegmentLength = 10; // Meter

function angleBetweenPoints(p1, p2, p3) {
  const v1 = {
    lat: p1.lat - p2.lat,
    lng: p1.lng - p2.lng,
  };
  
  const v2 = {
    lat: p3.lat - p2.lat,
    lng: p3.lng - p2.lng,
  };
  
  const dotProduct = v1.lat * v2.lat + v1.lng * v2.lng;
  const v1Magnitude = Math.sqrt(v1.lat * v1.lat + v1.lng * v1.lng);
  const v2Magnitude = Math.sqrt(v2.lat * v2.lat + v2.lng * v2.lng);
  
  const cosAngle = dotProduct / (v1Magnitude * v2Magnitude);
  const angle = Math.acos(cosAngle) * (180 / Math.PI);

  return angle;
}

function isSpecialCoordinate(prevCoordLatLng, currentCoordLatLng, nextCoordLatLng){
  if (!prevCoordLatLng || !currentCoordLatLng || !nextCoordLatLng) {
    return false;
  }
  const angle = angleBetweenPoints(prevCoordLatLng, currentCoordLatLng, nextCoordLatLng);
  return (angle >= 60 && angle <= 120)
}

function addExtraPoints(coords) {
  const modifiedCoords = [];

  for (let i = 0; i < coords.length; i++) {
    let prevCoord = i > 0 ? new L.LatLng(coords[i - 1].lat, coords[i - 1].lng) : null;
    let currentCoord = new L.LatLng(coords[i].lat, coords[i].lng);
    let nextCoord = i < coords.length - 1 ? new L.LatLng(coords[i + 1].lat, coords[i + 1].lng) : null;

    // Füge den eingefügten Vorgänger hinzu
    if (prevCoord && isSpecialCoordinate(prevCoord, currentCoord, nextCoord)) {
      const prevSegmentLength = currentCoord.distanceTo(prevCoord);
      if (prevSegmentLength > minSegmentLength) {
        const extraPrevCoord = currentCoord.destinationPoint(distanceToInsert, currentCoord.bearingTo(prevCoord));
        modifiedCoords.push({
          lat: extraPrevCoord.lat,
          lng: extraPrevCoord.lng,
          color: 'blue',
          synthetic: true,
        });
      }
    }

    // Füge die aktuelle Koordinate hinzu
    modifiedCoords.push({
      lat: currentCoord.lat,
      lng: currentCoord.lng,
      color: isSpecialCoordinate(prevCoord, currentCoord, nextCoord) ? 'yellow' : 'green',
      synthetic: false,
    });

    // Füge den eingefügten Nachfolger hinzu
    if (nextCoord && isSpecialCoordinate(prevCoord, currentCoord, nextCoord)) {
      const nextSegmentLength = currentCoord.distanceTo(nextCoord);
      if (nextSegmentLength > minSegmentLength) {
        const extraNextCoord = currentCoord.destinationPoint(distanceToInsert, currentCoord.bearingTo(nextCoord));
        modifiedCoords.push({
          lat: extraNextCoord.lat,
          lng: extraNextCoord.lng,
          color: 'blue',
          synthetic: true,
        });
      }
    }
  }

  return modifiedCoords;
}



console.log(JSON.stringify(gpsCoordinatesArray, undefined, 2))

gpsCoordinatesArray = addExtraPoints(gpsCoordinatesArray);

// Initialize the map
const map = L.map('map').setView([51.505, -0.09], 13);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  maxZoom: 19,
}).addTo(map);

// Display the route
const route = L.polyline(gpsCoordinatesArray, { color: 'blue' }).addTo(map);
map.fitBounds(route.getBounds());

// Initialize the user's marker
const userMarker = L.marker(gpsCoordinatesArray[0], { icon: new Icon.Default() }).addTo(map);

const distanceControl = new DistanceControl();
distanceControl.addTo(map);
const startControl = new StartControl();
startControl.addTo(map);

function addRouteMarkers(coordinatesArray) {
  coordinatesArray.forEach((coord, index) => {
    let color = 'green';

    if (index > 0 && index < coordinatesArray.length - 1) {
      const prevCoord = coordinatesArray[index - 1];
      const nextCoord = coordinatesArray[index + 1];

      const currentCoordLatLng = L.latLng(coord);
      const prevCoordLatLng = L.latLng(prevCoord);
      const nextCoordLatLng = L.latLng(nextCoord);

      if(isSpecialCoordinate(prevCoordLatLng, currentCoordLatLng, nextCoordLatLng)){
        color = 'yellow';
      }
    }

    L.circleMarker(coord, {
      color: color,
      fillColor: color,
      fillOpacity: 1,
      radius: 5,
    }).addTo(map);
  });
}


let nextLocationMarker;
function updateNextLocationMarker(coord) {
  if (!nextLocationMarker) {
    nextLocationMarker = L.circleMarker(coord, {
      color: 'red',
      fillColor: 'red',
      fillOpacity: 1,
      radius: 5,
    }).addTo(map);
  } else if (coord) {
    nextLocationMarker.setLatLng(coord);
  } else {
    map.removeLayer(nextLocationMarker);
    nextLocationMarker = null;
  }
}


let currentCoordinateIndex = 0;
function updatePosition(position) {
  const lat = position.coords.latitude;
  const lng = position.coords.longitude;
  const currentLatLng = L.latLng(lat, lng);

  userMarker.setLatLng(currentLatLng);

  const nextCoordinateIndex = gpsCoordinatesArray.findIndex(
    (coord, index, array) => {
      if (index <= currentCoordinateIndex) return false;

      const prevCoord = array[currentCoordinateIndex];
      const currentCoord = L.latLng(coord);
      const prevCoordLatLng = L.latLng(prevCoord);

      const distanceToCurrent = currentLatLng.distanceTo(currentCoord);
      const distanceToPrev = currentLatLng.distanceTo(prevCoordLatLng);

      return distanceToCurrent <= distanceToDetectHit && distanceToPrev >= distanceToDetectHit;
    }
  );

  if (nextCoordinateIndex >= 0) {
    // Lassen Sie das Handy für 200 Millisekunden vibrieren, wenn ein neuer Punkt ausgewählt wird
    if (typeof navigator.vibrate === "function") {
      navigator.vibrate(200);
    }

    currentCoordinateIndex = nextCoordinateIndex;
    if (currentCoordinateIndex < gpsCoordinatesArray.length - 1) {
      updateNextLocationMarker(gpsCoordinatesArray[currentCoordinateIndex + 1]);
    } else {
      updateNextLocationMarker(null);
    }
  }

  // Calculate the distance
  if (gpsCoordinatesArray[currentCoordinateIndex + 1]) {
    const nearestCoord = gpsCoordinatesArray[currentCoordinateIndex + 1];
    const nearestCoordLatLng = L.latLng(nearestCoord);
    const distance = currentLatLng.distanceTo(nearestCoordLatLng);

    // Update the distance control
    const distanceControlElement = document.getElementById('distance-control');
    distanceControlElement.innerHTML = `Distance: ${(distance).toFixed(1)} m`;
  }
}

addRouteMarkers(gpsCoordinatesArray);
updateNextLocationMarker(gpsCoordinatesArray[currentCoordinateIndex + 1]);

let watchId = null;
function handleStartButtonClick() {
  (async () => {
    if (watchId) {
      // Stoppe die aktuelle GPS-Überwachung oder Debug-Simulation
      navigator.geolocation.clearWatch(watchId);
      clearTimeout(watchId);
      watchId = null;
      document.getElementById("start-button").innerText = "Start";
    } else {
      const isGpsAllowed = await requestGeolocationPermission();
      if (isGpsAllowed) {
        currentCoordinateIndex = 0;
        updateNextLocationMarker(gpsCoordinatesArray[currentCoordinateIndex + 1]);
        watchId = navigator.geolocation.watchPosition(updatePosition, geolocationError, {
          enableHighAccuracy: true,
          maximumAge: 10000,
          timeout: 10000,
        });
      } else {
        currentCoordinateIndex = 0;
        updateNextLocationMarker(gpsCoordinatesArray[currentCoordinateIndex + 1]);
        watchId = debugWatchPosition(updatePosition, geolocationError);
      }
      document.getElementById("start-button").innerText = "Stop";
    }
  })();
}

document.getElementById('start-button').addEventListener('click', handleStartButtonClick);

// Function to handle geolocation errors
function geolocationError(error) {
  console.error('Error occurred in geolocation:', error);
}


function debugWatchPosition(callback, errorCallback, options) {
  let debugCurrentCoordinateIndex = 0;
  let currentLatLng = L.latLng(gpsCoordinatesArray[0]);

  function updateDebugPosition() {
    if (debugCurrentCoordinateIndex >= gpsCoordinatesArray.length - 1) {
      return;
    }

    const nextLatLng = L.latLng(gpsCoordinatesArray[debugCurrentCoordinateIndex + 1]);
    const distance = currentLatLng.distanceTo(nextLatLng);
    const bearing = currentLatLng.bearingTo(nextLatLng);

    // Berechne die normalisierte walkingSpeed für das Simulationsintervall
    const normalizedWalkingSpeed = walkingSpeed * (simulationInterval / 1000);

    if (distance > normalizedWalkingSpeed) {
      // Bewege dich mit der normalisierten Fußgängergeschwindigkeit entlang der Route
      currentLatLng = currentLatLng.destinationPoint(normalizedWalkingSpeed, bearing);
    } else {
      // Bewege dich zur nächsten Koordinate auf der Route
      debugCurrentCoordinateIndex++;
      currentLatLng = nextLatLng;
    }

    const position = {
      coords: {
        latitude: currentLatLng.lat,
        longitude: currentLatLng.lng,
      },
    };

    callback(position);
    watchId = setTimeout(updateDebugPosition, simulationInterval);
  }

  updateDebugPosition();
  return watchId;
}

async function requestGeolocationPermission() {
  if ('geolocation' in navigator) {
    try {
      const permissionStatus = await navigator.permissions.query({name: 'geolocation'});
      if (permissionStatus.state === 'prompt') {
        return new Promise((resolve) => {
          navigator.geolocation.getCurrentPosition(() => {
            resolve(true);
          }, () => {
            resolve(false);
          });
        });
      } else {
        return permissionStatus.state === 'granted';
      }
    } catch (error) {
      console.error("Fehler bei der Abfrage der Berechtigungen:", error);
      return false;
    }
  } else {
    console.log("Keine GPS-Unterstützung");
    return false;
  }
}





let wakeLock = null;
async function requestWakeLock() {
  try {
    if ('wakeLock' in navigator && 'request' in navigator.wakeLock) {
      wakeLock = await navigator.wakeLock.request('screen');
      console.log('Wake Lock aktiviert.');

      wakeLock.addEventListener('release', () => {
        console.log('Wake Lock wurde freigegeben.');
      });

      document.addEventListener('visibilitychange', async () => {
        if (wakeLock !== null && document.visibilityState === 'visible') {
          wakeLock = await navigator.wakeLock.request('screen');
          console.log('Wake Lock erneut aktiviert.');
        }
      });
    } else {
      console.log('Wake Lock API wird vom Browser nicht unterstützt.');
    }
  } catch (err) {
    console.error(`Wake Lock konnte nicht aktiviert werden: ${err.name}, ${err.message}`);
  }
}
requestWakeLock();
