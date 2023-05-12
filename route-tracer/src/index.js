import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Icon } from 'leaflet';

delete Icon.Default.prototype._getIconUrl;
Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl: require('leaflet/dist/images/marker-icon.png'),
  shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
});


// Initialize GPS coordinates array
const gpsCoordinatesArray = require('./route.json');

// Set distanceToDetectHit
const distanceToDetectHit = 50; // Meters

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

const DistanceControl = L.Control.extend({
  options: {
    position: 'topright',
  },

  onAdd: function () {
    const container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
    container.style.backgroundColor = 'white';
    container.style.padding = '5px';
    container.style.fontSize = '14px';
    container.innerHTML = 'Distance: - m';
    container.id = 'distance-control';
    return container;
  },
});
const distanceControl = new DistanceControl().addTo(map);

// Function to update the user's position
function updatePosition(position) {
  const lat = position.coords.latitude;
  const lng = position.coords.longitude;
  const currentLatLng = L.latLng(lat, lng);

  userMarker.setLatLng(currentLatLng);

  const nextCoordinateIndex = gpsCoordinatesArray.findIndex(
    (coord, index, array) => {
      const prevCoord = index > 0 ? array[index - 1] : array[0];
      const currentCoord = L.latLng(coord);
      const prevCoordLatLng = L.latLng(prevCoord);

      const distanceToCurrent = currentLatLng.distanceTo(currentCoord);
      const distanceToPrev = currentLatLng.distanceTo(prevCoordLatLng);

      return distanceToCurrent <= distanceToDetectHit && distanceToPrev >= distanceToDetectHit;
    }
  );

  if (nextCoordinateIndex >= 0) {
    gpsCoordinatesArray.shift();
  }
  // Calculate the distance
  const nearestCoord = gpsCoordinatesArray[0];
  const nearestCoordLatLng = L.latLng(nearestCoord);
  const distance = currentLatLng.distanceTo(nearestCoordLatLng);

  // Update the distance control
  const distanceControlElement = document.getElementById('distance-control');
  distanceControlElement.innerHTML = `Distance: ${(distance / 1000).toFixed(1)} km`;
}

// Function to handle geolocation errors
function geolocationError(error) {
  console.error('Error occurred in geolocation:', error);
}

// Update the user's position every 10 seconds
navigator.geolocation.watchPosition(updatePosition, geolocationError, {
  enableHighAccuracy: true,
  maximumAge: 10000,
  timeout: 10000,
});
