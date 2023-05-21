// BLEConnectControl.js
import L from 'leaflet';

export const BLEConnectControl = L.Control.extend({
    options: {
        position: 'bottomright',
    },

    initialize: function (options) {
        L.Util.setOptions(this, options);
        this._myCharacteristic = null; 
    },

    onAdd: function () {
        const container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
        const connectButton = L.DomUtil.create('button', '', container);
        connectButton.innerHTML = 'Connect';
        connectButton.style.backgroundColor = 'white';
        connectButton.style.padding = '5px';
        connectButton.style.fontSize = '14px';
        connectButton.id = 'connect-button';

        connectButton.addEventListener('click',  () => {
            navigator.bluetooth.requestDevice({ 
                acceptAllDevices: true,
                optionalServices: ['4fafc201-1fb5-459e-8fcc-c5c9c331914b'] // Set the service UUID you want to connect with
              })
              .then(device => {
                return device.gatt.connect();
              })
              .then(server => {
                return server.getPrimaryService('4fafc201-1fb5-459e-8fcc-c5c9c331914b');
              })
              .then(service => {
                return service.getCharacteristic('beb5483e-36e1-4688-b7f5-ea07361b26a8');
              })
              .then(characteristic => {
                this._myCharacteristic = characteristic;
              })
              .catch(error => {
                console.log('Error: ' + error);
              });        
        });

        return container;
    },

    setAngle: function(angle) {
        console.log(this._myCharacteristic)
        if(this._myCharacteristic) {
            const angleBuffer = new TextEncoder().encode(String(angle));
            this._myCharacteristic.writeValue(angleBuffer);
        }
    }
});
