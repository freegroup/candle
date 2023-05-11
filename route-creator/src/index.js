import L from 'leaflet';
import 'leaflet-geometryutil/src/leaflet.geometryutil';

import 'leaflet/dist/leaflet.css';
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

const clickDistanceThreshold = 30; // in pixels


let shiftKeyDown = false; // track if the shift key is currently down
document.addEventListener('keydown', (event) => {
  if (event.key === 'Shift') {
    shiftKeyDown = true;
  }
});

document.addEventListener('keyup', (event) => {
  if (event.key === 'Shift') {
    shiftKeyDown = false;
  }
});

// Fix the default marker icon
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: markerIcon,
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
});

const map = L.map('map').setView([49.45952491071984, 8.603418437201945], 19);

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  maxZoom: 19,
}).addTo(map);

const markersLayer = L.layerGroup().addTo(map);

const routePoints = [];
const routeLayer = L.layerGroup().addTo(map);
let routePolyline = L.polyline(routePoints, { color: 'blue' }).addTo(routeLayer);

const updateRoute = () => {
  routeLayer.clearLayers();
  routePolyline = L.polyline(routePoints, { color: 'blue' }).addTo(routeLayer);
};

const findClosestSegmentIndex = (latlng) => {
  let minDistance = Infinity;
  let closestSegmentIndex = -1;

  for (let i = 0; i < routePoints.length - 1; i++) {
    const segmentStart = L.latLng(routePoints[i]);
    const segmentEnd = L.latLng(routePoints[i + 1]);
    const distance = L.GeometryUtil.distanceSegment(map, latlng, segmentStart, segmentEnd);

    if (distance < minDistance) {
      minDistance = distance;
      closestSegmentIndex = i;
    }
  }

  return closestSegmentIndex;
};


const createMarker = (latlng, index) => {
  const marker = L.marker(latlng, { draggable: true });

  marker.on('move', (moveEvent) => {
    const newPosition = moveEvent.target.getLatLng();
    routePoints[index] = [newPosition.lat, newPosition.lng];
    routePolyline.setLatLngs(routePoints);
    console.log(JSON.stringify(routePoints));
  });

  marker.on('click', (event) => {
    console.log('Marker clicked!', event.target, shiftKeyDown);
    if(shiftKeyDown){
        if(routePoints.length > 2){
            routePoints.splice(index, 1);
            updateRoute();
            updateMarkers();
        }
    }
  });

  return marker;
};

const updateMarkers = () => {
  markersLayer.clearLayers();
  routePoints.forEach((point, index) => {
    const marker = createMarker(point, index);
    markersLayer.addLayer(marker);
  });
};

map.on('click', (event) => {
  const latlng = event.latlng;
  const closestSegmentIndex = findClosestSegmentIndex(latlng);

  let index;

  if (closestSegmentIndex >= 0) {
    const segmentStart = L.latLng(routePoints[closestSegmentIndex]);
    const segmentEnd = L.latLng(routePoints[closestSegmentIndex + 1]);
    const distance = L.GeometryUtil.distanceSegment(map, latlng, segmentStart, segmentEnd);

    if (distance < clickDistanceThreshold) {
      index = closestSegmentIndex + 1;
      routePoints.splice(index, 0, [latlng.lat, latlng.lng]);
    } else {
      index = routePoints.length;
      routePoints.push([latlng.lat, latlng.lng]);
    }
  } else {
    index = routePoints.length;
    routePoints.push([latlng.lat, latlng.lng]);
  }

  updateRoute();
  updateMarkers();
  console.log(JSON.stringify(routePoints));
});

// add a button to the leaflet map which copies the routePoints to the clipboard
// The button shold be on the bottom left corner of the map. Avoid, that the defalt
// eventhandler for the map.click is called when the button is clicked.
const copyButton = L.control({ position: 'topright' });
copyButton.onAdd = () => {
  const button = L.DomUtil.create('button');
  button.innerHTML = 'Copy Route';
  button.onclick = (event) => {
    // avoid default eventhandler for map.click
    event.stopPropagation();
    const preciseRoutePoints = routePoints.map(point => truncateGPSCoordinatesToPrecision(point, 1));
    // copy the json array as formated json, with indent=2 into the clipboard
    navigator.clipboard.writeText(JSON.stringify(preciseRoutePoints, null, 2));
  };
  return button;
}

copyButton.addTo(map);

function getDecimalPlacesForPrecision(precisionInMeters) {
  const metersPerDegree = 111111;
  const degrees = precisionInMeters / metersPerDegree;
  const decimalPlaces = Math.ceil(-Math.log10(degrees));
  return decimalPlaces;
}

function truncateGPSCoordinatesToPrecision(gpsCoordinate, precisionInMeters) {
  const decimalPlaces = getDecimalPlacesForPrecision(precisionInMeters);
  
  const lat = parseFloat(gpsCoordinate[0].toFixed(decimalPlaces));
  const lng = parseFloat(gpsCoordinate[1].toFixed(decimalPlaces));

  return [lat, lng];
}