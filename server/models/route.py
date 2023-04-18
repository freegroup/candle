from sqlalchemy import text
from sqlalchemy import Column, String, Float
from sqlalchemy.dialects.postgresql import UUID
from utils.database import Base, SessionLocal
from models.coordinate import Coordinate
from sqlalchemy import ForeignKey

class Route(Base):
    __tablename__ = 'routes'

    id = Column(UUID(as_uuid=True), primary_key=True, default=text("gen_random_uuid()"))
    user_id = Column(UUID(as_uuid=True), ForeignKey('app_users.id'), nullable=False)
    name = Column(String, nullable=True)
    description = Column(String, nullable=True)
    length = Column(Float, nullable=True)


    # Add a property to cache the coordinates
    _coordinates_cache = None

    def get_coordinates(self):
        if self._coordinates_cache is None:
            session = SessionLocal()
            coordinates = session.query(Coordinate).filter_by(route_id=self.id).all()
            session.close()
            self._coordinates_cache = coordinates
        return self._coordinates_cache


    def serialize_geojson(self):
        coordinates = self.get_coordinates()

        # Create a GeoJSON object
        geojson = {
            "type": "FeatureCollection",
            "features": [
                {
                    "type": "Feature",
                    "properties": {
                        "route_id": str(self.id),
                        "name": self.name,
                        "description": self.description,
                        "length": self.length
                    },
                    "geometry": {
                        "type": "LineString",
                        "coordinates": [
                            [coordinate.longitude, coordinate.latitude]
                            for coordinate in coordinates
                        ],
                    },
                }
            ],
        }

        return geojson

    # Add this method to the Route class
    def serialize(self):
        return {
            'id': str(self.id),
            'user_id': str(self.user_id),
            'name': self.name,
            'description': self.description,
            'length': self.length
        }
