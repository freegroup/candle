from sqlalchemy import text
from sqlalchemy import Column, String, Float
from sqlalchemy.dialects.postgresql import UUID
from utils.database import Base
from sqlalchemy import ForeignKey

class Route(Base):
    __tablename__ = 'routes'

    id = Column(UUID(as_uuid=True), primary_key=True, default=text("gen_random_uuid()"))
    user_id = Column(UUID(as_uuid=True), ForeignKey('app_users.id'), nullable=False)
    name = Column(String, nullable=True)
    description = Column(String, nullable=True)
    length = Column(Float, nullable=True)
