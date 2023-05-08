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
        routePoints.splice(index, 1);
        updateRoute();
        updateMarkers();
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
