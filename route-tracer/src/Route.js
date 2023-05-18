import L from 'leaflet';
import { extendLatLng } from './leafletExtensions';
import { isSpecialCoordinate } from './utils.js';

const distanceToInsert = 5; // Meter
const minSegmentLength = 10; // Meter

// Erweitert die L.LatLng-Klasse mit den zusätzlichen Funktionen
extendLatLng(L);

export class Route {
    constructor(gpsCoordinatesArray) {
        this.gpsCoordinatesArray = gpsCoordinatesArray.map(coord => ({
            lat: coord[0],
            lng: coord[1],
        }));

        this.gpsRoute = this.addExtraPoints(this.gpsCoordinatesArray);

        // Return the Proxy instead of the instance itself
        return new Proxy(this, {
            get(target, prop) {
            if (!isNaN(prop)) {
                // If the property is a number, access the array
                return target.gpsRoute[prop];
            } else if (prop in target) {
                // If the property exists in the object, access it normally
                return target[prop];
            }
            },
            set(target, prop, value) {
            if (!isNaN(prop)) {
                // If the property is a number, modify the array
                target.gpsRoute[prop] = value;
            } else {
                // If the property exists in the object, modify it normally
                target[prop] = value;
            }
            return true;
            },
        });
    }

    addExtraPoints(coords) {
        const modifiedCoords = [];
      
        for (let i = 0; i < coords.length; i++) {
          let prevCoord = i > 0 ? new L.LatLng(coords[i - 1].lat, coords[i - 1].lng) : null;
          let currentCoord = new L.LatLng(coords[i].lat, coords[i].lng);
          let nextCoord = i < coords.length - 1 ? new L.LatLng(coords[i + 1].lat, coords[i + 1].lng) : null;
      
          // Füge den eingefügten Vorgänger hinzu
          if (prevCoord && isSpecialCoordinate(prevCoord, currentCoord, nextCoord)) {
            const prevSegmentLength = currentCoord.distanceTo(prevCoord);
            if (prevSegmentLength > minSegmentLength) {
              const extraPrevCoord = currentCoord.destinationPoint(distanceToInsert, currentCoord.bearingTo(prevCoord));
              modifiedCoords.push({
                lat: extraPrevCoord.lat,
                lng: extraPrevCoord.lng,
                color: 'blue',
                synthetic: true,
              });
            }
          }
      
          // Füge die aktuelle Koordinate hinzu
          modifiedCoords.push({
            lat: currentCoord.lat,
            lng: currentCoord.lng,
            color: isSpecialCoordinate(prevCoord, currentCoord, nextCoord) ? 'yellow' : 'green',
            synthetic: false,
          });
      
          // Füge den eingefügten Nachfolger hinzu
          if (nextCoord && isSpecialCoordinate(prevCoord, currentCoord, nextCoord)) {
            const nextSegmentLength = currentCoord.distanceTo(nextCoord);
            if (nextSegmentLength > minSegmentLength) {
              const extraNextCoord = currentCoord.destinationPoint(distanceToInsert, currentCoord.bearingTo(nextCoord));
              modifiedCoords.push({
                lat: extraNextCoord.lat,
                lng: extraNextCoord.lng,
                color: 'blue',
                synthetic: true,
              });
            }
          }
        }
      
        return modifiedCoords;
    }


    getSuccessorIndexByCoordinates(currentCoordinateIndex, testCoordinate, hitDetectionDistance) {
        return this.gpsRoute.findIndex((coord, index) => {
            if (index <= currentCoordinateIndex) return false;

            const prevCoord = this.gpsRoute[currentCoordinateIndex];
            const currentCoord = L.latLng(coord);
            const prevCoordLatLng = L.latLng(prevCoord);

            const distanceToCurrent = testCoordinate.distanceTo(currentCoord);
            const distanceToPrev = testCoordinate.distanceTo(prevCoordLatLng);

            return distanceToCurrent <= hitDetectionDistance && distanceToPrev >= hitDetectionDistance;
        });
    }

