import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

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
const userMarker = L.marker(gpsCoordinatesArray[0]).addTo(map);

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
