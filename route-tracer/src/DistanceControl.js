// DistanceControl.js
export const DistanceControl = L.Control.extend({
    options: {
      position: 'topright',
    },
  
    onAdd: function () {
      const container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
      container.style.backgroundColor = 'white';
      container.style.padding = '5px';
      container.style.fontSize = '14px';
      container.innerHTML = 'Distance: - m<br>Segment: -';
      container.id = 'distance-control';
      return container;
    },
  
    setInfo: function (distance, segment, angle) {
        const distanceControlElement = document.getElementById('distance-control');
        distanceControlElement.innerHTML = `Distance: ${(distance).toFixed(1)} m<br>Segment: ${segment}<br>Angle: ${angle.toFixed(1)}°`;
    }
});
  