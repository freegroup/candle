const walkingSpeed = 8; // m/s
const simulationInterval = 100; // ms

export class Device {
    static wakeLock = null;
    static watchId = null;
    static async startGPSTracking(updatePositionCallback, geolocationErrorCallback, gpsCoordinatesArray) {
        if (this.watchId !== null) {
          throw new Error('GPSTracking is already running.');
        }
    
        const isGpsAllowed = await this.requestGeolocationPermission();
    
        if (isGpsAllowed) {
          this.watchId = navigator.geolocation.watchPosition(updatePositionCallback, geolocationErrorCallback, {
            enableHighAccuracy: true,
            maximumAge: 10000,
            timeout: 10000,
          });
        } else {
          this.watchId = this.debugWatchPosition(updatePositionCallback, geolocationErrorCallback, gpsCoordinatesArray);
        }
    }


    static stopGPSTracking() {
        if (this.watchId === null) {
          throw new Error('GPSTracking is not running.');
        }
    
        navigator.geolocation.clearWatch(this.watchId);
        clearTimeout(this.watchId);
        this.watchId = null;
    }  

    static debugWatchPosition(callback, errorCallback, gpsCoordinatesArray) {
        let debugCurrentCoordinateIndex = 0;
        let currentLatLng = L.latLng(gpsCoordinatesArray[0]);
    
        const updateDebugPosition = () => {
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
            this.watchId = setTimeout(updateDebugPosition, simulationInterval);
        };
    
        updateDebugPosition();
        return this.watchId;
    }
    
    
    static async requestGeolocationPermission() {
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
      
    static async requestWakeLock() {
        try {
          if ('wakeLock' in navigator && 'request' in navigator.wakeLock) {
            this.wakeLock = await navigator.wakeLock.request('screen');
            console.log('Wake Lock aktiviert.');
      
            this.wakeLock.addEventListener('release', () => {
              console.log('Wake Lock wurde freigegeben.');
            });
      
            document.addEventListener('visibilitychange', async () => {
              if (this.wakeLock !== null && document.visibilityState === 'visible') {
                this.wakeLock = await navigator.wakeLock.request('screen');
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

    static vibrate() {
        if (typeof navigator.vibrate === "function") {
            navigator.vibrate(200);
        }  
    }
  }
  