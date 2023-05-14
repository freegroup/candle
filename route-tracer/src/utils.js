
export function angleBetweenPoints(p1, p2, p3) {
    const v1 = {
      lat: p1.lat - p2.lat,
      lng: p1.lng - p2.lng,
    };
    
    const v2 = {
      lat: p3.lat - p2.lat,
      lng: p3.lng - p2.lng,
    };
    
    const dotProduct = v1.lat * v2.lat + v1.lng * v2.lng;
    const v1Magnitude = Math.sqrt(v1.lat * v1.lat + v1.lng * v1.lng);
    const v2Magnitude = Math.sqrt(v2.lat * v2.lat + v2.lng * v2.lng);
    
    const cosAngle = dotProduct / (v1Magnitude * v2Magnitude);
    const angle = Math.acos(cosAngle) * (180 / Math.PI);
  
    return angle;
  }
  
  export function isSpecialCoordinate(prevCoordLatLng, currentCoordLatLng, nextCoordLatLng){
    if (!prevCoordLatLng || !currentCoordLatLng || !nextCoordLatLng) {
      return false;
    }
    const angle = angleBetweenPoints(prevCoordLatLng, currentCoordLatLng, nextCoordLatLng);
    return (angle >= 60 && angle <= 120)
  }