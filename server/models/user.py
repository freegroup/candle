from sqlalchemy import text
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Float, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import text
from utils.database import Base
from sqlalchemy import ForeignKey

class AppUser(Base):
    __tablename__ = 'app_users'

    id = Column(UUID(as_uuid=True), primary_key=True, default=text("gen_random_uuid()"))
    name = Column(String, nullable=False)
    email = Column(String, nullable=False, unique=True)
    created_date = Column(DateTime, nullable=False, default=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
    stride_length = Column(Float, nullable=True)

    __table_args__ = (
        UniqueConstraint('email', name='uix_email'),
    )

    def serialize(self):
            return {
                'id': str(self.id),
                'name': self.name,
                'email': self.email,
                'created_date': str(self.created_date),
                'last_login': str(self.last_login),
                'stride_length': self.stride_length
            }