    getBearingAtIndex(index) {
        if (index < this.gpsRoute.length - 1) {
          const currentCoord = L.latLng(this.gpsRoute[index]);
          const nextCoord = L.latLng(this.gpsRoute[index + 1]);
          return currentCoord.bearingTo(nextCoord);
        } else {
          throw new Error('Invalid index. Cannot calculate bearing for the last point on the route.');
        }
    }
      
    /*
    getClosestSegment(currentLatLng) {
        let minDistance = Infinity;
        let closestSegmentStartIndex = null;
      
        for (let i = 0; i < this.gpsRoute.length - 1; i++) {
          const startCoord = L.latLng(this.gpsRoute[i]);
          const endCoord = L.latLng(this.gpsRoute[i + 1]);
          const currentDistance = currentLatLng.distanceToSegment(startCoord, endCoord);
      
          if (currentDistance < minDistance) {
            minDistance = currentDistance;
            closestSegmentStartIndex = i;
          }
        }
      
        if (closestSegmentStartIndex === null) {
          throw new Error('Could not find closest segment.');
        }
      
        return [closestSegmentStartIndex, closestSegmentStartIndex + 1];
    }
    */
    getClosestSegment(currentLatLng) {
        let minDistance = Infinity;
        let closestSegmentStartIndex = null;
      
        for (let i = 0; i < this.gpsRoute.length - 1; i++) {
          const startCoord = L.latLng(this.gpsRoute[i]);
          const endCoord = L.latLng(this.gpsRoute[i + 1]);
          const currentDistance = currentLatLng.distanceToSegment(startCoord, endCoord);
      
          if (currentDistance < minDistance) {
            minDistance = currentDistance;
            closestSegmentStartIndex = i;
          }
        }
      
        if (closestSegmentStartIndex === null) {
          throw new Error('Could not find closest segment.');
        }
      
        const closestSegmentEndIndex = closestSegmentStartIndex + 1;
      
        return {
          start: {
            index: closestSegmentStartIndex,
            coord: this.gpsRoute[closestSegmentStartIndex],
          },
          end: {
            index: closestSegmentEndIndex,
            coord: this.gpsRoute[closestSegmentEndIndex]
          },
          distance: minDistance,
        };
      }
      
      
    
    getRandomPointNearRoute() {
        const randomIndex = Math.floor(Math.random() * this.gpsRoute.length);
        const randomRadius = 2 + Math.random() * 18; // Radius between 2 and 20 meters
    
        const originalPoint = L.latLng(this.gpsRoute[randomIndex]);
        const randomBearing = Math.random() * 360; // Random bearing in degrees
    
        // Use the destinationPoint method from the extendLatLng method to calculate the new point
        const randomPoint = originalPoint.destinationPoint(randomRadius, randomBearing);
    
        return {
            lat: randomPoint.lat,
            lng: randomPoint.lng,
        };
    }
    
    get length() {
        return this.gpsRoute.length;
    }

    get(index) {
        console.log("get index: " + index)
        return this.gpsRoute[index];
    }

    set(index, coord) {
        if (typeof coord.lat === 'number' && typeof coord.lng === 'number') {
            this.gpsRoute[index] = coord;
        } else {
            throw new Error('Invalid coordinate object. It should have "lat" and "lng" properties with numeric values.');
        }
    }
    
    *[Symbol.iterator]() {
        for (let i = 0; i < this.length; i++) {
            yield this.get(i);
        }
    }

    forEach(callback) {
        this.gpsRoute.forEach(callback);
    }

    findIndex(callback) {
        return this.gpsRoute.findIndex(callback);
    }

    toString() {
        return JSON.stringify(this.gpsRoute, null, 2);
    }    

    toJSON() {
        return this.gpsRoute;
    }
    
}




