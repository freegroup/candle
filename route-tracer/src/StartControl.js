import L from 'leaflet';

export const StartControl = L.Control.extend({
  options: {
    position: 'bottomright',
  },

  onAdd: function () {
    const container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
    const startButton = L.DomUtil.create('button', '', container);
    startButton.innerHTML = 'Start';
    startButton.style.backgroundColor = 'white';
    startButton.style.padding = '5px';
    startButton.style.fontSize = '14px';
    startButton.id = 'start-button';
    return container;
  },
});
