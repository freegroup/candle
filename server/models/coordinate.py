from sqlalchemy import text
from sqlalchemy import Column, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from utils.database import Base
from sqlalchemy import ForeignKey

class Coordinate(Base):
    __tablename__ = 'coordinates'

    id = Column(UUID(as_uuid=True), primary_key=True, default=text("gen_random_uuid()"))
    route_id = Column(UUID(as_uuid=True), ForeignKey('routes.id'), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
