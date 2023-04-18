from sqlalchemy import text
from sqlalchemy import Column, String, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from utils.database import Base
from sqlalchemy import ForeignKey

class Attachment(Base):
    __tablename__ = 'attachments'

    id = Column(UUID(as_uuid=True), primary_key=True, default=text("gen_random_uuid()"))
    coordinate_id = Column(UUID(as_uuid=True), ForeignKey('coordinates.id'), nullable=False)
    mimetype = Column(String, nullable=False)
    content = Column(String, nullable=False)
