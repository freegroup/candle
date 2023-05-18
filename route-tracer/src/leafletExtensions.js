
// Erweitert die L.LatLng-Klasse um zusätzliche Funktionen
export const extendLatLng = function (L) {

    // Add these utility functions to the code
    L.LatLng.prototype.toRadians = function () {
        return {
        lat: this.lat * Math.PI / 180,
        lng: this.lng * Math.PI / 180,
        };
    };
    

    L.LatLng.prototype.distanceToSquared = function(otherLatLng) {
        const dx = this.lat - otherLatLng.lat;
        const dy = this.lng - otherLatLng.lng;
        return dx * dx + dy * dy;
    };
      
    L.LatLng.prototype.distanceToSegment = function(a, b) {
        const p = this;
        const l2 = a.distanceToSquared(b);
      
        if (l2 === 0) {
          return p.distanceTo(a);
        }
      
        const t = ((p.lat - a.lat) * (b.lat - a.lat) + (p.lng - a.lng) * (b.lng - a.lng)) / l2;
      
        if (t < 0) {
          return p.distanceTo(a);
        }
        if (t > 1) {
          return p.distanceTo(b);
        }
      
        const projectedPoint = L.latLng(
          a.lat + t * (b.lat - a.lat),
          a.lng + t * (b.lng - a.lng)
        );
      
        return p.distanceTo(projectedPoint);
      };
      
    L.LatLng.prototype.bearingTo = function (destination) {
        const rad1 = this.toRadians();
        const rad2 = destination.toRadians();
        const dLng = rad2.lng - rad1.lng;
      
        const y = Math.sin(dLng) * Math.cos(rad2.lat);
        const x = Math.cos(rad1.lat) * Math.sin(rad2.lat) - Math.sin(rad1.lat) * Math.cos(rad2.lat) * Math.cos(dLng);

        function toDegrees(radians) {
            return radians * (180 / Math.PI);
          }

        const bearing = toDegrees(Math.atan2(y, x));
      
        return (bearing + 360) % 360;
      };
      
    
    L.LatLng.prototype.destinationPoint = function (distance, bearing) {
        const radius = 6371e3; // Earth's radius in meters
        const delta = distance / radius; // Angular distance in radians
        const start = this.toRadians();
        const bearingRadians = (bearing * Math.PI) / 180;
    
        const lat = Math.asin(
        Math.sin(start.lat) * Math.cos(delta) +
            Math.cos(start.lat) * Math.sin(delta) * Math.cos(bearingRadians)
        );
    
        const lng =
        start.lng +
        Math.atan2(
            Math.sin(bearingRadians) * Math.sin(delta) * Math.cos(start.lat),
            Math.cos(delta) - Math.sin(start.lat) * Math.sin(lat)
        );
    
        return new L.LatLng((lat * 180) / Math.PI, (lng * 180) / Math.PI);
    };
};