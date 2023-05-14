import L from 'leaflet';

export const DistanceControl = L.Control.extend({
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
